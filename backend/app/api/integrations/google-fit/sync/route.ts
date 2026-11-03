import { authenticate, handleError, json } from '@/lib/api-utils';
import { integrationService } from '@/lib/services/integration.service';
import { googleFitService } from '@/lib/services/google-fit.service';
import { prisma } from '@/lib/prisma';
import { logger } from '@/lib/logger';

export const runtime = 'nodejs';

export async function POST() {
  try {
    const session = await authenticate();

    const athlete = await prisma.athlete.findUnique({
      where: { userId: session.user.id },
      select: { id: true },
    });
    if (!athlete) {
      return json({ error: 'Atleta não encontrado' }, 404);
    }

    const integration = await integrationService.getIntegration(session.user.id, 'google_fit');
    if (!integration) {
      return json({ error: 'Google Fit não conectado' }, 400);
    }

    let accessToken = integration.accessToken;

    if (integration.expiresAt && integration.expiresAt < new Date() && integration.refreshToken) {
      const refreshed = await googleFitService.refreshAccessToken(integration.refreshToken);
      await integrationService.saveTokens(session.user.id, 'google_fit', refreshed);
      accessToken = refreshed.accessToken;
    }

    if (!accessToken) return json({ error: 'Reconecte o Google Fit antes de sincronizar.' }, 400);

    const endTime = new Date();
    const startTime = integration.lastSyncAt
      ? new Date(integration.lastSyncAt.getTime() - 86400000)
      : new Date(endTime.getTime() - 7 * 86400000);

    const { session: fitSessions } = await googleFitService.fetchSessions(accessToken, startTime, endTime);

    let imported = 0;
    let skipped = 0;

    for (const fitSession of fitSessions) {
      const existing = await prisma.workoutSession.findFirst({
        where: { athleteId: athlete.id },
        orderBy: { completedAt: 'desc' },
        select: { completedAt: true },
      });

      if (existing) {
        skipped++;
        continue;
      }

      const startDate = new Date(Number(fitSession.startTimeMillis));
      const endDate = new Date(Number(fitSession.endTimeMillis));
      const durationSec = Math.round((endDate.getTime() - startDate.getTime()) / 1000);

      await prisma.workoutSession.create({
        data: {
          athleteId: athlete.id,
          modality: googleFitService.mapActivityType(fitSession.activityType),
          durationSec: Math.max(durationSec, 1),
          completedAt: startDate,
        },
      });

      imported++;
    }

    const dataSources = await googleFitService.fetchDataSources(accessToken);
    const heartRateSource = dataSources.dataSource.find(
      (ds) => ds.dataType.name === 'com.google.heart_rate.bpm',
    );

    if (heartRateSource) {
      const hrData = await googleFitService.fetchDataset(
        accessToken,
        heartRateSource.dataStreamId,
        startTime,
        endTime,
      );

      if (hrData.point?.length > 0) {
        const avgBpm = Math.round(
          hrData.point.reduce((acc, p) => {
            const val = p.value?.[0]?.fpVal ?? 0;
            return acc + val;
          }, 0) / hrData.point.length,
        );

        const lastSession = await prisma.workoutSession.findFirst({
          where: { athleteId: athlete.id },
          orderBy: { completedAt: 'desc' },
        });

        if (lastSession && avgBpm > 0) {
          await prisma.workoutSession.update({
            where: { id: lastSession.id },
            data: { avgHeartRate: avgBpm },
          });
        }
      }
    }

    await integrationService.updateLastSync(session.user.id, 'google_fit');

    logger.info({ imported, skipped }, '[GoogleFit] Sync completed');

    return json({ imported, skipped, total: fitSessions.length });
  } catch (error) {
    return handleError(error);
  }
}

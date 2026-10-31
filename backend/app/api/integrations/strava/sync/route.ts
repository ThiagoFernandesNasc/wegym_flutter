import { authenticate, handleError, json } from '@/lib/api-utils';
import { integrationService } from '@/lib/services/integration.service';
import { stravaService } from '@/lib/services/strava.service';
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

    const integration = await integrationService.getIntegration(session.user.id, 'strava');
    if (!integration) {
      return json({ error: 'Strava não conectado' }, 400);
    }

    let accessToken = integration.accessToken;

    if (integration.expiresAt && integration.expiresAt < new Date() && integration.refreshToken) {
      const refreshed = await stravaService.refreshAccessToken(integration.refreshToken);
      await integrationService.saveTokens(session.user.id, 'strava', refreshed);
      accessToken = refreshed.accessToken;
    }

    if (!accessToken) return json({ error: 'Strava token unavailable; reconnect the integration' }, 400);

    const activities = await stravaService.fetchActivities(
      accessToken,
      integration.lastSyncAt ?? undefined,
    );

    let imported = 0;
    let skipped = 0;

    for (const activity of activities) {
      const existing = await prisma.workoutSession.findFirst({
        where: { athleteId: athlete.id, modality: stravaService.mapStravaTypeToModality(activity.type, activity.sport_type) },
        orderBy: { completedAt: 'desc' },
        select: { completedAt: true },
      });

      if (existing) {
        skipped++;
        continue;
      }

      await prisma.workoutSession.create({
        data: {
          athleteId: athlete.id,
          modality: stravaService.mapStravaTypeToModality(activity.type, activity.sport_type),
          durationSec: activity.moving_time,
          distanceKm: activity.distance > 0 ? activity.distance / 1000 : undefined,
          avgPaceSecPerKm: activity.distance > 0
            ? Math.round(activity.moving_time / (activity.distance / 1000))
            : undefined,
          calories: activity.calories,
          avgHeartRate: activity.average_heartrate,
          completedAt: new Date(activity.start_date),
        },
      });

      if (activity.start_latlng && activity.start_latlng.length === 2) {
        await prisma.gpsSession.create({
          data: {
            athleteId: athlete.id,
            modality: stravaService.mapStravaTypeToModality(activity.type, activity.sport_type),
            distanceKm: activity.distance / 1000,
            durationSec: activity.moving_time,
            avgPaceSecPerKm: activity.distance > 0
              ? Math.round(activity.moving_time / (activity.distance / 1000))
              : undefined,
            startLat: activity.start_latlng[0],
            startLng: activity.start_latlng[1],
            endLat: activity.end_latlng?.[0],
            endLng: activity.end_latlng?.[1],
            completedAt: new Date(activity.start_date),
          },
        });
      }

      imported++;
    }

    await integrationService.updateLastSync(session.user.id, 'strava');

    logger.info({ imported, skipped, userId: session.user.id }, '[Strava] Sync completed');

    return json({ imported, skipped, total: activities.length });
  } catch (error) {
    return handleError(error);
  }
}

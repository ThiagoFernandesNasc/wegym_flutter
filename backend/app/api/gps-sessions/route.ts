import { authenticate, handleError, created, withRateLimit } from '@/lib/api-utils';
import { gpsSessionService } from '@/lib/services/gps-session.service';
import { gamificationService } from '@/lib/services/gamification.service';
import { logger } from '@/lib/logger';
import { requireAthleteAccess } from '@/lib/athlete-access';
import { prisma } from '@/lib/prisma';
import { z } from 'zod';

export const runtime = 'nodejs';

const createSchema = z.object({
  modality: z.string().min(1),
  distanceKm: z.number().positive(),
  durationSec: z.number().int().positive(),
  avgPaceSecPerKm: z.number().int().optional(),
  steps: z.number().int().optional(),
  coordinates: z.any().optional(),
  startLat: z.number().optional(),
  startLng: z.number().optional(),
  endLat: z.number().optional(),
  endLng: z.number().optional(),
  athleteId: z.string().uuid().optional(),
});

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `gps-sessions:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;
    const parsed = createSchema.parse(await request.json());
    const athlete = parsed.athleteId
      ? await (async () => {
          await requireAthleteAccess(parsed.athleteId!, session.user.id);
          return prisma.athlete.findUnique({ where: { id: parsed.athleteId }, select: { id: true, userId: true } });
        })()
      : await prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true, userId: true } });
    if (!athlete) return Response.json({ error: 'Perfil de atleta não encontrado.' }, { status: 404 });

    const sessionData = { ...parsed };
    delete sessionData.athleteId;
    const result = await gpsSessionService.create({ athleteId: athlete.id, ...sessionData });
    try {
      await gamificationService.checkWorkoutAchievements(athlete.userId, athlete.id);
    } catch (error) {
      logger.warn({ error, userId: athlete.userId }, '[Gamification] Falha ao atualizar medalhas após atividade GPS');
    }
    return created(result);
  } catch (error) {
    return handleError(error);
  }
}

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const cursor = searchParams.get('cursor') ?? undefined;
    const limit = Number(searchParams.get('limit')) || 50;
    const requestedAthleteId = searchParams.get('athleteId');
    const athlete = requestedAthleteId
      ? await (async () => {
          await requireAthleteAccess(requestedAthleteId, session.user.id);
          return prisma.athlete.findUnique({ where: { id: requestedAthleteId }, select: { id: true } });
        })()
      : await prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true } });
    if (!athlete) {
      if ((session.user as { role?: string }).role === 'personal') return Response.json({ data: [] });
      return Response.json({ error: 'Perfil de atleta não encontrado.' }, { status: 404 });
    }
    return Response.json(await gpsSessionService.list(athlete.id, limit, cursor));
  } catch (error) {
    return handleError(error);
  }
}

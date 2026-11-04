import { authenticate, handleError, created, withRateLimit } from '@/lib/api-utils';
import { workoutSessionService } from '@/lib/services/workout-session.service';
import { gamificationService } from '@/lib/services/gamification.service';
import { logger } from '@/lib/logger';
import { requireAthleteAccess } from '@/lib/athlete-access';
import { prisma } from '@/lib/prisma';
import { z } from 'zod';

export const runtime = 'nodejs';

const createSchema = z.object({
  modality: z.string().min(1),
  durationSec: z.number().int().positive(),
  distanceKm: z.number().optional(),
  avgPaceSecPerKm: z.number().int().optional(),
  steps: z.number().int().optional(),
  calories: z.number().optional(),
  avgHeartRate: z.number().int().optional(),
  exercises: z.any().optional(),
  athleteId: z.string().uuid().optional(),
});

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `workout-sessions:${session.user.id}`);
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
    const result = await workoutSessionService.create({ athleteId: athlete.id, ...sessionData });
    try {
      await gamificationService.checkWorkoutAchievements(athlete.userId, athlete.id);
    } catch (error) {
      logger.warn({ error, userId: athlete.userId }, '[Gamification] Falha ao atualizar medalhas');
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
    const result = await workoutSessionService.list(athlete.id, limit, cursor);
    return Response.json(result);
  } catch (error) {
    return handleError(error);
  }
}

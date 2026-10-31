import { authenticate, handleError, created, withRateLimit } from '@/lib/api-utils';
import { workoutSessionService } from '@/lib/services/workout-session.service';
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
});

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `workout-sessions:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = createSchema.parse(body);

    const athlete = await import('@/lib/prisma').then(({ prisma }) =>
      prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true } })
    );
    if (!athlete) {
      return Response.json({ error: 'Atleta não encontrado' }, { status: 404 });
    }

    const result = await workoutSessionService.create({
      athleteId: athlete.id,
      ...parsed,
    });
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

    const athlete = await import('@/lib/prisma').then(({ prisma }) =>
      prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true } })
    );
    if (!athlete) {
      return Response.json({ error: 'Atleta não encontrado' }, { status: 404 });
    }

    const result = await workoutSessionService.list(athlete.id, limit, cursor);
    return Response.json(result);
  } catch (error) {
    return handleError(error);
  }
}

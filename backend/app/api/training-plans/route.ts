import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { trainingPlanService } from '@/lib/services/training-plan.service';
import { z } from 'zod';

export const runtime = 'nodejs';

const upsertSchema = z.object({
  athleteId: z.string().uuid(),
  day: z.string().min(1),
  exercises: z.array(z.object({
    name: z.string().min(1),
    sets: z.string().min(1),
    reps: z.string().min(1),
    load: z.string().optional().default('0'),
  })),
});

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `training-plans:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = upsertSchema.parse(body);
    const id = await trainingPlanService.upsert(parsed.athleteId, parsed.day, parsed.exercises);
    return created({ id });
  } catch (error) {
    return handleError(error);
  }
}

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const athleteId = searchParams.get('athleteId');
    if (!athleteId) {
      return json({ error: 'athleteId é obrigatório' }, 400);
    }
    const role = (session.user as { role?: string }).role;
    if (role === 'athlete' && session.user.id !== athleteId) {
      return json({ error: 'Acesso negado' }, 403);
    }
    const plans = await trainingPlanService.getByAthlete(athleteId);
    return json({ data: plans });
  } catch (error) {
    return handleError(error);
  }
}

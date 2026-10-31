import { authenticate, handleError, json, created, requireRole, withRateLimit } from '@/lib/api-utils';
import { progressService } from '@/lib/services/progress.service';
import { z } from 'zod';

export const runtime = 'nodejs';

const createSchema = z.object({
  athleteId: z.string().uuid(),
  date: z.string().min(1),
  weight: z.number().positive(),
  muscleMass: z.number().optional(),
  bodyFat: z.number().optional(),
  note: z.string().optional(),
});

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `progress:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = createSchema.parse(body);
    const entry = await progressService.create(parsed.athleteId, parsed);
    return created(entry);
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
    if (session.user.id !== athleteId && (session.user as { role?: string }).role !== 'personal') {
      return json({ error: 'Sem permissão para acessar estes dados' }, 403);
    }
    const entries = await progressService.list(athleteId);
    return json({ data: entries });
  } catch (error) {
    return handleError(error);
  }
}

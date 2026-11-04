import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { measurementService } from '@/lib/services/measurement.service';
import { prisma } from '@/lib/prisma';
import { measurementSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

async function resolveAthlete(userId: string, role: string | undefined, athleteId?: string | null) {
  if (role === 'personal') {
    if (!athleteId) return null;
    return prisma.athlete.findFirst({
      where: { id: athleteId, personal: { userId } },
      select: { id: true },
    });
  }
  return prisma.athlete.findUnique({ where: { userId }, select: { id: true } });
}

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const role = (session.user as { role?: string }).role;
    const athlete = await resolveAthlete(
      session.user.id,
      role,
      searchParams.get('athleteId'),
    );
    if (!athlete) {
      const status = role === 'personal' && !searchParams.has('athleteId') ? 400 : 404;
      return json({ error: role === 'personal' ? 'Selecione um aluno vinculado.' : 'Atleta n\u00e3o encontrado' }, status);
    }

    const metric = searchParams.get('metric');
    if (metric && ['weight', 'muscleMass', 'bodyFat'].includes(metric)) {
      const chart = await measurementService.getChartData(athlete.id, metric as 'weight' | 'muscleMass' | 'bodyFat');
      return json(chart);
    }
    const entries = await measurementService.list(athlete.id);
    return json(entries);
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, 'measurements:' + session.user.id);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const role = (session.user as { role?: string }).role;
    const athleteId = typeof body?.athleteId === 'string' ? body.athleteId : null;
    const athlete = await resolveAthlete(session.user.id, role, athleteId);
    if (!athlete) {
      const status = role === 'personal' && !athleteId ? 400 : 404;
      return json({ error: role === 'personal' ? 'Aluno n\u00e3o encontrado ou n\u00e3o vinculado a este personal.' : 'Atleta n\u00e3o encontrado' }, status);
    }

    const parsed = measurementSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Medida inv\u00e1lida', parsed.error.issues);
    const entry = await measurementService.create(athlete.id, {
      ...parsed.data,
      date: parsed.data.date ? new Date(parsed.data.date) : undefined,
    });
    return created(entry);
  } catch (error) {
    return handleError(error);
  }
}

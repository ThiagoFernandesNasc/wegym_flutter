import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { measurementService } from '@/lib/services/measurement.service';
import { prisma } from '@/lib/prisma';
import { measurementSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const athlete = await prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true } });
    if (!athlete) return json({ error: 'Atleta não encontrado' }, 404);
    const { searchParams } = new URL(request.url);
    const metric = searchParams.get('metric');
    if (metric && ['weight', 'muscleMass', 'bodyFat'].includes(metric)) {
      const chart = await measurementService.getChartData(athlete.id, metric as any);
      return json(chart);
    }
    const entries = await measurementService.list(athlete.id);
    return json(entries);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `measurements:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const athlete = await prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true } });
    if (!athlete) return json({ error: 'Atleta não encontrado' }, 404);
    const body = await request.json();
    const parsed = measurementSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Medida inválida', parsed.error.issues);

    const entry = await measurementService.create(athlete.id, {
      ...parsed.data,
      date: parsed.data.date ? new Date(parsed.data.date) : undefined,
    });
    return created(entry);
  } catch (error) { return handleError(error); }
}

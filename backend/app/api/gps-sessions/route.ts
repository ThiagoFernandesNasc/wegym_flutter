import { authenticate, handleError, created, withRateLimit } from '@/lib/api-utils';
import { gpsSessionService } from '@/lib/services/gps-session.service';
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
});

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `gps-sessions:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = createSchema.parse(body);

    const athlete = await import('@/lib/prisma').then(({ prisma }) =>
      prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true } })
    );
    if (!athlete) {
      return Response.json({ error: 'Atleta não encontrado' }, { status: 404 });
    }

    const result = await gpsSessionService.create({
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

    const result = await gpsSessionService.list(athlete.id, limit, cursor);
    return Response.json(result);
  } catch (error) {
    return handleError(error);
  }
}

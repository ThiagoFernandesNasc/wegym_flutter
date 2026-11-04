import { prisma } from '@/lib/prisma';
import { authenticate, handleError, json, cache, created, requireRole, withRateLimit } from '@/lib/api-utils';
import { ValidationError } from '@/lib/errors';
import { weeklyClassSchema } from '@/lib/validation';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const userRole = (session.user as { role?: string }).role;
    const userId = session.user.id;

    const cacheKey = `classes:${userId}:${userRole}`;

    const classes = await cache.getOrSet(
      cacheKey,
      () =>
        prisma.weeklyClass.findMany({
          where: userRole === 'personal'
            ? { athlete: { personal: { userId } } }
            : { athlete: { userId } },
          orderBy: { date: 'asc' },
          select: {
            id: true,
            day: true,
            date: true,
            time: true,
            type: true,
            status: true,
            athlete: { select: { id: true, name: true } },
          },
        }),
      30,
    );

    return json(classes, 200, 30);
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(request: Request) {
  try {
    const session = await requireRole(['personal']);
    const rateLimitResponse = await withRateLimit(
      request,
      `classes:create:${session.user.id}`,
    );
    if (rateLimitResponse) return rateLimitResponse;

    const parsed = weeklyClassSchema.safeParse(await request.json());
    if (!parsed.success) {
      throw new ValidationError('Confira os dados da aula.', parsed.error.issues);
    }

    const athlete = await prisma.athlete.findFirst({
      where: {
        id: parsed.data.athleteId,
        personal: { userId: session.user.id },
      },
      select: { id: true, userId: true },
    });
    if (!athlete) {
      return json({ error: 'O aluno selecionado não está vinculado a este Personal.' }, 404);
    }

    const createdClass = await prisma.weeklyClass.create({
      data: {
        athleteId: athlete.id,
        day: parsed.data.day,
        date: new Date(parsed.data.date),
        time: parsed.data.time,
        type: parsed.data.type,
        status: 'confirmed',
      },
      select: {
        id: true,
        day: true,
        date: true,
        time: true,
        type: true,
        status: true,
        athlete: { select: { id: true, name: true } },
      },
    });

    await cache.delPattern('classes:');
    return created(createdClass);
  } catch (error) {
    return handleError(error);
  }
}

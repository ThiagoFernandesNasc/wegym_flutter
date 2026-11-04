import { requireRole, handleError, json, cache } from '@/lib/api-utils';
import { prisma } from '@/lib/prisma';
import { ConflictError, NotFoundError, ValidationError } from '@/lib/errors';
import { z } from 'zod';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await requireRole(['personal']);
    const personal = await prisma.personalTrainer.findUnique({
      where: { userId: session.user.id },
      select: { id: true },
    });
    if (!personal) throw new NotFoundError('Personal trainer');

    const athletes = await prisma.athlete.findMany({
      where: { personalId: null, user: { role: 'atleta' } },
      orderBy: { name: 'asc' },
      take: 100,
      select: {
        id: true,
        name: true,
        city: true,
        state: true,
        experienceLevel: true,
        user: { select: { email: true } },
      },
    });
    return json({ data: athletes.map(({ user, ...athlete }) => ({ ...athlete, email: user.email })) });
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(req: Request) {
  try {
    const session = await requireRole(['personal']);
    const body = await req.json();
    const parsed = z.object({ athleteId: z.string().uuid() }).safeParse(body);
    if (!parsed.success) throw new ValidationError('Selecione uma conta de aluno v\u00e1lida.');

    const personal = await prisma.personalTrainer.findUnique({
      where: { userId: session.user.id },
      select: { id: true },
    });
    if (!personal) throw new NotFoundError('Personal trainer');

    const linked = await prisma.athlete.updateMany({
      where: { id: parsed.data.athleteId, personalId: null, user: { role: 'atleta' } },
      data: { personalId: personal.id },
    });
    if (linked.count !== 1) {
      throw new ConflictError('Este aluno n\u00e3o est\u00e1 dispon\u00edvel para v\u00ednculo. Atualize a lista e tente novamente.');
    }

    const linkedAthlete = await prisma.athlete.findUnique({
      where: { id: parsed.data.athleteId },
      select: { userId: true },
    });
    await cache.delPattern('athletes:list:*');
    if (linkedAthlete) await cache.del(`profile:${linkedAthlete.userId}`);
    return json({ success: true, athleteId: parsed.data.athleteId });
  } catch (error) {
    return handleError(error);
  }
}

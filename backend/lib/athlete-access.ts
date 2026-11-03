import { prisma } from './prisma';
import { ForbiddenError, NotFoundError } from './errors';
export async function requireAthleteAccess(athleteId: string, userId: string) {
  const athlete = await prisma.athlete.findUnique({
    where: { id: athleteId }, select: { userId: true, personal: { select: { userId: true } } },
  });
  if (!athlete) throw new NotFoundError('Atleta');
  if (athlete.userId !== userId && athlete.personal?.userId !== userId) throw new ForbiddenError();
}

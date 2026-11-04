import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';
import { ForbiddenError, NotFoundError, ValidationError } from '@/lib/errors';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(
      request,
      'challenge-leave:' + session.user.id,
    );
    if (rateLimitResponse) return rateLimitResponse;

    const { id } = await params;
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(id)) {
      throw new ValidationError('Identificador de desafio inválido');
    }
    const { searchParams } = new URL(request.url);
    const athleteId = searchParams.get('athleteId');
    let participantUserId = session.user.id;
    if (athleteId) {
      if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(athleteId)) {
        throw new ValidationError('Identificador do aluno inválido');
      }
      const role = (session.user as { role?: string }).role;
      if (role !== 'personal') {
        throw new ForbiddenError('Somente um personal pode retirar um aluno.');
      }
      const athlete = await prisma.athlete.findFirst({
        where: { id: athleteId, personal: { userId: session.user.id } },
        select: { userId: true },
      });
      if (!athlete) throw new NotFoundError('Aluno vinculado');
      participantUserId = athlete.userId;
    }
    await gamificationService.leaveChallenge(participantUserId, id);
    return json({ left: true });
  } catch (error) {
    return handleError(error);
  }
}

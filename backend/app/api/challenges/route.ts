import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';
import { challengeCreateSchema, challengeJoinSchema } from '@/lib/validation';
import { ForbiddenError, NotFoundError, ValidationError } from '@/lib/errors';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const challenges = await gamificationService.listChallenges();
    return json(challenges);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(
      request,
      'challenges:' + session.user.id,
    );
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    if (body && typeof body.challengeId === 'string') {
      const parsedJoin = challengeJoinSchema.safeParse(body);
      if (!parsedJoin.success) {
        throw new ValidationError(
          'Identificador de desafio inválido',
          parsedJoin.error.issues,
        );
      }
      let participantUserId = session.user.id;
      if (parsedJoin.data.athleteId) {
        const role = (session.user as { role?: string }).role;
        if (role !== 'personal') {
          throw new ForbiddenError('Somente um personal pode inscrever um aluno.');
        }
        const athlete = await prisma.athlete.findFirst({
          where: {
            id: parsedJoin.data.athleteId,
            personal: { userId: session.user.id },
          },
          select: { userId: true },
        });
        if (!athlete) throw new NotFoundError('Aluno vinculado');
        participantUserId = athlete.userId;
      }
      const participant = await gamificationService.joinChallenge(
        participantUserId,
        parsedJoin.data.challengeId,
      );
      return created(participant);
    }

    const parsed = challengeCreateSchema.safeParse(body);
    if (!parsed.success) {
      throw new ValidationError(
        'Confira os dados do desafio',
        parsed.error.issues,
      );
    }
    const challenge = await gamificationService.createChallenge(
      session.user.id,
      {
        ...parsed.data,
        startDate: new Date(parsed.data.startDate),
        endDate: new Date(parsed.data.endDate),
      },
    );
    return created(challenge);
  } catch (error) {
    return handleError(error);
  }
}

import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';
import { ValidationError } from '@/lib/errors';

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
    await gamificationService.leaveChallenge(session.user.id, id);
    return json({ left: true });
  } catch (error) {
    return handleError(error);
  }
}

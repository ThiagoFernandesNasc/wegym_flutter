import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';
import { challengeJoinSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

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
    const rateLimitResponse = await withRateLimit(request, `challenges:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = challengeJoinSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Dados inválidos', parsed.error.issues);

    const participant = await gamificationService.joinChallenge(session.user.id, parsed.data.challengeId);
    return created(participant);
  } catch (error) { return handleError(error); }
}

import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { socialService } from '@/lib/services/social.service';
import { friendRequestSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `friends:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const friends = await socialService.getFriends(session.user.id);
    return json(friends);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `friends:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = friendRequestSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Dados inválidos', parsed.error.issues);

    if (parsed.data.action === 'respond') {
      const result = await socialService.respondToFriend(parsed.data.friendshipId!, 'accepted');
      return json(result);
    }
    const friendship = await socialService.sendFriendRequest(session.user.id, parsed.data.addresseeId!);
    return json(friendship);
  } catch (error) { return handleError(error); }
}

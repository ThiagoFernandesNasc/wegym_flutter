import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { socialService } from '@/lib/services/social.service';
import { prisma } from '@/lib/prisma';
import { friendRequestSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `friends:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const { searchParams } = new URL(request.url);
    if (searchParams.get('includeRequests') === '1') {
      return json(await socialService.getFriendRequests(session.user.id));
    }
    return json(await socialService.getFriends(session.user.id));
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
      const result = await socialService.respondToFriend(
        parsed.data.friendshipId!,
        session.user.id,
        parsed.data.response === 'reject' ? 'rejected' : 'accepted',
      );
      return json(result);
    }
    let addresseeId = parsed.data.addresseeId;
    if (parsed.data.addresseeEmail) {
      const recipient = await prisma.user.findUnique({
        where: { email: parsed.data.addresseeEmail.toLowerCase() },
        select: { id: true },
      });
      if (!recipient) return json({ error: 'Usuário não encontrado' }, 404);
      addresseeId = recipient.id;
    }
    if (addresseeId === session.user.id) {
      return json({ error: 'Não é possível adicionar a própria conta' }, 400);
    }
    const friendship = await socialService.sendFriendRequest(session.user.id, addresseeId!);
    return json(friendship);
  } catch (error) { return handleError(error); }
}

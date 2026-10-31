import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { engagementService } from '@/lib/services/engagement.service';
import { messageSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `messages:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const conversations = await engagementService.getConversations(session.user.id);
    const unread = await engagementService.getUnreadCount(session.user.id);
    return json({ conversations, unreadCount: unread });
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `messages:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = messageSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Mensagem inválida', parsed.error.issues);

    const msg = await engagementService.sendMessage(session.user.id, parsed.data.receiverId, parsed.data.text);
    return created(msg);
  } catch (error) { return handleError(error); }
}

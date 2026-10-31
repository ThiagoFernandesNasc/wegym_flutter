import { authenticate, handleError, json } from '@/lib/api-utils';
import { engagementService } from '@/lib/services/engagement.service';

export const runtime = 'nodejs';

export async function GET(request: Request, { params }: { params: Promise<{ userId: string }> }) {
  try {
    const session = await authenticate();
    const { userId } = await params;
    const messages = await engagementService.getConversation(session.user.id, userId);
    await engagementService.markAsRead(session.user.id, userId);
    return json(messages);
  } catch (error) { return handleError(error); }
}

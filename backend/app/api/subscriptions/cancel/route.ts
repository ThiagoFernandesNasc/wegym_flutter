import { authenticate, handleError, withRateLimit, getIP } from '@/lib/api-utils';
import { subscriptionService } from '@/lib/services/subscription.service';
import { auditLog } from '@/lib/audit';

export const runtime = 'nodejs';

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `subscription-cancel:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    await auditLog({
      userId: session.user.id,
      action: 'subscription.cancelled',
      ip: getIP(request),
    });

    const result = await subscriptionService.cancel(session.user.id);
    return Response.json(result);
  } catch (error) {
    return handleError(error);
  }
}

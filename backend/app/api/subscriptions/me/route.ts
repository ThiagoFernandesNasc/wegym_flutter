import { authenticate, handleError } from '@/lib/api-utils';
import { subscriptionService } from '@/lib/services/subscription.service';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const subscription = await subscriptionService.getActive(session.user.id);
    return Response.json({ data: subscription });
  } catch (error) {
    return handleError(error);
  }
}

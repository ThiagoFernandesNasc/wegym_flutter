import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { socialService } from '@/lib/services/social.service';

export const runtime = 'nodejs';

export async function POST(request: Request, { params }: { params: Promise<{ postId: string }> }) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `like:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const { postId } = await params;
    const result = await socialService.toggleLike(postId, session.user.id);
    return json(result);
  } catch (error) { return handleError(error); }
}

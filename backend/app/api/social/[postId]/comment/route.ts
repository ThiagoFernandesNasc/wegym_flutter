import { authenticate, handleError, created, withRateLimit } from '@/lib/api-utils';
import { socialService } from '@/lib/services/social.service';
import { socialCommentSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function POST(request: Request, { params }: { params: Promise<{ postId: string }> }) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `comment:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const { postId } = await params;
    const body = await request.json();
    const parsed = socialCommentSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Comentário inválido', parsed.error.issues);

    const comment = await socialService.addComment(postId, session.user.id, parsed.data.text);
    return created(comment);
  } catch (error) {
    return handleError(error);
  }
}

import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { socialService } from '@/lib/services/social.service';
import { socialPostSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    if (searchParams.get('feed') === 'friends') {
      const posts = await socialService.getFeedForUser(session.user.id);
      return json(posts);
    }
    const page = Number(searchParams.get('page')) || 1;
    const posts = await socialService.getFeed(page);
    return json(posts);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `social:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = socialPostSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Post inválido', parsed.error.issues);

    const post = await socialService.createPost(session.user.id, parsed.data);
    return created(post);
  } catch (error) { return handleError(error); }
}

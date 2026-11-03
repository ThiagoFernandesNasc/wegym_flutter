import { userService } from '@/lib/services/user.service';
import { authenticate, handleError, json, cache, withRateLimit } from '@/lib/api-utils';
import { profileUpdateSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const profile = await userService.getProfile(session.user.id);
    return json(profile);
  } catch (error) {
    return handleError(error);
  }
}

export async function PATCH(req: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(req, `profile:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await req.json();
    const parsed = profileUpdateSchema.safeParse(body);
    if (!parsed.success) {
      throw new ValidationError('Dados inválidos', parsed.error.issues);
    }

    const result = await userService.updateProfile(session.user.id, parsed.data);

    // Invalidate profile cache
    await cache.del(`profile:${session.user.id}`);

    return Response.json(result);
  } catch (error) {
    return handleError(error);
  }
}

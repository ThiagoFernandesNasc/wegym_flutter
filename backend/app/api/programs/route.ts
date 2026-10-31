import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { programService } from '@/lib/services/program.service';
import { programSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const featured = searchParams.get('featured');
    if (featured === 'true') {
      const programs = await programService.getFeatured();
      return json(programs);
    }
    const category = searchParams.get('category') ?? undefined;
    const level = searchParams.get('level') ?? undefined;
    const programs = await programService.list(category, level);
    return json(programs);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    await authenticate();
    const rateLimitResponse = await withRateLimit(request, 'programs');
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = programSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Programa inválido', parsed.error.issues);

    const program = await programService.create(parsed.data);
    return created(program);
  } catch (error) { return handleError(error); }
}

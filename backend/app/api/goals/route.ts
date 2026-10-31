import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { goalService } from '@/lib/services/goal.service';
import { goalSchema, goalUpdateSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status') ?? undefined;
    const goals = await goalService.list(session.user.id, status);
    return json(goals);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `goals:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = goalSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Meta inválida', parsed.error.issues);

    const goal = await goalService.create({
      userId: session.user.id,
      ...parsed.data,
      endDate: parsed.data.endDate ? new Date(parsed.data.endDate) : new Date(),
    });
    return created(goal);
  } catch (error) { return handleError(error); }
}

export async function PATCH(request: Request) {
  try {
    const session = await authenticate();
    const body = await request.json();
    const parsed = goalUpdateSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Dados inválidos', parsed.error.issues);

    const goal = await goalService.updateProgress(parsed.data.id, session.user.id, parsed.data.currentValue);
    return json(goal);
  } catch (error) { return handleError(error); }
}

export async function DELETE(request: Request) {
  try {
    const session = await authenticate();
    const body = await request.json();
    if (!body.id) return json({ error: 'ID obrigatório' }, 400);
    await goalService.remove(body.id, session.user.id);
    return json({ success: true });
  } catch (error) { return handleError(error); }
}

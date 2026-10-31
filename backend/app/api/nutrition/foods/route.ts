import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { nutritionService } from '@/lib/services/nutrition.service';
import { foodSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const q = searchParams.get('q') ?? '';
    const category = searchParams.get('category') ?? undefined;
    const foods = await nutritionService.searchFoods(q, category);
    return json(foods);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `foods:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = foodSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Alimento inválido', parsed.error.issues);

    const food = await nutritionService.createFoodItem({ ...parsed.data, userId: session.user.id });
    return created(food);
  } catch (error) { return handleError(error); }
}

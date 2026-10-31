import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { nutritionService } from '@/lib/services/nutrition.service';
import { mealSchema, addFoodToMealSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const date = searchParams.get('date') ? new Date(searchParams.get('date')!) : new Date();
    const meals = await nutritionService.getMealLogs(session.user.id, date);
    return json(meals);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `meals:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    if (body.foodId && body.mealId) {
      const parsed = addFoodToMealSchema.safeParse(body);
      if (!parsed.success) throw new ValidationError('Dados inválidos', parsed.error.issues);
      const mf = await nutritionService.addFoodToMeal(parsed.data.mealId, parsed.data.foodId, parsed.data.amount ?? 1);
      return json(mf);
    }
    const parsed = mealSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Refeição inválida', parsed.error.issues);
    const meal = await nutritionService.createMealLog(session.user.id, {
      ...parsed.data,
      date: parsed.data.date ? new Date(parsed.data.date) : new Date(),
    });
    return created(meal);
  } catch (error) { return handleError(error); }
}

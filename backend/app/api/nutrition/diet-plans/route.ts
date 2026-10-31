import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { nutritionService } from '@/lib/services/nutrition.service';
import { dietPlanSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const plans = await nutritionService.getDietPlans(session.user.id);
    return json(plans);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `diet-plans:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = dietPlanSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Plano inválido', parsed.error.issues);

    const plan = await nutritionService.createDietPlan(session.user.id, {
      ...parsed.data,
      endDate: parsed.data.endDate ? new Date(parsed.data.endDate) : undefined,
    });
    return created(plan);
  } catch (error) { return handleError(error); }
}

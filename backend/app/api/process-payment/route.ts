import { authenticate, handleError, withRateLimit } from '@/lib/api-utils';
import { paymentService } from '@/lib/services/payment.service';
import { paymentSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';
import { logger } from '@/lib/logger';

export const runtime = 'nodejs';

export const maxDuration = 15;

export async function POST(request: Request) {
  try {
    const rateLimitResponse = await withRateLimit(request, `payment:${request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? '127.0.0.1'}`);
    if (rateLimitResponse) return rateLimitResponse;

    const session = await authenticate();

    const body = await request.json();
    const parsed = paymentSchema.safeParse(body);
    if (!parsed.success) {
      throw new ValidationError('Dados de pagamento incompletos', parsed.error.issues);
    }

    const result = await paymentService.process(parsed.data);

    if (result.status === 'approved' && result.id) {
      try {
        const { subscriptionService } = await import('@/lib/services/subscription.service');
        await subscriptionService.create(
          session.user.id,
          parsed.data.description ?? 'wegym-pro',
          String(result.id),
        );
      } catch (err) {
        logger.error({ err }, '[Payment] Erro ao criar assinatura');
      }
    }

    return Response.json(result);
  } catch (error) {
    return handleError(error);
  }
}

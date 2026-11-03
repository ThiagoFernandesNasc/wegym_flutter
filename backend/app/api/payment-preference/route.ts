import { MercadoPagoConfig, Preference } from 'mercadopago';
import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { ValidationError } from '@/lib/errors';
import { checkoutPreferenceSchema } from '@/lib/validation';

export const runtime = 'nodejs';

const plans = {
  mensal: { title: 'WEGYM PRO Mensal', amount: 49.9, description: 'wegym-pro-mensal' },
  anual: { title: 'WEGYM PRO Anual', amount: 399.9, description: 'wegym-pro-anual' },
} as const;

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(
      request,
      `payment-preference:${session.user.id}`,
    );
    if (rateLimitResponse) return rateLimitResponse;

    const parsed = checkoutPreferenceSchema.safeParse(await request.json());
    if (!parsed.success) {
      throw new ValidationError('Plano de pagamento inválido', parsed.error.issues);
    }

    const payerEmail = session.user.email;
    if (!payerEmail) return json({ error: 'A conta não possui e-mail para o pagamento.' }, 400);

    const accessToken = process.env.MP_ACCESS_TOKEN;
    if (!accessToken) return json({ error: 'Checkout indisponível: configure MP_ACCESS_TOKEN no backend.' }, 503);

    const plan = plans[parsed.data.planId];
    const preference = new Preference(
      new MercadoPagoConfig({ accessToken, options: { timeout: 10000 } }),
    );
    const appUrl = process.env.NEXTAUTH_URL;
    const webhookUrl = appUrl ? new URL('/api/webhooks/mercadopago', appUrl) : null;
    const canNotify = webhookUrl?.protocol === 'https:' &&
      !['localhost', '127.0.0.1', '::1'].includes(webhookUrl.hostname);

    const nativeReturnUrls = {
      success: 'wegym://payment-return?payment_return=success',
      pending: 'wegym://payment-return?payment_return=pending',
      failure: 'wegym://payment-return?payment_return=failure',
    };
    const flutterAppUrl = process.env.FLUTTER_APP_URL;
    let webReturnUrls: typeof nativeReturnUrls | undefined;
    if (parsed.data.platform === 'web' && flutterAppUrl) {
      try {
        const appUrl = new URL(flutterAppUrl);
        if (appUrl.protocol === 'https:' &&
            !['localhost', '127.0.0.1', '::1'].includes(appUrl.hostname)) {
          const returnUrl = (result: string) => {
            const url = new URL(appUrl);
            url.searchParams.set('payment_return', result);
            return url.toString();
          };
          webReturnUrls = {
            success: returnUrl('success'),
            pending: returnUrl('pending'),
            failure: returnUrl('failure'),
          };
        }
      } catch {
        // An invalid optional URL must not become an open redirect.
      }
    }
    const backUrls = parsed.data.platform === 'web'
      ? webReturnUrls
      : nativeReturnUrls;

    const result = await preference.create({
      body: {
        items: [{
          id: plan.description,
          title: plan.title,
          description: 'Assinatura WeGYM Performance OS',
          quantity: 1,
          unit_price: plan.amount,
          currency_id: 'BRL',
        }],
        payer: { email: payerEmail },
        external_reference: `${session.user.id}:${parsed.data.planId}`,
        metadata: { userId: session.user.id, planId: parsed.data.planId },
        ...(backUrls ? { back_urls: backUrls, auto_return: 'approved' as const } : {}),
        ...(canNotify ? { notification_url: webhookUrl.toString() } : {}),
      },
    });

    if (!result.init_point) {
      return json({ error: 'O Mercado Pago não retornou o endereço do checkout.' }, 502);
    }
    return json({
      url: result.init_point,
      planId: parsed.data.planId,
      amount: plan.amount,
      webhookConfigured: Boolean(canNotify),
      returnUrlConfigured: Boolean(backUrls),
    });
  } catch (error) {
    return handleError(error);
  }
}

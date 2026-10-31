import { NextResponse } from 'next/server';
import { verifyMpWebhook } from '@/lib/webhook-signature';
import { logger } from '@/lib/logger';

export const runtime = 'nodejs';

export async function POST(request: Request) {
  try {
    const secret = process.env.MP_WEBHOOK_SECRET;
    if (secret) {
      const url = new URL(request.url);
      const xSignature = request.headers.get('x-signature');
      const xRequestId = request.headers.get('x-request-id');
      const dataId = url.searchParams.get('data.id');
      const isValid = verifyMpWebhook(xSignature, xRequestId, dataId, secret);
      if (!isValid) {
        logger.error('[Webhook] Assinatura inválida');
        return NextResponse.json({ error: 'invalid signature' }, { status: 401 });
      }
    } else if (process.env.NODE_ENV === 'production') {
      logger.error('[Webhook] MP_WEBHOOK_SECRET não configurado em produção — recusando webhook');
      return NextResponse.json({ error: 'Webhook secret not configured' }, { status: 500 });
    }

    const body = await request.json();
    const paymentId = body.data?.id ?? body.id;
    const action = body.action ?? body.type ?? 'notification';

    if (!paymentId) {
      return NextResponse.json({ received: true });
    }

    logger.info({ paymentId, action }, '[Webhook] Notification received');

    if (action === 'payment.created' || action === 'payment.updated') {
      const mpToken = process.env.MP_ACCESS_TOKEN;
      if (mpToken) {
        const maxRetries = 3;
        let lastError: unknown;
        for (let attempt = 0; attempt < maxRetries; attempt++) {
          if (attempt > 0) await new Promise((r) => setTimeout(r, 1000 * attempt));
          try {
            const mpRes = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
              headers: { Authorization: `Bearer ${mpToken}` },
              signal: AbortSignal.timeout(5000),
            });
            if (mpRes.ok) {
              const payment = await mpRes.json();
              if (payment.status === 'approved') {
                const { prisma } = await import('@/lib/prisma');
                const userEmail = payment.payer?.email;
                if (userEmail) {
                  const user = await prisma.user.findUnique({
                    where: { email: userEmail },
                    select: { id: true },
                  });
                  if (user) {
                    const { subscriptionService } = await import('@/lib/services/subscription.service');
                    await subscriptionService.create(
                      user.id,
                      payment.description ?? 'wegym-pro',
                      String(paymentId),
                    );
                    logger.info({ paymentId }, '[Webhook] PRO ativado');
                  }
                }
              }
            }
            break;
          } catch (err) {
            lastError = err;
            if (attempt < maxRetries - 1) {
              logger.warn({ attempt: attempt + 1 }, '[Webhook] Tentativa falhou, retentando');
            }
          }
        }
        if (lastError) {
          logger.error({ err: lastError }, '[Webhook] Erro ao consultar pagamento após retentativas');
        }
      }
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    logger.error({ err: error }, '[Webhook] Erro ao processar notificação');
    return NextResponse.json({ received: false }, { status: 500 });
  }
}

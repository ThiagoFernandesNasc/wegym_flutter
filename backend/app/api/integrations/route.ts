import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { integrationService } from '@/lib/services/integration.service';
import { stravaService } from '@/lib/services/strava.service';
import { googleFitService } from '@/lib/services/google-fit.service';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const integrations = await integrationService.getIntegrations(session.user.id);
    return json(integrations);
  } catch (error) {
    return handleError(error);
  }
}

export async function DELETE(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `integrations:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const { provider } = (await request.json()) as { provider: string };

    if (!['strava', 'google_fit'].includes(provider)) {
      return json({ error: 'Provedor inválido' }, 400);
    }

    await integrationService.disconnect(session.user.id, provider as 'strava' | 'google_fit');
    return json({ success: true });
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `integrations-connect:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const { provider } = (await request.json()) as { provider: string };

    const statePayload = JSON.stringify({ userId: session.user.id, provider });
    const stateBase64 = Buffer.from(statePayload).toString('base64');
    const { createHmac } = await import('crypto');
    const hmac = createHmac('sha256', process.env.NEXTAUTH_SECRET ?? '').update(stateBase64).digest('hex');
    const state = `${stateBase64}.${hmac}`;

    let url: string;
    if (provider === 'strava') {
      url = stravaService.getAuthorizationUrl(state);
    } else if (provider === 'google_fit') {
      url = googleFitService.getAuthorizationUrl(state);
    } else {
      return json({ error: 'Provedor inválido' }, 400);
    }

    return json({ url });
  } catch (error) {
    return handleError(error);
  }
}

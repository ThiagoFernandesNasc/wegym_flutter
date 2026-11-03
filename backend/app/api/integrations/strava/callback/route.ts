import { json } from '@/lib/api-utils';
import { integrationService } from '@/lib/services/integration.service';
import { stravaService } from '@/lib/services/strava.service';
import { logger } from '@/lib/logger';
import { integrationOAuthReturnUrl, verifyIntegrationOAuthState } from '@/lib/integration-oauth-state';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get('code');
  const state = verifyIntegrationOAuthState(searchParams.get('state'), 'strava');
  const providerError = searchParams.get('error');

  if (!state) return json({ error: 'Estado de autoriza??o inv?lido' }, 400);
  if (providerError) {
    logger.warn({ error: providerError }, '[Strava] Auth error');
    return Response.redirect(integrationOAuthReturnUrl(state, 'error', providerError));
  }
  if (!code) return json({ error: 'C?digo de autoriza??o inv?lido' }, 400);

  try {
    const tokens = await stravaService.exchangeCode(code);
    await integrationService.saveTokens(state.userId, 'strava', tokens);
    logger.info({ userId: state.userId }, '[Strava] Connected successfully');
    return Response.redirect(integrationOAuthReturnUrl(state, 'success'));
  } catch (error) {
    logger.error({ error }, '[Strava] Callback error');
    return Response.redirect(integrationOAuthReturnUrl(state, 'error', 'callback_failed'));
  }
}

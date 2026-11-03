import { createHmac, timingSafeEqual } from 'crypto';

export type IntegrationProvider = 'strava' | 'google_fit';
export type IntegrationPlatform = 'next' | 'flutter_web' | 'flutter_native';
export type IntegrationOAuthState = {
  userId: string;
  provider: IntegrationProvider;
  platform: IntegrationPlatform;
};

function sign(payload: string, secret: string): string {
  return createHmac('sha256', secret).update(payload).digest('hex');
}

export function createIntegrationOAuthState(
  input: Omit<IntegrationOAuthState, 'platform'> & { platform?: IntegrationPlatform },
  secret = process.env.NEXTAUTH_SECRET ?? '',
): string {
  const payload = Buffer.from(JSON.stringify({
    ...input,
    platform: input.platform ?? 'next',
  })).toString('base64');
  return `${payload}.${sign(payload, secret)}`;
}

export function verifyIntegrationOAuthState(
  state: string | null,
  expectedProvider: IntegrationProvider,
  secret = process.env.NEXTAUTH_SECRET ?? '',
): IntegrationOAuthState | null {
  if (!state) return null;
  const parts = state.split('.');
  if (parts.length !== 2 || !/^[a-f0-9]{64}$/i.test(parts[1])) return null;
  const expected = Buffer.from(sign(parts[0], secret), 'hex');
  const supplied = Buffer.from(parts[1], 'hex');
  if (supplied.length !== expected.length || !timingSafeEqual(supplied, expected)) {
    return null;
  }

  try {
    const decoded = JSON.parse(Buffer.from(parts[0], 'base64').toString('utf8')) as Record<string, unknown>;
    const platform = decoded.platform ?? 'next';
    if (
      typeof decoded.userId !== 'string' ||
      decoded.userId.length === 0 ||
      decoded.provider !== expectedProvider ||
      !['next', 'flutter_web', 'flutter_native'].includes(String(platform))
    ) {
      return null;
    }
    return {
      userId: decoded.userId,
      provider: expectedProvider,
      platform: platform as IntegrationPlatform,
    };
  } catch {
    return null;
  }
}

function addResult(url: URL, state: IntegrationOAuthState, status: 'success' | 'error', error?: string): URL {
  url.searchParams.set('integration', state.provider);
  url.searchParams.set('integration_result', status);
  if (status === 'success') {
    url.searchParams.set('success', 'true');
  } else {
    const safeError = error && /^[a-z0-9_-]{1,64}$/i.test(error) ? error : 'callback_failed';
    url.searchParams.set('error', safeError);
    url.searchParams.set('integration_error', safeError);
  }
  return url;
}

function flutterWebUrl(): URL | null {
  const configured = process.env.FLUTTER_APP_URL;
  if (!configured) return null;
  try {
    const url = new URL(configured);
    const localHttp = url.protocol === 'http:' &&
      ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
    if (url.protocol !== 'https:' && !localHttp) return null;
    if (url.username || url.password) return null;
    return url;
  } catch {
    return null;
  }
}

function flutterNativeUrl(): URL | null {
  const configured = process.env.FLUTTER_NATIVE_APP_URL || 'wegym://integration-return';
  try {
    const url = new URL(configured);
    if (url.protocol !== 'wegym:' || url.host !== 'integration-return' || url.username || url.password) {
      return null;
    }
    return url;
  } catch {
    return null;
  }
}

export function integrationOAuthReturnUrl(
  state: IntegrationOAuthState,
  status: 'success' | 'error',
  error?: string,
): string {
  const flutterTarget = state.platform === 'flutter_native'
    ? flutterNativeUrl()
    : state.platform === 'flutter_web'
      ? flutterWebUrl()
      : null;
  if (flutterTarget) return addResult(flutterTarget, state, status, error).toString();

  const base = process.env.NEXTAUTH_URL || 'http://localhost:3000';
  const fallback = new URL('/profile', base);
  return addResult(fallback, state, status, error).toString();
}

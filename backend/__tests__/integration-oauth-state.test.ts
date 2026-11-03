import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  createIntegrationOAuthState,
  integrationOAuthReturnUrl,
  verifyIntegrationOAuthState,
} from '@/lib/integration-oauth-state';

afterEach(() => vi.unstubAllEnvs());

describe('integration OAuth state and platform return', () => {
  const secret = 'test-nextauth-secret';

  it('signs platform state and rejects tampering or a different provider', () => {
    const state = createIntegrationOAuthState({
      userId: 'athlete-1',
      provider: 'strava',
      platform: 'flutter_native',
    }, secret);

    expect(verifyIntegrationOAuthState(state, 'strava', secret)).toEqual({
      userId: 'athlete-1',
      provider: 'strava',
      platform: 'flutter_native',
    });
    expect(verifyIntegrationOAuthState(`${state}x`, 'strava', secret)).toBeNull();
    expect(verifyIntegrationOAuthState(state, 'google_fit', secret)).toBeNull();
  });

  it('returns a native deep link after OAuth completes', () => {
    vi.stubEnv('FLUTTER_NATIVE_APP_URL', '');
    const url = new URL(integrationOAuthReturnUrl({
      userId: 'athlete-1', provider: 'google_fit', platform: 'flutter_native',
    }, 'success'));

    expect(url.protocol).toBe('wegym:');
    expect(url.host).toBe('integration-return');
    expect(url.searchParams.get('integration')).toBe('google_fit');
    expect(url.searchParams.get('integration_result')).toBe('success');
  });

  it('returns a web client only to HTTPS or loopback Flutter origins', () => {
    vi.stubEnv('FLUTTER_APP_URL', 'https://app.wegym.example/');
    const state = { userId: 'athlete-1', provider: 'strava' as const, platform: 'flutter_web' as const };
    const url = new URL(integrationOAuthReturnUrl(state, 'success'));
    expect(url.origin).toBe('https://app.wegym.example');
    expect(url.searchParams.get('success')).toBe('true');

    vi.stubEnv('FLUTTER_APP_URL', 'http://attacker.example');
    const fallback = new URL(integrationOAuthReturnUrl(state, 'error', 'access_denied'));
    expect(fallback.origin).toBe('http://localhost:3000');
    expect(fallback.pathname).toBe('/profile');
  });

  it('keeps existing Next.js clients on their profile callback', () => {
    vi.stubEnv('NEXTAUTH_URL', 'https://webgym.example');
    const url = new URL(integrationOAuthReturnUrl({
      userId: 'coach-1', provider: 'strava', platform: 'next',
    }, 'success'));

    expect(url.origin).toBe('https://webgym.example');
    expect(url.pathname).toBe('/profile');
    expect(url.searchParams.get('integration')).toBe('strava');
    expect(url.searchParams.get('success')).toBe('true');
  });
});

import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  authenticate: vi.fn(),
  withRateLimit: vi.fn(),
  createPreference: vi.fn(),
}));

vi.mock('mercadopago', () => ({
  MercadoPagoConfig: class {
    constructor(readonly options: unknown) {}
  },
  Preference: class {
    async create(input: unknown) {
      return mocks.createPreference(input);
    }
  },
}));

vi.mock('@/lib/api-utils', () => ({
  authenticate: mocks.authenticate,
  handleError: (error: unknown) =>
    Response.json({ error: String(error) }, {
      status: (error as { statusCode?: number })?.statusCode ?? 500,
    }),
  json: (data: unknown, status = 200) => Response.json(data, { status }),
  withRateLimit: mocks.withRateLimit,
}));

import { POST } from '@/app/api/payment-preference/route';

describe('POST /api/payment-preference', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv('MP_ACCESS_TOKEN', 'test-access-token');
    vi.stubEnv('NEXTAUTH_URL', 'http://localhost:3000');
    vi.stubEnv('FLUTTER_APP_URL', '');
    mocks.authenticate.mockResolvedValue({
      user: { id: 'athlete-1', email: 'athlete@example.com' },
    });
    mocks.withRateLimit.mockResolvedValue(null);
    mocks.createPreference.mockResolvedValue({
      init_point: 'https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=test',
    });
  });

  it('creates an annual preference with the server price and authenticated payer', async () => {
    const response = await POST(
      new Request('http://localhost:3000/api/payment-preference', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ planId: 'anual', amount: 0.01 }),
      }),
    );

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({
      planId: 'anual',
      amount: 399.9,
      webhookConfigured: false,
      returnUrlConfigured: true,
    });
    expect(mocks.createPreference).toHaveBeenCalledWith({
      body: expect.objectContaining({
        items: [expect.objectContaining({ unit_price: 399.9, quantity: 1 })],
        payer: { email: 'athlete@example.com' },
        external_reference: 'athlete-1:anual',
        metadata: { userId: 'athlete-1', planId: 'anual' },
        back_urls: {
          success: 'wegym://payment-return?payment_return=success',
          pending: 'wegym://payment-return?payment_return=pending',
          failure: 'wegym://payment-return?payment_return=failure',
        },
      }),
    });
  });

  it('creates a monthly preference and attaches a public HTTPS webhook', async () => {
    vi.stubEnv('NEXTAUTH_URL', 'https://api.wegym.example');
    const response = await POST(
      new Request('https://api.wegym.example/api/payment-preference', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ planId: 'mensal' }),
      }),
    );

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({
      planId: 'mensal',
      amount: 49.9,
      webhookConfigured: true,
      returnUrlConfigured: true,
    });
    expect(mocks.createPreference).toHaveBeenCalledWith({
      body: expect.objectContaining({
        items: [expect.objectContaining({ unit_price: 49.9 })],
        notification_url: 'https://api.wegym.example/api/webhooks/mercadopago',
      }),
    });
  });

  it('uses only the configured HTTPS Flutter Web origin for web return URLs', async () => {
    vi.stubEnv('FLUTTER_APP_URL', 'https://app.wegym.example/');
    const response = await POST(
      new Request('https://api.wegym.example/api/payment-preference', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ planId: 'mensal', platform: 'web' }),
      }),
    );

    expect(response.status).toBe(200);
    expect(mocks.createPreference).toHaveBeenCalledWith({
      body: expect.objectContaining({
        back_urls: {
          success: 'https://app.wegym.example/?payment_return=success',
          pending: 'https://app.wegym.example/?payment_return=pending',
          failure: 'https://app.wegym.example/?payment_return=failure',
        },
      }),
    });
  });

  it('does not use an unsafe local URL as a web return target', async () => {
    vi.stubEnv('FLUTTER_APP_URL', 'http://localhost:7358');
    const response = await POST(
      new Request('https://api.wegym.example/api/payment-preference', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ planId: 'mensal', platform: 'web' }),
      }),
    );

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toMatchObject({
      returnUrlConfigured: false,
    });
    expect(mocks.createPreference.mock.calls[0]?.[0]).not.toHaveProperty(
      'body.back_urls',
    );
  });

  it('rejects unknown plans and never asks Mercado Pago to price them', async () => {
    const response = await POST(
      new Request('http://localhost:3000/api/payment-preference', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ planId: 'custom', amount: 0.01 }),
      }),
    );

    expect(response.status).toBe(422);
    expect(mocks.createPreference).not.toHaveBeenCalled();
  });

  it('reports missing Mercado Pago credentials without attempting a checkout', async () => {
    vi.stubEnv('MP_ACCESS_TOKEN', '');
    const response = await POST(
      new Request('http://localhost:3000/api/payment-preference', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ planId: 'mensal' }),
      }),
    );

    expect(response.status).toBe(503);
    expect(mocks.createPreference).not.toHaveBeenCalled();
  });
});

import { logger } from '@/lib/logger';

const GOOGLE_AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
const GOOGLE_TOKEN_URL = 'https://oauth2.googleapis.com/token';
const GOOGLE_FIT_API_URL = 'https://www.googleapis.com/fitness/v1/users/me';

function getClientConfig() {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  const redirectUri = process.env.GOOGLE_REDIRECT_URI || `${process.env.NEXTAUTH_URL}/api/integrations/google-fit/callback`;

  if (!clientId || !clientSecret) {
    throw new Error('GOOGLE_CLIENT_ID e GOOGLE_CLIENT_SECRET devem estar definidos');
  }

  return { clientId, clientSecret, redirectUri };
}

const SCOPES = [
  'https://www.googleapis.com/auth/fitness.activity.read',
  'https://www.googleapis.com/auth/fitness.heart_rate.read',
  'https://www.googleapis.com/auth/fitness.body.read',
  'https://www.googleapis.com/auth/fitness.location.read',
];

export const googleFitService = {
  getAuthorizationUrl(state: string): string {
    const { clientId, redirectUri } = getClientConfig();
    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: SCOPES.join(' '),
      access_type: 'offline',
      prompt: 'consent',
      state,
    });
    return `${GOOGLE_AUTH_URL}?${params.toString()}`;
  },

  async exchangeCode(code: string) {
    const { clientId, clientSecret, redirectUri } = getClientConfig();

    const response = await fetch(GOOGLE_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        grant_type: 'authorization_code',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      logger.error({ error }, '[GoogleFit] Token exchange failed');
      throw new Error('Falha ao autenticar com Google Fit');
    }

    const data = (await response.json()) as {
      access_token: string;
      refresh_token: string;
      expires_in: number;
      scope: string;
      token_type: string;
    };

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      tokenType: data.token_type,
      scope: data.scope,
      expiresAt: new Date(Date.now() + data.expires_in * 1000),
    };
  },

  async refreshAccessToken(refreshToken: string) {
    const { clientId, clientSecret } = getClientConfig();

    const response = await fetch(GOOGLE_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        refresh_token: refreshToken,
        grant_type: 'refresh_token',
      }),
    });

    if (!response.ok) {
      throw new Error('Falha ao renovar token do Google Fit');
    }

    const data = (await response.json()) as {
      access_token: string;
      expires_in: number;
      scope: string;
      token_type: string;
    };

    return {
      accessToken: data.access_token,
      tokenType: data.token_type,
      scope: data.scope,
      expiresAt: new Date(Date.now() + data.expires_in * 1000),
    };
  },

  async fetchSessions(accessToken: string, startTime: Date, endTime: Date) {
    const params = new URLSearchParams({
      startTime: startTime.toISOString(),
      endTime: endTime.toISOString(),
    });

    const response = await fetch(`${GOOGLE_FIT_API_URL}/sessions?${params.toString()}`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
      throw new Error('Falha ao buscar sessões do Google Fit');
    }

    return (await response.json()) as {
      session: Array<{
        id: string;
        name: string;
        description?: string;
        startTimeMillis: string;
        endTimeMillis: string;
        activityType: number;
        application: { packageName: string };
      }>;
    };
  },

  async fetchDataSources(accessToken: string) {
    const response = await fetch(`${GOOGLE_FIT_API_URL}/dataSources`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
      throw new Error('Falha ao buscar fontes de dados do Google Fit');
    }

    return (await response.json()) as {
      dataSource: Array<{
        dataStreamId: string;
        dataType: { name: string };
        device?: { manufacturer: string; model: string };
      }>;
    };
  },

  async fetchDataset(
    accessToken: string,
    dataStreamId: string,
    startTime: Date,
    endTime: Date,
  ) {
    const startNanos = startTime.getTime() * 1_000_000;
    const endNanos = endTime.getTime() * 1_000_000;

    const response = await fetch(
      `${GOOGLE_FIT_API_URL}/dataSources/${dataStreamId}/datasets/${startNanos}-${endNanos}`,
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );

    if (!response.ok) {
      throw new Error('Falha ao buscar dataset do Google Fit');
    }

    return (await response.json()) as {
      point: Array<{
        startTimeNanos: string;
        endTimeNanos: string;
        dataTypeName: string;
        value: Array<{ fpVal?: number; intVal?: number }>;
      }>;
    };
  },

  mapActivityType(type: number): string {
    const mapping: Record<number, string> = {
      7: 'corrida',
      8: 'caminhada',
      9: 'ciclismo',
      17: 'corrida',
      18: 'natacao',
      19: 'yoga',
      20: 'pilates',
      26: 'yoga',
      34: 'musculacao',
      35: 'musculacao',
      43: 'caminhada',
    };
    return mapping[type] || 'outro';
  },
};

import { logger } from '@/lib/logger';

const STRAVA_AUTH_URL = 'https://www.strava.com/oauth/authorize';
const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token';
const STRAVA_API_URL = 'https://www.strava.com/api/v3';

function getClientConfig() {
  const clientId = process.env.STRAVA_CLIENT_ID;
  const clientSecret = process.env.STRAVA_CLIENT_SECRET;
  const redirectUri = process.env.STRAVA_REDIRECT_URI || `${process.env.NEXTAUTH_URL}/api/integrations/strava/callback`;

  if (!clientId || !clientSecret) {
    throw new Error('STRAVA_CLIENT_ID e STRAVA_CLIENT_SECRET devem estar definidos');
  }

  return { clientId, clientSecret, redirectUri };
}

export const stravaService = {
  getAuthorizationUrl(state: string): string {
    const { clientId, redirectUri } = getClientConfig();
    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      approval_prompt: 'auto',
      scope: 'read,activity:read_all,profile:read_all',
      state,
    });
    return `${STRAVA_AUTH_URL}?${params.toString()}`;
  },

  async exchangeCode(code: string) {
    const { clientId, clientSecret, redirectUri } = getClientConfig();

    const response = await fetch(STRAVA_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: clientId,
        client_secret: clientSecret,
        code,
        grant_type: 'authorization_code',
        redirect_uri: redirectUri,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      logger.error({ error }, '[Strava] Token exchange failed');
      throw new Error('Falha ao autenticar com Strava');
    }

    const data = (await response.json()) as {
      token_type: string;
      access_token: string;
      refresh_token: string;
      expires_at: number;
      athlete: {
        id: number;
        firstname: string;
        lastname: string;
        profile: string;
        city: string;
        country: string;
      };
    };

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      tokenType: data.token_type,
      expiresAt: new Date(data.expires_at * 1000),
      providerData: {
        athleteId: data.athlete.id,
        firstName: data.athlete.firstname,
        lastName: data.athlete.lastname,
        avatar: data.athlete.profile,
      },
    };
  },

  async refreshAccessToken(refreshToken: string) {
    const { clientId, clientSecret } = getClientConfig();

    const response = await fetch(STRAVA_TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: clientId,
        client_secret: clientSecret,
        grant_type: 'refresh_token',
        refresh_token: refreshToken,
      }),
    });

    if (!response.ok) {
      throw new Error('Falha ao renovar token do Strava');
    }

    const data = (await response.json()) as {
      token_type: string;
      access_token: string;
      refresh_token: string;
      expires_at: number;
    };

    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      tokenType: data.token_type,
      expiresAt: new Date(data.expires_at * 1000),
    };
  },

  async fetchActivities(accessToken: string, after?: Date, page = 1, perPage = 50) {
    const params = new URLSearchParams({
      page: String(page),
      per_page: String(Math.min(perPage, 200)),
    });

    if (after) {
      params.set('after', String(Math.floor(after.getTime() / 1000)));
    }

    const response = await fetch(`${STRAVA_API_URL}/athlete/activities?${params.toString()}`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
      throw new Error('Falha ao buscar atividades do Strava');
    }

    return (await response.json()) as Array<{
      id: number;
      name: string;
      type: string;
      sport_type: string;
      start_date: string;
      distance: number;
      moving_time: number;
      elapsed_time: number;
      total_elevation_gain: number;
      average_speed: number;
      max_speed: number;
      average_heartrate?: number;
      max_heartrate?: number;
      start_latlng?: [number, number];
      end_latlng?: [number, number];
      map?: { summary_polyline?: string };
      has_heartrate: boolean;
      calories?: number;
      device_name?: string;
    }>;
  },

  mapStravaTypeToModality(type: string, sportType: string): string {
    const mapping: Record<string, string> = {
      Run: 'corrida',
      TrailRun: 'corrida',
      VirtualRun: 'corrida',
      Ride: 'ciclismo',
      MountainBikeRide: 'ciclismo',
      GravelRide: 'ciclismo',
      VirtualRide: 'ciclismo',
      Swim: 'natacao',
      Walk: 'caminhada',
      Hike: 'caminhada',
      Workout: 'musculacao',
      WeightTraining: 'musculacao',
      Yoga: 'yoga',
      Pilates: 'pilates',
    };
    return mapping[sportType] || mapping[type] || 'outro';
  },
};

import { api } from "./client";

export type Integration = {
  id: string;
  provider: "strava" | "google_fit";
  enabled: boolean;
  syncEnabled: boolean;
  lastSyncAt: string | null;
  createdAt: string;
  providerData: {
    athleteId?: number;
    firstName?: string;
    lastName?: string;
    avatar?: string;
  } | null;
};

export async function getIntegrations() {
  return api.get<Integration[]>("/api/integrations");
}

export async function syncProvider(provider: "strava" | "google_fit") {
  return api.post<{ imported: number; skipped: number; total: number }>(
    `/api/integrations/${provider}/sync`,
  );
}

export async function disconnectProvider(provider: "strava" | "google_fit") {
  return api.delete<{ success: boolean }>("/api/integrations", { provider });
}

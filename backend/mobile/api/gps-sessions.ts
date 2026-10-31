import { api } from "./client";

export type GpsSession = {
  id: string; modality: string; distanceKm: number; durationSec: number;
  avgPaceSecPerKm: number; avgHeartRate?: number; steps: number;
  calories: number; coordinates: { latitude: number; longitude: number }[];
  completedAt: string;
};

export async function createGpsSession(data: {
  modality: string; distanceKm: number; durationSec: number;
  avgPaceSecPerKm: number; steps: number; calories?: number;
  avgHeartRate?: number; coordinates?: { latitude: number; longitude: number }[];
}) {
  return api.post<GpsSession>("/api/gps-sessions", data);
}

export async function getGpsSessions(cursor?: string) {
  const params = cursor ? `?cursor=${cursor}` : "";
  return api.get<{ data: GpsSession[] }>(`/api/gps-sessions${params}`);
}

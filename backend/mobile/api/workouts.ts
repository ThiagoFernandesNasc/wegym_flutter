import { api } from "./client";

export type WorkoutSession = {
  id: string;
  modality: string;
  durationSec: number;
  distanceKm: number | null;
  avgPaceSecPerKm: number | null;
  steps: number | null;
  calories: number | null;
  avgHeartRate: number | null;
  completedAt: string;
  exercises: unknown;
};

export async function getWorkouts(cursor?: string) {
  const params = new URLSearchParams();
  if (cursor) params.set("cursor", cursor);
  return api.get<{
    data: WorkoutSession[];
    nextCursor: string | null;
    hasMore: boolean;
  }>(`/api/workout-sessions?${params.toString()}`);
}

export async function createWorkout(data: {
  modality: string;
  durationSec: number;
  distanceKm?: number;
  steps?: number;
  calories?: number;
  avgHeartRate?: number;
}) {
  return api.post<WorkoutSession>("/api/workout-sessions", data);
}

export async function getStats(period: "week" | "month" | "year") {
  return api.get<{
    totalSessions: number;
    totalVolume: number;
    totalCalories: number;
    totalDistance: number;
    avgHeartRate: number;
  }>(`/api/workout-stats?period=${period}`);
}

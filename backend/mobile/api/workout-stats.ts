import { api } from "./client";

export type WorkoutStats = {
  totalSessions: number;
  totalVolume: number;
  totalCalories: number;
  totalDistance: number;
  avgHeartRate: number;
  totalActiveTime: number;
};

export type ChartDataPoint = { period: string; value: number };

export async function getStats(period: "week" | "month" | "year") {
  return api.get<WorkoutStats>(`/api/workout-stats?period=${period}`);
}

export async function getChartData(period: "week" | "month" | "year") {
  return api.get<ChartDataPoint[]>(`/api/workout-stats?period=${period}&chart=true`);
}

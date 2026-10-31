import { api } from "./client";

export type MeasurementEntry = {
  id: string; date: string; weight: number;
  muscleMass?: number; bodyFat?: number; note?: string;
};
export type ChartDataPoint = { date: string; value: number };

export async function getMeasurements() { return api.get<MeasurementEntry[]>("/api/body-measurements"); }
export async function getChartData(metric: string) { return api.get<ChartDataPoint[]>(`/api/body-measurements?metric=${metric}`); }
export async function createMeasurement(data: { weight: number; muscleMass?: number; bodyFat?: number; note?: string }) { return api.post<MeasurementEntry>("/api/body-measurements", data); }

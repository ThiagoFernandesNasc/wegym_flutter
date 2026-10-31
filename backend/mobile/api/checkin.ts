import { api } from "./client";

export type DailyCheckIn = {
  id: string; mood: number; energy: number; sleepHours: number;
  trained: boolean; note: string; date: string;
};
export type CheckInHistory = { checkIns: DailyCheckIn[]; streak: number };

export async function getCheckIn(date?: string) {
  return api.get<DailyCheckIn>(`/api/checkin${date ? `?date=${date}` : ""}`);
}
export async function getCheckInHistory() { return api.get<CheckInHistory>("/api/checkin?history=true"); }
export async function saveCheckIn(data: { mood: number; energy: number; sleepHours: number; trained: boolean; note?: string }) { return api.post<DailyCheckIn>("/api/checkin", data); }

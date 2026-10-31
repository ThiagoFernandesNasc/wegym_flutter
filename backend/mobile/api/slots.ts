import { api } from "./client";

export type TimeSlot = {
  id: string;
  date: string;
  startTime: string;
  endTime: string;
  available: boolean;
  personalId: string;
};

export async function getAvailableSlots(personalId: string, date: string) {
  return api.get<TimeSlot[]>(`/api/appointments/slots?personalId=${personalId}&date=${date}`);
}

export async function bookSlot(slotId: string) {
  return api.post<{ message: string }>("/api/appointments", { slotId });
}

export async function createSlot(data: { date: string; startTime: string; endTime: string }) {
  return api.post<TimeSlot>("/api/appointments/slots", data);
}

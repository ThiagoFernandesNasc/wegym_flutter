import { api } from "./client";

export type Appointment = {
  id: string; athleteId: string; personalId: string;
  date: string; type: string; status: string; notes?: string;
  athlete?: { id: string; displayName: string };
  personal?: { id: string; displayName: string };
};

export async function getAppointments() { return api.get<Appointment[]>("/api/appointments"); }
export async function createAppointment(data: { personalId: string; date: string; type: string; notes?: string }) { return api.post<Appointment>("/api/appointments", data); }
export async function cancelAppointment(id: string) { return api.patch("/api/appointments", { id, action: "cancel" }); }

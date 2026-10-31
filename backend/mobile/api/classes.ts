import { api } from "./client";

export type ClassEntry = {
  id: string; studentId: string; studentName: string;
  dayOfWeek: number; time: string; type: string; status: string;
};

export async function getClasses() {
  return api.get<ClassEntry[]>("/api/classes");
}

import { api } from "./client";

export type ProgressEntry = {
  id: string; date: string; weight: number;
  muscleMass?: number; bodyFat?: number; notes?: string;
  studentId: string;
};

export async function getStudentProgress(studentId: string) {
  return api.get<ProgressEntry[]>(`/api/progress?studentId=${studentId}`);
}

export async function addProgress(data: {
  studentId: string; weight: number;
  muscleMass?: number; bodyFat?: number; notes?: string;
}) {
  return api.post<ProgressEntry>("/api/progress", data);
}

export async function deleteProgress(id: string) {
  return api.delete(`/api/progress/${id}`);
}

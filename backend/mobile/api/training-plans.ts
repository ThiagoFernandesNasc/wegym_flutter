import { api } from "./client";

export type TrainingPlanExercise = {
  id: string; name: string; sets: number; reps: string;
  load: string; dayOfWeek: number; studentId: string;
};

export async function getTrainingPlan(athleteId: string) {
  return api.get<TrainingPlanExercise[]>(`/api/training-plans?athleteId=${athleteId}`);
}

export async function addExercise(data: {
  studentId: string; name: string; sets: number; reps: string;
  load?: string; dayOfWeek: number;
}) {
  return api.post<TrainingPlanExercise>("/api/training-plans", data);
}

export async function removeExercise(id: string) {
  return api.delete(`/api/training-plans/${id}`);
}

export async function getPlanById(id: string) {
  return api.get<TrainingPlanExercise[]>(`/api/training-plans/${id}`);
}

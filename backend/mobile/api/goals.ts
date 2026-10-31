import { api } from "./client";

export type Goal = {
  id: string; title: string; description?: string; category: string;
  metric: string; targetValue: number; currentValue: number;
  endDate: string; status: string; userId: string;
};

export async function getGoals() { return api.get<Goal[]>("/api/goals"); }
export async function createGoal(data: { title: string; category: string; metric: string; targetValue: number; endDate: string }) { return api.post<Goal>("/api/goals", data); }
export async function updateGoal(id: string, data: { currentValue?: number; status?: string }) { return api.patch<Goal>("/api/goals", { id, ...data }); }
export async function deleteGoal(id: string) { return api.delete(`/api/goals/${id}`); }

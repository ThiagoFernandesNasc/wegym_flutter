import { api } from "./client";

export type DietPlan = {
  id: string;
  name: string;
  description: string;
  dailyCalories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  meals: DietMeal[];
  createdAt: string;
};

export type DietMeal = {
  id: string;
  type: "breakfast" | "lunch" | "dinner" | "snack";
  foods: DietFood[];
};

export type DietFood = {
  name: string;
  amount: number;
  unit: string;
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
};

export async function getDietPlans() {
  return api.get<DietPlan[]>("/api/nutrition/diet-plans");
}

export async function getActiveDietPlan() {
  return api.get<DietPlan | null>("/api/nutrition/diet-plans?active=true");
}

export async function assignDietPlan(planId: string) {
  return api.post<DietPlan>("/api/nutrition/diet-plans", { planId });
}

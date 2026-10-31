import { api } from "./client";

export type FoodItem = { id: string; name: string; calories: number; proteinG: number; carbsG: number; fatG: number; fiberG: number; servingSizeG: number; };
export type MealFood = { id: string; amount: number; food: FoodItem; };
export type MealLog = { id: string; type: string; date: string; foods: MealFood[]; totals?: { calories: number; proteinG: number; carbsG: number; fatG: number; }; };

export async function getFoods(q: string) { return api.get<FoodItem[]>(`/api/nutrition/foods?q=${encodeURIComponent(q)}`); }
export async function getMeals(date: string) { return api.get<MealLog[]>(`/api/nutrition/meals?date=${date}`); }
export async function createMeal(data: { date: string; type: string }) { return api.post<MealLog>("/api/nutrition/meals", data); }
export async function addFoodToMeal(mealId: string, foodId: string, amount: number) { return api.post<MealLog>("/api/nutrition/meals", { mealId, foodId, amount }); }

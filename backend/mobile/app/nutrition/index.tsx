import { useCallback, useEffect, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator } from "react-native";
import { Stack } from "expo-router";
import { getFoods, getMeals, createMeal, addFoodToMeal, type MealLog, type FoodItem } from "@/api/nutrition";
import { getDietPlans, getActiveDietPlan, assignDietPlan, type DietPlan } from "@/api/diet-plans";

const MEAL_TYPES = ["breakfast", "lunch", "dinner", "snack"];
const MEAL_LABELS: Record<string, string> = { breakfast: "☕ Café da manhã", lunch: "🍽️ Almoço", dinner: "🌙 Jantar", snack: "🍪 Lanche" };

export default function NutritionScreen() {
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [meals, setMeals] = useState<MealLog[]>([]);
  const [foods, setFoods] = useState<FoodItem[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [dietPlans, setDietPlans] = useState<DietPlan[]>([]);
  const [activePlan, setActivePlan] = useState<DietPlan | null>(null);
  const [showPlans, setShowPlans] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [mealsData, foodsData, plans, active] = await Promise.all([
        getMeals(date), getFoods(search), getDietPlans().catch(() => []), getActiveDietPlan().catch(() => null),
      ]);
      setMeals(mealsData); setFoods(foodsData); setDietPlans(plans); setActivePlan(active);
    } catch { /* silent */ } finally { setLoading(false); }
  }, [date, search]);

  useEffect(() => { load(); }, [load]);

  const handleCreateMeal = async (type: string) => {
    try { await createMeal({ date, type }); load(); } catch { /* silent */ }
  };

  const handleAddFood = async (mealId: string, foodId: string) => {
    try { await addFoodToMeal(mealId, foodId, 1); load(); } catch { /* silent */ }
  };

  const totals = meals.reduce((acc, m) => ({
    calories: acc.calories + (m.totals?.calories ?? 0),
    protein: acc.protein + (m.totals?.proteinG ?? 0),
    carbs: acc.carbs + (m.totals?.carbsG ?? 0),
    fat: acc.fat + (m.totals?.fatG ?? 0),
  }), { calories: 0, protein: 0, carbs: 0, fat: 0 });

  return (
    <>
      <Stack.Screen options={{ title: "Nutrição" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 4 }}>Nutrição</Text>
          <TextInput value={date} onChangeText={setDate} placeholderTextColor="#71717a" style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 12, fontSize: 14, color: "#fff", marginBottom: 16 }} />

          <View style={{ flexDirection: "row", gap: 8, marginBottom: 16 }}>
            {Object.entries(totals).map(([k, v]) => (
              <View key={k} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 14, padding: 10, flex: 1, alignItems: "center" }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 4 }}>{k}</Text>
                <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{k === "calories" ? `${Math.round(v)} kcal` : `${Math.round(v)}g`}</Text>
              </View>
            ))}
          </View>

          {activePlan && (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#22c55e40", borderRadius: 20, padding: 16, marginBottom: 16 }}>
              <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#22c55e" }}>Plano alimentar ativo</Text>
                <TouchableOpacity onPress={() => setShowPlans(!showPlans)}><Text style={{ color: "#ea580c", fontSize: 9, fontWeight: "900" }}>{showPlans ? "Ocultar planos" : "Trocar plano"}</Text></TouchableOpacity>
              </View>
              <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{activePlan.name}</Text>
              <Text style={{ fontSize: 10, color: "#a1a1aa", marginTop: 4 }}>{activePlan.description}</Text>
              <View style={{ flexDirection: "row", gap: 8, marginTop: 8 }}>
                <View style={{ backgroundColor: "#27272a", borderRadius: 10, paddingHorizontal: 10, paddingVertical: 4 }}>
                  <Text style={{ fontSize: 9, color: "#facc15" }}>🔥 {activePlan.dailyCalories} kcal/dia</Text>
                </View>
                <View style={{ backgroundColor: "#27272a", borderRadius: 10, paddingHorizontal: 10, paddingVertical: 4 }}>
                  <Text style={{ fontSize: 9, color: "#3b82f6" }}>🥩 {activePlan.proteinG}g prot</Text>
                </View>
              </View>
            </View>
          )}
          {showPlans && dietPlans.length > 0 && (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Planos disponíveis</Text>
              {dietPlans.filter((p) => !activePlan || p.id !== activePlan.id).map((plan) => (
                <TouchableOpacity key={plan.id} onPress={async () => { await assignDietPlan(plan.id); load(); setShowPlans(false); }} style={{ paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
                  <Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>{plan.name}</Text>
                  <Text style={{ fontSize: 10, color: "#71717a", marginTop: 2 }}>{plan.dailyCalories} kcal/dia · {plan.proteinG}g prot</Text>
                </TouchableOpacity>
              ))}
            </View>
          )}
          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : MEAL_TYPES.map((type) => {
            const meal = meals.find((m) => m.type === type);
            return (
              <View key={type} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 12 }}>
                <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                  <Text style={{ fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{MEAL_LABELS[type]}</Text>
                  {!meal && <TouchableOpacity onPress={() => handleCreateMeal(type)}><Text style={{ color: "#ea580c", fontSize: 10, fontWeight: "900" }}>+ Adicionar</Text></TouchableOpacity>}
                </View>
                {meal && (
                  <>
                    {meal.foods?.map((mf) => (
                      <View key={mf.id} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 4 }}>
                        <Text style={{ color: "#d4d4d8", fontSize: 13 }}>{mf.food.name} <Text style={{ color: "#71717a" }}>x{mf.amount}</Text></Text>
                        <Text style={{ color: "#71717a", fontSize: 12 }}>{Math.round(mf.food.calories * mf.amount)} kcal</Text>
                      </View>
                    ))}
                    <View style={{ flexDirection: "row", gap: 8, marginTop: 8 }}>
                      <TextInput value={search} onChangeText={setSearch} placeholder="Buscar alimentos..." placeholderTextColor="#71717a" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 12, padding: 10, fontSize: 12, color: "#fff" }} />
                      <View style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 12, overflow: "hidden" }}>
                        <TouchableOpacity onPress={() => {
                          if (foods.length > 0) handleAddFood(meal.id, foods[0].id);
                        }} style={{ paddingHorizontal: 12, paddingVertical: 10 }}>
                          <Text style={{ color: "#ea580c", fontSize: 10, fontWeight: "800" }}>+</Text>
                        </TouchableOpacity>
                      </View>
                    </View>
                    {foods.length > 0 && (
                      <ScrollView horizontal style={{ marginTop: 8 }}>
                        {foods.map((f) => (
                          <TouchableOpacity key={f.id} onPress={() => handleAddFood(meal.id, f.id)} style={{ backgroundColor: "#27272a", borderRadius: 10, paddingHorizontal: 12, paddingVertical: 6, marginRight: 6 }}>
                            <Text style={{ color: "#fff", fontSize: 10 }}>{f.name} - {f.calories} kcal</Text>
                          </TouchableOpacity>
                        ))}
                      </ScrollView>
                    )}
                  </>
                )}
              </View>
            );
          })}
        </View>
      </ScrollView>
    </>
  );
}

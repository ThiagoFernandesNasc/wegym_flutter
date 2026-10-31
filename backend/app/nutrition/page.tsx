"use client";
export const dynamic = 'force-dynamic';
import React, { useCallback, useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Apple, Loader2, Search, Plus, Coffee, UtensilsCrossed, Moon, Cookie } from "lucide-react";
import { toast } from "sonner";

const MEAL_TYPES = ["breakfast", "lunch", "dinner", "snack"];
const MEAL_ICONS: Record<string, React.ComponentType<{ size?: number; className?: string }>> = { breakfast: Coffee, lunch: UtensilsCrossed, dinner: Moon, snack: Cookie };

export default function NutritionPage() {
  const { t } = useTranslations();
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [meals, setMeals] = useState<any[]>([]);
  const [foods, setFoods] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [debouncedSearch, setDebouncedSearch] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [mealsRes, foodsRes] = await Promise.all([
        fetch(`/api/nutrition/meals?date=${date}`, { credentials: "include" }),
        fetch(`/api/nutrition/foods?q=${debouncedSearch}`, { credentials: "include" }),
      ]);
      if (mealsRes.ok) setMeals(await mealsRes.json());
      if (foodsRes.ok) setFoods(await foodsRes.json());
    } finally { setLoading(false); }
  }, [date, debouncedSearch]);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(search), 300);
    return () => clearTimeout(timer);
  }, [search]);

  const createMeal = async (type: string) => {
    setIsSaving(true);
    try {
      const res = await fetch("/api/nutrition/meals", { method: "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ date, type }) });
      if (res.ok) load();
    } catch {
      toast.error("Erro ao criar refeição. Tente novamente.");
    } finally {
      setIsSaving(false);
    }
  };

  const addFood = async (mealId: string, foodId: string) => {
    try {
      const res = await fetch("/api/nutrition/meals", { method: "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ mealId, foodId, amount: 1 }) });
      if (!res.ok) throw new Error("Erro ao adicionar alimento");
      load();
    } catch {
      toast.error("Erro ao adicionar alimento. Tente novamente.");
    }
  };

  const totals = meals.reduce((acc, m) => ({ calories: acc.calories + (m.totals?.calories ?? 0), protein: acc.protein + (m.totals?.proteinG ?? 0), carbs: acc.carbs + (m.totals?.carbsG ?? 0), fat: acc.fat + (m.totals?.fatG ?? 0) }), { calories: 0, protein: 0, carbs: 0, fat: 0 });

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4"><h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("nutrition.title")}</h1></header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-4">
          <input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="w-full bg-zinc-800 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white outline-none focus:border-orange-500" />

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            {Object.entries({ calories: `${Math.round(totals.calories)} kcal`, protein: `${Math.round(totals.protein)}g`, carbs: `${Math.round(totals.carbs)}g`, fat: `${Math.round(totals.fat)}g` }).map(([k, v]) => (
              <div key={k} className="bg-zinc-900/40 border border-white/5 rounded-2xl p-3 text-center">
                <p className="text-[9px] font-black uppercase text-zinc-500">{t(`nutrition.${k}`)}</p>
                <p className="text-sm font-black italic text-white mt-1">{v}</p>
              </div>
            ))}
          </div>

          {loading ? <div className="flex justify-center pt-8"><Loader2 size={24} className="animate-spin text-orange-500" /></div> : meals.length === 0 ? (
            <div className="bg-zinc-900/30 rounded-4xl border border-white/5 text-center py-16 px-6">
              <Apple size={40} className="mx-auto text-zinc-600 mb-4" />
              <p className="text-zinc-400 text-sm font-medium">Nenhuma refeição registrada</p>
              <p className="text-zinc-600 text-xs mt-1">Crie uma refeição acima para começar a registrar sua alimentação.</p>
            </div>
          ) : MEAL_TYPES.map((type) => {
            const Icon = MEAL_ICONS[type] || Apple;
            const meal = meals.find((m) => m.type === type);
            return (
              <div key={type} className="bg-zinc-900/40 border border-white/5 rounded-4xl p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2"><Icon size={16} className="text-orange-500" /><p className="text-xs font-black italic uppercase text-white">{t(`nutrition.${type}`)}</p></div>
                  {!meal && <button onClick={() => createMeal(type)} disabled={isSaving} className="text-[10px] text-orange-500 font-black uppercase italic cursor-pointer flex items-center gap-1 disabled:opacity-50"><Plus size={12} /> {t("nutrition.addFood")}</button>}
                </div>
                {meal && (
                  <div className="space-y-2">
                    {meal.foods?.map((mf: any) => (
                      <div key={mf.id} className="flex items-center justify-between text-sm">
                        <span className="text-zinc-300">{mf.food.name} <span className="text-zinc-500">x{mf.amount}</span></span>
                        <span className="text-zinc-500 text-xs">{Math.round(mf.food.calories * mf.amount)} kcal</span>
                      </div>
                    ))}
                    <div className="flex gap-2 mt-2">
                      <input placeholder={t("nutrition.searchFood")} value={search} onChange={(e) => setSearch(e.target.value)} className="flex-1 bg-zinc-950 border border-zinc-700 rounded-xl px-3 py-2 text-xs text-white placeholder:text-zinc-600 outline-none" />
                      {foods.length > 0 && (
                        <select onChange={(e) => { if (e.target.value) { addFood(meal.id, e.target.value); e.target.value = ""; } }} className="bg-zinc-950 border border-zinc-700 rounded-xl px-3 py-2 text-xs text-white outline-none">
                          <option value="">+ {t("nutrition.addFood")}</option>
                          {foods.map((f: any) => <option key={f.id} value={f.id}>{f.name} - {f.calories} kcal</option>)}
                        </select>
                      )}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </main>
      </div>
    </AuthGuard>
  );
}

"use client";
export const dynamic = 'force-dynamic';
import React, { useCallback, useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Loader2, Plus, Target, CheckCircle2, X, Trophy, Calendar } from "lucide-react";
import { toast } from "sonner";

type Goal = { id: string; title: string; description?: string; category: string; metric: string; targetValue: number; currentValue: number; endDate: string; status: string };

const CATEGORIES = ["workout", "weight", "nutrition", "cardio", "custom"] as const;

export default function GoalsPage() {
  const { t } = useTranslations();
  const [goals, setGoals] = useState<Goal[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ title: "", category: "workout", metric: "sessions", targetValue: 10, endDate: "" });
  const [isSaving, setIsSaving] = useState(false);

  const load = useCallback(async () => {
    try { const r = await fetch("/api/goals", { credentials: "include" }); if (r.ok) setGoals(await r.json()); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const createGoal = async () => {
    setIsSaving(true);
    try {
      const res = await fetch("/api/goals", { method: "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ...form, endDate: form.endDate ? new Date(form.endDate) : undefined, userId: "" }) });
      if (!res.ok) throw new Error("Erro ao criar meta");
      setShowForm(false); setForm({ title: "", category: "workout", metric: "sessions", targetValue: 10, endDate: "" }); load();
    } catch {
      toast.error("Erro ao criar meta. Tente novamente.");
    } finally {
      setIsSaving(false);
    }
  };

  const updateProgress = async (id: string, val: number) => {
    try {
      const res = await fetch("/api/goals", { method: "PATCH", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id, currentValue: val }) });
      if (!res.ok) throw new Error("Erro ao atualizar");
      load();
    } catch {
      toast.error("Erro ao atualizar progresso. Tente novamente.");
    }
  };

  const CAT_ICONS: Record<string, React.ComponentType<{ size?: number; className?: string }>> = { workout: Trophy, weight: Target, nutrition: CheckCircle2, cardio: Trophy, custom: Target };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 flex items-center justify-between">
          <h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("goals.title")}</h1>
          <button onClick={() => setShowForm(!showForm)} className="bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 rounded-xl text-[10px] font-black uppercase italic cursor-pointer transition-colors flex items-center gap-1.5">
            <Plus size={14} /> {t("goals.create")}
          </button>
        </header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-4">
          {showForm && (
            <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 space-y-4">
              <input value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} placeholder="Título da meta" className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
              <select value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white outline-none focus:border-orange-500">
                {CATEGORIES.map((c) => <option key={c} value={c}>{t(`goals.${c}`)}</option>)}
              </select>
              <input value={form.metric} onChange={(e) => setForm({ ...form, metric: e.target.value })} placeholder="Métrica (kg, km, sessões...)" className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
              <input type="number" value={form.targetValue} onChange={(e) => setForm({ ...form, targetValue: Number(e.target.value) })} placeholder="Valor alvo" className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
              <input type="date" value={form.endDate} onChange={(e) => setForm({ ...form, endDate: e.target.value })} className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white outline-none focus:border-orange-500" />
              <div className="flex gap-3">
                <button onClick={() => setShowForm(false)} className="flex-1 py-3 rounded-xl bg-zinc-800 text-zinc-300 text-xs font-black uppercase italic cursor-pointer">Cancelar</button>
                <button onClick={createGoal} disabled={!form.title || isSaving} className="flex-1 py-3 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-xs font-black uppercase italic cursor-pointer disabled:opacity-50 flex items-center justify-center gap-2">
                  {isSaving ? <Loader2 size={14} className="animate-spin" /> : "Salvar"}
                </button>
              </div>
            </div>
          )}

          {loading ? (
            <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div>
          ) : goals.length === 0 ? (
            <div className="text-center pt-20">
              <Target size={48} className="mx-auto text-zinc-600 mb-4" />
              <p className="text-zinc-500 text-sm">Nenhuma meta ainda. Crie sua primeira meta SMART!</p>
            </div>
          ) : (
            goals.map((goal) => {
              const pct = Math.min(100, Math.round((goal.currentValue / goal.targetValue) * 100));
              const CatIcon = CAT_ICONS[goal.category] || Target;
              return (
                <div key={goal.id} className={`bg-zinc-900/40 border rounded-4xl p-5 ${goal.status === "completed" ? "border-emerald-500/30" : "border-white/5"}`}>
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 ${goal.status === "completed" ? "bg-emerald-600/20 text-emerald-400" : "bg-white/5 text-zinc-400"}`}>
                        {goal.status === "completed" ? <CheckCircle2 size={18} /> : <CatIcon size={18} />}
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-black italic uppercase text-white">{goal.title}</p>
                        <p className="text-[10px] text-zinc-500 mt-0.5">{goal.currentValue} / {goal.targetValue} {goal.metric}</p>
                      </div>
                    </div>
                    <span className={`text-[10px] font-black uppercase px-2 py-1 rounded-full ${goal.status === "completed" ? "bg-emerald-600/20 text-emerald-400" : "bg-blue-600/20 text-blue-400"}`}>{t(`goals.${goal.status}`)}</span>
                  </div>
                  <div className="mt-3 w-full bg-zinc-800 rounded-full h-2 overflow-hidden">
                    <div className={`h-full rounded-full transition-all ${goal.status === "completed" ? "bg-emerald-500" : "bg-orange-500"}`} style={{ width: `${pct}%` }} />
                  </div>
                  {goal.status === "active" && (
                    <button onClick={() => updateProgress(goal.id, goal.targetValue)} className="mt-3 text-[10px] text-emerald-400 hover:text-emerald-300 font-black uppercase italic cursor-pointer flex items-center gap-1">
                      <CheckCircle2 size={12} /> {t("goals.markComplete")}
                    </button>
                  )}
                </div>
              );
            })
          )}
        </main>
      </div>
    </AuthGuard>
  );
}

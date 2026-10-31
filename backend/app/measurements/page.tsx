"use client";
export const dynamic = 'force-dynamic';
import React, { useCallback, useEffect, useState } from "react";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Plus, Loader2, Weight, Activity, Droplets, LineChart } from "lucide-react";
import { toast } from "sonner";

export default function MeasurementsPage() {
  const [entries, setEntries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ weight: "", muscleMass: "", bodyFat: "", note: "" });
  const [chartMetric, setChartMetric] = useState<string | null>(null);
  const [chartData, setChartData] = useState<any[]>([]);
  const [isSaving, setIsSaving] = useState(false);

  const load = useCallback(async () => {
    try { const r = await fetch("/api/body-measurements", { credentials: "include" }); if (r.ok) setEntries(await r.json()); } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const loadChart = async (metric: string) => {
    setChartMetric(metric);
    const r = await fetch(`/api/body-measurements?metric=${metric}`, { credentials: "include" });
    if (r.ok) setChartData(await r.json());
  };

  const save = async () => {
    setIsSaving(true);
    try {
      const res = await fetch("/api/body-measurements", { method: "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ weight: Number(form.weight), muscleMass: form.muscleMass ? Number(form.muscleMass) : undefined, bodyFat: form.bodyFat ? Number(form.bodyFat) : undefined, note: form.note }) });
      if (!res.ok) throw new Error("Erro ao salvar");
      setShowForm(false); setForm({ weight: "", muscleMass: "", bodyFat: "", note: "" }); load();
    } catch {
      toast.error("Erro ao salvar medição. Tente novamente.");
    } finally {
      setIsSaving(false);
    }
  };

  const METRICS = [
    { key: "weight", label: "Peso", icon: Weight, color: "text-orange-500", unit: "kg" },
    { key: "muscleMass", label: "Massa Muscular", icon: Activity, color: "text-emerald-400", unit: "kg" },
    { key: "bodyFat", label: "Gordura", icon: Droplets, color: "text-blue-400", unit: "%" },
  ];

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 flex items-center justify-between">
          <h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">Evolução</h1>
          <button onClick={() => setShowForm(!showForm)} className="bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 rounded-xl text-[10px] font-black uppercase italic cursor-pointer transition-colors flex items-center gap-1.5"><Plus size={14} /> Nova Medida</button>
        </header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-4">
          {showForm && (
            <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 space-y-3">
              <input type="number" value={form.weight} onChange={(e) => setForm({ ...form, weight: e.target.value })} placeholder="Peso (kg)" step="0.1" className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
              <input type="number" value={form.muscleMass} onChange={(e) => setForm({ ...form, muscleMass: e.target.value })} placeholder="Massa muscular (kg, opcional)" step="0.1" className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
              <input type="number" value={form.bodyFat} onChange={(e) => setForm({ ...form, bodyFat: e.target.value })} placeholder="% gordura (opcional)" step="0.1" className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
              <textarea value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} placeholder="Observação" rows={2} className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
              <button onClick={save} disabled={!form.weight || isSaving} className="w-full py-3 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-xs font-black uppercase italic cursor-pointer disabled:opacity-50 flex items-center justify-center gap-2">
                {isSaving ? <Loader2 size={14} className="animate-spin" /> : "Salvar"}
              </button>
            </div>
          )}

          <div className="grid grid-cols-3 gap-3">
            {METRICS.map((m) => {
              const Icon = m.icon;
              const latest = entries.find((e) => e[m.key] != null);
              return (
                <button key={m.key} onClick={() => loadChart(m.key)} className={`bg-zinc-900/40 border rounded-3xl p-4 text-left cursor-pointer transition-colors ${chartMetric === m.key ? "border-orange-500/50" : "border-white/5 hover:border-white/10"}`}>
                  <Icon size={16} className={m.color} />
                  <p className="text-[9px] text-zinc-500 font-bold uppercase mt-2">{m.label}</p>
                  <p className="text-lg font-black italic text-white">{latest ? `${latest[m.key]} ${m.unit}` : "—"}</p>
                </button>
              );
            })}
          </div>

          {chartData.length > 1 && (
            <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-5">
              <p className="text-[9px] font-black uppercase text-zinc-500 mb-4">Evolução - {METRICS.find((m) => m.key === chartMetric)?.label}</p>
              <div className="flex items-end gap-1 h-40">
                {chartData.map((d: any, i: number) => {
                  const values = chartData.map((cd: any) => cd.value);
                  const min = Math.min(...values);
                  const max = Math.max(...values);
                  const range = max - min || 1;
                  const h = ((d.value - min) / range) * 100;
                  return (
                    <div key={i} className="flex-1 flex flex-col items-center gap-1">
                      <div className="w-full bg-orange-500/20 rounded-t-sm" style={{ height: `${h}%`, minHeight: 4 }}><div className="w-full h-full bg-orange-500 rounded-t-sm" style={{ height: `${Math.max(10, h)}%` }} /></div>
                      <span className="text-[7px] text-zinc-600">{d.date.slice(5)}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {loading ? (
            <div className="flex justify-center pt-8"><Loader2 size={24} className="animate-spin text-orange-500" /></div>
          ) : entries.length === 0 ? (
            <div className="bg-zinc-900/30 rounded-4xl border border-white/5 text-center py-16 px-6">
              <LineChart size={40} className="mx-auto text-zinc-600 mb-4" />
              <p className="text-zinc-400 text-sm font-medium">Nenhuma medição registrada</p>
              <p className="text-zinc-600 text-xs mt-1 mb-4">Adicione sua primeira medição para acompanhar sua evolução.</p>
              <button onClick={() => setShowForm(true)} className="bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 rounded-xl text-[10px] font-black uppercase italic cursor-pointer transition-colors inline-flex items-center gap-1.5">
                <Plus size={14} /> Adicionar medição
              </button>
            </div>
          ) : entries.map((e: any) => (
            <div key={e.id} className="bg-zinc-900/40 border border-white/5 rounded-3xl p-4 flex items-center justify-between">
              <div>
                <p className="text-sm font-bold text-white">{e.weight} kg</p>
                <p className="text-[10px] text-zinc-500">{new Date(e.date).toLocaleDateString("pt-BR")}{e.muscleMass && ` · ${e.muscleMass}kg massa`}{e.bodyFat && ` · ${e.bodyFat}% gordura`}</p>
              </div>
              {e.note && <p className="text-[10px] text-zinc-600 max-w-[120px] text-right">{e.note}</p>}
            </div>
          ))}
        </main>
      </div>
    </AuthGuard>
  );
}

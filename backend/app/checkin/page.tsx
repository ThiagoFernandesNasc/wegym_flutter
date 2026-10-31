"use client";
export const dynamic = 'force-dynamic';
import React, { useCallback, useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Loader2, CheckCircle2, Smile, Zap, Moon, Dumbbell } from "lucide-react";
import { toast } from "sonner";

export default function CheckinPage() {
  const { t } = useTranslations();
  const [mood, setMood] = useState(3);
  const [energy, setEnergy] = useState(3);
  const [sleepHours, setSleepHours] = useState("7");
  const [trained, setTrained] = useState(false);
  const [note, setNote] = useState("");
  const [saved, setSaved] = useState(false);
  const [streak, setStreak] = useState(0);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  const load = useCallback(async () => {
    try {
      const [checkinRes, historyRes] = await Promise.all([
        fetch("/api/checkin", { credentials: "include" }),
        fetch("/api/checkin?history=true", { credentials: "include" }),
      ]);
      if (checkinRes.ok) { const d = await checkinRes.json(); if (d) { setMood(d.mood); setEnergy(d.energy); setSleepHours(String(d.sleepHours ?? "7")); setTrained(d.trained ?? false); setNote(d.note ?? ""); } }
      if (historyRes.ok) { const h = await historyRes.json(); setStreak(h.streak ?? 0); }
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const save = async () => {
    setIsSaving(true);
    try {
      const res = await fetch("/api/checkin", { method: "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ mood, energy, sleepHours: Number(sleepHours), trained, note }) });
      if (!res.ok) throw new Error("Erro ao salvar");
      setSaved(true); setTimeout(() => setSaved(false), 2000);
    } catch {
      toast.error("Erro ao salvar check-in. Tente novamente.");
    } finally {
      setIsSaving(false);
    }
  };

  const moods = [
    { v: 1, label: "😢", color: "#ef4444" }, { v: 2, label: "😕", color: "#f97316" },
    { v: 3, label: "😐", color: "#eab308" }, { v: 4, label: "😊", color: "#22c55e" }, { v: 5, label: "🔥", color: "#22c55e" },
  ];

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4"><h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("checkin.title")}</h1></header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-6">
          {loading ? <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div> : (
            <>
              {streak > 0 && <div className="text-center text-emerald-400 text-sm font-black italic">🔥 {t("checkin.streak").replace("{days}", String(streak))}</div>}
              <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8 space-y-6">
                <div><p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500 mb-3">{t("checkin.mood")}</p>
                  <div className="flex gap-3 justify-center">{moods.map((m) => (
                    <button key={m.v} onClick={() => setMood(m.v)} className={`text-3xl p-3 rounded-2xl transition-all cursor-pointer ${mood === m.v ? "bg-zinc-800 scale-110 border border-orange-500/50" : "bg-zinc-900/60 border border-white/5 opacity-50 hover:opacity-80"}`}>{m.label}</button>
                  ))}</div>
                </div>
                <div><p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500 mb-3">{t("checkin.energy")}</p>
                  <div className="flex gap-3 justify-center">{moods.map((m) => (
                    <button key={m.v} onClick={() => setEnergy(m.v)} className={`text-3xl p-3 rounded-2xl transition-all cursor-pointer ${energy === m.v ? "bg-zinc-800 scale-110 border border-orange-500/50" : "bg-zinc-900/60 border border-white/5 opacity-50 hover:opacity-80"}`}>{m.label}</button>
                  ))}</div>
                </div>
                <div><p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500 mb-2">{t("checkin.sleep")}</p>
                  <input type="number" value={sleepHours} onChange={(e) => setSleepHours(e.target.value)} step="0.5" min="0" max="24" className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white outline-none focus:border-orange-500" />
                </div>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input type="checkbox" checked={trained} onChange={(e) => setTrained(e.target.checked)} className="w-5 h-5 accent-orange-500" />
                  <span className="text-sm font-black italic uppercase text-white">{t("checkin.trained")}</span>
                </label>
                <textarea value={note} onChange={(e) => setNote(e.target.value)} placeholder={t("checkin.note")} rows={3} className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
                <button onClick={save} disabled={isSaving} className="w-full py-4 rounded-xl bg-orange-600 hover:bg-orange-700 disabled:bg-zinc-700 text-white text-xs font-black uppercase italic cursor-pointer transition-colors flex items-center justify-center gap-2 disabled:cursor-not-allowed">
                  {isSaving ? <Loader2 size={16} className="animate-spin" /> : saved ? <><CheckCircle2 size={16} /> {t("checkin.saved")}</> : t("checkin.save")}
                </button>
              </div>
            </>
          )}
        </main>
      </div>
    </AuthGuard>
  );
}

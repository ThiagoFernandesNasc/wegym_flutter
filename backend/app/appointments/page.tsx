"use client";
export const dynamic = 'force-dynamic';
import React, { useCallback, useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Calendar, CheckCircle2, XCircle, Loader2, Clock } from "lucide-react";

export default function AppointmentsPage() {
  const { t } = useTranslations();
  const [appointments, setAppointments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try { const r = await fetch("/api/appointments", { credentials: "include" }); if (r.ok) setAppointments(await r.json()); } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const cancel = async (id: string) => {
    await fetch("/api/appointments", { method: "PATCH", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id, action: "cancel" }) });
    load();
  };

  const STATUS_STYLES: Record<string, string> = { pending: "text-yellow-400 bg-yellow-400/10", confirmed: "text-emerald-400 bg-emerald-400/10", completed: "text-zinc-500 bg-zinc-500/10", cancelled: "text-rose-400 bg-rose-400/10" };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4"><h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("appointments.title")}</h1></header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-4">
          {loading ? <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div> : appointments.length === 0 ? (
            <div className="text-center pt-20"><Calendar size={48} className="mx-auto text-zinc-600 mb-4" /><p className="text-zinc-500 text-sm">Nenhum agendamento ainda</p></div>
          ) : appointments.map((a: any) => (
            <div key={a.id} className="bg-zinc-900/40 border border-white/5 rounded-4xl p-5">
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-2xl bg-orange-600/20 text-orange-500 flex items-center justify-center"><Calendar size={18} /></div>
                  <div>
                    <p className="text-sm font-black italic uppercase text-white">{a.athlete?.displayName || a.personal?.displayName}</p>
                    <p className="text-xs text-zinc-400 mt-1">{new Date(a.date).toLocaleDateString("pt-BR")} às {new Date(a.date).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}</p>
                    <span className={`inline-block mt-2 text-[9px] font-black uppercase px-2 py-0.5 rounded-full ${STATUS_STYLES[a.status] || "text-zinc-500 bg-zinc-500/10"}`}>{a.status}</span>
                  </div>
                </div>
                {a.status === "pending" && (
                  <button onClick={() => cancel(a.id)} className="shrink-0 text-rose-400 hover:text-rose-300 text-[10px] font-black uppercase italic cursor-pointer flex items-center gap-1"><XCircle size={12} /> {t("appointments.cancel")}</button>
                )}
              </div>
            </div>
          ))}
        </main>
      </div>
    </AuthGuard>
  );
}

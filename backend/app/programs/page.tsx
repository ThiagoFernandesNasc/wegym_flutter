"use client";
export const dynamic = 'force-dynamic';
import React, { useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { useRouter } from "next/navigation";
import { BookOpen, Loader2, Dumbbell, Wind, Heart } from "lucide-react";

const CAT_ICONS: Record<string, React.ComponentType<{ size?: number; className?: string }>> = { gym: Dumbbell, running: Wind, weight_loss: Heart };

export default function ProgramsPage() {
  const { t } = useTranslations();
  const router = useRouter();
  const [programs, setPrograms] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/programs", { credentials: "include" }).then((r) => r.json()).then(setPrograms).finally(() => setLoading(false));
  }, []);

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4"><h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("programs.title")}</h1></header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-4">
          {loading ? (
            <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div>
          ) : programs.length === 0 ? (
            <div className="bg-zinc-900/30 rounded-4xl border border-white/5 text-center py-16 px-6">
              <BookOpen size={40} className="mx-auto text-zinc-600 mb-4" />
              <p className="text-zinc-400 text-sm font-medium">Nenhum programa disponível</p>
              <p className="text-zinc-600 text-xs mt-1">Programas de treino estarão disponíveis em breve.</p>
            </div>
          ) : programs.map((p: any) => {
            const Icon = CAT_ICONS[p.category] || BookOpen;
            return (
              <button key={p.id} onClick={() => router.push(`/programs/${p.id}`)} className="w-full bg-zinc-900/40 border border-white/5 hover:border-white/10 rounded-4xl p-5 text-left cursor-pointer transition-all group">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-orange-600/20 text-orange-500 flex items-center justify-center shrink-0 group-hover:scale-105 transition-transform"><Icon size={22} /></div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-black italic uppercase text-white">{p.title}</p>
                    <p className="text-[10px] text-zinc-500 mt-1 line-clamp-2">{p.description}</p>
                    <div className="flex gap-3 mt-2">
                      <span className="text-[9px] text-zinc-600 font-bold uppercase">{p.durationWeeks} semanas · {p.daysPerWeek}x/sem</span>
                      {p.featured && <span className="text-[9px] text-orange-500 font-bold uppercase">★ Destaque</span>}
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </main>
      </div>
    </AuthGuard>
  );
}

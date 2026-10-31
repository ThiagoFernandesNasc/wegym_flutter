"use client";
export const dynamic = 'force-dynamic';
import React, { useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Award, Loader2, Lock } from "lucide-react";

export default function AchievementsPage() {
  const { t } = useTranslations();
  const [data, setData] = useState<{ achievements: any[]; userAchievements: any[] }>({ achievements: [], userAchievements: [] });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/achievements", { credentials: "include" }).then((r) => r.json()).then(setData).finally(() => setLoading(false));
  }, []);

  const earnedIds = new Set(data.userAchievements.map((ua: any) => ua.achievementId));

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4"><h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("achievements.title")}</h1></header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8">
          {loading ? <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div> : (
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {data.achievements.map((ach: any) => {
                const earned = data.userAchievements.find((ua: any) => ua.achievementId === ach.id);
                return (
                  <div key={ach.id} className={`rounded-3xl border p-4 text-center ${earned ? "bg-orange-600/10 border-orange-500/30" : "bg-zinc-900/40 border-white/5 opacity-60"}`}>
                    <div className="text-4xl mb-2">{ach.icon}</div>
                    <p className="text-xs font-black italic uppercase text-white">{ach.title}</p>
                    <p className="text-[9px] text-zinc-500 mt-1">{ach.description}</p>
                    <p className="text-[10px] text-orange-500 font-bold mt-2">+{ach.xpReward} XP</p>
                    {earned && <p className="text-[9px] text-emerald-400 mt-1">{t("achievements.earned").replace("{date}", new Date(earned.earnedAt).toLocaleDateString("pt-BR"))}</p>}
                    {!earned && <Lock size={12} className="mx-auto mt-2 text-zinc-600" />}
                  </div>
                );
              })}
            </div>
          )}
        </main>
      </div>
    </AuthGuard>
  );
}

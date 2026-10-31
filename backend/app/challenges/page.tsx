"use client";
export const dynamic = 'force-dynamic';
import React, { useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { useRouter } from "next/navigation";
import { Swords, Loader2, Users, Calendar } from "lucide-react";

export default function ChallengesPage() {
  const { t } = useTranslations();
  const router = useRouter();
  const [challenges, setChallenges] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/challenges", { credentials: "include" }).then((r) => r.json()).then(setChallenges).finally(() => setLoading(false));
  }, []);

  const join = async (id: string) => {
    await fetch("/api/challenges", { method: "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ challengeId: id }) });
    router.push(`/challenges/${id}`);
  };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4"><h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("challenges.title")}</h1></header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-4">
          {loading ? <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div> : challenges.length === 0 ? (
            <div className="text-center pt-20"><Swords size={48} className="mx-auto text-zinc-600 mb-4" /><p className="text-zinc-500 text-sm">Nenhum desafio ativo no momento</p></div>
          ) : challenges.map((c: any) => (
            <div key={c.id} className="bg-zinc-900/40 border border-white/5 rounded-4xl p-5">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm font-black italic uppercase text-white">{c.title}</p>
                  <p className="text-[10px] text-zinc-500 mt-1">{c.description}</p>
                  <div className="flex items-center gap-4 mt-2 text-[10px] text-zinc-600">
                    <span className="flex items-center gap-1"><Calendar size={10} /> {new Date(c.startDate).toLocaleDateString()} - {new Date(c.endDate).toLocaleDateString()}</span>
                    <span className="flex items-center gap-1"><Users size={10} /> {c.participants?.length || 0}</span>
                  </div>
                </div>
                <button onClick={() => join(c.id)} className="shrink-0 bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 rounded-xl text-[10px] font-black uppercase italic cursor-pointer transition-colors">{t("challenges.join")}</button>
              </div>
            </div>
          ))}
        </main>
      </div>
    </AuthGuard>
  );
}

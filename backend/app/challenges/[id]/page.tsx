"use client";
export const dynamic = 'force-dynamic';
import React, { useEffect, useState } from "react";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { useParams } from "next/navigation";
import Link from "next/link";
import { ChevronLeft, Crown, Loader2, Medal } from "lucide-react";

export default function ChallengeDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [leaderboard, setLeaderboard] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/challenges/${id}/leaderboard`, { credentials: "include" }).then((r) => r.json()).then(setLeaderboard).finally(() => setLoading(false));
  }, [id]);

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 flex items-center gap-4">
          <Link href="/challenges"><ChevronLeft size={20} className="text-orange-500" /></Link>
          <h1 className="text-lg font-black italic uppercase tracking-tighter text-white">Ranking</h1>
        </header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8">
          {loading ? <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div> : (
            <div className="space-y-2">
              {leaderboard.map((p: any, i: number) => (
                <div key={p.userId} className="bg-zinc-900/40 border border-white/5 rounded-3xl p-4 flex items-center gap-4">
                  <div className={`w-8 h-8 rounded-xl flex items-center justify-center text-sm font-bold ${i === 0 ? "bg-yellow-500/20 text-yellow-500" : i === 1 ? "bg-zinc-400/20 text-zinc-400" : i === 2 ? "bg-amber-700/20 text-amber-700" : "bg-zinc-800 text-zinc-500"}`}>
                    {i === 0 ? <Crown size={16} /> : i < 3 ? <Medal size={16} /> : i + 1}
                  </div>
                  <div className="flex-1">
                    <p className="text-sm font-black italic text-white">{p.user.displayName || "Atleta"}</p>
                    <p className="text-[10px] text-zinc-500">{p.currentValue} pontos</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </main>
      </div>
    </AuthGuard>
  );
}

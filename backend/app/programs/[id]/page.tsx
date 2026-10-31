"use client";
export const dynamic = 'force-dynamic';
import React, { useEffect, useState } from "react";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { useParams } from "next/navigation";
import { ChevronLeft, Loader2, CheckCircle2 } from "lucide-react";
import Link from "next/link";

export default function ProgramDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [program, setProgram] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/programs/${id}`, { credentials: "include" }).then((r) => r.json()).then(setProgram).finally(() => setLoading(false));
  }, [id]);

  const weeks = program?.exercises?.reduce((acc: any, ex: any) => {
    if (!acc[ex.week]) acc[ex.week] = {};
    if (!acc[ex.week][ex.day]) acc[ex.week][ex.day] = [];
    acc[ex.week][ex.day].push(ex);
    return acc;
  }, {});

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 flex items-center gap-4">
          <Link href="/programs"><ChevronLeft size={20} className="text-orange-500" /></Link>
          <h1 className="text-lg font-black italic uppercase tracking-tighter text-white">{program?.title || "..."}</h1>
        </header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8">
          {loading ? <div className="flex justify-center pt-12"><Loader2 size={24} className="animate-spin text-orange-500" /></div> : program ? (
            <div className="space-y-4">
              <p className="text-sm text-zinc-400">{program.description}</p>
              <p className="text-[10px] text-zinc-600 font-bold">{program.durationWeeks} semanas · {program.daysPerWeek}x/semana · Nível: {program.level}</p>
              {weeks && Object.entries(weeks).map(([week, days]: [string, any]) => (
                <div key={week} className="bg-zinc-900/40 border border-white/5 rounded-4xl p-5">
                  <h3 className="text-sm font-black italic uppercase text-orange-500 mb-4">Semana {week}</h3>
                  {Object.entries(days).map(([day, exercises]: [string, any]) => (
                    <div key={day} className="mb-4 last:mb-0">
                      <p className="text-[10px] font-black uppercase text-zinc-500 mb-2">Dia {day}</p>
                      {exercises.map((ex: any, i: number) => (
                        <div key={i} className="flex items-center gap-3 py-2 border-b border-white/5 last:border-0">
                          <CheckCircle2 size={14} className="text-zinc-600 shrink-0" />
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium text-white">{ex.name}</p>
                            <p className="text-[10px] text-zinc-500">{ex.sets && `${ex.sets}x${ex.reps}`}{ex.duration && ex.duration}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  ))}
                </div>
              ))}
            </div>
          ) : <p className="text-zinc-500 text-center pt-12">Programa não encontrado</p>}
        </main>
      </div>
    </AuthGuard>
  );
}

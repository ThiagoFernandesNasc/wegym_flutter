"use client";

import { useState, useCallback } from "react";
import { motion } from "framer-motion";
import {
  ChevronLeft,
  TrendingUp,
  Flame,
  Clock,
  Dumbbell,
  Heart,
  Loader2,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Tilt3D } from "@/components/ui/Tilt3D";
import { ScrollReveal } from "@/components/ui/ScrollReveal";
import { ParallaxField } from "@/components/ui/ParallaxField";
import { useTranslations } from "@/lib/i18n/hook";

type PeriodKey = "week" | "month" | "year";

interface StatsData {
  totalSessions: number;
  totalVolume: number;
  totalCalories: number;
  totalDistance: number;
  avgHeartRate: number;
  chartData: Record<string, number>;
}

interface StatsClientProps {
  initialStats: StatsData;
  initialPeriod: PeriodKey;
}

export function StatsClient({ initialStats, initialPeriod }: StatsClientProps) {
  const router = useRouter();
  const { t } = useTranslations();
  const [activeTab, setActiveTab] = useState<PeriodKey>(initialPeriod);
  const [statsData, setStatsData] = useState<StatsData>(initialStats);
  const [loading, setLoading] = useState(false);

  const fetchStats = useCallback(async (period: PeriodKey) => {
    setLoading(true);
    try {
      const res = await fetch(`/api/workout-stats?period=${period}`, {
        headers: { "Cache-Control": "no-cache" },
      });
      if (res.ok) {
        const data = await res.json();
        setStatsData(data.data);
      }
    } catch {
      // keep previous data
    } finally {
      setLoading(false);
    }
  }, []);

  const handleTabChange = (period: PeriodKey) => {
    if (period === activeTab) return;
    setActiveTab(period);
    fetchStats(period);
  };

  const formatDuration = (seconds: number) => {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  };

  const stats = [
    {
      label: t("stats.totalVolume"),
      value: formatDuration(statsData.totalVolume),
      icon: <Dumbbell size={18} />,
      color: "text-orange-500",
    },
    {
      label: t("stats.avgHeartRate"),
      value: statsData.avgHeartRate ? `${statsData.avgHeartRate} bpm` : "—",
      icon: <Heart size={18} />,
      color: "text-rose-500",
    },
    {
      label: t("stats.calories"),
      value: statsData.totalCalories.toLocaleString(),
      icon: <Flame size={18} />,
      color: "text-yellow-500",
    },
    {
      label: t("stats.activeTime"),
      value: formatDuration(statsData.totalVolume),
      icon: <Clock size={18} />,
      color: "text-blue-500",
    },
  ];

  const chartValues = statsData?.chartData
    ? Object.entries(statsData.chartData).map(([_, sec]) => sec)
    : [];
  const maxChartValue = Math.max(...chartValues, 1);

  return (
    <AuthGuard allowedRoles={["atleta"]}>
      <div className="min-h-screen bg-zinc-950 text-white pb-32 font-sans selection:bg-orange-500/30 relative overflow-hidden">
        <ParallaxField variant="subtle" />

        <header className="sticky top-0 z-50 bg-zinc-950/60 backdrop-blur-xl border-b border-white/5 px-6 py-5 flex items-center justify-between">
          <button
            onClick={() => router.back()}
            className="p-2 bg-white/5 rounded-full hover:bg-white/10 transition-colors z-50 cursor-pointer"
          >
            <ChevronLeft size={20} />
          </button>
          <h1 className="font-black italic uppercase tracking-tighter text-lg">{t("stats.title")}</h1>
          <div className="p-2 bg-orange-600/10 rounded-full text-orange-500">
            <TrendingUp size={20} />
          </div>
        </header>

        <main className="max-w-2xl mx-auto px-6 pt-8 space-y-8 relative z-10">
          <section className="flex bg-zinc-900/50 p-1 rounded-2xl border border-white/5">
            {[
              { label: t("stats.week"), key: "week" as PeriodKey },
              { label: t("stats.month"), key: "month" as PeriodKey },
              { label: t("stats.year"), key: "year" as PeriodKey },
            ].map((tab) => (
              <button
                key={tab.key}
                onClick={() => handleTabChange(tab.key)}
                className={`flex-1 py-2.5 rounded-xl text-[10px] font-black uppercase transition-all cursor-pointer ${
                  activeTab === tab.key ? "bg-orange-600 text-white shadow-lg" : "text-zinc-500"
                }`}
              >
                {tab.label}
              </button>
            ))}
          </section>

          {loading ? (
            <div className="flex justify-center py-16">
              <Loader2 className="w-8 h-8 text-orange-500 animate-spin" />
            </div>
          ) : (
            <>
              <ScrollReveal className="grid grid-cols-2 gap-4">
                {stats.map((item, idx) => (
                  <Tilt3D key={idx} className="rounded-[30px]" intensity={9} scale={1.02} glareOpacity={0.12} disabled={loading}>
                    <div className="bg-zinc-900/40 border border-white/5 p-5 rounded-[30px] relative overflow-hidden group">
                      <div className={`${item.color} mb-3 group-hover:scale-110 transition-transform`}>{item.icon}</div>
                      <p className="text-[10px] font-black text-zinc-500 uppercase tracking-widest">{item.label}</p>
                      <p className="text-2xl font-black italic mt-1">{item.value}</p>
                    </div>
                  </Tilt3D>
                ))}
              </ScrollReveal>

              <ScrollReveal className="bg-zinc-900/40 border border-white/5 rounded-[40px] p-8">
                <div className="flex justify-between items-end mb-8">
                  <div>
                    <h3 className="font-black italic uppercase text-sm">{t("stats.loadVolume")}</h3>
                    {statsData && (
                      <p className="text-[10px] text-zinc-500 font-bold mt-1">
                        {statsData.totalSessions} {statsData.totalSessions === 1 ? "sessão" : "sessões"}
                      </p>
                    )}
                  </div>
                </div>
                <div className="flex items-end justify-between h-40 gap-2" style={{ perspective: 500 }}>
                  {chartValues.length > 0 ? (
                    chartValues.map((value, i) => {
                      const height = (value / maxChartValue) * 100;
                      return (
                        <div key={i} className="flex-1 flex flex-col items-center gap-3" style={{ transformStyle: "preserve-3d" }}>
                          <motion.div
                            initial={{ height: 0, opacity: 0, rotateX: 45, transformPerspective: 500 }}
                            whileInView={{ height: `${Math.max(height, 2)}%`, opacity: 1, rotateX: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.6, delay: i * 0.06, ease: [0.22, 1, 0.36, 1] }}
                            className={`w-full rounded-t-lg ${i === chartValues.length - 1 ? "bg-linear-to-t from-orange-600 to-orange-400 shadow-[0_0_20px_rgba(234,88,12,0.4)]" : "bg-zinc-800"}`}
                          />
                        </div>
                      );
                    })
                  ) : (
                    <div className="w-full text-center text-zinc-600 text-xs font-bold uppercase py-10">
                      Nenhum dado no período
                    </div>
                  )}
                </div>
              </ScrollReveal>
            </>
          )}
        </main>
      </div>
    </AuthGuard>
  );
}
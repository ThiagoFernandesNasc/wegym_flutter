import { unstable_cache } from "next/cache";
import { headers } from "next/headers";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { StatsClient } from "./StatsClient";

type PeriodKey = "week" | "month" | "year";

interface StatsData {
  totalSessions: number;
  totalVolume: number;
  totalCalories: number;
  totalDistance: number;
  avgHeartRate: number;
  chartData: Record<string, number>;
}

async function getStatsData(athleteId: string, period: PeriodKey): Promise<StatsData> {
  const now = new Date();
  const startDate = new Date(now);
  switch (period) {
    case "week":
      startDate.setDate(startDate.getDate() - 7);
      break;
    case "month":
      startDate.setMonth(startDate.getMonth() - 1);
      break;
    case "year":
      startDate.setFullYear(startDate.getFullYear() - 1);
      break;
  }

  const [aggregate, sessions] = await Promise.all([
    prisma.workoutSession.aggregate({
      where: { athleteId, completedAt: { gte: startDate } },
      _count: true,
      _sum: { durationSec: true, calories: true, distanceKm: true },
      _avg: { avgHeartRate: true },
    }),
    prisma.workoutSession.findMany({
      where: { athleteId, completedAt: { gte: startDate } },
      select: { completedAt: true, durationSec: true },
      orderBy: { completedAt: "desc" },
    }),
  ]);

  return {
    totalSessions: aggregate._count,
    totalVolume: aggregate._sum.durationSec ?? 0,
    totalCalories: aggregate._sum.calories ?? 0,
    totalDistance: aggregate._sum.distanceKm ?? 0,
    avgHeartRate: aggregate._avg.avgHeartRate ? Math.round(aggregate._avg.avgHeartRate) : 0,
    chartData: sessions.reduce<Record<string, number>>((acc, s) => {
      const key = s.completedAt.toISOString().slice(0, 10);
      acc[key] = (acc[key] ?? 0) + s.durationSec;
      return acc;
    }, {}),
  };
}

const getCachedStats = unstable_cache(getStatsData, ["stats-page"], {
  revalidate: 30,
  tags: ["workout-stats"],
});

async function getSessionData() {
  const headersList = await headers();
  const session = await getServerSession(authOptions);
  return session;
}

export default async function StatsPage({
  searchParams,
}: {
  searchParams: Promise<{ period?: string }>;
}) {
  const { period = "week" } = await searchParams;
  const session = await getSessionData();

  if (!session?.user?.id || session.user.role !== "atleta") {
    redirect("/");
  }

  const athlete = await prisma.athlete.findUnique({
    where: { userId: session.user.id },
    select: { id: true },
  });

  if (!athlete) {
    redirect("/");
  }

  const statsData = await getCachedStats(athlete.id, period as PeriodKey);

  return <StatsClient initialStats={statsData} initialPeriod={period as PeriodKey} />;
}
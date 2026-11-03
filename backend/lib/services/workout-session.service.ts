import { prisma } from '@/lib/prisma';
import type { Prisma } from '@prisma/client';

function sumPerformedLiftVolumeKg(sessions: Array<{ exercises: Prisma.JsonValue | null }>) {
  let total = 0;
  for (const session of sessions) {
    if (!Array.isArray(session.exercises)) continue;
    for (const item of session.exercises) {
      if (typeof item !== 'object' || item === null || Array.isArray(item)) continue;
      const performedSets = (item as Prisma.JsonObject).performedSets;
      if (!Array.isArray(performedSets)) continue;
      for (const set of performedSets) {
        if (typeof set !== 'object' || set === null || Array.isArray(set)) continue;
        const row = set as Prisma.JsonObject;
        const weightKg = row.weightKg;
        const reps = row.reps;
        if (row.completed !== true || typeof weightKg !== 'number' || typeof reps !== 'number') continue;
        if (!Number.isFinite(weightKg) || !Number.isFinite(reps) || weightKg < 0 || reps < 1) continue;
        total += weightKg * reps;
      }
    }
  }
  return Math.round(total * 100) / 100;
}

export const workoutSessionService = {
  async create(data: {
    athleteId: string;
    modality: string;
    durationSec: number;
    distanceKm?: number;
    avgPaceSecPerKm?: number;
    steps?: number;
    calories?: number;
    avgHeartRate?: number;
    exercises?: Prisma.InputJsonValue;
  }) {
    return prisma.workoutSession.create({ data });
  },

  async list(athleteId: string, limit = 50, cursor?: string) {
    const takeClamped = Math.min(limit, 100);
    const sessions = await prisma.workoutSession.findMany({
      where: { athleteId },
      take: takeClamped + 1,
      orderBy: { completedAt: 'desc' },
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    });
    const hasMore = sessions.length > takeClamped;
    const sliced = hasMore ? sessions.slice(0, takeClamped) : sessions;
    const nextCursor = hasMore ? sliced[sliced.length - 1].id : null;
    return { data: sliced, nextCursor, hasMore };
  },

  async getStats(athleteId: string, period: 'week' | 'month' | 'year') {
    const now = new Date();
    const startDate = new Date(now);
    switch (period) {
      case 'week':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(startDate.getMonth() - 1);
        break;
      case 'year':
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
    }

    const aggregate = await prisma.workoutSession.aggregate({
      where: { athleteId, completedAt: { gte: startDate } },
      _count: true,
      _sum: { durationSec: true, calories: true, distanceKm: true },
      _avg: { avgHeartRate: true },
    });

    const sessions = await prisma.workoutSession.findMany({
      where: { athleteId, completedAt: { gte: startDate } },
      select: { completedAt: true, durationSec: true, exercises: true },
      orderBy: { completedAt: 'desc' },
    });

    return {
      totalSessions: aggregate._count,
      totalVolume: aggregate._sum.durationSec ?? 0,
      totalLiftedVolumeKg: sumPerformedLiftVolumeKg(sessions),
      totalCalories: aggregate._sum.calories ?? 0,
      totalDistance: aggregate._sum.distanceKm ?? 0,
      avgHeartRate: aggregate._avg.avgHeartRate ? Math.round(aggregate._avg.avgHeartRate) : 0,
      chartData: sessions.reduce<Record<string, number>>((acc, s) => {
        const key = s.completedAt.toISOString().slice(0, 10);
        acc[key] = (acc[key] ?? 0) + s.durationSec;
        return acc;
      }, {}),
    };
  },
};

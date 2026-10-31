import { prisma } from '@/lib/prisma';
import type { Prisma } from '@prisma/client';

export const gpsSessionService = {
  async create(data: {
    athleteId: string;
    modality: string;
    distanceKm: number;
    durationSec: number;
    avgPaceSecPerKm?: number;
    steps?: number;
    coordinates?: Prisma.InputJsonValue;
    startLat?: number;
    startLng?: number;
    endLat?: number;
    endLng?: number;
  }) {
    return prisma.gpsSession.create({ data });
  },

  async list(athleteId: string, limit = 50, cursor?: string) {
    const takeClamped = Math.min(limit, 100);
    const sessions = await prisma.gpsSession.findMany({
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
};

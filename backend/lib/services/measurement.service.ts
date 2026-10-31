import { prisma } from '@/lib/prisma';

export const measurementService = {
  async create(athleteId: string, data: { date?: Date; weight: number; muscleMass?: number; bodyFat?: number; note?: string }) {
    return prisma.progressEntry.create({ data: { athleteId, ...data, date: data.date ?? new Date() } });
  },

  async list(athleteId: string) {
    return prisma.progressEntry.findMany({ where: { athleteId }, orderBy: { date: 'desc' } });
  },

  async getChartData(athleteId: string, metric: 'weight' | 'muscleMass' | 'bodyFat') {
    const entries = await prisma.progressEntry.findMany({
      where: { athleteId, [metric]: { not: null } },
      orderBy: { date: 'asc' },
      select: { date: true, weight: true, muscleMass: true, bodyFat: true },
    });
    return entries.map((e) => ({ date: e.date.toISOString().slice(0, 10), value: Number(e[metric]) }));
  },

  async delete(id: string, athleteId: string) {
    return prisma.progressEntry.deleteMany({ where: { id, athleteId } });
  },
};

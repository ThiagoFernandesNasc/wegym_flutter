import { prisma } from '@/lib/prisma';
import { cache } from '@/lib/cache';

export const programService = {
  async create(data: { title: string; description?: string; category: string; level: string; durationWeeks: number; daysPerWeek: number; authorId?: string }) {
    await cache.delPattern('programs');
    return prisma.program.create({ data });
  },

  async list(category?: string, level?: string) {
    const cacheKey = `programs:list:${category ?? 'all'}:${level ?? 'all'}`;
    return cache.getOrSet(cacheKey, async () => {
      const where: Record<string, unknown> = {};
      if (category) where.category = category;
      if (level) where.level = level;
      return prisma.program.findMany({ where: where as any, orderBy: { createdAt: 'desc' }, include: { author: { select: { displayName: true } } } });
    }, 300);
  },

  async getFeatured() {
    return cache.getOrSet('programs:featured', async () => {
      return prisma.program.findMany({ where: { featured: true }, take: 10 });
    }, 300);
  },

  async getById(id: string) {
    return cache.getOrSet(`program:${id}`, async () => {
      return prisma.program.findUnique({ where: { id }, include: { exercises: { orderBy: [{ week: 'asc' }, { day: 'asc' }, { order: 'asc' }] } } });
    }, 300);
  },

  async addExercise(programId: string, data: { week: number; day: number; name: string; sets?: string; reps?: string; duration?: string; notes?: string; order?: number }) {
    await cache.del(`program:${programId}`);
    return prisma.programExercise.create({ data: { programId, ...data, order: data.order ?? 0 } });
  },
};

import { prisma } from '@/lib/prisma';

export const goalService = {
  async create(data: { userId: string; title: string; description?: string; category: string; metric: string; targetValue: number; endDate: Date }) {
    return prisma.goal.create({ data });
  },

  async list(userId: string, status?: string) {
    const where: Record<string, unknown> = { userId };
    if (status) where.status = status;
    return prisma.goal.findMany({ where: where as any, orderBy: { endDate: 'asc' } });
  },

  async updateProgress(id: string, userId: string, currentValue: number) {
    const goal = await prisma.goal.findFirst({ where: { id, userId } });
    if (!goal) throw new Error('Meta não encontrada');

    const status = currentValue >= goal.targetValue ? 'completed' : 'active';
    return prisma.goal.update({
      where: { id },
      data: { currentValue, status, completedAt: status === 'completed' ? new Date() : undefined },
    });
  },

  async complete(id: string, userId: string) {
    return prisma.goal.updateMany({ where: { id, userId }, data: { status: 'completed', completedAt: new Date() } });
  },

  async remove(id: string, userId: string) {
    return prisma.goal.deleteMany({ where: { id, userId } });
  },
};

import { prisma } from '@/lib/prisma';

export const checkinService = {
  async upsert(userId: string, data: { mood: number; energy: number; sleepHours?: number; note?: string; trained?: boolean }) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return prisma.dailyCheckIn.upsert({
      where: { userId_date: { userId, date: today } },
      create: { userId, ...data, date: today },
      update: data,
    });
  },

  async getToday(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return prisma.dailyCheckIn.findUnique({ where: { userId_date: { userId, date: today } } });
  },

  async getHistory(userId: string, days = 30) {
    const since = new Date();
    since.setDate(since.getDate() - days);
    return prisma.dailyCheckIn.findMany({
      where: { userId, date: { gte: since } },
      orderBy: { date: 'desc' },
    });
  },

  async getStreak(userId: string) {
    const checkins = await prisma.dailyCheckIn.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      select: { date: true },
    });
    if (checkins.length === 0) return 0;
    let streak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    for (const c of checkins) {
      const expected = new Date(today);
      expected.setDate(expected.getDate() - streak);
      const cDate = new Date(c.date);
      cDate.setHours(0, 0, 0, 0);
      if (cDate.getTime() === expected.getTime()) streak++;
      else break;
    }
    return streak;
  },
};

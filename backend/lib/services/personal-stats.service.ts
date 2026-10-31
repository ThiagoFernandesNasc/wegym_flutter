import { prisma } from '@/lib/prisma';

export const personalStatsService = {
  async getDashboard(personalId: string) {
    const [athletes, classes] = await Promise.all([
      prisma.athlete.count({ where: { personalId } }),
      prisma.weeklyClass.count({
        where: {
          athlete: { personalId },
          date: { gte: new Date(Date.now() - 7 * 86400000) },
        },
      }),
    ]);

    return {
      activeStudents: athletes,
      classesPerWeek: classes,
    };
  },
};

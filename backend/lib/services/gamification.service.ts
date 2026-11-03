import { prisma } from '@/lib/prisma';

const defaultChallenges = [
  {
    id: '00000000-0000-4000-8000-000000000101',
    title: 'Desafio da Consistência',
    description: 'Registre 21 treinos e mantenha a rotina em movimento.',
    type: 'workouts',
    goalValue: 21,
    startDate: new Date('2025-01-01T00:00:00.000Z'),
    endDate: new Date('2099-12-31T23:59:59.999Z'),
    creatorId: null,
  },
  {
    id: '00000000-0000-4000-8000-000000000102',
    title: '100 toneladas em 30 dias',
    description: 'Some o volume de carga dos treinos registrados.',
    type: 'volume',
    goalValue: 100000,
    startDate: new Date('2025-01-01T00:00:00.000Z'),
    endDate: new Date('2099-12-31T23:59:59.999Z'),
    creatorId: null,
  },
];

const defaultAchievements = [
  {
    key: 'wegym_first_workout',
    title: 'Primeiro Passo',
    description: 'Complete seu primeiro treino registrado.',
    icon: '🏅',
    category: 'workouts',
    xpReward: 50,
    criteria: { type: 'total_workouts', value: 1 },
  },
  {
    key: 'wegym_weekly_consistency',
    title: 'Ritmo Constante',
    description: 'Registre quatro treinos em um período de sete dias.',
    icon: '🔥',
    category: 'workouts',
    xpReward: 100,
    criteria: { type: 'weekly_workouts', value: 4 },
  },
  {
    key: 'wegym_10km',
    title: 'Desbravador',
    description: 'Some 10 km em atividades registradas.',
    icon: '🏃',
    category: 'distance',
    xpReward: 150,
    criteria: { type: 'total_distance_km', value: 10 },
  },
  {
    key: 'wegym_100_workouts',
    title: 'Lenda da Academia',
    description: 'Complete 100 treinos registrados.',
    icon: '🏆',
    category: 'workouts',
    xpReward: 250,
    criteria: { type: 'total_workouts', value: 100 },
  },
];

let defaultChallengesReady = false;
let defaultAchievementsReady = false;

export const gamificationService = {
  async getAchievements() {
    if (!defaultAchievementsReady) {
      await prisma.achievement.createMany({
        data: defaultAchievements,
        skipDuplicates: true,
      });
      defaultAchievementsReady = true;
    }
    return prisma.achievement.findMany({ orderBy: { xpReward: 'asc' } });
  },

  async getUserAchievements(userId: string) {
    return prisma.userAchievement.findMany({
      where: { userId },
      include: { achievement: true },
      orderBy: { earnedAt: 'desc' },
    });
  },

  async checkAndAward(userId: string, event: { type: string; value: number }) {
    const achievements = await this.getAchievements();
    const earned = await prisma.userAchievement.findMany({ where: { userId }, select: { achievementId: true } });
    const earnedIds = new Set(earned.map((e) => e.achievementId));

    const toAward = achievements.filter((ach) => {
      if (earnedIds.has(ach.id)) return false;
      const criteria = ach.criteria as { type: string; value: number };
      return criteria.type === event.type && event.value >= criteria.value;
    });

    if (toAward.length > 0) {
      await prisma.userAchievement.createMany({
        data: toAward.map((ach) => ({ userId, achievementId: ach.id })),
        skipDuplicates: true,
      });
    }
  },

  async checkWorkoutAchievements(userId: string, athleteId: string) {
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - 7);
    const [workoutTotals, weeklyWorkouts, gpsTotals, weeklyGpsWorkouts] =
      await Promise.all([
        prisma.workoutSession.aggregate({
          where: { athleteId },
          _count: true,
          _sum: { distanceKm: true },
        }),
        prisma.workoutSession.count({
          where: { athleteId, completedAt: { gte: weekStart } },
        }),
        prisma.gpsSession.aggregate({
          where: { athleteId },
          _count: true,
          _sum: { distanceKm: true },
        }),
        prisma.gpsSession.count({
          where: { athleteId, completedAt: { gte: weekStart } },
        }),
      ]);

    await Promise.all([
      this.checkAndAward(userId, {
        type: 'total_workouts',
        value: workoutTotals._count + gpsTotals._count,
      }),
      this.checkAndAward(userId, {
        type: 'weekly_workouts',
        value: weeklyWorkouts + weeklyGpsWorkouts,
      }),
      this.checkAndAward(userId, {
        type: 'total_distance_km',
        value:
          (workoutTotals._sum.distanceKm ?? 0) +
          (gpsTotals._sum.distanceKm ?? 0),
      }),
    ]);
  },
  async getLeaderboard(challengeId: string) {
    return prisma.challengeParticipant.findMany({
      where: { challengeId },
      orderBy: { currentValue: 'desc' },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  },

  async joinChallenge(userId: string, challengeId: string) {
    return prisma.challengeParticipant.upsert({
      where: { challengeId_userId: { challengeId, userId } },
      create: { challengeId, userId },
      update: {},
    });
  },

  async createChallenge(
    userId: string,
    data: {
      title: string;
      description?: string;
      type: string;
      goalValue: number;
      startDate: Date;
      endDate: Date;
    },
  ) {
    return prisma.challenge.create({
      data: {
        ...data,
        creatorId: userId,
        participants: { create: { userId } },
      },
      include: {
        participants: { select: { userId: true, currentValue: true } },
      },
    });
  },

  async leaveChallenge(userId: string, challengeId: string) {
    return prisma.challengeParticipant.deleteMany({
      where: { userId, challengeId },
    });
  },

  async updateChallengeProgress(userId: string, challengeId: string, value: number) {
    return prisma.challengeParticipant.update({
      where: { challengeId_userId: { challengeId, userId } },
      data: { currentValue: { increment: value } },
    });
  },

  async listChallenges() {
    if (!defaultChallengesReady) {
      await prisma.challenge.createMany({
        data: defaultChallenges,
        skipDuplicates: true,
      });
      defaultChallengesReady = true;
    }
    const now = new Date();
    return prisma.challenge.findMany({
      where: { endDate: { gte: now } },
      orderBy: { startDate: 'asc' },
      include: {
        participants: {
          select: {
            userId: true,
            currentValue: true,
            user: { select: { displayName: true, avatarUrl: true } },
          },
        },
      },
    });
  },
};

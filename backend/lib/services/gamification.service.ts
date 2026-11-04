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
  {
    key: 'wegym_5_workouts',
    title: 'Ritmo em Constru\u00e7\u00e3o',
    description: 'Complete cinco treinos registrados.',
    icon: '\u{1F525}',
    category: 'workouts',
    xpReward: 75,
    criteria: { type: 'total_workouts', value: 5, role: 'atleta' },
  },
  {
    key: 'wegym_25_workouts',
    title: 'Disciplina de Ferro',
    description: 'Complete 25 treinos registrados.',
    icon: '\u{1F3CB}',
    category: 'workouts',
    xpReward: 150,
    criteria: { type: 'total_workouts', value: 25, role: 'atleta' },
  },
  {
    key: 'wegym_50km',
    title: 'Rota em Expans\u00e3o',
    description: 'Some 50 km em atividades registradas.',
    icon: '\u{1F6E4}',
    category: 'distance',
    xpReward: 200,
    criteria: { type: 'total_distance_km', value: 50, role: 'atleta' },
  },
  {
    key: 'wegym_100km',
    title: 'Horizonte Aberto',
    description: 'Some 100 km em atividades registradas.',
    icon: '\u{1F3C3}',
    category: 'distance',
    xpReward: 300,
    criteria: { type: 'total_distance_km', value: 100, role: 'atleta' },
  },
  {
    key: 'wegym_coach_first_athlete',
    title: 'Primeiro Acompanhamento',
    description: 'Vincule seu primeiro aluno ao seu perfil de personal.',
    icon: '\u{1F91D}',
    category: 'coaching',
    xpReward: 50,
    criteria: { type: 'total_coached_athletes', value: 1, role: 'personal' },
  },
  {
    key: 'wegym_coach_5_athletes',
    title: 'Equipe em Forma',
    description: 'Acompanhe cinco alunos vinculados.',
    icon: '\u{1F465}',
    category: 'coaching',
    xpReward: 100,
    criteria: { type: 'total_coached_athletes', value: 5, role: 'personal' },
  },
  {
    key: 'wegym_coach_10_athletes',
    title: 'Coach de Destaque',
    description: 'Acompanhe dez alunos vinculados.',
    icon: '\u{1F3C5}',
    category: 'coaching',
    xpReward: 200,
    criteria: { type: 'total_coached_athletes', value: 10, role: 'personal' },
  },
  {
    key: 'wegym_coach_25_athletes',
    title: 'Refer\u00eancia em Treinamento',
    description: 'Acompanhe 25 alunos vinculados.',
    icon: '\u{1F3C6}',
    category: 'coaching',
    xpReward: 350,
    criteria: { type: 'total_coached_athletes', value: 25, role: 'personal' },
  },
  {
    key: 'wegym_coach_50_athletes',
    title: 'Lideran\u00e7a de Elite',
    description: 'Acompanhe 50 alunos vinculados.',
    icon: '\u{1F451}',
    category: 'coaching',
    xpReward: 500,
    criteria: { type: 'total_coached_athletes', value: 50, role: 'personal' },
  },
  {
    key: 'wegym_coach_100_athletes',
    title: 'Legado WeGYM',
    description: 'Acompanhe 100 alunos vinculados.',
    icon: '\u{1F31F}',
    category: 'coaching',
    xpReward: 1000,
    criteria: { type: 'total_coached_athletes', value: 100, role: 'personal' },
  }
];

let defaultChallengesReady = false;

export const gamificationService = {
  async getAchievements() {
    // Idempotently add new catalog entries even when the server stayed running
    // while the app was updated.
    await prisma.achievement.createMany({
      data: defaultAchievements,
      skipDuplicates: true,
    });
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

  async checkPersonalAchievements(userId: string, personalId: string) {
    const athleteCount = await prisma.athlete.count({ where: { personalId } });
    await this.checkAndAward(userId, {
      type: 'total_coached_athletes',
      value: athleteCount,
    });
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
      include: {
        user: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            athlete: { select: { name: true } },
            personal: { select: { name: true } },
          },
        },
      },
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
            user: {
              select: {
                displayName: true,
                avatarUrl: true,
                athlete: { select: { name: true } },
                personal: { select: { name: true } },
              },
            },
          },
        },
      },
    });
  },
};

import { prisma } from '@/lib/prisma';

export const nutritionService = {
  async searchFoods(query: string, category?: string) {
    const where: Record<string, unknown> = {
      isPublic: true,
      name: { contains: query, mode: 'insensitive' },
    };
    if (category) where.category = category;
    return prisma.foodItem.findMany({ where: where as any, take: 20, orderBy: { name: 'asc' } });
  },

  async createFoodItem(data: { name: string; brand?: string; servingSize: number; servingUnit: string; calories: number; proteinG: number; carbsG: number; fatG: number; fiberG?: number; sodiumMg?: number; category: string; userId?: string }) {
    return prisma.foodItem.create({ data });
  },

  async createMealLog(userId: string, data: { date: Date; type: string; notes?: string }) {
    return prisma.mealLog.create({ data: { userId, ...data } });
  },

  async addFoodToMeal(mealId: string, foodId: string, amount: number) {
    const food = await prisma.foodItem.findUnique({ where: { id: foodId } });
    if (!food) throw new Error('Alimento não encontrado');
    const mf = await prisma.mealFood.create({ data: { mealId, foodId, amount } });
    await this.recalculateTotals(mealId);
    return mf;
  },

  async recalculateTotals(mealId: string) {
    const result = await prisma.$queryRaw<[{ calories: number; protein_g: number; carbs_g: number; fat_g: number; fiber_g: number }]>`
      SELECT
        COALESCE(SUM(f.calories * mf.amount), 0) AS calories,
        COALESCE(SUM(f."proteinG" * mf.amount), 0) AS protein_g,
        COALESCE(SUM(f."carbsG" * mf.amount), 0) AS carbs_g,
        COALESCE(SUM(f."fatG" * mf.amount), 0) AS fat_g,
        COALESCE(SUM(COALESCE(f."fiberG", 0) * mf.amount), 0) AS fiber_g
      FROM "MealFood" mf
      JOIN "FoodItem" f ON f.id = mf."foodId"
      WHERE mf."mealId" = ${mealId}
    `;
    const totals = result[0] ?? { calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0, fiber_g: 0 };
    return prisma.mealTotals.upsert({
      where: { mealId },
      create: {
        mealId,
        calories: Number(totals.calories),
        proteinG: Number(totals.protein_g),
        carbsG: Number(totals.carbs_g),
        fatG: Number(totals.fat_g),
        fiberG: Number(totals.fiber_g),
      },
      update: {
        calories: Number(totals.calories),
        proteinG: Number(totals.protein_g),
        carbsG: Number(totals.carbs_g),
        fatG: Number(totals.fat_g),
        fiberG: Number(totals.fiber_g),
      },
    });
  },

  async getMealLogs(userId: string, date: Date) {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);
    return prisma.mealLog.findMany({
      where: { userId, date: { gte: start, lte: end } },
      include: { foods: { include: { food: true } }, totals: true },
      orderBy: { date: 'asc' },
    });
  },

  async createDietPlan(userId: string, data: { title: string; description?: string; dailyCalories?: number; proteinGoal?: number; carbsGoal?: number; fatGoal?: number; endDate?: Date }) {
    return prisma.dietPlan.create({ data: { userId, ...data } });
  },

  async getDietPlans(userId: string) {
    return prisma.dietPlan.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
  },
};

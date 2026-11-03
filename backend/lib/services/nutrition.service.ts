import { prisma } from '@/lib/prisma';

const starterFoods = [
  { id: '20000000-0000-4000-8000-000000000001', name: 'Feij\u00e3o carioca cozido', servingSize: 100, servingUnit: 'g', calories: 76, proteinG: 4.8, carbsG: 13.6, fatG: 0.5, fiberG: 8.5, category: 'legume', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000002', name: 'Carne bovina magra grelhada', servingSize: 100, servingUnit: 'g', calories: 217, proteinG: 26, carbsG: 0, fatG: 12, category: 'meat', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000003', name: 'Carne mo\u00edda magra refogada', servingSize: 100, servingUnit: 'g', calories: 215, proteinG: 26, carbsG: 0, fatG: 11, category: 'meat', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000004', name: 'Bife de patinho grelhado', servingSize: 100, servingUnit: 'g', calories: 219, proteinG: 35, carbsG: 0, fatG: 7.3, category: 'meat', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000005', name: 'Til\u00e1pia grelhada', servingSize: 100, servingUnit: 'g', calories: 128, proteinG: 26, carbsG: 0, fatG: 2.7, category: 'meat', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000006', name: 'Batata inglesa cozida', servingSize: 100, servingUnit: 'g', calories: 87, proteinG: 1.9, carbsG: 20.1, fatG: 0.1, category: 'tuber', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000007', name: 'Macarr\u00e3o cozido', servingSize: 100, servingUnit: 'g', calories: 158, proteinG: 5.8, carbsG: 30.9, fatG: 0.9, category: 'grain', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000008', name: 'Tomate cru', servingSize: 100, servingUnit: 'g', calories: 18, proteinG: 0.9, carbsG: 3.9, fatG: 0.2, fiberG: 1.2, category: 'vegetable', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000009', name: 'Alface', servingSize: 100, servingUnit: 'g', calories: 15, proteinG: 1.4, carbsG: 2.9, fatG: 0.2, fiberG: 1.3, category: 'vegetable', isPublic: true },
  { id: '20000000-0000-4000-8000-000000000010', name: 'Cenoura cozida', servingSize: 100, servingUnit: 'g', calories: 35, proteinG: 0.8, carbsG: 8.2, fatG: 0.2, fiberG: 3, category: 'vegetable', isPublic: true },
] as const;

const normalizeFoodText = (value: string) =>
  value.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase();

export const nutritionService = {
  async searchFoods(query: string, category?: string) {
    await prisma.foodItem.createMany({
      data: [...starterFoods],
      skipDuplicates: true,
    });
    const where: Record<string, unknown> = { isPublic: true };
    if (category) where.category = category;
    const rows = await prisma.foodItem.findMany({
      where: where as any,
      take: 500,
      orderBy: { name: 'asc' },
    });
    const normalized = normalizeFoodText(query.trim());
    const aliases: Record<string, string[]> = {
      carne: ['meat'],
      boi: ['beef'],
      bife: ['beef'],
      feijao: ['bean'],
      peixe: ['fish'],
      frango: ['chicken'],
    };
    const matchingAliases = aliases[normalized] ?? [];
    return rows
      .filter((food) => {
        if (!normalized) return true;
        const name = normalizeFoodText(food.name);
        const itemCategory = normalizeFoodText(food.category);
        return (
          name.includes(normalized) ||
          itemCategory.includes(normalized) ||
          (matchingAliases.includes('meat') && itemCategory === 'meat') ||
          (matchingAliases.includes('bean') && itemCategory === 'legume') ||
          (matchingAliases.includes('beef') &&
            (name.includes('carne') || name.includes('patinho'))) ||
          (matchingAliases.includes('fish') &&
            (name.includes('peixe') || name.includes('tilapia'))) ||
          (matchingAliases.includes('chicken') &&
            (name.includes('frango') || name.includes('chicken')))
        );
      })
      .slice(0, 20);
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
    const existing = await prisma.mealFood.findFirst({ where: { mealId, foodId } });
    const mf = existing
      ? await prisma.mealFood.update({
          where: { id: existing.id },
          data: { amount: { increment: amount } },
        })
      : await prisma.mealFood.create({ data: { mealId, foodId, amount } });
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
      FROM "meal_foods" mf
      JOIN "food_items" f ON f.id = mf."foodId"
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

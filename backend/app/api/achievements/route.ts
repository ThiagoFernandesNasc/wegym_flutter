import { authenticate, handleError, json } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';
import { logger } from '@/lib/logger';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const role = (session.user as { role?: string }).role;
    const all = await gamificationService.getAchievements();
    let personalId: string | null = null;
    if (role === 'personal') {
      const personal = await prisma.personalTrainer.findUnique({
        where: { userId: session.user.id },
        select: { id: true },
      });
      personalId = personal?.id ?? null;
      if (personalId) {
        try {
          await gamificationService.checkPersonalAchievements(
            session.user.id,
            personalId,
          );
        } catch (error) {
          logger.warn(
            { error, userId: session.user.id },
            '[Gamification] Falha ao sincronizar conquistas do personal',
          );
        }
      }
    } else {
      const athlete = await prisma.athlete.findUnique({
        where: { userId: session.user.id },
        select: { id: true },
      });
      if (athlete) {
        try {
          await gamificationService.checkWorkoutAchievements(
            session.user.id,
            athlete.id,
          );
        } catch (error) {
          logger.warn(
            { error, userId: session.user.id },
            '[Gamification] Falha ao sincronizar medalhas do hist?rico',
          );
        }
      }
    }

    const achievements = all.filter((achievement) => {
      const criteria = achievement.criteria as { role?: string };
      return role === 'personal'
        ? criteria.role === 'personal'
        : criteria.role !== 'personal';
    });
    const visibleIds = new Set(achievements.map((achievement) => achievement.id));
    const userAchievements = (await gamificationService.getUserAchievements(
      session.user.id,
    )).filter((earned) => visibleIds.has(earned.achievementId));
    return json({ achievements, userAchievements });
  } catch (error) {
    return handleError(error);
  }
}
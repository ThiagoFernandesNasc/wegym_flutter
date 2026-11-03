import { authenticate, handleError, json } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';
import { logger } from '@/lib/logger';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const all = await gamificationService.getAchievements();
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
          '[Gamification] Falha ao sincronizar medalhas do histórico',
        );
      }
    }
    const userAchievements = await gamificationService.getUserAchievements(
      session.user.id,
    );
    return json({ achievements: all, userAchievements });
  } catch (error) {
    return handleError(error);
  }
}
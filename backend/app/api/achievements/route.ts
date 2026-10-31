import { authenticate, handleError, json } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const all = await gamificationService.getAchievements();
    const userAchievements = await gamificationService.getUserAchievements(session.user.id);
    return json({ achievements: all, userAchievements });
  } catch (error) { return handleError(error); }
}

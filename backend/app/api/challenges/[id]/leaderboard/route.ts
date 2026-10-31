import { authenticate, handleError, json } from '@/lib/api-utils';
import { gamificationService } from '@/lib/services/gamification.service';

export const runtime = 'nodejs';

export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await authenticate();
    const leaderboard = await gamificationService.getLeaderboard(id);
    return json(leaderboard);
  } catch (error) { return handleError(error); }
}

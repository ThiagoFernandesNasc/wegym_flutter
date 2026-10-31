import { authenticate, handleError } from '@/lib/api-utils';
import { personalStatsService } from '@/lib/services/personal-stats.service';
import { prisma } from '@/lib/prisma';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();

    const personal = await prisma.personalTrainer.findUnique({
      where: { userId: session.user.id },
      select: { id: true },
    });

    if (!personal) {
      return Response.json({ error: 'Personal trainer não encontrado' }, { status: 404 });
    }

    const stats = await personalStatsService.getDashboard(personal.id);
    return Response.json({ data: stats });
  } catch (error) {
    return handleError(error);
  }
}

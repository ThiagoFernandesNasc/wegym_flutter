import { authenticate, handleError } from '@/lib/api-utils';
import { goalService } from '@/lib/services/goal.service';

export const runtime = 'nodejs';

export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const session = await authenticate();
    const { id } = await params;
    await goalService.remove(id, session.user.id);
    return Response.json({ success: true });
  } catch (error) {
    return handleError(error);
  }
}

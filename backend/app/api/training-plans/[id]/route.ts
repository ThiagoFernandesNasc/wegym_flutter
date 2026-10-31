import { authenticate, handleError } from '@/lib/api-utils';
import { trainingPlanService } from '@/lib/services/training-plan.service';

export const runtime = 'nodejs';

export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const session = await authenticate();
    const { id } = await params;
    await trainingPlanService.delete(id, session.user.id);
    return Response.json({ success: true });
  } catch (error) {
    return handleError(error);
  }
}

export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const session = await authenticate();
    const { id } = await params;
    const role = (session.user as { role?: string }).role;
    const plan = await trainingPlanService.getById(id);
    if (role === 'athlete' && plan.athleteId !== session.user.id) {
      return Response.json({ error: 'Acesso negado' }, { status: 403 });
    }
    if (role !== 'personal' && role !== 'admin' && role !== 'athlete') {
      return Response.json({ error: 'Acesso negado' }, { status: 403 });
    }
    return Response.json({ data: plan });
  } catch (error) {
    return handleError(error);
  }
}

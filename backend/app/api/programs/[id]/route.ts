import { handleError, json } from '@/lib/api-utils';
import { programService } from '@/lib/services/program.service';

export const runtime = 'nodejs';

export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const program = await programService.getById(id);
    if (!program) return json({ error: 'Programa não encontrado' }, 404);
    return json(program);
  } catch (error) { return handleError(error); }
}

import { handleError } from '@/lib/api-utils';
import { cepService } from '@/lib/services/cep.service';
import { z } from 'zod';

export const runtime = 'nodejs';

const cepQuerySchema = z.object({
  cep: z.string().min(8).max(9),
});

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const cep = searchParams.get('cep');
    const parsed = cepQuerySchema.parse({ cep });
    const result = await cepService.validate(parsed.cep);
    return Response.json(result);
  } catch (error) {
    return handleError(error);
  }
}

import { userService } from '@/lib/services/user.service';
import { handleError, getIP, withRateLimit } from '@/lib/api-utils';
import { registerSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function POST(req: Request): Promise<Response> {
  try {
    const rlIp = await withRateLimit(req, `register:${getIP(req)}`);
    if (rlIp) return rlIp;

    const body = await req.json();
    const parsed = registerSchema.safeParse(body);
    if (!parsed.success) {
      throw new ValidationError('Dados inválidos', parsed.error.issues);
    }

    const rlEmail = await withRateLimit(req, `register:email:${parsed.data.email}`);
    if (rlEmail) return rlEmail;

    await userService.register(parsed.data);

    return Response.json({ message: 'Cadastro realizado com sucesso!' }, { status: 201 });
  } catch (error) {
    return handleError(error);
  }
}

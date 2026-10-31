import { userService } from '@/lib/services/user.service';
import { authenticate, handleError, json, withRateLimit, getIP } from '@/lib/api-utils';
import { consentSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';
import { auditLog } from '@/lib/audit';

export const runtime = 'nodejs';

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `consent:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = consentSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Dados inválidos', parsed.error.issues);

    const result = await userService.consent(session.user.id, parsed.data);

    await auditLog({
      userId: session.user.id,
      action: 'user.consent_change',
      metadata: { consent: parsed.data },
      ip: getIP(request),
    });

    return json(result);
  } catch (error) {
    return handleError(error);
  }
}

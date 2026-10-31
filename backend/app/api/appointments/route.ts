import { authenticate, handleError, json, created, withRateLimit } from '@/lib/api-utils';
import { appointmentService } from '@/lib/services/appointment.service';
import { appointmentBookSchema, appointmentActionSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET() {
  try {
    const session = await authenticate();
    const role = (session.user as { role?: string }).role ?? 'atleta';
    const appointments = await appointmentService.getAppointments(session.user.id, role as 'athlete' | 'personal');
    return json(appointments);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `appointments:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = appointmentBookSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Dados inválidos', parsed.error.issues);

    const appointment = await appointmentService.book(session.user.id, parsed.data.slotId, parsed.data.type ?? '', parsed.data.notes);
    return created(appointment);
  } catch (error) { return handleError(error); }
}

export async function PATCH(request: Request) {
  try {
    const session = await authenticate();
    const body = await request.json();
    const parsed = appointmentActionSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Ação inválida', parsed.error.issues);

    if (parsed.data.action === 'cancel') {
      await appointmentService.cancel(parsed.data.id, session.user.id);
      return json({ success: true });
    }
    const appt = await appointmentService.confirm(parsed.data.id);
    return json(appt);
  } catch (error) { return handleError(error); }
}

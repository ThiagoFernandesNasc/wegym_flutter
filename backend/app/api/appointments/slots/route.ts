import { authenticate, handleError, json, created } from '@/lib/api-utils';
import { appointmentService } from '@/lib/services/appointment.service';
import { requireRole } from '@/lib/api-utils';
import { appointmentSlotSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';
import { z } from 'zod';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const requestedPersonalId = searchParams.get('personalId');
    if (requestedPersonalId !== null && !requestedPersonalId.trim()) {
      return json([]);
    }
    const personalId = requestedPersonalId?.trim() || session.user.id;
    if (!z.string().uuid().safeParse(personalId).success) {
      throw new ValidationError('Identificador do personal inválido.');
    }
    const date = searchParams.get('date') ? new Date(searchParams.get('date')!) : undefined;
    const slots = await appointmentService.getSlots(personalId, date);
    return json(slots);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await requireRole(['personal']);
    const body = appointmentSlotSchema.parse(await request.json());
    const date = new Date(body.date);
    const validTime = (v: string) => /^([01]\d|2[0-3]):[0-5]\d$/.test(v);
    if (isNaN(date.getTime()) || !validTime(body.startTime) || !validTime(body.endTime) || body.endTime <= body.startTime) throw new ValidationError('Data ou intervalo de horário inválido');
    const slot = await appointmentService.createSlot(session.user.id, { ...body, date });
    return created(slot);
  } catch (error) { return handleError(error); }
}

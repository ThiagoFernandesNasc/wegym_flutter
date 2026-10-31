import { authenticate, handleError, json, created } from '@/lib/api-utils';
import { appointmentService } from '@/lib/services/appointment.service';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const personalId = searchParams.get('personalId') ?? session.user.id;
    const date = searchParams.get('date') ? new Date(searchParams.get('date')!) : undefined;
    const slots = await appointmentService.getSlots(personalId, date);
    return json(slots);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const body = await request.json();
    const slot = await appointmentService.createSlot(session.user.id, body);
    return created(slot);
  } catch (error) { return handleError(error); }
}

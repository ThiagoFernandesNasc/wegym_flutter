import { authenticate, handleError, json, withRateLimit } from '@/lib/api-utils';
import { checkinService } from '@/lib/services/checkin.service';
import { checkinSchema } from '@/lib/validation';
import { ValidationError } from '@/lib/errors';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    if (searchParams.get('history') === 'true') {
      const days = Number(searchParams.get('days')) || 30;
      const history = await checkinService.getHistory(session.user.id, days);
      const streak = await checkinService.getStreak(session.user.id);
      return json({ history, streak });
    }
    const checkin = await checkinService.getToday(session.user.id);
    return json(checkin ?? null);
  } catch (error) { return handleError(error); }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `checkin:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = checkinSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError('Check-in inválido', parsed.error.issues);

    const checkin = await checkinService.upsert(session.user.id, parsed.data);
    return json(checkin);
  } catch (error) { return handleError(error); }
}

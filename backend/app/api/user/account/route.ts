import { NextResponse } from 'next/server';
import { userService } from '@/lib/services/user.service';
import { authenticate, handleError, cache, withRateLimit, getIP } from '@/lib/api-utils';
import { auditLog } from '@/lib/audit';

export const runtime = 'nodejs';

export async function DELETE(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `account-delete:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    await auditLog({
      userId: session.user.id,
      action: 'user.delete_account',
      ip: getIP(request),
    });

    await cache.del(`profile:${session.user.id}`);
    await cache.delPattern(`classes:${session.user.id}:*`);

    const result = await userService.deleteAccount(session.user.id);
    return NextResponse.json(result);
  } catch (error) {
    return handleError(error);
  }
}

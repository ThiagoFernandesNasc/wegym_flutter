import { NextResponse } from 'next/server';
import { userService } from '@/lib/services/user.service';
import { authenticate, handleError, getIP, withRateLimit } from '@/lib/api-utils';
import { auditLog } from '@/lib/audit';

export const runtime = 'nodejs';

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `user-export:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    await auditLog({
      userId: session.user.id,
      action: 'user.export_data',
      ip: getIP(request),
    });

    const data = await userService.exportData(session.user.id);
    return NextResponse.json(data);
  } catch (error) {
    return handleError(error);
  }
}

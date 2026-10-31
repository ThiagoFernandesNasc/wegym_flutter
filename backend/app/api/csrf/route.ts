import { NextResponse } from 'next/server';
import { setCsrfCookie, generateCsrfToken } from '@/lib/csrf';

export const runtime = 'nodejs';

export async function GET() {
  const response = NextResponse.json({ success: true, csrfToken: process.env.CSRF_TOKEN || generateCsrfToken() });
  return setCsrfCookie(response);
}

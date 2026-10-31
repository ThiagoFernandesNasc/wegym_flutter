import { NextResponse } from 'next/server';
import crypto from 'crypto';

const CSRF_TOKEN_NAME = 'wegym-csrf';
const CSRF_SECRET = process.env.CSRF_SECRET || process.env.NEXTAUTH_SECRET || 'fallback-csrf-secret';

export function generateCsrfToken(): string {
  const token = crypto.randomBytes(32).toString('hex');
  const signature = crypto.createHmac('sha256', CSRF_SECRET).update(token).digest('hex');
  return `${token}.${signature}`;
}

export function validateCsrfToken(token: string | undefined): boolean {
  if (!token) return false;
  const [tokenPart, signature] = token.split('.');
  if (!tokenPart || !signature) return false;
  const expectedSignature = crypto.createHmac('sha256', CSRF_SECRET).update(tokenPart).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
}

export function setCsrfCookie(response: NextResponse): NextResponse {
  const token = generateCsrfToken();
  response.cookies.set(CSRF_TOKEN_NAME, token, {
    httpOnly: false,
    sameSite: 'strict',
    path: '/',
    secure: process.env.NODE_ENV === 'production',
    maxAge: 3600,
  });
  return response;
}

export async function validateCsrfRequest(request: Request): Promise<boolean> {
  const cookieHeader = request.headers.get('cookie') || '';
  const csrfCookie = cookieHeader.split(';').find(c => c.trim().startsWith(`${CSRF_TOKEN_NAME}=`))?.split('=')[1]?.trim();
  const csrfHeader = request.headers.get('x-csrf-token');
  if (!csrfCookie || !csrfHeader) return false;
  return csrfCookie === csrfHeader && validateCsrfToken(csrfCookie);
}

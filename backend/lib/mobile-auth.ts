import { SignJWT, jwtVerify } from 'jose';

const ALG = 'HS256';
const MOBILE_TOKEN_MAX_AGE = 60 * 60 * 24 * 7;

function getKey(): Uint8Array {
  const secret = process.env.NEXTAUTH_SECRET;
  if (!secret) {
    throw new Error('NEXTAUTH_SECRET não configurado');
  }
  return new TextEncoder().encode(secret);
}

export type MobileTokenPayload = {
  id: string;
  role: string;
  email?: string;
};

export async function signMobileToken(payload: MobileTokenPayload): Promise<string> {
  const key = getKey();
  return new SignJWT(payload)
    .setProtectedHeader({ alg: ALG })
    .setIssuedAt()
    .setExpirationTime(`${MOBILE_TOKEN_MAX_AGE}s`)
    .sign(key);
}

export async function verifyMobileToken(token: string): Promise<MobileTokenPayload | null> {
  try {
    const { payload } = await jwtVerify(token, getKey(), { algorithms: [ALG] });
    if (typeof payload.id !== 'string' || typeof payload.role !== 'string') {
      return null;
    }
    return {
      id: payload.id,
      role: payload.role,
      email: typeof payload.email === 'string' ? payload.email : undefined,
    };
  } catch {
    return null;
  }
}

import { createHmac, timingSafeEqual } from 'crypto';

export function verifyMpWebhook(
  xSignature: string | null,
  xRequestId: string | null,
  dataId: string | null,
  secret: string,
): boolean {
  if (!xSignature || !secret) return false;

  const parts = xSignature.split(',');
  let ts = '';
  let hash = '';
  for (const part of parts) {
    const [key, ...rest] = part.split('=');
    if (key === 'ts') ts = rest.join('=');
    if (key === 'v1') hash = rest.join('=');
  }
  if (!ts || !hash) return false;

  let manifest = '';
  if (dataId) manifest += `id:${dataId.toLowerCase()};`;
  if (xRequestId) manifest += `request-id:${xRequestId};`;
  manifest += `ts:${ts};`;

  const expected = createHmac('sha256', secret).update(manifest).digest('hex');

  try {
    return timingSafeEqual(Buffer.from(expected), Buffer.from(hash));
  } catch {
    return false;
  }
}

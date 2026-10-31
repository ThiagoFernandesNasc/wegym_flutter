import { getRedis } from './redis';

const WINDOW_MS = 10_000;
const PROD_MAX_REQUESTS = 10;
const DEV_MAX_REQUESTS = 1_000;

const MAX_REQUESTS =
  process.env.NODE_ENV === 'production' ? PROD_MAX_REQUESTS : DEV_MAX_REQUESTS;

const memWindows = new Map<string, number[]>();

export const ratelimit = {
  async limit(identifier: string): Promise<{ success: boolean }> {
    const redis = await getRedis();
    if (redis) {
      try {
        const key = `ratelimit:${identifier}`;
        const current = await redis.incr(key);
        if (current === 1) await redis.pExpire(key, WINDOW_MS);
        return { success: current <= MAX_REQUESTS };
      } catch {
        return memLimit(identifier);
      }
    }
    return memLimit(identifier);
  },
};

function memLimit(identifier: string): { success: boolean } {
  const now = Date.now();
  const timestamps = memWindows.get(identifier) ?? [];
  const withinWindow = timestamps.filter((t) => now - t < WINDOW_MS);
  if (withinWindow.length >= MAX_REQUESTS) {
    return { success: false };
  }
  withinWindow.push(now);
  memWindows.set(identifier, withinWindow);
  return { success: true };
}

const CLEANUP_INTERVAL_MS = 60_000;
setInterval(() => {
  const now = Date.now();
  for (const [key, timestamps] of memWindows) {
    const valid = timestamps.filter((t) => now - t < WINDOW_MS);
    if (valid.length === 0) {
      memWindows.delete(key);
    } else {
      memWindows.set(key, valid);
    }
  }
}, CLEANUP_INTERVAL_MS).unref();

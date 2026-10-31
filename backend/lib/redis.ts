import { logger } from './logger';

let redisClient: Awaited<ReturnType<typeof createRedisClient>> | null = null;
let redisFailed = false;
let lastFailTime = 0;

const RECOVERY_INTERVAL_MS = 30_000;

async function createRedisClient() {
  const { createClient } = await import('redis');
  const client = createClient({
    url: process.env.REDIS_URL,
    socket: { reconnectStrategy: false },
  });
  await client.connect();
  return client;
}

export async function getRedis() {
  if (!process.env.REDIS_URL) return null;

  if (redisFailed) {
    if (Date.now() - lastFailTime < RECOVERY_INTERVAL_MS) return null;
    redisFailed = false;
  }

  if (redisClient?.isOpen) return redisClient;

  try {
    redisClient = await createRedisClient();
    redisFailed = false;
    return redisClient;
  } catch (err) {
    logger.warn({ err }, '[Redis] Unavailable, using in-memory fallback');
    try { redisClient?.quit(); } catch { /* ignore */ }
    redisClient = null;
    redisFailed = true;
    lastFailTime = Date.now();
    return null;
  }
}

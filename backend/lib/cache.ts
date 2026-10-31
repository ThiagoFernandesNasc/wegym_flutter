import { getRedis } from './redis';

type StoreEntry = { data: unknown; expiresAt: number };

function prefix(key: string) {
  if (process.env.NODE_ENV === 'production') return `wegym:${key}`;
  return `wegym:dev:${key}`;
}

const memStore = new Map<string, StoreEntry>();

const CACHE_CLEANUP_INTERVAL_MS = 60_000;
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of memStore) {
    if (now > entry.expiresAt) {
      memStore.delete(key);
    }
  }
}, CACHE_CLEANUP_INTERVAL_MS).unref();

async function memGet<T>(key: string): Promise<T | null> {
  const entry = memStore.get(prefix(key));
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    memStore.delete(prefix(key));
    return null;
  }
  return entry.data as T;
}

export const cache = {
  async get<T>(key: string): Promise<T | null> {
    const redis = await getRedis();
    if (redis) {
      try {
        const raw = await redis.get(prefix(key));
        if (!raw) return null;
        const parsed = JSON.parse(raw) as StoreEntry;
        if (Date.now() > parsed.expiresAt) {
          await redis.del(prefix(key));
          return null;
        }
        return parsed.data as T;
      } catch { return memGet(key); }
    }
    return memGet(key);
  },

  async set(key: string, value: unknown, ttlSeconds = 60) {
    const prefixed = prefix(key);
    const expiresAt = Date.now() + ttlSeconds * 1000;
    const entry = { data: value, expiresAt };

    const redis = await getRedis();
    if (redis) {
      try { await redis.set(prefixed, JSON.stringify(entry), { PX: ttlSeconds * 1000 }); return; } catch { /* fall through */ }
    }

    memStore.set(prefixed, entry);
  },

  async del(key: string) {
    const prefixed = prefix(key);

    const redis = await getRedis();
    if (redis) {
      try { await redis.del(prefixed); return; } catch { /* fall through */ }
    }

    memStore.delete(prefixed);
  },

  async delPattern(pattern: string) {
    const prefixed = prefix(pattern);

    const redis = await getRedis();
    if (redis) {
      try {
        let cursor = 0;
        do {
          const result = await redis.scan(cursor, { MATCH: `${prefixed}*`, COUNT: 100 });
          cursor = result.cursor;
          if (result.keys.length > 0) await redis.del(result.keys);
        } while (cursor !== 0);
        return;
      } catch { /* fall through */ }
    }

    for (const k of memStore.keys()) {
      if (k.startsWith(prefixed)) memStore.delete(k);
    }
  },

  async getOrSet<T>(key: string, fetch: () => Promise<T>, ttlSeconds = 60): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null) return cached;
    const data = await fetch();
    await this.set(key, data, ttlSeconds);
    return data;
  },
};

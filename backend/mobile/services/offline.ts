import AsyncStorage from "@react-native-async-storage/async-storage";

const KEYS = {
  PENDING_WORKOUTS: "wegym_pending_workouts",
  CACHED_PROFILE: "wegym_cached_profile",
  CACHED_STATS: "wegym_cached_stats",
  LAST_SYNC: "wegym_last_sync",
};

export type PendingWorkout = {
  id: string;
  data: Record<string, unknown>;
  createdAt: string;
};

export const offlineStorage = {
  async savePendingWorkout(workout: Record<string, unknown>): Promise<void> {
    const existing = await this.getPendingWorkouts();
    const pending: PendingWorkout = {
      id: Date.now().toString(),
      data: workout,
      createdAt: new Date().toISOString(),
    };
    existing.push(pending);
    await AsyncStorage.setItem(KEYS.PENDING_WORKOUTS, JSON.stringify(existing));
  },

  async getPendingWorkouts(): Promise<PendingWorkout[]> {
    try {
      const raw = await AsyncStorage.getItem(KEYS.PENDING_WORKOUTS);
      return raw ? JSON.parse(raw) : [];
    } catch {
      return [];
    }
  },

  async removePendingWorkout(id: string): Promise<void> {
    const existing = await this.getPendingWorkouts();
    const filtered = existing.filter((w) => w.id !== id);
    await AsyncStorage.setItem(KEYS.PENDING_WORKOUTS, JSON.stringify(filtered));
  },

  async clearPendingWorkouts(): Promise<void> {
    await AsyncStorage.removeItem(KEYS.PENDING_WORKOUTS);
  },

  async cacheProfile(profile: Record<string, unknown>): Promise<void> {
    await AsyncStorage.setItem(KEYS.CACHED_PROFILE, JSON.stringify(profile));
  },

  async getCachedProfile<T = Record<string, unknown>>(): Promise<T | null> {
    try {
      const raw = await AsyncStorage.getItem(KEYS.CACHED_PROFILE);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  },

  async cacheStats(stats: Record<string, unknown>): Promise<void> {
    await AsyncStorage.setItem(KEYS.CACHED_STATS, JSON.stringify(stats));
  },

  async getCachedStats<T = Record<string, unknown>>(): Promise<T | null> {
    try {
      const raw = await AsyncStorage.getItem(KEYS.CACHED_STATS);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  },

  async setLastSync(date: Date): Promise<void> {
    await AsyncStorage.setItem(KEYS.LAST_SYNC, date.toISOString());
  },

  async getLastSync(): Promise<Date | null> {
    try {
      const raw = await AsyncStorage.getItem(KEYS.LAST_SYNC);
      return raw ? new Date(raw) : null;
    } catch {
      return null;
    }
  },

  async syncPendingWorkouts(syncFn: (workout: PendingWorkout) => Promise<boolean>): Promise<{ synced: number; failed: number }> {
    const pending = await this.getPendingWorkouts();
    let synced = 0;
    let failed = 0;

    for (const workout of pending) {
      try {
        const ok = await syncFn(workout);
        if (ok) {
          await this.removePendingWorkout(workout.id);
          synced++;
        } else {
          failed++;
        }
      } catch {
        failed++;
      }
    }

    return { synced, failed };
  },
};

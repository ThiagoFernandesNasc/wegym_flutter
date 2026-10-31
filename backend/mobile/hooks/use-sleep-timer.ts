import { useRef, useCallback, useEffect } from "react";

export interface SleepTimerHandle {
  start: () => void;
  stop: () => void;
}

type WakeLock = { release: () => void };

function getWakeLock(): { request: (type: string) => Promise<WakeLock> } | undefined {
  return (navigator as { wakeLock?: { request: (type: string) => Promise<WakeLock> } } | undefined)
    ?.wakeLock;
}

export function useSleepTimer(onWake: () => void) {
  const wakeLockRef = useRef<WakeLock | null>(null);
  const screenTimeoutRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const lastActivityRef = useRef(0);

  const keepAwake = useCallback(async () => {
    try {
      const wakeLock = getWakeLock();
      if (wakeLock) {
        wakeLockRef.current = await wakeLock.request("screen");
      }
    } catch {}
  }, []);

  const releaseAwake = useCallback(() => {
    try { wakeLockRef.current?.release(); } catch {}
    wakeLockRef.current = null;
  }, []);

  const start = useCallback(() => {
    keepAwake();
    lastActivityRef.current = Date.now();
    screenTimeoutRef.current = setInterval(() => {
      if (Date.now() - lastActivityRef.current > 120000 && wakeLockRef.current) {
        releaseAwake();
        onWake();
      }
    }, 30000);
  }, [keepAwake, releaseAwake, onWake]);

  const stop = useCallback(() => {
    releaseAwake();
    if (screenTimeoutRef.current) {
      clearInterval(screenTimeoutRef.current);
      screenTimeoutRef.current = null;
    }
  }, [releaseAwake]);

  useEffect(() => () => stop(), [stop]);

  return { start, stop };
}

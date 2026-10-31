"use client";

import { useEffect } from "react";

function storageKeys(storage: Storage): string[] {
  return Array.from({ length: storage.length }, (_, index) => storage.key(index))
    .filter((key): key is string => key !== null);
}

interface CacheCleanupOptions {
  clearLocalStorage?: boolean;
  clearSessionStorage?: boolean;
  clearServiceWorkerCaches?: boolean;
  allowedPatterns?: RegExp[];
  blockedPatterns?: RegExp[];
}

export function useCacheCleanup(options: CacheCleanupOptions = {}) {
  const {
    clearLocalStorage = true,
    clearSessionStorage = false,
    clearServiceWorkerCaches = true,
    allowedPatterns,
    blockedPatterns,
  } = options;

  useEffect(() => {
    // Cleanup Service Worker caches
    if (clearServiceWorkerCaches && "caches" in window) {
      (caches as CacheStorage).keys().then((keys) => {
        keys.forEach((key) => {
          if (blockedPatterns) {
            if (blockedPatterns.some((pattern) => pattern.test(key))) return;
          }
          if (allowedPatterns) {
            if (!allowedPatterns.some((pattern) => pattern.test(key))) {
              caches.delete(key);
            }
          } else {
            caches.delete(key);
          }
        });
      });
    }

    // Clear LocalStorage
    if (clearLocalStorage && "localStorage" in window) {
      const ls = localStorage as Storage;
      if (blockedPatterns) {
        const keys = storageKeys(ls).filter((key) => !blockedPatterns.some((pattern) => pattern.test(key)));
        keys.forEach((key) => ls.removeItem(key));
      } else {
        // Clear all non-system keys (keep items starting with "__" or "@")
        const keys = storageKeys(ls).filter(
          (key) => !["__next_data", "__react_prop_types", "@react"].includes(key)
        );
        keys.forEach((key) => ls.removeItem(key));
      }
    }

    // Clear SessionStorage
    if (clearSessionStorage && "sessionStorage" in window) {
      const ss = sessionStorage as Storage;
      if (blockedPatterns) {
        const keys = storageKeys(ss).filter((key) => !blockedPatterns.some((pattern) => pattern.test(key)));
        keys.forEach((key) => ss.removeItem(key));
      } else {
        const keys = storageKeys(ss).filter(
          (key) => !["__next_data", "__react_prop_types", "@react"].includes(key)
        );
        keys.forEach((key) => ss.removeItem(key));
      }
    }
  }, [clearLocalStorage, clearSessionStorage, clearServiceWorkerCaches]);
}

export default useCacheCleanup;
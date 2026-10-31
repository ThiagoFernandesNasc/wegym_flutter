"use client";

import { useState, useEffect, useCallback } from "react";

type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
};

export function usePWAInstall() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [isInstallable, setIsInstallable] = useState(false);

  useEffect(() => {
    const handler = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      setIsInstallable(true);
    };

    window.addEventListener("beforeinstallprompt", handler);

    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  const install = useCallback(async () => {
    if (!deferredPrompt) return false;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    setDeferredPrompt(null);
    setIsInstallable(false);
    return outcome === "accepted";
  }, [deferredPrompt]);

  return { isInstallable, install, isStandalone: typeof window !== "undefined" && window.matchMedia("(display-mode: standalone)").matches };
}

export function useRegisterSW() {
  useEffect(() => {
    if (!("serviceWorker" in navigator)) return;

    const hostname = window.location.hostname;
    const isDev = hostname === "localhost" || hostname === "127.0.0.1";

    if (isDev) {
      navigator.serviceWorker.getRegistrations().then((registrations) =>
        Promise.all(registrations.map((registration) => registration.unregister())),
      );
      if (window.caches) {
        caches.keys().then((keys) =>
          Promise.all(keys.map((key) => caches.delete(key))),
        );
      }
      return;
    }

    navigator.serviceWorker.register("/sw.js").catch(() => {
      // Silencioso
    });
  }, []);
}

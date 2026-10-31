const CACHE = "wegym-v4";
const PRECACHE_URLS = ["/", "/offline", "/home", "/personal", "/training", "/profile", "/stats", "/goals", "/achievements", "/programs", "/checkin", "/nutrition", "/measurements"];

const STATIC_CACHE = "wegym-static";
const API_CACHE = "wegym-api";

const IS_DEV = ["localhost", "127.0.0.1"].includes(self.location.hostname);

self.addEventListener("install", (event) => {
  if (IS_DEV) {
    event.waitUntil(self.registration.unregister());
    self.skipWaiting();
    return;
  }
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
  // Register background sync for offline data
  if (!IS_DEV) {
    event.waitUntil(registration.sync.register("sync-offline-data"));
  }
});

self.addEventListener("sync", (event) => {
  if (IS_DEV) {
    event.ignoreResources = ["*"];
    return;
  }
  if (event.tag === "sync-offline-data") {
    event.waitUntil(syncOfflineData());
  }
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      if (IS_DEV) {
        const keys = await caches.keys();
        await Promise.all(keys.map((key) => caches.delete(key)));
        return;
      }
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((k) => k !== CACHE && k !== STATIC_CACHE && k !== API_CACHE)
          .map((k) => caches.delete(k)),
      );
    })().then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  if (IS_DEV) return;
  if (event.request.method !== "GET") return;

  const { pathname } = new URL(event.request.url);

  // Queue POST/PUT/DELETE requests when offline
  if (event.request.method !== "GET") {
    event.respondWith(
      fetch(event.request)
        .catch(() => {
          // Queue the request for sync
          const queued = JSON.parse(localStorage.getItem("wegym-queued") || "[]");
          queued.push({ url: event.request.url, method: event.request.method, body: event.request.body });
          localStorage.setItem("wegym-queued", JSON.stringify(queued));
          throw new Error("Offline");
        })
    );
    return;
  }

  if (pathname.startsWith("/_next/static/") || pathname.startsWith("/static/")) {
    event.respondWith(staticStrategy(event.request));
    return;
  }

  if (pathname === "/manifest.json" || pathname === "/favicon.ico" || pathname === "/sw.js") {
    event.respondWith(staticStrategy(event.request));
    return;
  }

  if (/^\/icon-\d+\.(png|jpg|jpeg|svg|webp)$/.test(pathname)) {
    event.respondWith(staticStrategy(event.request));
    return;
  }

  if (pathname.startsWith("/api/auth/")) {
    return;
  }

  if (pathname.startsWith("/api/")) {
    event.respondWith(apiFirst(event.request));
    return;
  }

  if (pathname === "/" || pathname.startsWith("/home") || pathname.startsWith("/personal")) {
    event.respondWith(networkFirst(event.request, CACHE, 30));
    return;
  }

  event.respondWith(
    fetch(event.request)
      .catch(() => caches.match(event.request).then((r) => r || caches.match("/offline"))),
  );
});

async function staticStrategy(request) {
  const cached = await caches.match(request, { cacheName: STATIC_CACHE });
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok) {
    const clone = response.clone();
    caches.open(STATIC_CACHE).then((cache) => cache.put(request, clone));
  }
  return response;
}

async function networkFirst(request, cacheName, ttlSeconds) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);

  try {
    const response = await fetch(request, { signal: controller.signal });
    clearTimeout(timeoutId);
    if (response.ok) {
      const clone = response.clone();
      caches.open(cacheName).then((cache) => cache.put(request, clone));
    }
    return response;
  } catch {
    clearTimeout(timeoutId);
    const cached = await caches.match(request, { cacheName });
    return cached || caches.match("/offline");
  }
}

async function apiFirst(request) {
  const cached = await caches.match(request, { cacheName: API_CACHE });
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);

  try {
    const response = await fetch(request, { signal: controller.signal });
    clearTimeout(timeoutId);
    if (response.ok) {
      const clone = response.clone();
      caches.open(API_CACHE).then((cache) => cache.put(request, clone));
    }
    return response;
  } catch {
    clearTimeout(timeoutId);
    return cached;
  }
}

async function syncOfflineData() {
  const queued = JSON.parse(localStorage.getItem("wegym-queued") || "[]");
  for (const request of queued) {
    try {
      const response = await fetch(request.url, { method: request.method, body: request.body });
      if (response.ok) {
        queued.splice(queued.indexOf(request), 1);
      }
    } catch {
      // Keep queued for next sync cycle
    }
  }
  localStorage.setItem("wegym-queued", JSON.stringify(queued));
}

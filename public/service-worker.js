const CACHE_NAME = "nu-sublets-static-v1";
const STATIC_ASSETS = [
  "/",
  "/manifest.json",
  "/icons/icon-192.png",
  "/icons/icon-512.png",
  "/icons/apple-touch-icon.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => (
      Promise.all(
        cacheNames
          .filter((cacheName) => cacheName !== CACHE_NAME)
          .map((cacheName) => caches.delete(cacheName))
      )
    ))
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const { request } = event;

  if (request.method !== "GET") return;

  const url = new URL(request.url);

  if (url.origin !== self.location.origin) return;
  if (request.headers.get("Accept")?.includes("text/html") && url.pathname !== "/") return;
  if (url.pathname.startsWith("/profile")) return;
  if (url.pathname.startsWith("/users/")) return;
  if (url.pathname.startsWith("/listings/")) return;
  if (url.pathname.startsWith("/saved")) return;
  if (url.pathname.startsWith("/post-sublet")) return;
  if (url.pathname.startsWith("/login")) return;
  if (url.pathname.startsWith("/signup")) return;
  if (url.pathname.startsWith("/session")) return;
  if (url.pathname.startsWith("/auth/")) return;

  const isStaticAsset = STATIC_ASSETS.includes(url.pathname) ||
    url.pathname.startsWith("/assets/") ||
    url.pathname.startsWith("/icons/");

  if (!isStaticAsset) return;

  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response.ok) {
          const responseCopy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, responseCopy));
        }

        return response;
      })
      .catch(() => caches.match(request))
  );
});

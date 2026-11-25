// Service Worker for the Quran PWA.
//
// - App files (index.html, main.dart.js, canvaskit, manifests, ...):
//   network-first, so updates are picked up immediately; the cached copy is
//   used only when offline.
// - Mushaf page images (pages/*.jpg) and icons: cache-first, they never change.

// Bump when page images are renamed/replaced so stale cached pages are dropped.
const VERSION = 'v3';
const APP_CACHE = `quran-app-${VERSION}`;
const PAGES_CACHE = `quran-pages-${VERSION}`;

const APP_SHELL = [
  './',
  './index.html',
  './flutter_bootstrap.js',
  './main.dart.js',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(APP_CACHE)
      .then((cache) => cache.addAll(APP_SHELL))
      .catch((err) => console.warn('[SW] Pre-cache failed:', err))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) => Promise.all(
        names
          .filter((name) => name !== APP_CACHE && name !== PAGES_CACHE)
          .map((name) => caches.delete(name))
      ))
      .then(() => self.clients.claim())
  );
});

function isCacheFirst(url) {
  return /\/pages\/page-\d+\.jpg$/.test(url.pathname) ||
         /\/icons\/[^/]+\.png$/.test(url.pathname);
}

async function cacheFirst(request) {
  const cache = await caches.open(PAGES_CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response && response.ok) {
    cache.put(request, response.clone());
  }
  return response;
}

async function networkFirst(request) {
  const cache = await caches.open(APP_CACHE);
  try {
    const response = await fetch(request);
    if (response && response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (err) {
    const cached = await cache.match(request, { ignoreSearch: true });
    if (cached) return cached;
    if (request.mode === 'navigate') {
      const shell = await cache.match('./index.html') || await cache.match('./');
      if (shell) return shell;
    }
    return new Response('Offline', { status: 503, statusText: 'Offline' });
  }
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // Only handle our own files; let the browser deal with everything else.
  if (url.origin !== self.location.origin) return;

  event.respondWith(isCacheFirst(url) ? cacheFirst(request) : networkFirst(request));
});

self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
});

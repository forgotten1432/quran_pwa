// Custom Service Worker for Quran PWA
// Implements a Cache-First strategy with special handling for the large PDF asset.

const CACHE_NAME = 'quran-pwa-cache-v1';
const PDF_CACHE_NAME = 'quran-pdf-cache-v1';
const PDF_ASSET_PATH = 'assets/assets/quran.pdf';

// Core app shell files to pre-cache
const APP_SHELL_FILES = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Install event: Pre-cache the app shell
self.addEventListener('install', (event) => {
  console.log('[SW] Installing Quran PWA Service Worker...');
  event.waitUntil(
    Promise.all([
      // Cache app shell
      caches.open(CACHE_NAME).then((cache) => {
        console.log('[SW] Pre-caching app shell');
        return cache.addAll(APP_SHELL_FILES);
      }),
      // Pre-cache the PDF (large file - separate cache)
      caches.open(PDF_CACHE_NAME).then(async (cache) => {
        console.log('[SW] Checking PDF cache...');
        const cached = await cache.match(PDF_ASSET_PATH);
        if (!cached) {
          console.log('[SW] PDF not cached. Downloading quran.pdf for offline use...');
          try {
            const response = await fetch(PDF_ASSET_PATH);
            if (response.ok) {
              await cache.put(PDF_ASSET_PATH, response);
              console.log('[SW] quran.pdf cached successfully for offline use!');
            } else {
              console.warn('[SW] Failed to fetch PDF:', response.status);
            }
          } catch (err) {
            console.warn('[SW] PDF caching deferred - will cache on first access:', err);
          }
        } else {
          console.log('[SW] PDF already cached.');
        }
      }),
    ]).then(() => {
      console.log('[SW] Installation complete.');
      return self.skipWaiting();
    })
  );
});

// Activate event: Clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating Quran PWA Service Worker...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME && name !== PDF_CACHE_NAME)
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    }).then(() => {
      console.log('[SW] Activation complete. Claiming clients...');
      return self.clients.claim();
    })
  );
});

// Fetch event: Cache-First strategy
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Special handling for the PDF file
  if (url.pathname.includes('quran.pdf')) {
    event.respondWith(
      caches.open(PDF_CACHE_NAME).then(async (cache) => {
        const cached = await cache.match(event.request);
        if (cached) {
          console.log('[SW] Serving PDF from cache');
          return cached;
        }
        console.log('[SW] PDF not in cache, fetching from network...');
        const response = await fetch(event.request);
        if (response.ok) {
          cache.put(event.request, response.clone());
          console.log('[SW] PDF fetched and cached');
        }
        return response;
      })
    );
    return;
  }

  // Cache-First for all other requests
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) {
        return cached;
      }
      return fetch(event.request).then((response) => {
        // Don't cache non-GET or non-OK responses
        if (!response || response.status !== 200 || event.request.method !== 'GET') {
          return response;
        }
        // Cache successful responses
        const responseClone = response.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseClone);
        });
        return response;
      }).catch(() => {
        // Offline fallback for navigation requests
        if (event.request.mode === 'navigate') {
          return caches.match('/index.html');
        }
        return new Response('Offline', { status: 503, statusText: 'Offline' });
      });
    })
  );
});

// Listen for messages from the app
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
});

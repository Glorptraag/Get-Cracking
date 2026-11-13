/* Get Cracking — offline cache. Bump VERSION when the file list changes. */
const VERSION = 'gc-v6';
const FILES = [
  './', 'index.html', 'manifest.webmanifest', 'css/app.css',
  'js/util.js', 'js/icons.js', 'js/animals.js', 'js/egg.js', 'js/shellfx.js',
  'js/hatch/roll.js', 'js/hatch/boom.js', 'js/hatch/crumble.js', 'js/scenes.js', 'js/audio.js', 'js/store.js', 'js/app.js',
  'fonts/fredoka.woff2', 'fonts/patrick-hand-sc.woff2',
  'icons/icon.svg', 'icons/icon-192.png', 'icons/icon-512.png', 'icons/apple-touch-icon.png', 'icons/icon-maskable-512.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k))))
    .then(() => self.clients.claim()));
});

// network-first: always get the latest build when online (so a new deploy
// shows up on the next load), fall back to the cache when offline.
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET' || new URL(e.request.url).origin !== location.origin) return;
  e.respondWith(
    fetch(e.request).then((res) => {
      if (res.ok) {
        const copy = res.clone();
        caches.open(VERSION).then((c) => c.put(e.request, copy));
      }
      return res;
    }).catch(() => caches.match(e.request, { ignoreSearch: true }).then((hit) => hit || caches.match('index.html')))
  );
});

/* Get Cracking — offline cache. Bump VERSION when the file list changes. */
const VERSION = 'gc-v11';
const FILES = [
  './', 'index.html', 'privacy.html', 'manifest.webmanifest', 'css/app.css',
  'js/util.js', 'js/icons.js', 'js/animals.js', 'js/egg.js', 'js/shellfx.js',
  'js/hatch/roll.js', 'js/hatch/boom.js', 'js/hatch/crumble.js', 'js/scenes.js', 'js/samples.js', 'js/audio.js', 'js/band.js', 'js/karaoke.js',
  'js/packs.js', 'js/packs/aussie.js', 'js/packs/christmas.js', 'js/store.js', 'js/app.js',
  'fonts/fredoka.woff2', 'fonts/patrick-hand-sc.woff2',
  'sounds/index.json', 'icons/icon.svg', 'icons/icon-192.png', 'icons/icon-512.png', 'icons/apple-touch-icon.png', 'icons/icon-maskable-512.png',
];

self.addEventListener('install', (e) => {
  // the app files, then every recorded sound listed in sounds/index.json (so they work offline)
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(FILES).then(() =>
    fetch('sounds/index.json').then((r) => r.json()).then((idx) => c.addAll([
      ...Object.keys(idx.calls).map((id) => `sounds/${id}.mp3`),
      ...Object.keys(idx.voice).map((id) => `sounds/voice/${id}.mp3`),
      ...['inst', 'sing', 'extra'].flatMap((kind) => Object.keys((idx.karaoke || {})[kind] || {}).map((id) => `sounds/karaoke/${kind}/${id}.mp3`)),
    ])).catch(() => {}))).then(() => self.skipWaiting()));
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

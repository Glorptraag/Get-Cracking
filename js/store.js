/* Get Cracking — local-only storage. No accounts, no network.
 * Settings + friend book live in localStorage; photos in IndexedDB. */
(function () {
  'use strict';
  const GC = window.GC;
  const KEY = 'gc.settings.v1';

  const DEFAULTS = {
    minutes: 5,
    seconds: 0,
    scene: 'random',        // scene id or 'random'
    music: 'musicbox',
    endSound: 'tada',
    volume: 0.7,
    sayName: true,
    hatchWho: 'animals',    // 'animals' | 'photos' | 'both'
    hatchStyle: 'random',   // shell effect id from js/hatch/*, or 'random'
    hatchMode: 'tap',       // 'tap' (hatch waits for you) | 'auto'
    showPause: false,       // pause button visible on timer screen
    showAdjust: false,      // −/+ time buttons visible on timer screen
    longPressStop: true,    // grown-up controls need a long press
    holdSeconds: 1.5,
    showNumbers: true,      // big mm:ss clock at the top of the timer screen
    fullscreen: true,
    nextUp: { on: false, text: 'Tidy-up time', icon: 'teddy', photo: null },
    seenHint: false,
  };

  function load() {
    try {
      const raw = JSON.parse(localStorage.getItem(KEY) || '{}');
      const s = Object.assign({}, DEFAULTS, raw, { nextUp: Object.assign({}, DEFAULTS.nextUp, raw.nextUp || {}) });
      // older builds saved an emoji here; it is now the name of a drawn icon
      if (!GC.Icons.has(s.nextUp.icon)) s.nextUp.icon = GC.Icons.fromEmoji(s.nextUp.icon) || 'star';
      return s;
    } catch (e) {
      return JSON.parse(JSON.stringify(DEFAULTS));
    }
  }
  function save(s) {
    try { localStorage.setItem(KEY, JSON.stringify(s)); } catch (e) {}
  }

  /* friend book: { id: timesHatched } */
  const BOOK = 'gc.book.v1';
  function book() { try { return JSON.parse(localStorage.getItem(BOOK) || '{}'); } catch (e) { return {}; } }
  function addToBook(id) {
    const b = book(); b[id] = (b[id] || 0) + 1;
    try { localStorage.setItem(BOOK, JSON.stringify(b)); } catch (e) {}
    return b[id];
  }

  /* photos in IndexedDB (falls back to memory if IDB is unavailable) */
  let dbp = null;
  const mem = [];
  function db() {
    if (dbp) return dbp;
    dbp = new Promise((resolve) => {
      try {
        const req = indexedDB.open('get-cracking', 1);
        req.onupgradeneeded = () => req.result.createObjectStore('photos', { keyPath: 'id' });
        req.onsuccess = () => resolve(req.result);
        req.onerror = () => resolve(null);
      } catch (e) { resolve(null); }
    });
    return dbp;
  }
  async function tx(mode, fn) {
    const d = await db();
    if (!d) return fn(null);
    return new Promise((resolve, reject) => {
      const t = d.transaction('photos', mode);
      const st = t.objectStore('photos');
      const out = fn(st);
      t.oncomplete = () => resolve(out && out.result !== undefined ? out.result : out);
      t.onerror = () => reject(t.error);
    });
  }
  async function listPhotos() {
    const d = await db();
    if (!d) return mem.slice();
    return new Promise((resolve) => {
      const r = d.transaction('photos').objectStore('photos').getAll();
      r.onsuccess = () => resolve(r.result || []);
      r.onerror = () => resolve([]);
    });
  }
  async function addPhoto(dataUrl) {
    const rec = { id: 'ph' + Date.now() + Math.random().toString(36).slice(2, 6), url: dataUrl, added: Date.now() };
    const d = await db();
    if (!d) { mem.push(rec); return rec; }
    await tx('readwrite', (st) => st.put(rec));
    return rec;
  }
  async function removePhoto(id) {
    const d = await db();
    if (!d) { const i = mem.findIndex((p) => p.id === id); if (i >= 0) mem.splice(i, 1); return; }
    await tx('readwrite', (st) => st.delete(id));
  }

  /** Read an image File, centre-crop to a square and shrink it. */
  function fileToSquareDataUrl(file, size = 480) {
    return new Promise((resolve, reject) => {
      const url = URL.createObjectURL(file);
      const img = new Image();
      img.onload = () => {
        const s = Math.min(img.naturalWidth, img.naturalHeight);
        const c = document.createElement('canvas');
        c.width = c.height = size;
        c.getContext('2d').drawImage(img, (img.naturalWidth - s) / 2, (img.naturalHeight - s) / 2, s, s, 0, 0, size, size);
        URL.revokeObjectURL(url);
        resolve(c.toDataURL('image/jpeg', 0.85));
      };
      img.onerror = (e) => { URL.revokeObjectURL(url); reject(e); };
      img.src = url;
    });
  }

  GC.Store = { DEFAULTS, load, save, book, addToBook, listPhotos, addPhoto, removePhoto, fileToSquareDataUrl };
})();

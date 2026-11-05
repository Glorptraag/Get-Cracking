/* Get Cracking — shared helpers. Classic script (no modules) so the app
   also works when index.html is opened straight from disk. */
(function () {
  'use strict';
  const GC = (window.GC = window.GC || {});

  GC.OUT = '#3b2224';          // the chunky dark outline used everywhere
  GC.SVGNS = 'http://www.w3.org/2000/svg';

  let uidCounter = 0;
  GC.uid = (p = 'u') => `${p}${++uidCounter}${Math.random().toString(36).slice(2, 6)}`;

  GC.clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  GC.lerp = (a, b, t) => a + (b - a) * t;
  GC.rand = (a, b) => a + Math.random() * (b - a);
  GC.pick = (arr) => arr[Math.floor(Math.random() * arr.length)];

  /** Deterministic PRNG so scenes/animals draw the same every time. */
  GC.seeded = function (seed) {
    let s = seed >>> 0 || 1;
    return function () {
      s ^= s << 13; s >>>= 0;
      s ^= s >> 17;
      s ^= s << 5; s >>>= 0;
      return (s % 100000) / 100000;
    };
  };

  /** Lighten (amt>0) or darken (amt<0) a #rrggbb colour. */
  GC.shade = function (hex, amt) {
    const n = parseInt(hex.slice(1), 16);
    let r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
    const f = (c) => Math.round(amt < 0 ? c * (1 + amt) : c + (255 - c) * amt);
    r = f(r); g = f(g); b = f(b);
    return '#' + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
  };

  GC.el = function (tag, attrs = {}, parent) {
    const e = document.createElementNS(GC.SVGNS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  };

  /** Build an <svg> fragment from markup and return the first element. */
  GC.svgFrag = function (markup) {
    const wrap = document.createElementNS(GC.SVGNS, 'svg');
    wrap.innerHTML = markup;
    const g = document.createElementNS(GC.SVGNS, 'g');
    while (wrap.firstChild) g.appendChild(wrap.firstChild);
    return g;
  };

  GC.fmtTime = function (ms) {
    const s = Math.max(0, Math.ceil(ms / 1000));
    const m = Math.floor(s / 60);
    const ss = String(s % 60).padStart(2, '0');
    return `${m}:${ss}`;
  };

  GC.prefersReducedMotion = () =>
    window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /** Shuffle-bag: every item comes up once before any repeats. */
  GC.ShuffleBag = class {
    constructor(key, items) {
      this.key = key; this.items = items;
      try { this.bag = JSON.parse(localStorage.getItem(key) || '[]'); } catch (e) { this.bag = []; }
      this.bag = this.bag.filter((x) => items.includes(x));
    }
    next() {
      if (!this.bag.length) {
        this.bag = this.items.slice();
        for (let i = this.bag.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [this.bag[i], this.bag[j]] = [this.bag[j], this.bag[i]];
        }
      }
      const v = this.bag.pop();
      try { localStorage.setItem(this.key, JSON.stringify(this.bag)); } catch (e) {}
      return v;
    }
  };
})();

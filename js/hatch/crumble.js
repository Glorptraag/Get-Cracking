/* Get Cracking — shell effect "Crumble".
 *
 * The Looney Tunes "teeth fall out" gag: the egg lands from its stretch and
 * freezes; a web of cracks races across it; then the shell drops out tile by
 * tile, top row first, each one wobbling, falling straight down under
 * gravity and tinkling onto a little heap at the egg's base. The heap gives a
 * last slump, one tile slides off the top, and the rubble stays behind the
 * friend. See js/shellfx.js for the contract.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT;

  /* ---------- egg geometry helpers ---------- */

  // half-width of the egg at height y, from the egg's right-hand beziers
  const HW = (() => {
    const curves = [
      [[0, -170], [40, -170], [64, -96], [64, -58]],
      [[64, -58], [64, -20], [36, 0], [0, 0]],
    ];
    const pts = [];
    for (const [a, b, c, d] of curves) {
      for (let i = 0; i <= 48; i++) {
        const t = i / 48, u = 1 - t;
        const k0 = u * u * u, k1 = 3 * u * u * t, k2 = 3 * u * t * t, k3 = t * t * t;
        pts.push([k0 * a[0] + k1 * b[0] + k2 * c[0] + k3 * d[0], k0 * a[1] + k1 * b[1] + k2 * c[1] + k3 * d[1]]);
      }
    }
    pts.sort((p, q) => p[1] - q[1]);
    return (y) => {
      if (y <= -170 || y >= 0) return 0;
      for (let i = 1; i < pts.length; i++) {
        if (pts[i][1] >= y) {
          const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
          return y1 === y0 ? Math.max(x0, x1) : x0 + (x1 - x0) * (y - y0) / (y1 - y0);
        }
      }
      return 0;
    };
  })();

  function inPoly(x, y, poly) {
    let inside = false;
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      const [xi, yi] = poly[i], [xj, yj] = poly[j];
      if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
    }
    return inside;
  }

  /** points of the tile polygon that are actually visible (inside the egg) */
  function visibleSamples(poly) {
    let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
    for (const [x, y] of poly) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    const out = [];
    for (let y = Math.max(y0, -170) + 1; y < Math.min(y1, 0); y += 3) {
      const hw = HW(y);
      for (let x = Math.max(x0, -hw) + 1; x < Math.min(x1, hw); x += 3) {
        if (inPoly(x, y, poly)) out.push([x, y]);
      }
    }
    return out;
  }

  /* ---------- the tile grid ---------- */

  // row boundaries (top → bottom) and where each row is split into tiles
  const ROW_Y = [-196, -134, -100, -66, -32, 14];
  const SPLITS = [[2], [-17, 18], [-32, 0, 32], [-40, -14, 12, 38], [-26, 0, 26]];
  const XS = [-100, -80, -60, -40, -20, 0, 20, 40, 60, 80, 100];

  function buildGrid(rand) {
    // horizontal boundaries: jittered polylines (outer ones straight)
    const H = ROW_Y.map((y, k) => XS.map((x) => [x, k === 0 || k === ROW_Y.length - 1 ? y : y + rand(-4, 4)]));
    const yAt = (line, x) => {
      for (let i = 1; i < line.length; i++) {
        if (line[i][0] >= x) {
          const [xa, ya] = line[i - 1], [xb, yb] = line[i];
          return ya + (yb - ya) * (x - xa) / (xb - xa);
        }
      }
      return line[line.length - 1][1];
    };
    const between = (line, a, b) => line.filter(([x]) => x > a && x < b);
    const tiles = [], cracks = [];
    for (let r = 0; r < SPLITS.length; r++) {
      const top = H[r], bot = H[r + 1];
      // each split is a little kinked line from the top boundary to the bottom one
      const cuts = SPLITS[r].map((s) => {
        const xt = s + rand(-3, 3), xb = s + rand(-3, 3);
        const yt = yAt(top, xt), yb = yAt(bot, xb);
        const mid = [(xt + xb) / 2 + rand(-3.5, 3.5), (yt + yb) / 2 + rand(-3, 3)];
        return [[xt, yt], mid, [xb, yb]];
      });
      const edges = [[[-100, top[0][1]], [-100, bot[0][1]]], ...cuts, [[100, top[top.length - 1][1]], [100, bot[bot.length - 1][1]]]];
      for (let c = 0; c + 1 < edges.length; c++) {
        const L = edges[c], R = edges[c + 1];
        const pts = [
          L[0], ...between(top, L[0][0], R[0][0]), R[0],
          ...R.slice(1, -1), R[R.length - 1],
          ...between(bot, L[L.length - 1][0], R[R.length - 1][0]).reverse(), L[L.length - 1],
          ...L.slice(1, -1).reverse(),
        ];
        tiles.push({ row: r, poly: pts });
      }
      cracks.push(...cuts);
    }
    for (let k = 1; k < H.length - 1; k++) cracks.push(H[k]);
    return { tiles, cracks };
  }

  /* ---------- small helpers ---------- */

  const tf = (x, y, r, sx = 1, sy = 1) =>
    `translate(${x.toFixed(1)}px,${y.toFixed(1)}px) rotate(${r.toFixed(1)}deg)` + (sx !== 1 || sy !== 1 ? ` scale(${sx},${sy})` : '');

  /** extents of a tile's visible samples (centroid-relative) after rotating by deg */
  function extents(rel, deg) {
    const a = deg * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
    let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    for (const [x, y] of rel) {
      const X = x * c - y * s, Y = x * s + y * c;
      if (X < minX) minX = X; if (X > maxX) maxX = X;
      if (Y < minY) minY = Y; if (Y > maxY) maxY = Y;
    }
    return { minX, maxX, minY, maxY };
  }

  /** a ground heightmap for the rubble heap */
  function heap(ground) {
    const COL = 8, X0 = -180, n = Math.ceil(360 / COL);
    const h = new Array(n).fill(0);
    const idx = (x) => GC.clamp(Math.round((x - X0) / COL), 0, n - 1);
    return {
      ground,
      surface(a, b) { let s = 0, m = 0; for (let i = idx(a); i <= idx(b); i++) { s += h[i]; m++; } return m ? s / m : 0; },
      at(x) { return h[idx(x)]; },
      raise(a, b, v) { for (let i = idx(a); i <= idx(b); i++) h[i] = Math.max(h[i], v); },
    };
  }

  GC.ShellFX.register({
    id: 'crumble',
    name: 'Crumble',
    icon: '🧱',
    async run(ctx) {
      const R = ctx.rand;
      const { tiles: grid, cracks } = buildGrid(R);

      /* ---------- reduced motion: tiles just sink and fade together ---------- */
      if (ctx.reduce) {
        const ps = grid.map((g) => ctx.piece(g.poly, { layer: ctx.back, edge: 4 }));
        ctx.sfx.crack();
        ctx.release();
        await Promise.all(ps.map((p) => ctx.animate(p.el, [
          { transform: 'translate(0px,0px)', opacity: 1 },
          { transform: `translate(0px,${R(5, 9).toFixed(1)}px)`, opacity: 0 },
        ], { duration: 360, easing: 'ease-in', fill: 'forwards' })));
        return;
      }

      /* ---------- beat 1: land from the stretch, freeze, crack web ---------- */
      const shadow = ctx.shadow(0, 24, 112, ctx.back);
      shadow.setAttribute('opacity', '0');
      const whole = ctx.piece([[-100, -200], [100, -200], [100, 20], [-100, 20]], { cx: 0, cy: 0 });
      await ctx.animate(whole.el, [
        { transform: 'scale(.9,1.12)' }, { transform: 'scale(1.07,.93)', offset: 0.55 }, { transform: 'scale(1,1)' },
      ], { duration: 180, easing: 'ease-out', fill: 'forwards' });
      await ctx.wait(70);

      const ox = 6, oy = -124;   // where the first crack starts
      const clipId = GC.uid('crc');
      const web = GC.el('g', {}, ctx.front);
      const clip = GC.el('clipPath', { id: clipId }, web);
      GC.el('path', { d: ctx.EGG_PATH }, clip);
      const lines = GC.el('g', { 'clip-path': `url(#${clipId})` }, web);
      const SPEED = 0.95;        // px per ms the crack travels
      const segs = [];
      const len = (pts) => { let s = 0; for (let i = 1; i < pts.length; i++) s += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]); return s; };
      for (const c of cracks) {
        if (c.length > 3) {
          // a horizontal boundary: crack from the point nearest the origin outwards both ways
          let k = 0;
          c.forEach((p, i) => { if (Math.abs(p[0] - ox) < Math.abs(c[k][0] - ox)) k = i; });
          segs.push(c.slice(0, k + 1).reverse(), c.slice(k));
        } else {
          const d0 = Math.hypot(c[0][0] - ox, c[0][1] - oy), d1 = Math.hypot(c[2][0] - ox, c[2][1] - oy);
          segs.push(d0 <= d1 ? c : c.slice().reverse());
        }
      }
      ctx.sfx.crack();
      const crackAnims = segs.filter((s) => s.length > 1).map((s) => {
        const pl = GC.el('polyline', {
          points: s.map((p) => p.map((v) => v.toFixed(1)).join(',')).join(' '), pathLength: 1,
          fill: 'none', stroke: O, 'stroke-width': 4.5, 'stroke-linejoin': 'round', 'stroke-linecap': 'round',
          'stroke-dasharray': '1 2', 'stroke-dashoffset': 1,
        }, lines);
        const d = Math.hypot(s[0][0] - ox, s[0][1] - oy) * 0.75;
        return ctx.animate(pl, [{ strokeDashoffset: 1 }, { strokeDashoffset: 0 }], {
          duration: Math.max(40, len(s) / SPEED), delay: d / SPEED, easing: 'linear', fill: 'forwards',
        });
      });
      // a tiny "tink" sparkle where it starts
      const star = GC.el('g', { transform: `translate(${ox} ${oy})` }, web);
      const sp = GC.el('path', { d: 'M0,-13 L3,-3 L13,0 L3,3 L0,13 L-3,3 L-13,0 L-3,-3 Z', fill: '#fff', stroke: O, 'stroke-width': 2.5, 'stroke-linejoin': 'round' }, star);
      ctx.animate(sp, [{ transform: 'scale(.1) rotate(0deg)' }, { transform: 'scale(1.2) rotate(30deg)', offset: 0.35 }, { transform: 'scale(0) rotate(60deg)' }], { duration: 260, easing: 'ease-out', fill: 'forwards' });
      await Promise.all(crackAnims);
      await ctx.wait(190);       // …uh-oh.

      /* ---------- beat 2: swap to the tiles (identical picture) ---------- */
      // bottom rows first in the DOM so falling upper tiles pass in front of them
      const tiles = grid.slice().reverse().map((g) => {
        const vis = visibleSamples(g.poly);
        let cx = 0, cy = 0;
        for (const [x, y] of vis) { cx += x; cy += y; }
        cx /= vis.length || 1; cy /= vis.length || 1;
        const p = ctx.piece(g.poly, { cx, cy });
        return Object.assign(p, { row: g.row, rel: vis.map(([x, y]) => [x - cx, y - cy]) });
      });
      web.remove();
      whole.wrap.remove();

      /* ---------- beat 3: the cascade ---------- */
      // fall order: top row first, shuffled inside each row
      const order = [];
      for (let r = 0; r < SPLITS.length; r++) {
        const row = tiles.filter((t) => t.row === r);
        for (let i = row.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [row[i], row[j]] = [row[j], row[i]]; }
        order.push(...row);
      }
      const front = heap(28), back = heap(9);   // upper rows land nearer the viewer
      const G = 0.0030;                         // gravity, px/ms²
      const WOB = 95;
      let t0 = 0;
      let landed = 0;
      order.forEach((t, i) => {
        t.start = t0;
        t0 += t.row < 3 ? R(52, 66) : R(38, 50);
        const hp = t.row < 3 ? front : back;
        const side = Math.abs(t.cx) < 4 ? (i % 2 ? 1 : -1) : Math.sign(t.cx);
        // where it comes to rest: pushed out to the sides so the friend stands in front
        const ax = Math.abs(t.cx);
        const xr = side * [ax * 0.7, 16 + ax * 1.1, 30 + ax * 1.3, 48 + ax * 1.3, 52 + ax * 1.4][t.row] + R(-7, 7);
        const rr = side * R(14, 48) * (Math.random() < 0.2 ? -1 : 1);
        const eR = extents(t.rel, rr);
        const fw = (eR.maxX - eR.minX) / 2;
        const surf = hp.surface(xr - fw * 0.6, xr + fw * 0.6) * 0.8;
        const restBottom = hp.ground + R(-4, 6) - surf;
        const yr = restBottom - eR.maxY;
        hp.raise(xr - fw * 0.75, xr + fw * 0.75, Math.min(46, surf + (eR.maxY - eR.minY) * 0.55));
        // the drop: straight down at first, edging outward as it nears the heap
        // (as if glancing off the shell below), then it skitters down the slope
        const rx = xr - t.cx, ry = yr - t.cy;
        const xi = side * R(2, 8) + (rx) * (t.row < 3 ? 0.5 : 0.3);
        const ri = side * R(6, 18);
        const eI = extents(t.rel, ri);
        const impactBottom = hp.ground - 4 - hp.at(t.cx + xi) * 0.6;
        const yi = Math.max(6, impactBottom - eI.maxY - t.cy);   // drop distance
        const d = yi - 2;
        t.T = Math.sqrt(2 * d / G);
        const S = 150 + Math.abs(rx - xi) * 1.5;
        t.rest = { x: rx, y: ry, r: rr };
        // keyframes in absolute ms, converted to offsets below
        const k = [];
        const sw = R(3, 6) * (Math.random() < 0.5 ? -1 : 1);
        k.push([0, tf(0, 0, 0)], [WOB * 0.3, tf(0, 1, sw)], [WOB * 0.65, tf(0, 1, -sw * 0.8)], [WOB, tf(0, 2, 0)]);
        const N = 8;
        for (let s = 1; s <= N; s++) {
          const u = s / N;
          k.push([WOB + t.T * u, tf(xi * u * u * u, 2 + (yi - 2) * u * u, ri * u)]);
        }
        const tI = WOB + t.T;
        const hop = R(7, 13);
        k.push([tI + 25, tf(xi + (rx - xi) * 0.08, yi - 2, ri + (rr - ri) * 0.1, 1.08, 0.9)]);
        k.push([tI + S * 0.45, tf(xi + (rx - xi) * 0.5, Math.min(yi, ry) - hop, ri + (rr - ri) * 0.7)]);
        k.push([tI + S, tf(rx, ry, rr + side * 5)]);
        k.push([tI + S + 90, tf(rx, ry, rr)]);
        const total = k[k.length - 1][0];
        t.frames = k.map(([ms, transform], j) => ({
          transform, offset: ms / total,
          easing: j >= k.length - 4 ? (j === k.length - 3 ? 'ease-out' : 'ease-in') : 'linear',
        }));
        t.total = total;
        t.impact = tI;
        t.settle = tI + S;
      });

      // releasing the friend once the top two rows are on their way down
      const RELEASE_AT = order[5].start + WOB + 40;
      const releaseFlow = (async () => {
        await ctx.wait(RELEASE_AT);
        ctx.release();
        await ctx.wait(320);
        // everything goes behind the friend now (keeps the original stacking order)
        ctx.back.appendChild(shadow);
        for (const t of tiles) ctx.back.appendChild(t.wrap);
      })();

      ctx.animate(shadow, [{ opacity: 0 }, { opacity: 0.18 }], { duration: t0 + 300, fill: 'forwards' });

      const N = order.length;
      await Promise.all(order.map(async (t) => {
        const a = ctx.animate(t.el, t.frames, { duration: t.total, delay: t.start, fill: 'forwards' });
        await ctx.wait(t.start + t.impact);
        ctx.sfx.clink(GC.clamp(0.95 - (landed++ / N) * 0.85, 0, 1));
        await a;
      }));
      await releaseFlow;

      /* ---------- beat 4: the heap slumps, one tile slides off ---------- */
      ctx.sfx.thud(0.25);
      // pick the highest tile on the front heap that sits off to one side
      let topTile = null;
      for (const t of order) {
        if (t.row >= 3) continue;
        const y = t.cy + t.rest.y;
        if (Math.abs(t.cx + t.rest.x) > 60 && (!topTile || y < topTile.cy + topTile.rest.y)) topTile = t;
      }
      const slumps = order.map((t) => {
        const r = t.rest;
        const dx = Math.sign(r.x + t.cx || 1) * R(1, 4), dy = R(2, 5), dr = R(-5, 5);
        t.rest = { x: r.x + dx, y: r.y + dy, r: r.r + dr };
        return ctx.animate(t.el, [
          { transform: tf(r.x, r.y, r.r) },
          { transform: tf(r.x + dx * 0.5, r.y - 2, r.r + dr * 0.3), offset: 0.3 },
          { transform: tf(t.rest.x, t.rest.y, t.rest.r) },
        ], { duration: 260, delay: R(0, 50), easing: 'cubic-bezier(.5,0,.6,1.4)', fill: 'forwards' });
      });
      ctx.puff(-104, 22, 22, ctx.back);
      ctx.puff(106, 24, 20, ctx.back);
      await ctx.wait(110);
      if (topTile) {
        const r = topTile.rest;
        const side = Math.sign(topTile.cx + r.x);
        const rr = r.r + side * R(50, 80);
        const e = extents(topTile.rel, rr);
        const xr = r.x + side * R(44, 56);
        const yr = 40 - e.maxY - topTile.cy;
        await ctx.animate(topTile.el, [
          { transform: tf(r.x, r.y, r.r) },
          { transform: tf(r.x + side * 4, r.y + 1, r.r + side * 8), offset: 0.25, easing: 'ease-in' },
          { transform: tf(xr, yr, rr), offset: 0.8, easing: 'ease-out' },
          { transform: tf(xr + side * 3, yr - 5, rr + side * 6), offset: 0.9, easing: 'ease-in' },
          { transform: tf(xr + side * 5, yr, rr + side * 4) },
        ], { duration: 420, fill: 'forwards' });
        ctx.sfx.clink(0.05);
      }
      await Promise.all(slumps);
    },
  });
})();

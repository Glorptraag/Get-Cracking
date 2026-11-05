/* Get Cracking — shell effect "Kaboom".
 *
 * A cartoon party-pop: the egg puffs up and jitters, a pale "POW" star
 * flashes behind it, then the shell bursts into ~15 jagged shards that tile
 * the egg exactly. Shards fly out on gravity arcs, spin, bounce once or
 * twice with a squash, skid to a stop; a few stay as rubble, the rest sail
 * off-screen or fade. See js/shellfx.js for the contract.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT || '#3b2224';

  const CENTER_Y = -85;      // egg-local pivot for the whole-egg puff-up
  const PUFF_MS = 200;       // inflate + jitter before the burst
  const BURST_S = 1.2;       // inflation at the moment of bursting
  const GRAV = 2500;         // px/s²
  const DT = 1 / 60;
  const MAX_T = 2.15;        // s — every shard is done by then
  const BOX = { l: -75, r: 75, t: -200, b: 60 }; // keep-clear box (front layer)

  /* ───────────── geometry ───────────── */

  /** Sample the egg outline (M + cubic C segments) into a polygon. */
  function eggPolygon(d) {
    const n = (d.match(/-?\d+(\.\d+)?/g) || []).map(Number);
    const out = [];
    let px = n[0], py = n[1];
    for (let i = 2; i + 5 < n.length; i += 6) {
      const [x1, y1, x2, y2, x3, y3] = n.slice(i, i + 6);
      for (let k = 0; k < 16; k++) {
        const t = k / 16, u = 1 - t;
        out.push([
          u * u * u * px + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t * t * t * x3,
          u * u * u * py + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y3,
        ]);
      }
      px = x3; py = y3;
    }
    return out;
  }

  function inPoly(x, y, poly) {
    let c = false;
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      const [xi, yi] = poly[i], [xj, yj] = poly[j];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
    }
    return c;
  }

  /** n jaggy points strictly between a and b (zig-zag across the line). */
  function jag(a, b, n, amp, rand) {
    const dx = b[0] - a[0], dy = b[1] - a[1];
    const len = Math.hypot(dx, dy) || 1;
    const nx = -dy / len, ny = dx / len;
    const pts = [];
    let sgn = rand(0, 1) < 0.5 ? -1 : 1;
    for (let i = 1; i <= n; i++) {
      const t = i / (n + 1) + rand(-0.06, 0.06);
      const o = sgn * amp * rand(0.55, 1);
      pts.push([a[0] + dx * t + nx * o, a[1] + dy * t + ny * o]);
      sgn = -sgn;
    }
    return pts;
  }

  /**
   * A radial / ring split that tiles the whole egg with no gaps: 5 inner
   * pieces around a burst point P, and 10 outer pieces between jagged rays.
   * Every edge polyline is shared by its two neighbours.
   */
  function buildPolys(rand) {
    const P = [rand(-5, 5), rand(-94, -82)];
    const K = 10, R = 140;
    const Q = [], Ang = [];
    for (let k = 0; k < K; k++) {
      const a = -Math.PI / 2 + (k / K) * Math.PI * 2 + rand(-0.13, 0.13);
      const r = (k % 2 ? 44 : 34) + rand(-4, 4);
      Ang.push(a);
      Q.push([P[0] + Math.cos(a) * r, P[1] + Math.sin(a) * r * 1.15]);
    }
    const spoke = [];   // P → Q[2j]
    for (let j = 0; j < K / 2; j++) spoke.push(jag(P, Q[2 * j], 1, 6, rand));
    const ring = [];    // Q[k] → Q[k+1]
    for (let k = 0; k < K; k++) ring.push(jag(Q[k], Q[(k + 1) % K], 1, 6, rand));
    const ray = [], Oend = [];   // Q[k] → far outside the egg
    for (let k = 0; k < K; k++) {
      const a = Ang[k] + rand(-0.1, 0.1);
      const o = [P[0] + Math.cos(a) * R, P[1] + Math.sin(a) * R * 1.2];
      Oend.push(o);
      ray.push(jag(Q[k], o, 3, 7, rand));
    }
    const polys = [];
    for (let j = 0; j < K / 2; j++) {
      const a = 2 * j, b = 2 * j + 1, c = (2 * j + 2) % K;
      polys.push([P, ...spoke[j], Q[a], ...ring[a], Q[b], ...ring[b], Q[c], ...spoke[(j + 1) % (K / 2)].slice().reverse()]);
    }
    for (let k = 0; k < K; k++) {
      const k2 = (k + 1) % K;
      const am = (Ang[k] + (k2 ? Ang[k2] : Ang[k2] + Math.PI * 2)) / 2;
      const mid = [P[0] + Math.cos(am) * R * 1.05, P[1] + Math.sin(am) * R * 1.25];
      polys.push([Q[k], ...ray[k], Oend[k], mid, Oend[k2], ...ray[k2].slice().reverse(), Q[k2], ...ring[k].slice().reverse()]);
    }
    return { P, polys };
  }

  /** Visible (inside-the-egg) centroid, area and sample points per polygon. */
  function measure(polys, egg) {
    const st = polys.map(() => ({ sx: 0, sy: 0, n: 0, pts: [] }));
    const step = 4;
    for (let y = -170 + step / 2; y < 0; y += step) {
      for (let x = -64 + step / 2; x < 64; x += step) {
        if (!inPoly(x, y, egg)) continue;
        for (let i = 0; i < polys.length; i++) {
          if (inPoly(x, y, polys[i])) { const s = st[i]; s.sx += x; s.sy += y; s.n++; s.pts.push([x, y]); break; }
        }
      }
    }
    return st.map((s) => {
      const cx = s.n ? s.sx / s.n : 0, cy = s.n ? s.sy / s.n : CENTER_Y;
      const pts = s.pts.map(([x, y]) => [x - cx, y - cy]);
      let r = 4;
      for (const [x, y] of pts) r = Math.max(r, Math.hypot(x, y));
      // keep the extreme points only (enough to find the lowest point when rotated)
      const hull = pts.filter((p, i) => i % 3 === 0 || Math.hypot(p[0], p[1]) > r * 0.6);
      return { cx, cy, area: s.n * step * step, pts: hull.length ? hull : [[0, 0]], r: r + 2.5 };
    });
  }

  /** lowest (max y) offset of the shard's points when rotated by deg */
  function lowest(pts, deg) {
    const a = (deg * Math.PI) / 180, s = Math.sin(a), c = Math.cos(a);
    let m = -1e9;
    for (const [x, y] of pts) { const v = x * s + y * c; if (v > m) m = v; }
    return m + 2; // half the outline
  }

  /* ───────────── physics ───────────── */

  function inflateAt(t) {
    const k = Math.max(0, 1 - t / 0.14);
    return 1 + (BURST_S - 1) * k * k;
  }

  /**
   * Simulate one shard. Returns frames {t,X,Y,R,sx,sy,low} (absolute egg-local
   * centroid), bounce events and the end state.
   */
  function simulate(sh, v, depth, rand) {
    let X = sh.x0, Y = sh.y0, vx = v.vx, vy = v.vy, R = 0, w = v.w;
    let bounces = 0, resting = false, out = false, sqA = 0, sqT = 1;
    const frames = [], events = [];
    const rest = [0.46, 0.34, 0.25];
    for (let i = 0; i * DT <= MAX_T; i++) {
      const t = i * DT;
      const s = inflateAt(t);
      // squash after an impact: flat → tall → settle
      let qx = 1, qy = 1;
      if (sqT < 0.12) {
        const p = sqT / 0.12;
        const k = p < 0.35 ? 1 : p < 0.7 ? -0.35 : 0.1;
        qx = 1 + sqA * k; qy = 1 - sqA * k;
      }
      const low = lowest(sh.pts, R);
      frames.push({ t, X, Y: Y + low * (1 - qy * s) * (resting || sqT < 0.12 ? 1 : 0), R, sx: s * qx, sy: s * qy });
      if (out) break;
      sqT += DT;
      if (!resting) vy += GRAV * DT;
      X += vx * DT; Y += vy * DT; R += w * DT;
      const lo = lowest(sh.pts, R);
      if (!resting && vy > 0 && Y + lo >= depth) {
        Y = depth - lo;
        events.push({ t: t + DT, X, impact: vy, n: bounces });
        bounces++;
        sqA = Math.min(0.28, vy / 3800);
        sqT = 0;
        const e = rest[Math.min(bounces - 1, 2)];
        if (bounces >= v.maxB || vy * e < 230) { resting = true; vy = 0; } else vy = -vy * e;
        vx *= 0.7;
        w = w * rand(0.35, 0.6) * (rand(0, 1) < 0.3 ? -1 : 1);
      }
      if (resting) {
        Y = depth - lo;
        const f = 900 * DT;
        vx = Math.abs(vx) <= f ? 0 : vx - Math.sign(vx) * f;
        w *= 0.86;
        if (vx === 0 && Math.abs(w) < 8 && sqT > 0.14) {
          frames.push({ t: t + DT, X, Y, R, sx: 1, sy: 1 });
          break;
        }
      }
      if (Math.abs(X) - sh.r > 330 || Y + sh.r < -470) out = true;
    }
    return { frames, events, resting, out, X, Y, depth };
  }

  /** do any frames after tFrom put the shard inside the keep-clear box? */
  function crossesBox(frames, r, tFrom) {
    for (const f of frames) {
      if (f.t < tFrom) continue;
      if (f.X + r > BOX.l && f.X - r < BOX.r && f.Y + r > BOX.t && f.Y - r < BOX.b) return true;
    }
    return false;
  }

  const fmt = (n) => n.toFixed(1);

  /* ───────────── decorations ───────────── */

  function starPath(n, r1, r2, rand) {
    let d = '';
    for (let i = 0; i < n * 2; i++) {
      const a = (i / (n * 2)) * Math.PI * 2 + rand(-0.06, 0.06);
      const r = (i % 2 ? r2 : r1) * rand(0.85, 1.12);
      d += (i ? 'L' : 'M') + fmt(Math.cos(a) * r) + ',' + fmt(Math.sin(a) * r * 1.08);
    }
    return d + 'Z';
  }

  /** a dust puff that also drifts outward */
  function driftPuff(ctx, x, y, r, dx, dy, layer) {
    const outer = GC.el('g', { transform: `translate(${fmt(x)} ${fmt(y)})` }, layer);
    const inner = GC.el('g', {}, outer);
    ctx.puff(0, 0, r, inner);
    ctx.animate(inner, [{ transform: 'translate(0px,0px)' }, { transform: `translate(${fmt(dx)}px,${fmt(dy)}px)` }],
      { duration: 600, easing: 'cubic-bezier(.2,.8,.4,1)', fill: 'forwards' }).then(() => outer.remove());
  }

  /* ───────────── the effect ───────────── */

  GC.ShellFX.register({
    id: 'boom',
    name: 'Kaboom',
    icon: 'boom',
    async run(ctx) {
      const rand = ctx.rand;
      const egg = eggPolygon(ctx.EGG_PATH);
      const { P, polys } = buildPolys(rand);
      const stats = measure(polys, egg);

      if (ctx.reduce) return reduced(ctx, polys, stats, P);

      /* 1. puff up: a whole-egg piece inflates and jitters */
      const whole = ctx.piece([[-90, -200], [90, -200], [90, 20], [-90, 20]], { cx: 0, cy: CENTER_Y });
      const inflateTo = (sx, sy, jx) => `translate(${fmt(jx)}px,${fmt(-(sy - 1) * -CENTER_Y)}px) scale(${sx},${sy})`;
      const puffAnim = ctx.animate(whole.el, [
        { transform: inflateTo(0.9, 1.12, 0) },
        { transform: inflateTo(1.1, 1.0, -3), offset: 0.22 },
        { transform: inflateTo(1.06, 1.13, 3), offset: 0.4 },
        { transform: inflateTo(1.17, 1.08, -3), offset: 0.56 },
        { transform: inflateTo(1.13, 1.2, 3), offset: 0.7 },
        { transform: inflateTo(1.23, 1.17, -2), offset: 0.85 },
        { transform: inflateTo(BURST_S, BURST_S, 0) },
      ], { duration: PUFF_MS, easing: 'ease-out', fill: 'forwards' });

      // pale "POW" starburst behind (back layer, behind everything else)
      const powG = GC.el('g', { transform: `translate(0 ${CENTER_Y - 6})` }, ctx.back);
      ctx.back.insertBefore(powG, ctx.back.firstChild);
      const pow = GC.el('g', { opacity: 0 }, powG);
      GC.el('path', { d: starPath(12, 150, 92, rand), fill: '#fff6c9', stroke: O, 'stroke-width': 5, 'stroke-linejoin': 'round' }, pow);
      GC.el('path', { d: starPath(9, 92, 58, rand), fill: '#ffffff' }, pow);
      ctx.animate(pow, [
        { transform: 'scale(.25) rotate(-8deg)', opacity: 0 },
        { transform: 'scale(.8) rotate(-2deg)', opacity: 1, offset: 0.2 },
        { transform: 'scale(1.18) rotate(4deg)', opacity: 1, offset: 0.45 },
        { transform: 'scale(1.06) rotate(6deg)', opacity: 0.95, offset: 0.62 },
        { transform: 'scale(1.3) rotate(10deg)', opacity: 0 },
      ], { duration: 640, delay: PUFF_MS - 90, easing: 'ease-out', fill: 'forwards' }).then(() => powG.remove());

      /* 2. pre-build the shards (hidden) while the egg puffs up */
      // where each shard's centroid sits on the inflated egg (scaled about
      // (0, CENTER_Y), then lifted so the base stays on the ground)
      const shards = polys.map((pts, i) => {
        const s = stats[i];
        const x0 = s.cx * BURST_S, y0 = CENTER_Y + (s.cy - CENTER_Y) * BURST_S - (BURST_S - 1) * -CENTER_Y;
        return { pts: s.pts, poly: pts, cx: s.cx, cy: s.cy, area: s.area, r: s.r * BURST_S, x0, y0, inner: i < 5 };
      }).filter((s) => s.area > 40);

      // choose a few keepers: three each side, biggest non-top shards first
      const side = (s) => (s.cx - P[0] >= 0 ? 1 : -1);
      const cand = shards.filter((s) => !s.inner && s.cy > -125).sort((a, b) => b.area - a.area);
      for (const sd of [-1, 1]) cand.filter((s) => side(s) === sd).slice(0, 3).forEach((s) => (s.keeper = true));

      let keepSlotL = 0, keepSlotR = 0;
      for (const s of shards) {
        let dx = s.cx - P[0], dy = s.cy - P[1];
        const dl = Math.hypot(dx, dy);
        if (dl < 6) { dx = rand(-1, 1); dy = -1; }
        const ux = dx / (Math.hypot(dx, dy) || 1), uy = dy / (Math.hypot(dx, dy) || 1);
        const sg = side(s);
        let v;
        if (s.keeper) {
          // land in staggered slots around the friend, 2–3 bounces
          const slot = sg < 0 ? keepSlotL++ : keepSlotR++;
          const reach = [215, 150, 285][slot % 3] + rand(-15, 15);
          v = { vx: sg * reach * rand(0.5, 0.65), vy: -rand(520, 760), maxB: 3 };
        } else if (s.inner) {
          // the middle pieces get out of the friend's way fast
          v = { vx: (ux || sg) * rand(380, 560) + sg * 120, vy: -rand(650, 950) + uy * 150, maxB: 2 };
        } else if (uy < -0.55) {
          // top of the shell rockets up and away
          v = { vx: (ux * 260) + sg * rand(140, 260), vy: -rand(900, 1150), maxB: 2 };
        } else {
          v = { vx: sg * rand(360, 600), vy: -rand(380, 760) + uy * 200, maxB: 2 };
        }
        v.w = Math.sign(v.vx || 1) * rand(s.keeper ? 360 : 500, s.keeper ? 720 : 1100);
        s.v = v;

        // front layer if the path stays clear of the friend; otherwise back
        const fromBox = 0.38; // s after release
        let sim = simulate(s, v, Math.max(rand(52, 70), s.y0 + 30), rand);
        s.layer = ctx.front;
        if (crossesBox(sim.frames, s.r, fromBox) || (sim.resting && Math.abs(sim.X) - s.r < 82)) {
          sim = simulate(s, v, Math.max(rand(-15, 36), s.y0 + lowest(s.pts, 0) + 4), rand);
          s.layer = ctx.back;
        }
        s.sim = sim;
        s.stay = sim.resting && !sim.out && Math.abs(sim.X) + s.r < 250;
      }
      // too much rubble? fade the extras (non-keepers first)
      let stayers = shards.filter((s) => s.stay).sort((a, b) => (b.keeper ? 1 : 0) - (a.keeper ? 1 : 0));
      stayers.slice(7).forEach((s) => (s.stay = false));

      // shadows first (so shards draw on top), then shards; back pieces under front ones
      for (const s of shards) {
        s.shadow = ctx.shadow(0, 0, Math.max(9, Math.min(28, Math.sqrt(s.area) * 0.55)), ctx.back);
        s.shadow.setAttribute('opacity', 0);
      }
      for (const s of shards) {
        s.piece = ctx.piece(s.poly, { layer: s.layer, cx: s.cx, cy: s.cy, edge: 5 });
        s.piece.wrap.style.visibility = 'hidden';
      }

      await puffAnim;

      /* 3. KABOOM */
      whole.wrap.remove();
      ctx.release();
      ctx.sfx.crack();
      ctx.sfx.whoosh();

      // smoke ring bursting outward + a ground dust ring
      for (let i = 0; i < 7; i++) {
        const a = (i / 7) * Math.PI * 2 + rand(-0.2, 0.2);
        const x = Math.cos(a) * 66, y = CENTER_Y + Math.sin(a) * 82;
        const layer = Math.abs(x) > 50 ? ctx.front : ctx.back;
        const dx = Math.cos(a) * rand(55, 85), dy = Math.sin(a) * rand(55, 85);
        driftPuff(ctx, x, y, rand(22, 28), dx, dy, layer);
        driftPuff(ctx, x + Math.cos(a + 1.6) * 16, y + Math.sin(a + 1.6) * 16, rand(13, 17), dx * 1.2, dy * 1.2, layer);
      }
      for (const sx of [-1, 1]) {
        for (let i = 0; i < 3; i++) {
          const x = sx * (30 + i * 34), y = 6 + i * 4;
          driftPuff(ctx, x, y, 14 + i * 2, sx * rand(40, 70), rand(-6, 4), Math.abs(x) > 95 ? ctx.front : ctx.back);
        }
      }

      const runs = [];
      const sounds = [];
      for (const s of shards) {
        const { frames, events, out } = s.sim;
        const total = frames[frames.length - 1].t || DT;
        const fadeFrom = s.stay ? Infinity : out ? total - 0.08 : Math.max(0.35, total - 0.32);
        const kf = [], skf = [];
        const groundY = s.sim.depth;
        frames.forEach((f, i) => {
          const keep = i % 2 === 0 || i === frames.length - 1 || f.sx !== f.sy;
          if (!keep) return;
          const offset = Math.min(1, f.t / total);
          const op = f.t <= fadeFrom ? 1 : Math.max(0, 1 - (f.t - fadeFrom) / (total - fadeFrom || 1));
          kf.push({
            offset,
            transform: `translate(${fmt(f.X - s.cx)}px,${fmt(f.Y - s.cy)}px) scale(${f.sx.toFixed(3)},${f.sy.toFixed(3)}) rotate(${fmt(f.R)}deg)`,
            opacity: op,
          });
          const h = Math.max(0, groundY - f.Y);
          const k = Math.max(0.35, 1 - h / 320);
          skf.push({ offset, transform: `translate(${fmt(f.X)}px,${fmt(groundY)}px) scale(${k.toFixed(3)})`, opacity: (0.2 * k * op).toFixed(3) });
        });
        kf[kf.length - 1].offset = 1; skf[skf.length - 1].offset = 1;
        s.piece.wrap.style.visibility = '';
        const dur = total * 1000;
        runs.push(ctx.animate(s.piece.el, kf, { duration: dur, easing: 'linear', fill: 'forwards' }).then(() => {
          if (!s.stay) s.piece.wrap.remove();
        }));
        s.shadow.removeAttribute('opacity');
        runs.push(ctx.animate(s.shadow, skf, { duration: dur, easing: 'linear', fill: 'forwards' }).then(() => {
          if (!s.stay) s.shadow.remove();
        }));
        for (const ev of events) {
          if (Math.abs(ev.X) > 270 || ev.t > fadeFrom) continue;
          sounds.push({ t: ev.t, p: Math.min(1, 0.35 + 900 / (s.area + 300)) + rand(-0.1, 0.1), big: s.area > 1400 && ev.n === 0, first: ev.n === 0, x: ev.X, y: groundY, s });
        }
      }

      // impact sounds + landing dust, thinned so it's a patter, not a din
      sounds.sort((a, b) => a.t - b.t);
      let lastT = -1, thuds = 0;
      for (const e of sounds) {
        if (e.t - lastT < 0.05) continue;
        lastT = e.t;
        ctx.wait(e.t * 1000).then(() => {
          if (e.big && thuds < 1) { thuds++; ctx.sfx.thud(0.4); } else ctx.sfx.clink(Math.max(0, Math.min(1, e.p)));
          if (e.first) {
            const front = e.y > 48 && Math.abs(e.x) > 100;
            ctx.puff(e.x, e.y - 4, 9 + Math.min(8, Math.sqrt(e.s.area) * 0.12), front ? ctx.front : ctx.back);
          }
        });
      }

      await Promise.all(runs);
    },
  });

  /** prefers-reduced-motion: a soft pop — shards nudge outward and fade. */
  async function reduced(ctx, polys, stats, P) {
    const pieces = polys.map((pts, i) => ({ s: stats[i], p: ctx.piece(pts, { cx: stats[i].cx, cy: stats[i].cy }) }));
    ctx.release();
    ctx.sfx.crack();
    await Promise.all(pieces.map(({ s, p }) => {
      const dx = s.cx - P[0], dy = s.cy - P[1], l = Math.hypot(dx, dy) || 1;
      return ctx.animate(p.el, [
        { transform: 'translate(0px,0px) scale(1)', opacity: 1 },
        { transform: `translate(${fmt((dx / l) * 8)}px,${fmt((dy / l) * 8)}px) scale(.92)`, opacity: 0 },
      ], { duration: 300, easing: 'ease-out', fill: 'forwards' }).then(() => p.wrap.remove());
    }));
  }
})();

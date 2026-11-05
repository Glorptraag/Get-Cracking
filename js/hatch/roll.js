/* Get Cracking — shell effect "Roll away".
 *
 * Cartoon physics: the lid pops straight up with a spin, lands dome-down,
 * rocks like a bowl and then trundles off to the left. The bottom cup splits
 * down a jagged crack; the halves flop open like petals, bounce, and roll
 * away like wheels (rotation = distance / radius). The left half rolls off
 * screen, the right half teeters to a stop face-down near the edge. A few
 * chips rattle to rest on the ground.
 *
 * Rolling height comes from each piece's real outline: for every rotation we
 * find the lowest point of the piece, so the non-round halves bob and bump
 * naturally as their corners come round.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const PI = Math.PI;
  const D2R = PI / 180;

  /* ── geometry ───────────────────────────────────────────────────────── */

  // the egg outline (matches EGG_PATH) as cubic segments
  const EGG_SEGS = [
    [[0, -170], [40, -170], [64, -96], [64, -58]],
    [[64, -58], [64, -20], [36, 0], [0, 0]],
    [[0, 0], [-36, 0], [-64, -20], [-64, -58]],
    [[-64, -58], [-64, -96], [-40, -170], [0, -170]],
  ];
  let OUTLINE = null;
  function outline() {
    if (OUTLINE) return OUTLINE;
    OUTLINE = [];
    for (const [a, b, c, d] of EGG_SEGS) {
      for (let i = 0; i < 20; i++) {
        const u = i / 20, v = 1 - u;
        const k0 = v * v * v, k1 = 3 * v * v * u, k2 = 3 * v * u * u, k3 = u * u * u;
        OUTLINE.push([k0 * a[0] + k1 * b[0] + k2 * c[0] + k3 * d[0], k0 * a[1] + k1 * b[1] + k2 * c[1] + k3 * d[1]]);
      }
    }
    return OUTLINE;
  }

  function inside(poly, x, y) {
    let c = false;
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      const [xi, yi] = poly[i], [xj, yj] = poly[j];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
    }
    return c;
  }

  /** the visible region of a piece (egg ∩ polygon): boundary points + area centroid */
  function region(poly) {
    const egg = outline();
    const pts = egg.filter(([x, y]) => inside(poly, x, y));
    for (let i = 0; i < poly.length; i++) {
      const a = poly[i], b = poly[(i + 1) % poly.length];
      const n = Math.max(1, Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1]) / 5));
      for (let k = 0; k <= n; k++) {
        const x = a[0] + ((b[0] - a[0]) * k) / n, y = a[1] + ((b[1] - a[1]) * k) / n;
        if (inside(egg, x, y)) pts.push([x, y]);
      }
    }
    let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
    for (const [x, y] of pts) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
    let sx = 0, sy = 0, n = 0;
    // a 6 px grid is plenty for a centroid and keeps the break frame cheap on phones
    for (let y = y0; y <= y1; y += 6) for (let x = x0; x <= x1; x += 6) {
      if (inside(egg, x, y) && inside(poly, x, y)) { sx += x; sy += y; n++; }
    }
    return { pts, cx: n ? sx / n : (x0 + x1) / 2, cy: n ? sy / n : (y0 + y1) / 2, w: x1 - x0, h: y1 - y0 };
  }

  /** lowest point of region R (relative to its centroid) when rotated by deg */
  function low(R, deg) {
    const s = Math.sin(deg * D2R), c = Math.cos(deg * D2R);
    let m = -Infinity;
    for (const [px, py] of R.pts) {
      const dx = px - R.cx, dy = py - R.cy;
      const y = dx * s + dy * c;
      if (y > m) m = y;
    }
    return m;
  }

  /* ── motion helpers ─────────────────────────────────────────────────── */

  const f1 = (v) => (+v).toFixed(1);
  const f3 = (v) => (+v).toFixed(3);
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const lerp = (a, b, u) => a + (b - a) * u;
  /** 0 → 1 as v goes from a to b */
  const ramp = (v, a, b) => clamp((v - a) / (b - a), 0, 1);
  /** parabolic hops: [{ t, d, h }] → upward offset (positive = up) */
  function hops(list, t) {
    let up = 0;
    for (const hp of list) {
      const u = (t - hp.t) / hp.d;
      if (u > 0 && u < 1) up += hp.h * 4 * u * (1 - u);
    }
    return up;
  }
  /** squash on impacts: [{ t, a }] → amount 0..a */
  function squash(list, t) {
    let k = 0;
    for (const im of list) {
      const tau = t - im.t;
      if (tau >= 0 && tau < 170) k = Math.max(k, im.a * Math.sin((PI * tau) / 170) * (1 - tau / 340));
    }
    return k;
  }
  /** cubic Hermite from (p0, slope m0) to (p1, slope m1) over duration D */
  function hermite(p0, m0, p1, m1, D, tau) {
    const s = clamp(tau / D, 0, 1), s2 = s * s, s3 = s2 * s;
    return (2 * s3 - 3 * s2 + 1) * p0 + (s3 - 2 * s2 + s) * D * m0 + (-2 * s3 + 3 * s2) * p1 + (s3 - s2) * D * m1;
  }

  /**
   * Animate a piece along a sampled path. fn(t) → { x, y, r, sq?, o?, air? }
   * x, y = centroid position; r = rotation (deg); sq = squash amount (0 = none),
   * applied in world space and anchored to the piece's lowest point.
   * If `shadow` is given it follows on the ground at depth g.
   */
  function track(ctx, pc, R, dur, fn, shadow, g, rx) {
    const n = Math.max(2, Math.round(dur / 14));
    const kf = [], sk = [];
    for (let i = 0; i <= n; i++) {
      const t = (dur * i) / n;
      const s = fn(t);
      const q = s.sq || 0;
      const sx = 1 + q * 0.8, sy = 1 - q;
      const lo = low(R, s.r);
      const y = s.y + (1 - sy) * lo; // keep the bottom planted while squashing
      kf.push({
        offset: i / n,
        transform: `translate(${f1(s.x - R.cx)}px,${f1(y - R.cy)}px) scale(${f3(sx)},${f3(sy)}) rotate(${f1(s.r)}deg)`,
        opacity: f3(s.o == null ? 1 : s.o),
      });
      if (shadow) {
        const air = Math.max(0, g - (s.y + lo));
        const k = clamp(1 - air / 260, 0.3, 1);
        sk.push({
          offset: i / n,
          transform: `translate(${f1(s.x)}px,${f1(g)}px) scale(${f3(k * (1 + q * 0.5))})`,
          opacity: f3(0.18 * (s.o == null ? 1 : s.o) * k * (s.so == null ? 1 : s.so)),
        });
      }
    }
    const opts = { duration: dur, easing: 'linear', fill: 'forwards' };
    const ps = [ctx.animate(pc.el, kf, opts)];
    if (shadow) ps.push(ctx.animate(shadow, sk, opts));
    return Promise.all(ps);
  }

  function later(ctx, ms, f) { ctx.wait(ms).then(f); }

  /* ── the effect ─────────────────────────────────────────────────────── */

  GC.ShellFX.register({
    id: 'roll',
    name: 'Roll away',
    icon: '🛞',

    async run(ctx) {
      const ZIG = ctx.ZIG;
      const zi = 4; // the zig point the vertical crack starts from
      const top = ZIG[zi];
      const CRACK = [top, [7, -62], [-5, -50], [6, -37], [-4, -24], [4, -12], [-2, 0], [0, 24]];

      const lidPoly = [[-100, -240], [100, -240], [100, ZIG[ZIG.length - 1][1]], ...ZIG.slice().reverse(), [-100, ZIG[0][1]]];
      const leftPoly = [[-100, ZIG[0][1]], ...ZIG.slice(0, zi), ...CRACK, [-100, 24]];
      const rightPoly = [...ZIG.slice(zi + 1), [100, ZIG[ZIG.length - 1][1]], [100, 24], ...CRACK.slice().reverse()];

      const Rl = region(lidPoly), RL = region(leftPoly), RR = region(rightPoly);

      /* reduced motion: the halves just ease apart and fade, ≤ 400 ms */
      if (ctx.reduce) {
        const lid = ctx.piece(lidPoly, { layer: ctx.back, cx: Rl.cx, cy: Rl.cy });
        const L = ctx.piece(leftPoly, { cx: RL.cx, cy: RL.cy });
        const Rt = ctx.piece(rightPoly, { cx: RR.cx, cy: RR.cy });
        ctx.release();
        const o = { duration: 350, easing: 'ease-out', fill: 'forwards' };
        await Promise.all([
          ctx.animate(lid.el, [{ transform: 'translate(0px,0px)', opacity: 1 }, { transform: 'translate(0px,-24px)', opacity: 0 }], o),
          ctx.animate(L.el, [{ transform: 'translate(0px,0px) rotate(0deg)', opacity: 1 }, { transform: 'translate(-40px,0px) rotate(-10deg)', opacity: 0 }], o),
          ctx.animate(Rt.el, [{ transform: 'translate(0px,0px) rotate(0deg)', opacity: 1 }, { transform: 'translate(40px,0px) rotate(10deg)', opacity: 0 }], o),
        ]);
        return;
      }

      // shadows first so they sit underneath everything in the back layer
      const shLid = ctx.shadow(0, 0, 52, ctx.back);
      const shL = ctx.shadow(0, 0, 34, ctx.back);
      const shR = ctx.shadow(0, 0, 34, ctx.back);
      for (const s of [shLid, shL, shR]) s.style.opacity = 0;

      // the lid lives behind the friend from the start; the halves cover the
      // friend's first peek, then step back once it's out
      const lid = ctx.piece(lidPoly, { layer: ctx.back, cx: Rl.cx, cy: Rl.cy });
      const L = ctx.piece(leftPoly, { cx: RL.cx, cy: RL.cy });
      const Rt = ctx.piece(rightPoly, { cx: RR.cx, cy: RR.cy });

      const sfx = ctx.sfx;
      sfx.whoosh();
      ctx.release();
      later(ctx, 260, () => { ctx.back.appendChild(L.wrap); ctx.back.appendChild(Rt.wrap); });

      const jobs = [];

      /* ── lid: pop, spin, land dome-down, rock, roll off left ── */
      {
        const R = Rl;
        const g = 22;               // landing depth
        const T1 = 640;             // touchdown
        const X1 = -128;            // touchdown x
        const RE = -540;            // end spin: dome-down
        const yE = g - low(R, RE);
        const T2 = T1 + 760;        // rocking done
        const ROCK = 32, PER = 260, RAD = 38;
        const rockAt = (tau) => -ROCK * Math.exp(-tau / 240) * Math.sin((2 * PI * tau) / PER);
        const ROLL = 860;
        const dur = T2 + ROLL;
        const acc = (2 * 190) / (ROLL * ROLL);
        const imp = [{ t: T1, a: 0.24 }];
        const fn = (t) => {
          if (t < T1) {
            const u = t / T1;
            const x = X1 * Math.pow(u, 1.9);
            const r = RE * (1 - Math.pow(1 - u, 1.35));
            const y = lerp(R.cy, yE, u * u) - 150 * Math.sin(PI * Math.pow(u, 0.8)) * (1 - u * 0.25);
            // stretch on the way up
            const sq = -0.14 * (1 - ramp(u, 0, 0.35));
            return { x, y, r, sq, so: ramp(t, 0, 120) };
          }
          if (t < T2) {
            const phi = rockAt(t - T1);
            const r = RE + phi;
            return { x: X1 + RAD * phi * D2R, y: g - low(R, r), r, sq: squash(imp, t) };
          }
          const tau = t - T2;
          // a tiny hesitation, then it trundles off to the left
          const dx = -0.5 * acc * tau * tau - 4 * Math.sin(PI * ramp(tau, 0, 160));
          const x = X1 + RAD * rockAt(T2 - T1) * D2R + dx;
          const r = RE + rockAt(T2 - T1) + (dx / RAD) / D2R;
          const o = 1 - ramp(x, -205, -262);
          return { x, y: g - low(R, r), r, o };
        };
        jobs.push(track(ctx, lid, R, dur, fn, shLid, g, 52));
        later(ctx, T1, () => { sfx.thud(0.35); ctx.puff(X1 - 40, g, 16, ctx.back); ctx.puff(X1 + 44, g, 13, ctx.back); });
        for (let i = 1; i <= 3; i++) later(ctx, T1 + i * PER * 0.5 + 40, () => sfx.clink(0.25 + 0.05 * i));
      }

      /* ── halves: flop open like petals, bounce, roll like wheels ── */
      const TT = 250; // petal lands on its back
      const half = (pc, R, dir) => {
        const g = R.cy + low(R, 0); // resting depth == where it stands now
        const RAD = dir < 0 ? 38 : 33;
        const imp = [{ t: TT, a: 0.22 }];
        const bump = dir < 0
          ? [{ t: TT, d: 190, h: 16 }, { t: 470, d: 120, h: 9 }, { t: 640, d: 90, h: 5 }]
          : [{ t: TT, d: 190, h: 14 }, { t: 520, d: 120, h: 7 }];
        let ang, dur, fade;
        if (dir < 0) {
          // keeps rolling until it's gone off the left
          dur = 980;
          ang = (t) => (t < TT ? -90 * (t / TT) * (t / TT) : -90 - 0.58 * (t - TT) - 0.00034 * (t - TT) * (t - TT));
          fade = (x) => 1 - ramp(x, -215, -270);
        } else {
          // rolls right, slows, teeters to rest face-down near the edge
          const D = 700, SET = 720, END = 270, OVER = 15;
          dur = TT + D + SET;
          ang = (t) => {
            if (t < TT) return 90 * (t / TT) * (t / TT);
            const tau = t - TT;
            if (tau < D) return hermite(90, 0.55, END + OVER, 0, D, tau);
            const s = tau - D;
            return END + OVER * Math.exp(-s / 170) * Math.cos((2 * PI * s) / 250);
          };
          fade = () => 1;
        }
        const x0 = R.cx;
        const fn = (t) => {
          const r = ang(t);
          const x = x0 + RAD * r * D2R;
          return { x, y: g - low(R, r) - hops(bump, t), r, sq: squash(imp, t), o: fade(x) };
        };
        const sh = dir < 0 ? shL : shR;
        jobs.push(track(ctx, pc, R, dur, fn, sh, g, 34));
        later(ctx, TT, () => { sfx.thud(dir < 0 ? 0.55 : 0.6); ctx.puff(x0 + dir * 42, g + 2, 15, ctx.back); });
        for (const b of bump.slice(1)) later(ctx, b.t + b.d, () => { sfx.clink(dir < 0 ? 0.5 : 0.65); ctx.puff(fn(b.t + b.d).x - dir * 18, g + 2, 9, ctx.back); });
        if (dir > 0) for (const s of [TT + 700 + 120, TT + 700 + 250]) later(ctx, s, () => sfx.clink(0.8));
      };
      half(L, RL, -1);
      half(Rt, RR, +1);

      /* ── chips: a few crumbs rattle down beside the friend ── */
      const CHIPS = [
        { at: [-44, -84], to: -98, g: 30, t: 380, h: 70, spin: -420 },
        { at: [-18, -84], to: -150, g: 40, t: 460, h: 95, spin: -300 },
        { at: [22, -86], to: 104, g: 34, t: 420, h: 85, spin: 380 },
        { at: [48, -82], to: 158, g: 18, t: 480, h: 60, spin: 520 },
        { at: [2, -40], to: 84, g: 52, t: 360, h: 50, spin: 260 },
      ];
      CHIPS.forEach((c, i) => {
        const [ax, ay] = c.at;
        const s = 7 + (i % 3) * 2;
        const poly = [[ax - s, ay - s * 0.6], [ax + s, ay - s * 0.4], [ax + s * 0.3, ay + s * 0.9], [ax - s * 0.7, ay + s * 0.5]];
        const R = region(poly);
        if (R.pts.length < 3) return;
        const pc = ctx.piece(poly, { layer: ctx.back, edge: 3, cx: R.cx, cy: R.cy });
        pc.el.style.opacity = 0;
        const start = 30 + i * 18;
        const yE = c.g - low(R, c.spin);
        const rattle = [{ t: c.t, d: 150, h: 12 }, { t: c.t + 150, d: 90, h: 5 }, { t: c.t + 240, d: 60, h: 2 }];
        const fn = (t) => {
          if (t < c.t) {
            const u = t / c.t;
            return { x: lerp(R.cx, c.to, u), y: lerp(R.cy, yE, u) - c.h * 4 * u * (1 - u), r: c.spin * u, o: 1 };
          }
          const tau = t - c.t;
          const r = c.spin + 18 * Math.exp(-tau / 120) * Math.sin(tau / 22);
          return { x: c.to + Math.sign(c.to) * 10 * (1 - Math.exp(-tau / 120)), y: c.g - low(R, r) - hops(rattle, t), r, o: 1 };
        };
        later(ctx, start, () => {
          pc.el.style.opacity = '';
          track(ctx, pc, R, c.t + 420, fn);
        });
        later(ctx, start + c.t, () => sfx.clink(0.7 + 0.06 * i));
        later(ctx, start + c.t + 150, () => sfx.clink(0.85));
      });

      await Promise.all(jobs);
    },
  });
})();

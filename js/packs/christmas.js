/* Get Cracking — Christmas pack.
 *
 * 13 festive friends in the house style (one chunky bean, 6 px outlines, soft
 * flat colours), borrowing designs and colours from Advent Eggs, the owner's
 * advent-calendar spin-off:
 *   Christmas baking  Gingerbread Pal, Christmas Tree Cookie, Shortbread Star, Christmas Pudding
 *   The Nutcracker    Nutcracker, Sugar Plum Fairy, Mouse King, Snowflake Fairy
 *   Christmas Eve     Angel, Reindeer, Robin, Snowman, Christmas Beetle (an Aussie Christmas)
 * The cookies keep the bean and dress it up: the tree's branches and the star's
 * points sit behind the bean (like the hedgehog's quills), so every friend still
 * bounces, blinks and waves like the Classic 40.
 *
 * One world (Christmas Village: snowy roofs, warm windows, fairy lights, the
 * church under the star, gifts, a mouse hole with a tiny stocking and a cellar
 * full of presents) and one Egg karaoke band (jingle: celesta lead, flute,
 * piano, walking bass, brushes, clip-clop wood block and sleigh bells on every
 * off-beat). Only SVG path / ellipse / circle / rect / polygon / g transform /
 * clipPath is used, so the iPhone port can redraw everything from the same data.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT;
  const r1 = (n) => Math.round(n * 10) / 10;

  /* ------------------------------------------------------------ helpers */
  const GOLD = '#f0b63c', HOLLY = '#3f8a5a', BERRY = '#d63b4f', WHITE = '#fdfaf3', ICING = '#fffdf8';

  /** a star polygon's points: n points, outer R, inner r, centred on (cx, cy), first point straight up */
  function starPts(cx, cy, R, r, n = 5) {
    const pts = [];
    for (let i = 0; i < n * 2; i++) {
      const a = -Math.PI / 2 + (i * Math.PI) / n, rr = i % 2 ? r : R;
      pts.push(`${r1(cx + Math.cos(a) * rr)},${r1(cy + Math.sin(a) * rr)}`);
    }
    return pts.join(' ');
  }
  /** a four-point twinkle */
  const twinkle = (x, y, r, c, sw = 3) =>
    `<path d="M${r1(x)},${r1(y - r)} Q${r1(x)},${r1(y)} ${r1(x + r)},${r1(y)} Q${r1(x)},${r1(y)} ${r1(x)},${r1(y + r)} Q${r1(x)},${r1(y)} ${r1(x - r)},${r1(y)} Q${r1(x)},${r1(y)} ${r1(x)},${r1(y - r)} Z" fill="${c}" stroke="${O}" stroke-width="${sw}" stroke-linejoin="round"/>`;
  /** a holly leaf, centred on (x, y), pointing along angle a (degrees), L long */
  function hollyLeaf(x, y, a, L, c = HOLLY) {
    const q = (u, v) => `${r1(u * L)},${r1(v * L)}`;
    return `<g transform="translate(${r1(x)} ${r1(y)}) rotate(${a})">` +
      `<path d="M${q(-1, 0)} Q${q(-0.72, -0.16)} ${q(-0.52, -0.42)} Q${q(-0.3, -0.24)} ${q(0, -0.46)} Q${q(0.3, -0.24)} ${q(0.52, -0.42)} Q${q(0.72, -0.16)} ${q(1, 0)} ` +
      `Q${q(0.72, 0.16)} ${q(0.52, 0.42)} Q${q(0.3, 0.24)} ${q(0, 0.46)} Q${q(-0.3, 0.24)} ${q(-0.52, 0.42)} Q${q(-0.72, 0.16)} ${q(-1, 0)} Z" fill="${c}" stroke="${O}" stroke-width="3.5" stroke-linejoin="round"/>` +
      `<path d="M${q(-0.7, 0)} L${q(0.7, 0)}" stroke="${GC.shade(c, 0.35)}" stroke-width="2.5" stroke-linecap="round"/></g>`;
  }
  /** a sprig: two holly leaves and three berries, centred on (x, y) */
  const holly = (x, y, s = 1, tilt = 0) => `<g transform="translate(${r1(x)} ${r1(y)}) rotate(${tilt}) scale(${s})">` +
    hollyLeaf(-12, 2, -20, 15) + hollyLeaf(12, 2, 20, 15) +
    [[0, -4], [-6.5, 3], [6.5, 3]].map(([u, v]) => `<circle cx="${u}" cy="${v}" r="5.5" fill="${BERRY}" stroke="${O}" stroke-width="3"/>`).join('') +
    `<circle cx="-1.5" cy="-5.5" r="1.6" fill="#fff" opacity=".8"/></g>`;
  /** a wavy piped-icing line through points (alternating bumps of size amp) */
  function piped(pts, amp, c = ICING, wdt = 4) {
    let d = `M${r1(pts[0][0])},${r1(pts[0][1])}`;
    for (let i = 1; i < pts.length; i++) {
      const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
      const mx = (x0 + x1) / 2, my = (y0 + y1) / 2, len = Math.hypot(x1 - x0, y1 - y0) || 1;
      const nx = -(y1 - y0) / len, ny = (x1 - x0) / len, s = i % 2 ? amp : -amp;
      d += ` Q${r1(mx + nx * s)},${r1(my + ny * s)} ${r1(x1)},${r1(y1)}`;
    }
    return `<path d="${d}" fill="none" stroke="${c}" stroke-width="${wdt}" stroke-linecap="round" stroke-linejoin="round"/>`;
  }
  /** points along a quadratic curve a → b with control c */
  const along = (a, c, b, n) => Array.from({ length: n + 1 }, (_, i) => {
    const t = i / n, u = 1 - t;
    return [u * u * a[0] + 2 * u * t * c[0] + t * t * b[0], u * u * a[1] + 2 * u * t * c[1] + t * t * b[1]];
  });
  /** points along the bean body's outline (js/animals.js bodyPath), shrunk by sc about its middle */
  function beanPts(w, h, sc, n) {
    const segs = [[[-w, -h * 0.45], [-w, -h * 1.15], [w, -h * 1.15], [w, -h * 0.45]],
      [[w, -h * 0.45], [w, -h * 0.05], [w * 0.75, 0], [0, 0]], [[0, 0], [-w * 0.75, 0], [-w, -h * 0.05], [-w, -h * 0.45]]];
    const out = [], cy = -h * 0.5;
    segs.forEach((g, j) => {
      const m = j ? Math.round(n / 4) : Math.round(n / 2);
      for (let i = j ? 1 : 0; i <= m; i++) {
        const t = i / m, u = 1 - t;
        const x = u * u * u * g[0][0] + 3 * u * u * t * g[1][0] + 3 * u * t * t * g[2][0] + t * t * t * g[3][0];
        const y = u * u * u * g[0][1] + 3 * u * u * t * g[1][1] + 3 * u * t * t * g[2][1] + t * t * t * g[3][1];
        out.push([x * sc, cy + (y - cy) * sc]);
      }
    });
    return out;
  }
  /** where the friend's face sits (same as js/animals.js) */
  const faceY = (d, h) => -h * (d.faceY || 0.56);

  /** A person's head: hair framing a skin-coloured face, with a fringe.
   * d.skin, d.hair, d.hairTo (how far down the sides the hair falls, fraction of h) */
  function personHead(d, k) {
    const { w, h, f } = k, fy = faceY(d, h);
    const cy = fy + 5, rx = w * 0.64, ry = h * 0.255;
    // fringe: the top of the face, scalloped along its lower edge
    const yE = cy - ry * 0.3, xE = rx * Math.sqrt(1 - 0.09), yS = cy - ry * 0.62, n = 5;
    let fringe = `M${f(-xE)},${f(yE)} A${f(rx)},${f(ry)} 0 0 1 ${f(xE)},${f(yE)}`;
    for (let i = 1; i <= n; i++) {
      const x = xE - (2 * xE * i) / n, y = i === n ? yE : yS + (i % 2 ? 0 : 3);
      fringe += ` Q${f(x + xE / n)},${f(yS + 13)} ${f(x)},${f(y)}`;
    }
    return `<rect x="${f(-w - 10)}" y="${f(-h * 1.3)}" width="${f(2 * w + 20)}" height="${f(h * 1.3 - h * (d.hairTo || 0.46))}" fill="${d.hair}"/>` +
      `<ellipse cx="0" cy="${f(cy)}" rx="${f(rx)}" ry="${f(ry)}" fill="${d.skin}"/>` +
      `<path d="${fringe} Z" fill="${d.hair}"/>`;
  }

  /* ------------------------------------------------------------- parts */
  const parts = {
    back: {
      /* Christmas Tree Cookie: three tiers of branches behind the bean */
      treeTiers(d, k) {
        const { w, f, S } = k, c = GC.shade(d.body, -0.07);
        const tiers = [[-10, w + 30, -86], [-56, w + 22, -132], [-100, w + 8, -176]];
        let out = '';
        for (const [by, hw, ay] of tiers) {
          out += `<path d="M${f(-hw)},${by} L0,${ay} L${f(hw)},${by} Q0,${by + 8} ${f(-hw)},${by} Z" fill="${c}" ${S}/>`;
          // icing dots and sprinkles on the tips that show
          out += k.both((s) => `<circle cx="${f(s * (hw - 12))}" cy="${by - 4}" r="3.4" fill="${ICING}"/>` +
            `<circle cx="${f(s * (hw - 26))}" cy="${by - 13}" r="3" fill="${s < 0 ? BERRY : GOLD}" stroke="${O}" stroke-width="2"/>`);
        }
        return out;
      },
      /* Shortbread Star: five rounded points behind the bean, with piped icing */
      starPoints(d, k) {
        const cx = 0, cy = -78, pts = starPts(cx, cy, 96, 50);
        const icing = starPts(cx, cy, 80, 43);
        return `<polygon points="${pts}" fill="${O}" stroke="${O}" stroke-width="22" stroke-linejoin="round"/>` +
          `<polygon points="${pts}" fill="${d.body}" stroke="${d.body}" stroke-width="10" stroke-linejoin="round"/>` +
          `<polygon points="${icing}" fill="none" stroke="${ICING}" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round" stroke-dasharray="0.5 9"/>`;
      },
      /* Christmas Pudding sits on a plate */
      plate(d, k) {
        const { w, f, S } = k;
        return `<ellipse cx="0" cy="-3" rx="${f(w + 22)}" ry="14" fill="#eef3f8" ${S}/>` +
          `<ellipse cx="0" cy="-4" rx="${f(w + 8)}" ry="8" fill="none" stroke="#c9d6e2" stroke-width="3"/>`;
      },
      /* fairy wings: a big pair and a small pair */
      fairyWings(d, k) {
        const { w, h, f, S } = k, c = d.wingColor, hi = GC.shade(c, 0.45);
        return k.both((s) => {
          const ux = s * (w + 16), uy = -h * 0.74, lx = s * (w + 8), ly = -h * 0.38;
          return `<ellipse cx="${f(ux)}" cy="${f(uy)}" rx="25" ry="38" fill="${c}" ${S} transform="rotate(${s * 32} ${f(ux)} ${f(uy)})"/>` +
            `<ellipse cx="${f(ux + s * 3)}" cy="${f(uy - 6)}" rx="11" ry="20" fill="${hi}" transform="rotate(${s * 32} ${f(ux)} ${f(uy)})"/>` +
            `<ellipse cx="${f(lx)}" cy="${f(ly)}" rx="17" ry="24" fill="${c}" ${S} transform="rotate(${s * -34} ${f(lx)} ${f(ly)})"/>`;
        });
      },
      /* Snowflake Fairy: icy, pointed crystal wings */
      iceWings(d, k) {
        const { w, h, f, S } = k, c = d.wingColor;
        return k.both((s) => {
          const x0 = s * (w - 14), y0 = -h * 0.62;
          const p = `M${f(x0)},${f(y0)} L${f(s * (w + 12))},${f(-h * 1.06)} L${f(s * (w + 36))},${f(-h * 0.88)} L${f(s * (w + 24))},${f(-h * 0.6)} ` +
            `L${f(s * (w + 34))},${f(-h * 0.36)} L${f(s * (w + 10))},${f(-h * 0.24)} Z`;
          return `<path d="${p}" fill="${c}" ${S}/>` +
            `<path d="M${f(s * (w + 2))},${f(-h * 0.64)} L${f(s * (w + 18))},${f(-h * 0.88)} M${f(s * (w + 2))},${f(-h * 0.54)} L${f(s * (w + 22))},${f(-h * 0.38)}" stroke="#fff" stroke-width="4" stroke-linecap="round"/>`;
        });
      },
      /* Angel: soft feathered wings */
      featherWings(d, k) {
        const { w, h, f, S } = k, c = d.wingColor;
        return k.both((s) => {
          const X = (v) => f(s * v);
          const p = `M${X(w - 16)},${f(-h * 0.74)} Q${X(w + 24)},${f(-h * 1.16)} ${X(w + 40)},${f(-h * 0.92)} ` +
            `Q${X(w + 42)},${f(-h * 0.8)} ${X(w + 32)},${f(-h * 0.74)} Q${X(w + 40)},${f(-h * 0.62)} ${X(w + 28)},${f(-h * 0.55)} ` +
            `Q${X(w + 33)},${f(-h * 0.42)} ${X(w + 18)},${f(-h * 0.38)} Q${X(w + 16)},${f(-h * 0.26)} ${X(w - 6)},${f(-h * 0.3)} Z`;
          return `<path d="${p}" fill="${c}" ${S}/>` +
            `<path d="M${X(w + 6)},${f(-h * 0.76)} Q${X(w + 18)},${f(-h * 0.8)} ${X(w + 28)},${f(-h * 0.75)} M${X(w + 4)},${f(-h * 0.56)} Q${X(w + 14)},${f(-h * 0.58)} ${X(w + 22)},${f(-h * 0.54)}" fill="none" stroke="${GC.shade(c, -0.18)}" stroke-width="3" stroke-linecap="round"/>`;
        });
      },
      /* a ballerina's bun on top of the head */
      bun(d, k) {
        return `<circle cx="0" cy="${k.f(-k.h * 1.0)}" r="15" fill="${d.hair}" ${k.S}/>`;
      },
      /* Mouse King's royal cape */
      cape(d, k) {
        const { w, h, f, S } = k, c = d.capeColor;
        return `<path d="M${f(-w * 0.8)},${f(-h * 0.62)} L${f(w * 0.8)},${f(-h * 0.62)} Q${f(w * 1.25)},${f(-h * 0.3)} ${f(w * 1.3)},-4 Q0,10 ${f(-w * 1.3)},-4 Q${f(-w * 1.25)},${f(-h * 0.3)} ${f(-w * 0.8)},${f(-h * 0.62)} Z" fill="${c}" ${S}/>`;
      },
      /* Reindeer antlers */
      antlers(d, k) {
        const { w, h, f, tube } = k, c = d.antlerColor;
        return k.both((s) => tube(`M${f(s * w * 0.26)},${f(-h * 0.88)} C${f(s * w * 0.3)},${f(-h * 1.16)} ${f(s * w * 0.62)},${f(-h * 1.26)} ${f(s * w * 0.96)},${f(-h * 1.36)}`, c, 9) +
          tube(`M${f(s * w * 0.4)},${f(-h * 1.12)} Q${f(s * w * 0.3)},${f(-h * 1.3)} ${f(s * w * 0.2)},${f(-h * 1.4)}`, c, 8) +
          tube(`M${f(s * w * 0.7)},${f(-h * 1.28)} Q${f(s * w * 0.72)},${f(-h * 1.42)} ${f(s * w * 0.62)},${f(-h * 1.52)}`, c, 8) +
          // the two pieces join cleanly: repaint the core over the outlines where they meet
          `<path d="M${f(s * w * 0.26)},${f(-h * 0.88)} C${f(s * w * 0.3)},${f(-h * 1.16)} ${f(s * w * 0.62)},${f(-h * 1.26)} ${f(s * w * 0.96)},${f(-h * 1.36)}" fill="none" stroke="${c}" stroke-width="9" stroke-linecap="round"/>`);
      },
      /* Robin: a little tail tipped up behind */
      robinTail(d, k) {
        const { w, h, f, S } = k;
        return `<g class="c-tail"><path d="M${f(w * 0.55)},${f(-h * 0.14)} L${f(w + 18)},${f(-h * 0.6)} Q${f(w + 34)},${f(-h * 0.6)} ${f(w + 40)},${f(-h * 0.42)} L${f(w * 0.75)},${f(-h * 0.04)} Z" fill="${GC.shade(d.body, -0.12)}" ${S}/></g>`;
      },
      /* Christmas Beetle: short antennae with little fan-shaped clubs */
      fanAntennae(d, k) {
        const { w, h, f, S4 } = k, c = d.antennaColor;
        return k.both((s) => {
          const x = s * w * 0.86, y = -h * 1.2;
          return `<path d="M${f(s * w * 0.4)},${f(-h * 0.9)} Q${f(s * w * 0.5)},${f(-h * 1.14)} ${f(x)},${f(y)}" fill="none" stroke="${O}" stroke-width="5" stroke-linecap="round"/>` +
            [-40, 0, 40].map((a) => `<ellipse cx="${f(x + s * 2)}" cy="${f(y - 7)}" rx="4.5" ry="9" fill="${c}" ${S4} transform="rotate(${s * 30 + a} ${f(x)} ${f(y)})"/>`).join('');
        });
      },
    },

    marks: {
      /* Gingerbread Pal: a piped icing hairline */
      gingerIcing(d, k) {
        const { w, h } = k;
        return piped(beanPts(w, h, 0.86, 44), 2.6, ICING, 3.6);
      },
      /* Christmas Tree Cookie: icing garlands and sprinkles */
      treeIcing(d, k) {
        const { w, h, f } = k;
        const g1 = piped(along([-w * 1.05, -h * 0.3], [0, -h * 0.06], [w * 1.05, -h * 0.3], 10), 2.6);
        const g2 = piped(along([-w * 0.8, -h * 0.84], [0, -h * 0.68], [w * 0.8, -h * 0.84], 8), 2.6);
        const spr = [[-0.62, 0.17, BERRY], [0.58, 0.15, GOLD], [-0.18, 0.08, '#6fb3c9'], [0.24, 0.24, '#f2a0b8'], [-0.84, 0.5, GOLD], [0.84, 0.56, BERRY],
          [-0.3, 0.95, '#f2a0b8'], [0.34, 0.97, '#6fb3c9'], [0.02, 1.02, GOLD]];
        return g1 + g2 + spr.map(([x, y, c], i) => `<ellipse cx="${f(x * w)}" cy="${f(-y * h)}" rx="2.4" ry="5" fill="${c}" transform="rotate(${(i * 47) % 180 - 90} ${f(x * w)} ${f(-y * h)})"/>`).join('');
      },
      /* Shortbread Star: sugar sparkles baked on */
      sugar(d, k) {
        const { w, h, f } = k;
        return [[-0.62, 0.3], [0.6, 0.32], [-0.2, 0.14], [0.26, 0.2], [-0.72, 0.7], [0.74, 0.74], [-0.3, 0.96], [0.32, 0.94], [0, 0.32], [-0.5, 0.88], [0.52, 0.86]]
          .map(([x, y]) => `<circle cx="${f(x * w)}" cy="${f(-y * h)}" r="2.3" fill="${ICING}" opacity=".9"/>`).join('');
      },
      /* Christmas Pudding: custard poured over the top, and currants */
      custard(d, k) {
        const { w, h, f } = k;
        const top = -h * 0.8, drips = [[-w - 6, 0], [-w * 0.72, 14], [-w * 0.42, 4], [-w * 0.12, 12], [w * 0.2, 2], [w * 0.5, 15], [w * 0.8, 3], [w + 6, 8]];
        let p = `M${f(-w - 8)},${f(-h * 1.3)} L${f(-w - 8)},${f(top)}`;
        for (let i = 1; i < drips.length; i++) {
          const [x0] = drips[i - 1], [x1, dp] = drips[i];
          p += ` Q${f((x0 + x1) / 2)},${f(top + dp * 1.6)} ${f(x1)},${f(top + (i % 2 ? 2 : -2))}`;
        }
        p += ` L${f(w + 8)},${f(-h * 1.3)} Z`;
        const currants = [[-0.76, 0.3], [0.72, 0.28], [-0.34, 0.13], [0.38, 0.12], [0, 0.26], [-0.86, 0.56], [0.88, 0.6], [-0.56, 0.1], [0.6, 0.48]];
        return currants.map(([x, y], i) => `<ellipse cx="${f(x * w)}" cy="${f(-y * h)}" rx="4.5" ry="3.4" fill="#3a1f18" transform="rotate(${i * 37} ${f(x * w)} ${f(-y * h)})"/>`).join('') +
          `<path d="${p}" fill="#fdf3d0"/>` +
          `<path d="M${f(-w * 0.55)},${f(-h * 0.94)} Q${f(-w * 0.3)},${f(-h * 1.04)} 0,${f(-h * 1.02)}" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>`;
      },
      /* Nutcracker: white hair, painted face, chin-strap beard, belt, white trousers */
      nutcracker(d, k) {
        const { w, h, f } = k, fy = faceY(d, h);
        const hair = '#f5f0e6';
        return `<rect x="${f(-w - 10)}" y="${f(-h * 1.3)}" width="${f(2 * w + 20)}" height="${f(h * 0.68)}" fill="${hair}"/>` +
          k.both((s) => `<circle cx="${f(s * (w - 2))}" cy="${f(-h * 0.66)}" r="17" fill="${hair}"/>`) +
          `<ellipse cx="0" cy="${f(fy + 2)}" rx="${f(w * 0.68)}" ry="29" fill="${d.skin}"/>` +
          `<path d="M${f(-w * 0.74)},${f(fy - 8)} Q${f(-w * 0.8)},${f(fy + 36)} 0,${f(fy + 40)} Q${f(w * 0.8)},${f(fy + 36)} ${f(w * 0.74)},${f(fy - 8)} ` +
          `L${f(w * 0.56)},${f(fy - 2)} Q${f(w * 0.5)},${f(fy + 26)} 0,${f(fy + 28)} Q${f(-w * 0.5)},${f(fy + 26)} ${f(-w * 0.56)},${f(fy - 2)} Z" fill="${hair}"/>` +
          `<rect x="${f(-w - 10)}" y="${f(-h * 0.21)}" width="${f(2 * w + 20)}" height="${f(h * 0.21 + 4)}" fill="${hair}"/>` +
          `<rect x="${f(-w - 10)}" y="${f(-h * 0.29)}" width="${f(2 * w + 20)}" height="12" fill="#2d2a3a"/>` +
          `<rect x="-8" y="${f(-h * 0.29 - 2)}" width="16" height="16" rx="3" fill="${GOLD}" stroke="${O}" stroke-width="3"/>`;
      },
      /* hair and a face, for the people */
      person(d, k) { return personHead(d, k); },
      /* a tutu at the waist */
      tutu(d, k) {
        const { w, h, f } = k, y0 = -h * 0.32, y1 = -h * 0.15, n = 7;
        let p = `M${f(-w - 6)},${f(y0)} L${f(w + 6)},${f(y0)} L${f(w + 6)},${f(y1)}`;
        for (let i = 1; i <= n; i++) {
          const x = w + 6 - ((2 * w + 12) * i) / n;
          p += ` Q${f(x + (w + 6) / n)},${f(y1 + 12)} ${f(x)},${f(y1)}`;
        }
        return `<path d="${p} Z" fill="${d.tutu}"/>` +
          `<path d="M${f(-w - 6)},${f(y0)} L${f(w + 6)},${f(y0)}" stroke="${GC.shade(d.tutu, -0.2)}" stroke-width="3"/>` +
          [-0.6, -0.2, 0.2, 0.6].map((x, i) => (d.tutuFlakes ? flake(x * w, (y0 + y1) / 2 + 1, 5.5, '#fff', 2.2) : `<circle cx="${f(x * w)}" cy="${f((y0 + y1) / 2 + (i % 2) * 3)}" r="2.6" fill="#fff" opacity=".85"/>`)).join('');
      },
      /* Angel: a gold hem on the robe */
      hem(d, k) {
        const { w, h, f } = k;
        return `<path d="M${f(-w - 6)},${f(-h * 0.13)} Q0,${f(-h * 0.06)} ${f(w + 6)},${f(-h * 0.13)} L${f(w + 6)},4 L${f(-w - 6)},4 Z" fill="${GOLD}"/>` +
          `<path d="M${f(-w - 6)},${f(-h * 0.09)} Q0,${f(-h * 0.02)} ${f(w + 6)},${f(-h * 0.09)}" fill="none" stroke="#fff3c0" stroke-width="2.5" stroke-dasharray="0.5 7" stroke-linecap="round"/>`;
      },
      /* Robin: the orange-red breast and face, edged in soft grey */
      robin(d, k) {
        const { w, h, f } = k;
        return `<ellipse cx="0" cy="${f(-h * 0.47)}" rx="${f(w * 0.74)}" ry="${f(h * 0.37)}" fill="none" stroke="#b9c2cc" stroke-width="8"/>` +
          `<ellipse cx="0" cy="${f(-h * 0.47)}" rx="${f(w * 0.74)}" ry="${f(h * 0.37)}" fill="${d.breast}"/>` +
          `<ellipse cx="0" cy="${f(-h * 0.04)}" rx="${f(w * 0.6)}" ry="${f(h * 0.17)}" fill="#f6efe6"/>`;
      },
      /* Snowman: a soft blue shadow on the snowball */
      snowShade(d, k) {
        const { w, h, f } = k;
        return `<ellipse cx="${f(w * 0.2)}" cy="${f(-h * 0.44)}" rx="${f(w * 1.05)}" ry="${f(h * 0.52)}" fill="#dde9f3"/>` +
          `<ellipse cx="${f(-w * 0.06)}" cy="${f(-h * 0.52)}" rx="${f(w * 1.02)}" ry="${f(h * 0.5)}" fill="${d.body}"/>`;
      },
      /* Christmas Beetle: a shiny green-gold head plate, wing-case seam and ribs */
      beetle(d, k) {
        const { w, h, f } = k, m = GC.shade(d.body, -0.18);
        return `<ellipse cx="0" cy="${f(-h * 1.06)}" rx="${f(w * 0.86)}" ry="${f(h * 0.25)}" fill="${d.capColor}"/>` +
          `<ellipse cx="${f(-w * 0.32)}" cy="${f(-h * 0.92)}" rx="14" ry="5" fill="#fff" opacity=".45" transform="rotate(-18 ${f(-w * 0.32)} ${f(-h * 0.92)})"/>` +
          k.both((s) => `<path d="M${f(s * w * 0.86)},${f(-h * 0.76)} Q${f(s * w * 1.0)},${f(-h * 0.4)} ${f(s * w * 0.74)},${f(-h * 0.08)}" fill="none" stroke="${m}" stroke-width="3.5" stroke-linecap="round"/>` +
            `<path d="M${f(s * w * 0.72)},${f(-h * 0.84)} Q${f(s * w * 0.82)},${f(-h * 0.7)} ${f(s * w * 0.84)},${f(-h * 0.56)}" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="5" stroke-linecap="round"/>`);
      },
    },

    mouth: {
      /* a white piped icing smile */
      icingSmile(d, k) {
        const fy = faceY(d, k.h), my = fy + 15;
        const p = `M-10,${r1(my)} Q0,${r1(my + 10)} 10,${r1(my)}`;
        return `<path d="${p}" fill="none" stroke="${O}" stroke-width="9" stroke-linecap="round"/><path d="${p}" fill="none" stroke="${ICING}" stroke-width="4" stroke-linecap="round"/>`;
      },
      /* the Nutcracker's big toothy grin */
      nutGrin(d, k) {
        const fy = faceY(d, k.h), my = fy + 15;
        const p = `M-12,${r1(my - 3)} L12,${r1(my - 3)} Q12,${r1(my + 10)} 0,${r1(my + 10)} Q-12,${r1(my + 10)} -12,${r1(my - 3)} Z`;
        return `<path d="${p}" fill="#8c2f3a"/><rect x="-11" y="${r1(my - 3)}" width="22" height="5.5" fill="#fff"/>` +
          `<path d="M-4,${r1(my - 3)} L-4,${r1(my + 2.5)} M4,${r1(my - 3)} L4,${r1(my + 2.5)}" stroke="${O}" stroke-width="2"/>` +
          `<path d="${p}" fill="none" ${k.S4}/>`;
      },
      /* Snowman: a smile of little coals */
      coal(d, k) {
        const fy = faceY(d, k.h), my = fy + 19;
        return [-12, -6, 0, 6, 12].map((x) => `<circle cx="${x}" cy="${r1(my + 5 * (1 - (x / 12) ** 2))}" r="2.8" fill="${O}"/>`).join('');
      },
    },

    nose: {
      /* Snowman's carrot */
      carrot(d, k) {
        const fy = faceY(d, k.h), y = fy + 8;
        return `<path d="M-3,${r1(y - 4)} Q2,${r1(y - 6)} 4,${r1(y - 3)} L27,${r1(y + 5)} L3,${r1(y + 5)} Q-4,${r1(y + 3)} -3,${r1(y - 4)} Z" fill="#f29a3c" ${k.S4}/>` +
          `<path d="M9,${r1(y - 1)} L10,${r1(y + 3)} M16,${r1(y + 1)} L16.5,${r1(y + 4)}" stroke="${O}" stroke-width="2" stroke-linecap="round"/>`;
      },
    },

    arms: {
      /* Gingerbread Pal: stubby cookie arms out to the sides, iced at the ends */
      gingerArms(d, k) {
        const { w, h, f, S } = k, c = d.body;
        return k.both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}"><g transform="translate(${f(s * (w + 1))} ${f(-h * 0.3)}) rotate(${s * -48})">` +
          `<ellipse cx="0" cy="0" rx="13" ry="20" fill="${c}" ${S}/>` +
          piped([[-8, 8], [-4, 8], [0, 8], [4, 8], [8, 8]], 3, ICING, 3.2) + `</g></g>`);
      },
      /* holds a wand in the right hand; the left one waves */
      wand(d, k) {
        const { w, h, f, S, tube } = k, c = d.armColor || GC.shade(d.body, -0.06);
        const arm = (s) => `<ellipse cx="${f(s * (w - 9))}" cy="${f(-h * 0.3)}" rx="11" ry="14" fill="${c}" ${S} transform="rotate(${s * -25} ${f(s * (w - 9))} ${f(-h * 0.3)})"/>`;
        const tip = [w + 24, -h * 0.86];
        const top = d.wandTop === 'flake' ? flake(tip[0], tip[1], 15, '#fff', 4.5) :
          `<polygon points="${starPts(tip[0], tip[1], 16, 7.5)}" fill="${GOLD}" ${k.S4}/>`;
        return `<g class="c-arm-l">${arm(-1)}</g>` +
          `<g>${tube(`M${f(w - 4)},${f(-h * 0.36)} L${f(tip[0])},${f(tip[1])}`, '#f6e7c2', 4)}${top}${arm(1)}</g>`;
      },
      /* both hands together in front, holding something */
      hold(d, k) {
        const { h, f, S4 } = k;
        return k.both((s) => `<ellipse cx="${f(s * 20)}" cy="${f(-h * 0.29)}" rx="8" ry="9" fill="${d.skin}" ${S4}/>`);
      },
      /* Mouse King holds a sceptre */
      sceptre(d, k) {
        const { w, h, f, S, tube } = k, c = d.armColor || GC.shade(d.body, -0.06);
        const arm = (s) => `<ellipse cx="${f(s * (w - 9))}" cy="${f(-h * 0.3)}" rx="11" ry="14" fill="${c}" ${S} transform="rotate(${s * -25} ${f(s * (w - 9))} ${f(-h * 0.3)})"/>`;
        const top = [w + 14, -h * 0.82];
        return `<g class="c-arm-l">${arm(-1)}</g>` +
          `<g>${tube(`M${f(w - 8)},${f(-h * 0.2)} L${f(top[0])},${f(top[1])}`, GOLD, 5)}` +
          `<circle cx="${f(top[0])}" cy="${f(top[1])}" r="9" fill="${BERRY}" ${k.S4}/><circle cx="${f(top[0] - 3)}" cy="${f(top[1] - 3)}" r="2.5" fill="#fff" opacity=".8"/>${arm(1)}</g>`;
      },
      /* Snowman's twig arms */
      twigs(d, k) {
        const { w, h, f, tube } = k, c = '#8a5a3b';
        return k.both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}">` +
          tube(`M${f(s * (w - 8))},${f(-h * 0.48)} L${f(s * (w + 30))},${f(-h * 0.8)}`, c, 5) +
          tube(`M${f(s * (w + 16))},${f(-h * 0.68)} L${f(s * (w + 34))},${f(-h * 0.64)}`, c, 4) +
          tube(`M${f(s * (w + 30))},${f(-h * 0.8)} L${f(s * (w + 32))},${f(-h * 0.9)} M${f(s * (w + 30))},${f(-h * 0.8)} L${f(s * (w + 40))},${f(-h * 0.84)}`, c, 3.5) + `</g>`);
      },
    },

    feet: {
      /* Gingerbread Pal: cookie feet with icing zigzags */
      gingerFeet(d, k) {
        const { w, f, S } = k;
        return k.both((s) => `<g transform="translate(${f(s * w * 0.42)} -6)"><ellipse cx="0" cy="0" rx="17" ry="11" fill="${d.body}" ${S}/>` +
          piped([[-9, -1], [-4.5, -1], [0, -1], [4.5, -1], [9, -1]], 3, ICING, 3.2) + `</g>`);
      },
    },

    front: {
      /* a gold star held in front (the 'hold' arms are drawn over it) */
      heldStar(d, k) { const y = -k.h * 0.3; return `<polygon points="${starPts(0, y - 2, 18, 8.5)}" fill="${GOLD}" ${k.S4}/><circle cx="-4" cy="${r1(y - 6)}" r="2.4" fill="#fff" opacity=".8"/>`; },
      /* Christmas Beetle: a middle pair of legs */
      midLegs(d, k) {
        const { w, h, f, tube } = k;
        return k.both((s) => tube(`M${f(s * (w - 6))},${f(-h * 0.5)} L${f(s * (w + 12))},${f(-h * 0.46)} L${f(s * (w + 16))},${f(-h * 0.36)}`, d.armColor, 5));
      },
      /* Gingerbread Pal: three gumdrop buttons */
      gumdrops(d, k) {
        const { h, f, S4 } = k;
        return [[BERRY, 0.27], [HOLLY, 0.14]].map(([c, y]) => `<path d="M-7.5,${f(-h * y + 5)} Q-8,${f(-h * y - 8)} 0,${f(-h * y - 8)} Q8,${f(-h * y - 8)} 7.5,${f(-h * y + 5)} Q0,${f(-h * y + 7)} -7.5,${f(-h * y + 5)} Z" fill="${c}" ${S4}/>` +
          `<circle cx="-2.5" cy="${f(-h * y - 3)}" r="1.4" fill="#fff" opacity=".8"/><circle cx="2.5" cy="${f(-h * y + 1)}" r="1.2" fill="#fff" opacity=".8"/>`).join('');
      },
      /* Reindeer: a red harness with jingle bells */
      bellCollar(d, k) {
        const { w, h, f, tube } = k;
        const a = [-w * 0.84, -h * 0.34], c = [0, -h * 0.12], b = [w * 0.84, -h * 0.34];
        const pts = along(a, c, b, 8);
        return tube(`M${f(a[0])},${f(a[1])} Q${f(c[0])},${f(c[1])} ${f(b[0])},${f(b[1])}`, '#d6423f', 8) +
          [2, 4, 6].map((i) => { const [x, y] = pts[i]; return bell(x, y + 7, 7.5); }).join('');
      },
      /* Snowman: a red knitted scarf with a dangling end */
      scarf(d, k) {
        const { w, h, f, S } = k, c = '#e8604f', st = '#fdfaf3';
        const p = `M${f(-w * 0.95)},${f(-h * 0.4)} Q0,${f(-h * 0.22)} ${f(w * 0.95)},${f(-h * 0.4)} L${f(w * 0.98)},${f(-h * 0.29)} Q0,${f(-h * 0.1)} ${f(-w * 0.98)},${f(-h * 0.29)} Z`;
        const tail = `M${f(w * 0.36)},${f(-h * 0.26)} L${f(w * 0.62)},${f(-h * 0.25)} L${f(w * 0.66)},${f(-h * 0.04)} L${f(w * 0.4)},${f(-h * 0.03)} Z`;
        return `<path d="${tail}" fill="${c}" ${S}/>` +
          `<path d="M${f(w * 0.4)},${f(-h * 0.11)} L${f(w * 0.65)},${f(-h * 0.12)}" stroke="${st}" stroke-width="5"/>` +
          [0.42, 0.5, 0.58].map((x) => `<path d="M${f(w * x + 2)},${f(-h * 0.03)} L${f(w * x + 3)},${f(h * 0.02)}" stroke="${O}" stroke-width="3.5" stroke-linecap="round"/>`).join('') +
          `<path d="${p}" fill="${c}" ${S}/>` +
          [-0.5, 0, 0.5].map((x) => { const yt = -h * 0.4 + (1 - x * x) * h * 0.09, yb = -h * 0.29 + (1 - x * x) * h * 0.095; return `<path d="M${f(x * w - 4)},${f(yt + 3)} L${f(x * w - 4)},${f(yb - 3)} M${f(x * w + 4)},${f(yt + 3)} L${f(x * w + 4)},${f(yb - 3)}" stroke="${st}" stroke-width="3.5" stroke-linecap="round"/>`; }).join('');
      },
      /* Snowman: coal buttons */
      coalButtons(d, k) {
        return [0.2, 0.07].map((y) => `<circle cx="0" cy="${r1(-k.h * y)}" r="5.5" fill="${O}"/><circle cx="-1.6" cy="${r1(-k.h * y - 1.6)}" r="1.5" fill="#fff" opacity=".5"/>`).join('');
      },
      /* Mouse King: an ermine collar */
      ermine(d, k) {
        const { w, h, f, S } = k;
        const p = `M${f(-w * 0.9)},${f(-h * 0.46)} Q0,${f(-h * 0.3)} ${f(w * 0.9)},${f(-h * 0.46)} Q${f(w * 0.94)},${f(-h * 0.34)} ${f(w * 0.82)},${f(-h * 0.3)} Q0,${f(-h * 0.12)} ${f(-w * 0.82)},${f(-h * 0.3)} Q${f(-w * 0.94)},${f(-h * 0.34)} ${f(-w * 0.9)},${f(-h * 0.46)} Z`;
        return `<path d="${p}" fill="${WHITE}" ${S}/>` +
          [[-0.6, 0.36], [-0.22, 0.26], [0.2, 0.26], [0.58, 0.36]].map(([x, y]) => `<path d="M${f(x * w)},${f(-h * y - 4)} L${f(x * w - 3)},${f(-h * y + 3)} L${f(x * w + 3)},${f(-h * y + 3)} Z" fill="#2e2a2b" stroke="#2e2a2b" stroke-width="2" stroke-linejoin="round"/>`).join('');
      },
    },

    over: {
      /* a gold star on top of the tree */
      treeStar(d, k) { return `<polygon points="${starPts(0, -178, 20, 9)}" fill="${GOLD}" ${k.S4}/><circle cx="-4" cy="-182" r="2.4" fill="#fff" opacity=".8"/>`; },
      /* a sprig of holly on the head */
      hollyTop(d, k) { return holly(0, -k.h * 0.97, 1); },
      hollySide(d, k) { return holly(k.w * 0.42, -k.h * 0.9, 0.9, 24); },
      /* the Nutcracker's tall shako hat with a plume */
      shako(d, k) {
        const { h, S, S4 } = k, yb = -h * 0.8, top = yb - 54, navy = '#2d2a3a';
        return `<ellipse cx="0" cy="${r1(top - 12)}" rx="9" ry="14" fill="#fff" ${S4}/><circle cx="0" cy="${r1(top - 3)}" r="5" fill="${BERRY}" stroke="${O}" stroke-width="2.5"/>` +
          `<path d="M-27,${r1(yb)} L-31,${r1(top + 2)} Q0,${r1(top - 6)} 31,${r1(top + 2)} L27,${r1(yb)} Z" fill="${navy}" ${S}/>` +
          `<path d="M-28,${r1(yb - 14)} L28,${r1(yb - 14)} L28,${r1(yb - 6)} L-28,${r1(yb - 6)} Z" fill="${GOLD}"/>` +
          `<polygon points="${starPts(0, top + 22, 11, 5)}" fill="${GOLD}" stroke="${O}" stroke-width="3" stroke-linejoin="round"/>` +
          `<ellipse cx="0" cy="${r1(yb)}" rx="36" ry="8" fill="${navy}" ${S}/>`;
      },
      /* a little tiara */
      tiara(d, k) {
        const { w, h, f, S4 } = k, yb = -h * 0.87;
        const pts = [[-0.36, 0], [-0.26, -12], [-0.12, -6], [0, -22], [0.12, -6], [0.26, -12], [0.36, 0]].map(([x, y]) => `${f(x * w)},${f(yb + y)}`).join(' ');
        return `<polygon points="${pts}" fill="${d.tiara}" ${S4}/><circle cx="0" cy="${f(yb - 8)}" r="4" fill="${d.gem}" stroke="${O}" stroke-width="2.5"/>`;
      },
      /* Snowflake Fairy: a crown of icicles with a snowflake */
      iceCrown(d, k) {
        const { w, h, f, S4 } = k, yb = -h * 0.87;
        const pts = [[-0.42, 0], [-0.36, -14], [-0.24, -4], [-0.14, -20], [-0.05, -6], [0.05, -6], [0.14, -20], [0.24, -4], [0.36, -14], [0.42, 0]].map(([x, y]) => `${f(x * w)},${f(yb + y)}`).join(' ');
        return `<polygon points="${pts}" fill="#dff1ff" ${S4}/>` + flake(0, yb - 14, 10, '#fff', 3.4);
      },
      /* a golden halo */
      halo(d, k) {
        const { h } = k, cy = r1(-h * 1.1);
        return `<ellipse cx="0" cy="${cy}" rx="30" ry="8.5" fill="none" stroke="${O}" stroke-width="12"/><ellipse cx="0" cy="${cy}" rx="30" ry="8.5" fill="none" stroke="${GOLD}" stroke-width="5"/>`;
      },
      /* a crown */
      crown(d, k) {
        const { w, h, f, S } = k, yb = -h * 0.86;
        const pts = [[-0.48, 0], [-0.52, -32], [-0.25, -14], [0, -38], [0.25, -14], [0.52, -32], [0.48, 0]].map(([x, y]) => `${f(x * w)},${f(yb + y)}`).join(' ');
        return `<polygon points="${pts}" fill="${GOLD}" ${S}/>` +
          `<rect x="${f(-w * 0.5)}" y="${f(yb - 6)}" width="${f(w)}" height="7" fill="#d9952a"/>` +
          [[0, -12, BERRY, 5], [-0.3, -8, '#4f7fc0', 3.6], [0.3, -8, HOLLY, 3.6]].map(([x, y, c, r]) => `<circle cx="${f(x * w)}" cy="${f(yb + y)}" r="${r}" fill="${c}" stroke="${O}" stroke-width="2.5"/>`).join('') +
          [-0.52, 0, 0.52].map((x, i) => `<circle cx="${f(x * w)}" cy="${f(yb + (i === 1 ? -38 : -32))}" r="4" fill="${GOLD}" stroke="${O}" stroke-width="2.5"/>`).join('');
      },
      /* twinkles around the friend */
      sparkles(d, k) {
        const { w, h } = k, c = d.sparkleColor || '#ffe27a';
        return [[-w - 26, -h * 0.98, 10], [-w - 34, -h * 0.4, 8], [w + 34, -h * 0.4, 8], [w * 0.62, -h * 1.18, 9]]
          .map(([x, y, r]) => twinkle(x, y, r, c)).join('');
      },
      /* a black top hat with a holly band */
      topHat(d, k) {
        const { h } = k, yb = -h * 0.93, navy = '#2d2a3a';
        return `<g transform="rotate(-8 0 ${r1(yb)})">` +
          `<path d="M-24,${r1(yb)} L-24,${r1(yb - 40)} Q0,${r1(yb - 45)} 24,${r1(yb - 40)} L24,${r1(yb)} Z" fill="${navy}" ${k.S}/>` +
          `<rect x="-24" y="${r1(yb - 13)}" width="48" height="9" fill="#e8604f"/>` +
          `<ellipse cx="0" cy="${r1(yb)}" rx="38" ry="8" fill="${navy}" ${k.S}/>` +
          holly(14, yb - 10, 0.55, 10) + `</g>`;
      },
      /* a little red Christmas hat, tipped to one side */
      xmasHat(d, k) {
        const { h, S } = k, yb = -h * 0.95;
        return `<g transform="translate(16 ${r1(yb + 2)}) rotate(22) scale(0.78) translate(0 ${r1(-yb)})">` +
          `<path d="M-24,${r1(yb)} Q-14,${r1(yb - 34)} 6,${r1(yb - 46)} Q26,${r1(yb - 52)} 34,${r1(yb - 34)} Q20,${r1(yb - 34)} 20,${r1(yb)} Z" fill="#d6423f" ${S}/>` +
          `<circle cx="36" cy="${r1(yb - 32)}" r="8" fill="${WHITE}" ${S}/>` +
          `<rect x="-28" y="${r1(yb - 7)}" width="54" height="14" rx="7" fill="${WHITE}" ${S}/></g>`;
      },
      /* a snowflake hair clip */
      flakeClip(d, k) { return flake(-k.w * 0.5, -k.h * 0.82, 9, '#fff', 3.4); },
    },
  };
  /** a six-armed snowflake (outlined tubes) */
  function flake(x, y, r, c = '#fff', wdt = 3.5) {
    let d = '';
    for (let i = 0; i < 3; i++) {
      const a = (i * Math.PI) / 3 + Math.PI / 2, dx = Math.cos(a) * r, dy = Math.sin(a) * r;
      d += `M${r1(x - dx)},${r1(y - dy)} L${r1(x + dx)},${r1(y + dy)} `;
      for (const s of [-1, 1]) {
        const bx = x + s * dx * 0.55, by = y + s * dy * 0.55, b = r * 0.3;
        for (const t of [-1, 1]) {
          const aa = a + t * 0.6 + (s < 0 ? Math.PI : 0);
          d += `M${r1(bx)},${r1(by)} L${r1(bx + Math.cos(aa) * b)},${r1(by + Math.sin(aa) * b)} `;
        }
      }
    }
    return `<path d="${d}" fill="none" stroke="${O}" stroke-width="${wdt + 3.5}" stroke-linecap="round"/><path d="${d}" fill="none" stroke="${c}" stroke-width="${wdt}" stroke-linecap="round"/>`;
  }
  /** a jingle bell */
  const bell = (x, y, r) => `<circle cx="${r1(x)}" cy="${r1(y)}" r="${r}" fill="${GOLD}" stroke="${O}" stroke-width="3"/>` +
    `<path d="M${r1(x - r * 0.5)},${r1(y + r * 0.25)} L${r1(x + r * 0.5)},${r1(y + r * 0.25)}" stroke="${O}" stroke-width="2.2" stroke-linecap="round"/>` +
    `<circle cx="${r1(x - r * 0.35)}" cy="${r1(y - r * 0.35)}" r="${r1(r * 0.25)}" fill="#fff" opacity=".8"/>`;

  /* ------------------------------------------------------------ friends */
  const SKIN_LIGHT = '#f6d2b4', SKIN_WARM = '#e5b48c', SKIN_TAN = '#c68a5e';
  const friends = [
    // Christmas baking (Advent Eggs days 1, 5, 9, 13)
    { id: 'gingerbread', name: 'Gingerbread Pal', body: '#c98447', marks: ['gingerIcing'], front: ['gumdrops'], arms: 'gingerArms', feet: 'gingerFeet', nose: 'none', mouth: 'icingSmile', cheekColor: '#e8604f', call: 'gingerhee', karaoke: ['jingle', 'squeak', 1800] },
    { id: 'treecookie', name: 'Christmas Tree Cookie', body: '#5aa665', back: ['treeTiers'], marks: ['treeIcing'], over: ['treeStar'], armColor: '#4f955a', feetColor: '#9a6a3e', nose: 'none', mouth: 'u', call: 'bauble', karaoke: ['jingle', 'cheep', 2400] },
    { id: 'shortbread', name: 'Shortbread Star', body: '#eec070', back: ['starPoints'], marks: ['sugar'], arms: 'none', feet: 'none', nose: 'none', mouth: 'u', cheekColor: '#f39a6b', call: 'starding', karaoke: ['jingle', 'hoot', 880] },
    { id: 'pudding', name: 'Christmas Pudding', shape: 'wide', body: '#8e5236', back: ['plate'], marks: ['custard'], over: ['hollyTop'], feet: 'none', nose: 'none', mouth: 'w', armColor: '#7a4430', cheekColor: '#f3828f', call: 'wobble', karaoke: ['jingle', 'bloop', 300] },
    // The Nutcracker (Advent Eggs days 3, 11, 15, 18)
    { id: 'nutcracker', name: 'Nutcracker', shape: 'tall', body: '#c23b3f', skin: SKIN_LIGHT, marks: ['nutcracker'], over: ['shako'], mouth: 'nutGrin', noseColor: '#d98a7a', armColor: '#b0343a', feetColor: '#2d2a3a', cheekColor: '#f08a8a', call: 'clack', karaoke: ['jingle', 'ork', 240], say: 'It\'s the Nutcracker!' },
    { id: 'sugarplum', name: 'Sugar Plum Fairy', body: '#b98ad6', skin: SKIN_TAN, hair: '#4a2f45', marks: ['person', 'tutu'], tutu: '#e6c8f2', back: ['fairyWings', 'bun'], wingColor: '#f6c6e6', arms: 'wand', armColor: SKIN_TAN, feetColor: '#f29ac0', over: ['tiara', 'sparkles'], tiara: GOLD, gem: '#f28ab8', noseColor: '#8a5440', call: 'celesta', karaoke: ['jingle', 'hoot', 880], say: 'It\'s the Sugar Plum Fairy!' },
    { id: 'mouseking', name: 'Mouse King', body: '#a3a0aa', belly: '#d8d4dc', ears: 'bigRound', earInner: '#f2b6c4', back: ['cape', 'tailThin'], capeColor: '#8c2f45', tailColor: '#e8a3b4', whiskers: true, noseColor: '#e58aa0', front: ['ermine'], arms: 'sceptre', over: ['crown'], call: 'mouseking', karaoke: ['jingle', 'squeak', 2600], say: 'It\'s the Mouse King!' },
    { id: 'snowfairy', name: 'Snowflake Fairy', body: '#a9d6f0', skin: SKIN_LIGHT, hair: '#f2f5fb', hairTo: 0.4, marks: ['person', 'tutu'], tutu: '#e6f4ff', tutuFlakes: true, back: ['iceWings'], wingColor: '#e6f4ff', arms: 'wand', wandTop: 'flake', armColor: SKIN_LIGHT, feetColor: '#dff1ff', over: ['iceCrown', 'sparkles'], sparkleColor: '#ffffff', noseColor: '#e0a090', call: 'icetinkle', karaoke: ['jingle', 'cheep', 3000], say: 'It\'s the Snowflake Fairy!' },
    // Christmas Eve
    { id: 'angel', name: 'Angel', body: '#fdfaf2', skin: SKIN_WARM, hair: '#f2c75c', hairTo: 0.36, marks: ['person', 'hem'], back: ['featherWings'], wingColor: '#fffaf0', arms: 'hold', armColor: '#f3ede0', feetColor: '#efe4cc', front: ['heldStar'], over: ['halo', 'sparkles'], noseColor: '#b8785a', call: 'angelaah', karaoke: ['jingle', 'ah', 520], say: 'It\'s the Angel!' },
    { id: 'reindeer', name: 'Reindeer', body: '#a8774f', belly: '#efdcc0', ears: 'goat', earColor: '#8f6240', back: ['antlers'], antlerColor: '#e6cfa3', muzzle: 'snout', muzzleColor: '#efdcc0', nose: 'big', noseColor: '#4a3030', front: ['bellCollar'], feetColor: '#5a3a2a', call: 'reindeer', karaoke: ['jingle', 'ork', 200] },
    { id: 'robin', name: 'Robin', body: '#8a6a4f', breast: '#ec6a3c', marks: ['robin'], back: ['robinTail'], eyes: 'big', muzzle: 'beak', muzzleColor: '#6a5446', nose: 'none', mouth: 'none', arms: 'wing', armColor: '#7a5c44', feet: 'bird', feetColor: '#d49a7a', over: ['hollySide'], call: 'tweet', karaoke: ['jingle', 'cheep', 3000] },
    { id: 'snowman', name: 'Snowman', body: '#fbfdff', marks: ['snowShade'], nose: 'carrot', mouth: 'coal', arms: 'twigs', feet: 'none', front: ['coalButtons', 'scarf'], over: ['topHat'], call: 'snowhoo', karaoke: ['jingle', 'hoot', 330] },
    { id: 'xmasbeetle', name: 'Christmas Beetle', shape: 'wide', body: '#d9a43e', capColor: '#7f9a3a', marks: ['beetle'], back: ['fanAntennae'], front: ['midLegs'], antennaColor: '#8a6a2a', nose: 'none', mouth: 'u', armColor: '#6a4a2a', feetColor: '#6a4a2a', faceY: 0.52, over: ['xmasHat'], call: 'buzz', karaoke: ['jingle', 'buzz', 220] },
  ];

  /* -------------------------------------------------------------- calls
   * Synth stand-ins for the recorded calls (sounds/<id>.mp3). The friends who
   * aren't animals make the sound they really would: a giggle, a clack, a
   * twinkle, a wobble, a jingle. */
  const calls = {
    gingerhee: { len: 0.6, play: (k, t, o) => { [0, 0.13, 0.26].forEach((g, i) => k.say.squeak(t + g, 1700 + i * 160, 0.1, o)); k.say.squeak(t + 0.4, 2300, 0.16, o); } },
    bauble: { len: 0.8, play: (k, t, o) => { [0, 0.07, 0.15, 0.24].forEach((g) => k.tamb(t + g, 0.05)); [91, 96, 100].forEach((n, i) => k.glock(n, t + 0.1 + i * 0.12, 0.6, 0.04)); } },
    starding: { len: 1.0, play: (k, t, o) => { k.glock(84, t, 1.2, 0.07); k.glock(96, t + 0.02, 0.9, 0.03); k.say.hoot(t, 1046, 0.5, o, 0.5); } },
    wobble: { len: 0.7, play: (k, t, o) => [0, 0.16, 0.3, 0.42].forEach((g, i) => k.say.bloop(t + g, 320 - i * 30, 0.14, o, 1 - i * 0.18)) },
    clack: { len: 0.6, play: (k, t, o) => { k.woodblock(t, true, 0.14); k.woodblock(t + 0.16, false, 0.14); k.claves(t + 0.38, 0.12); k.say.ork(t + 0.4, 220, 0.12, o, 0.4); } },
    celesta: { len: 1.0, play: (k, t, o) => [79, 83, 86, 91, 95, 98].forEach((n, i) => k.glock(n, t + i * 0.09, 0.8, 0.05)) },
    mouseking: { len: 0.55, play: (k, t, o) => { k.say.squeak(t, 2400, 0.12, o); k.say.squeak(t + 0.18, 2800, 0.3, o); } },
    icetinkle: { len: 0.9, play: (k, t, o) => [96, 100, 103, 98, 101, 105].forEach((n, i) => k.glock(n, t + i * 0.06, 0.5, 0.035)) },
    angelaah: { len: 1.1, play: (k, t, o) => { k.say.ah(t, 523, 1.0, o, 0.8); k.say.ah(t, 659, 1.0, o, 0.4); [84, 88, 91].forEach((n, i) => k.glock(n, t + 0.7 + i * 0.07, 0.6, 0.03)); } },
    reindeer: { len: 0.8, play: (k, t, o) => { k.say.sniff(t, 700, 0.18, o); [0.22, 0.3, 0.38, 0.5].forEach((g) => k.tamb(t + g, 0.06)); k.say.ork(t + 0.5, 190, 0.2, o, 0.6); } },
    snowhoo: { len: 0.9, play: (k, t, o) => k.say.hoot(t, 330, 0.85, o) },
  };

  /* ------------------------------------------------- Egg karaoke: jingle */
  const worlds = {
    jingle: { bpm: 132, lead: 'celesta', second: 'flute', comp: 'piano', compStyle: 'block', bass: 'bass', bassStyle: 'walk', sparkle: 'glock', kick: 'kick', back: 'snare', backGain: 0.5, tick: 'sleighbells', perc: 'woodblock', chirp: 'jingle' },
  };
  const chirps = {
    /* a shake of the sleigh bells, then the chord rung on the glockenspiel (p.inst adds the key) */
    jingle(p, k, t, chord, hi, o) {
      p.inst('sleighbells', 0, t, 0, 1, k.ch.drums);
      p.inst('sleighbells', 0, t + 0.11, 0, 0.7, k.ch.drums);
      chord.concat(chord[0] + 12).forEach((n, i) => p.inst('glock', n + 24, t + 0.05 + i * 0.07, 0.5, 0.55, o));
    },
  };
  const instruments = {
    sleighbells: { syn: (k, n, t, d, g) => { k.tamb(t, 0.06 * g); k.tamb(t + 0.025, 0.03 * g); }, gain: 0.3 },
    celesta: { syn: (k, n, t, d, g) => k.glock(n, t, 0.9, 0.04 * g), gain: 0.3, home: 79 },
  };

  /* -------------------------------------------------------------- world */
  const K = GC.Scenes ? GC.Scenes.kit : null;
  const scenes = !K ? [] : (() => {
    const { P, S, NS, f, sh, leftPt, rightPt, lip, pebbles, roots, stars } = K;
    const LIGHTS = ['#ff6b6b', '#ffd86b', '#7fd8ff', '#9fe07a'];
    /** a string of fairy lights from a to b, sagging by sag */
    const lights = (a, b, sag, n, rot = 0) => {
      const c = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + sag];
      const pts = along(a, c, b, n + 1).slice(1, -1);
      return `<path d="M${f(a[0])},${f(a[1])} Q${f(c[0])},${f(c[1])} ${f(b[0])},${f(b[1])}" fill="none" stroke="${O}" stroke-width="2" ${NS}/>` +
        pts.map(([x, y], i) => `<ellipse class="twinkle" style="--td:${(1.6 + ((i * 7 + rot) % 5) * 0.35).toFixed(2)}s;animation-delay:-${(i * 0.37).toFixed(2)}s" cx="${f(x)}" cy="${f(y + 4)}" rx="3.6" ry="4.6" fill="${LIGHTS[(i + rot) % 4]}" stroke="${O}" stroke-width="2" ${NS}/>`).join('');
    };
    /** a little house: snowy roof, warm window, wreath on the door, fairy lights */
    const house = (x, y, s, wall, roof, chimney, flip) => {
      const W = 66 * s, H = 46 * s, pk = 36 * s, L = x - W / 2, R = x + W / 2, top = y - H;
      let o = '';
      if (chimney) {
        const cx = flip ? x - W * 0.28 : x + W * 0.22;
        o += `<rect x="${f(cx)}" y="${f(top - pk * 0.95)}" width="${f(12 * s)}" height="${f(pk * 0.8)}" fill="#9a5a48" ${S(4)}/>` +
          `<rect x="${f(cx - 3 * s)}" y="${f(top - pk * 1.02)}" width="${f(18 * s)}" height="${f(8 * s)}" rx="${f(4 * s)}" fill="#fbfdff" ${S(3.5)}/>`;
      }
      o += `<rect x="${f(L)}" y="${f(top)}" width="${f(W)}" height="${f(H)}" fill="${wall}" ${S()}/>`;
      // door with a wreath, and a warm window
      const dx = flip ? x + W * 0.2 : x - W * 0.2, wx = flip ? x - W * 0.2 : x + W * 0.18;
      o += `<path d="M${f(dx - 8 * s)},${f(y)} L${f(dx - 8 * s)},${f(y - 18 * s)} Q${f(dx)},${f(y - 27 * s)} ${f(dx + 8 * s)},${f(y - 18 * s)} L${f(dx + 8 * s)},${f(y)} Z" fill="#7a3f45" ${S(3.5)}/>` +
        `<circle cx="${f(dx)}" cy="${f(y - 15 * s)}" r="${f(4.5 * s)}" fill="none" stroke="${O}" stroke-width="${f(5 * s)}"/><circle cx="${f(dx)}" cy="${f(y - 15 * s)}" r="${f(4.5 * s)}" fill="none" stroke="${HOLLY}" stroke-width="${f(2.6 * s)}"/>` +
        `<circle cx="${f(wx)}" cy="${f(y - H * 0.55)}" r="${f(17 * s)}" fill="#ffd86b" opacity=".28" class="glow-pulse"/>` +
        `<rect x="${f(wx - 9 * s)}" y="${f(y - H * 0.55 - 9 * s)}" width="${f(18 * s)}" height="${f(18 * s)}" rx="${f(2 * s)}" fill="#ffd86b" ${S(3.5)}/>` +
        `<path d="M${f(wx)},${f(y - H * 0.55 - 9 * s)} L${f(wx)},${f(y - H * 0.55 + 9 * s)} M${f(wx - 9 * s)},${f(y - H * 0.55)} L${f(wx + 9 * s)},${f(y - H * 0.55)}" stroke="${O}" stroke-width="2.5"/>` +
        `<rect x="${f(wx - 12 * s)}" y="${f(y - H * 0.55 + 8 * s)}" width="${f(24 * s)}" height="${f(5 * s)}" rx="${f(2.5 * s)}" fill="#fbfdff" ${S(3)}/>`;
      // roof, snow on top, icicles and lights along the eaves
      o += `<path d="M${f(L - 8 * s)},${f(top + 3)} L${f(x)},${f(top - pk)} L${f(R + 8 * s)},${f(top + 3)} Z" fill="${roof}" ${S()}/>` +
        `<path d="M${f(L - 7 * s)},${f(top - 1)} L${f(x)},${f(top - pk - 2)} L${f(R + 7 * s)},${f(top - 1)}" fill="none" stroke="${O}" stroke-width="${f(13 * s + 4)}" stroke-linecap="round" stroke-linejoin="round"/>` +
        `<path d="M${f(L - 7 * s)},${f(top - 1)} L${f(x)},${f(top - pk - 2)} L${f(R + 7 * s)},${f(top - 1)}" fill="none" stroke="#fbfdff" stroke-width="${f(13 * s - 3)}" stroke-linecap="round" stroke-linejoin="round"/>`;
      for (let ix = L + 4; ix < R - 4; ix += 11 * s) o += `<path d="M${f(ix)},${f(top + 2)} L${f(ix + 3.5 * s)},${f(top + 2 + (6 + ((ix * 7) % 5)) * s)} L${f(ix + 7 * s)},${f(top + 2)} Z" fill="#e6f3fb" ${S(2)}/>`;
      o += lights([L - 2, top + 8], [R + 2, top + 8], 7 * s, 6, Math.round(x));
      return o;
    };
    /** the church under the star */
    const church = (x, y, s) => {
      const stone = '#e3d6c0';
      return `<path d="M${f(x - 30 * s)},${f(y - 50 * s)} L${f(x - 30 * s)},${f(y - 94 * s)} L${f(x)},${f(y - 150 * s)} L${f(x + 30 * s)},${f(y - 94 * s)} L${f(x + 30 * s)},${f(y - 50 * s)} Z" fill="#4a5a7a" ${S()}/>` +
        `<path d="M${f(x - 18 * s)},${f(y - 116 * s)} L${f(x)},${f(y - 148 * s)} L${f(x + 18 * s)},${f(y - 116 * s)}" fill="none" stroke="${O}" stroke-width="${f(9 * s + 4)}" stroke-linecap="round" stroke-linejoin="round"/>` +
        `<path d="M${f(x - 18 * s)},${f(y - 116 * s)} L${f(x)},${f(y - 148 * s)} L${f(x + 18 * s)},${f(y - 116 * s)}" fill="none" stroke="#fbfdff" stroke-width="${f(9 * s - 3)}" stroke-linecap="round" stroke-linejoin="round"/>` +
        `<rect x="${f(x - 22 * s)}" y="${f(y - 98 * s)}" width="${f(44 * s)}" height="${f(60 * s)}" fill="${stone}" ${S()}/>` +
        `<circle cx="${f(x)}" cy="${f(y - 78 * s)}" r="${f(16 * s)}" fill="#ffd86b" opacity=".3" class="glow-pulse"/>` +
        `<circle cx="${f(x)}" cy="${f(y - 78 * s)}" r="${f(9 * s)}" fill="#ffd86b" ${S(3.5)}/>` +
        `<path d="M${f(x)},${f(y - 87 * s)} L${f(x)},${f(y - 69 * s)} M${f(x - 9 * s)},${f(y - 78 * s)} L${f(x + 9 * s)},${f(y - 78 * s)}" stroke="${O}" stroke-width="2.5"/>` +
        `<rect x="${f(x - 24 * s)}" y="${f(y - 101 * s)}" width="${f(48 * s)}" height="${f(7 * s)}" rx="${f(3.5 * s)}" fill="#fbfdff" ${S(3.5)}/>`;
    };
    /** a decorated Christmas tree with baubles and a star */
    const xmasTree = (x, y, s) => {
      const t = (yy, ww, hh, col) => `<path d="M${f(x - ww)},${f(yy)} L${f(x)},${f(yy - hh)} L${f(x + ww)},${f(yy)} Q${x},${f(yy + 7 * s)} ${f(x - ww)},${f(yy)} Z" fill="${col}" ${S()}/>`;
      const balls = [[-22, -30, BERRY], [18, -34, GOLD], [-12, -62, '#7fd8ff'], [14, -66, BERRY], [0, -92, GOLD], [-26, -8, GOLD], [24, -10, '#7fd8ff']];
      return `<g class="sway" style="--sd:7s">` +
        `<rect x="${f(x - 6 * s)}" y="${f(y - 14 * s)}" width="${f(12 * s)}" height="${f(16 * s)}" rx="3" fill="#8a5a3b" ${S()}/>` +
        t(y - 10 * s, 40 * s, 46 * s, '#3f8a5a') + t(y - 42 * s, 32 * s, 42 * s, '#4f9a62') + t(y - 72 * s, 23 * s, 38 * s, '#5aa86c') +
        balls.map(([dx, dy, c]) => `<circle cx="${f(x + dx * s)}" cy="${f(y + dy * s)}" r="${f(4.6 * s)}" fill="${c}" ${S(2.5)}/>`).join('') +
        `<polygon points="${starPts(x, y - 112 * s, 12 * s, 5.5 * s)}" fill="${GOLD}" ${S(3.5)}/></g>`;
    };
    /** a gift box */
    const gift = (x, y, s, box, ribbon) => {
      const W = 30 * s, H = 24 * s;
      return `<rect x="${f(x - W / 2)}" y="${f(y - H)}" width="${f(W)}" height="${f(H)}" rx="2" fill="${box}" ${S(4)}/>` +
        `<rect x="${f(x - 3.5 * s)}" y="${f(y - H)}" width="${f(7 * s)}" height="${f(H)}" fill="${ribbon}"/>` +
        `<rect x="${f(x - W / 2 - 3 * s)}" y="${f(y - H - 7 * s)}" width="${f(W + 6 * s)}" height="${f(9 * s)}" rx="2" fill="${box}" ${S(4)}/>` +
        `<rect x="${f(x - 3.5 * s)}" y="${f(y - H - 7 * s)}" width="${f(7 * s)}" height="${f(9 * s)}" fill="${ribbon}"/>` +
        `<rect x="${f(x - W / 2)}" y="${f(y - H)}" width="${f(W)}" height="${f(H)}" rx="2" fill="none" ${S(4)}/>` +
        `<ellipse cx="${f(x - 6 * s)}" cy="${f(y - H - 10 * s)}" rx="${f(7 * s)}" ry="${f(4.5 * s)}" fill="${ribbon}" ${S(3)} transform="rotate(-25 ${f(x - 6 * s)} ${f(y - H - 10 * s)})"/>` +
        `<ellipse cx="${f(x + 6 * s)}" cy="${f(y - H - 10 * s)}" rx="${f(7 * s)}" ry="${f(4.5 * s)}" fill="${ribbon}" ${S(3)} transform="rotate(25 ${f(x + 6 * s)} ${f(y - H - 10 * s)})"/>` +
        `<circle cx="${f(x)}" cy="${f(y - H - 9 * s)}" r="${f(3.5 * s)}" fill="${ribbon}" ${S(2.5)}/>`;
    };
    /** a street lamp with a warm glow */
    const lamp = (x, y, s) => `<rect x="${f(x - 3 * s)}" y="${f(y - 58 * s)}" width="${f(6 * s)}" height="${f(58 * s)}" fill="#3f4a6a" ${S(3.5)}/>` +
      `<circle class="flicker" cx="${f(x)}" cy="${f(y - 66 * s)}" r="${f(18 * s)}" fill="#ffe28a" opacity=".3"/>` +
      `<rect x="${f(x - 8 * s)}" y="${f(y - 74 * s)}" width="${f(16 * s)}" height="${f(16 * s)}" rx="${f(4 * s)}" fill="#ffe28a" ${S(3.5)}/>` +
      `<path d="M${f(x - 11 * s)},${f(y - 75 * s)} L${f(x + 11 * s)},${f(y - 75 * s)} L${f(x)},${f(y - 84 * s)} Z" fill="#3f4a6a" ${S(3.5)}/>` +
      `<path d="M${f(x - 10 * s)},${f(y - 77 * s)} Q${f(x)},${f(y - 88 * s)} ${f(x + 10 * s)},${f(y - 77 * s)}" fill="none" stroke="#fbfdff" stroke-width="${f(5 * s)}" stroke-linecap="round"/>`;
    /** the star over the church */
    const bigStar = (x, y) => `<circle class="glow-pulse" cx="${x}" cy="${y}" r="58" fill="#fff1b0" opacity=".2"/>` +
      `<path d="M${x},${y - 40} Q${x + 5},${y - 5} ${x + 40},${y} Q${x + 5},${y + 5} ${x},${y + 40} Q${x - 5},${y + 5} ${x - 40},${y} Q${x - 5},${y - 5} ${x},${y - 40} Z" fill="#ffe27a" ${S(3.5)}/>` +
      `<path d="M${x - 14},${y - 14} Q${x},${y} ${x + 14},${y - 14} Q${x},${y} ${x + 14},${y + 14} Q${x},${y} ${x - 14},${y + 14} Q${x},${y} ${x - 14},${y - 14} Z" fill="#fff6cf" ${S(2.5)}/>`;
    /** a tiny mouse peeking out of its hole (upright, screen space) */
    const peekMouse = (x, y) => `<g class="burrow-critter">` +
      `<circle cx="${x - 9}" cy="${y - 22}" r="7" fill="#b6aeb0" ${S(3)}/><circle cx="${x + 9}" cy="${y - 22}" r="7" fill="#b6aeb0" ${S(3)}/>` +
      `<circle cx="${x - 9}" cy="${y - 22}" r="3.2" fill="#f6b3bf"/><circle cx="${x + 9}" cy="${y - 22}" r="3.2" fill="#f6b3bf"/>` +
      `<path d="M${x - 13},${y} Q${x - 15},${y - 22} ${x},${y - 22} Q${x + 15},${y - 22} ${x + 13},${y} Z" fill="#b6aeb0" ${S(3.5)}/>` +
      `<g class="blink"><ellipse cx="${x - 5}" cy="${y - 12}" rx="2.4" ry="3" fill="${O}"/><ellipse cx="${x + 5}" cy="${y - 12}" rx="2.4" ry="3" fill="${O}"/></g>` +
      `<circle cx="${x}" cy="${y - 7}" r="2.2" fill="#f18ea0"/></g>`;
    /** a tiny stocking hung on a nail (upright) */
    const stocking = (x, y) => `<path d="M${x},${y - 3} L${x},${y + 3}" stroke="${O}" stroke-width="3" stroke-linecap="round"/>` +
      `<path d="M${x - 6},${y + 3} L${x + 6},${y + 3} L${x + 6},${y + 17} Q${x + 14},${y + 18} ${x + 13},${y + 25} Q${x + 10},${y + 29} ${x},${y + 26} Q${x - 6},${y + 24} ${x - 6},${y + 17} Z" fill="#d6423f" ${S(3)}/>` +
      `<rect x="${x - 8}" y="${y + 1}" width="16" height="6" rx="3" fill="#fbfdff" ${S(2.5)}/>`;
    /** an arched mouse hole in the side (face-local, like the burrows) */
    const mouseHole = (u, v, rw, rh, c) => `<path d="M${u - rw},${v + rh} L${u - rw},${v} A${rw},${rw} 0 0 1 ${u + rw},${v} L${u + rw},${v + rh} Z" fill="${sh(c, -0.45)}" ${S(4.5)} ${NS}/>` +
      `<path d="M${u - rw + 4},${v + rh - 4} L${u + rw - 4},${v + rh - 4}" stroke="${sh(c, -0.25)}" stroke-width="5" ${NS}/>`;
    /** a cellar dug into the side (face-local) */
    const cellar = (u, v, rx, ry, c) => `<ellipse cx="${u}" cy="${v}" rx="${rx}" ry="${ry}" fill="${sh(c, -0.4)}" ${S(4.5)} ${NS}/>` +
      `<path d="M${u - rx + 8},${v + ry * 0.55} L${u + rx - 8},${v + ry * 0.55}" stroke="#8a5a3b" stroke-width="5" stroke-linecap="round" ${NS}/>`;

    return [{
      id: 'xmasvillage', name: 'Christmas Village', bg: '#34406c', ring: '#ffd86b', particles: 'snowflakes', dark: true,
      top: '#f4f8fb', left: '#9b7a68', right: '#7d5f50', lip: '#e6eef4',
      sky: () => stars() + bigStar(300, 58),
      ground: () => `<path d="M120,240 Q118,170 140,120 T120,0" stroke="#dbe5ee" stroke-width="26" fill="none" stroke-linecap="round" ${NS}/>` +
        [[132, 200], [124, 172], [136, 146], [128, 118]].map(([u, v], i) => `<ellipse cx="${u + (i % 2) * 8}" cy="${v}" rx="3.5" ry="5" fill="#c9d8e4"/>`).join('') +
        `<ellipse cx="44" cy="190" rx="26" ry="16" fill="#e3ecf4"/><ellipse cx="200" cy="44" rx="22" ry="14" fill="#e3ecf4"/>`,
      leftSide: (r, c) => `<rect x="0" y="12" width="240" height="10" fill="#dfeaf2" opacity=".5"/>` + roots(r, '#6b4c3e', 2) +
        mouseHole(76, 70, 22, 30, c) + pebbles(r, '#86685a', 8) + lights([4, 26], [236, 26], 12, 9, 1),
      rightSide: (r, c) => `<rect x="0" y="12" width="240" height="10" fill="#dfeaf2" opacity=".4"/>` + cellar(150, 68, 52, 30, c) + pebbles(r, '#6b5044', 7) +
        K.icicles() + lights([4, 30], [236, 30], 12, 9, 2),
      sideCritters: () => peekMouse(...leftPt(76, 100)) + stocking(...leftPt(116, 64)) +
        gift(...K.shift(rightPt(126, 92), 0, 0), 0.62, BERRY, GOLD) + gift(...K.shift(rightPt(156, 90), 0, 0), 0.55, '#4f9a62', '#fbfdff') +
        gift(...K.shift(rightPt(176, 86), 0, 0), 0.45, '#7fb6d8', BERRY) + P.candle(...rightPt(102, 94), 0.6),
      back: () => P.pine(226, 290, 0.75, '#4f8f6a', '#6aaa84', true) + P.pine(380, 292, 0.7, '#4f8f6a', '#6aaa84', true) + church(300, 284, 1.32) +
        house(164, 338, 1.32, '#c4674a', '#5a4660', true, false) + house(438, 340, 1.25, '#6f8fa6', '#4a3a4a', true, true) +
        gift(246, 318, 0.8, '#f2a0b8', '#fbfdff') + lamp(360, 322, 0.85),
      front: () => xmasTree(100, 404, 0.62) + gift(502, 404, 0.9, BERRY, GOLD) + gift(480, 412, 0.65, '#4f9a62', '#fbfdff') +
        gift(204, 436, 0.6, '#7fb6d8', BERRY) + P.snowman(424, 438, 0.85),
    }];
  })();

  const particles = {
    /* falling snow, every third one a little six-armed flake */
    snowflakes: (i, x, y, st, r) => i % 3 ? `<g transform="translate(${r1(x)} -20)"><circle class="p-fall" ${st} r="${r1(2.5 + r() * 3)}" fill="#fff"/></g>` :
      `<g transform="translate(${r1(x)} -20)"><g class="p-fall" ${st}>${flake(0, 0, 6, '#fff', 2).replace(/stroke="#3b2224" stroke-width="5.5"/, 'stroke="#c7d9e6" stroke-width="4"')}</g></g>`,
  };

  GC.Packs.register({
    id: 'christmas', name: 'Christmas', blurb: 'Gingerbread, the Nutcracker, a reindeer and a snowy village', icon: 'gift',
    friends, parts, calls, scenes, particles, worlds, chirps, instruments,
  });
})();

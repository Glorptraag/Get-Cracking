/* Get Cracking — Aussie Bush pack.
 *
 * Twelve Australian friends drawn in the house style (one chunky bean, 6 px
 * outlines, soft flat colours), two worlds (a red-dirt outback with the mole
 * cricket's tunnel, and a gum-tree billabong with the platypus's burrow), and
 * an Egg karaoke bush band: banjo lead and spoons (both recorded), flute,
 * ukulele, upright bass, and a kookaburra laugh made of the chord's notes.
 *
 * Everything here is plain SVG (path, ellipse, circle, rect, polygon, g with
 * transform, clipPath) so the iPhone app can re-draw it from the same numbers.
 * Native animals and generic bush landscape only: no sacred sites, no
 * Aboriginal instruments or art motifs.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT;
  const sh = GC.shade;
  const f = (n) => Math.round(n * 10) / 10;
  const FY = (d, h) => -h * (d.faceY || 0.56);
  const arm = (s) => (s < 0 ? 'c-arm-l' : 'c-arm-r');
  const midi = (n) => 440 * Math.pow(2, (n - 69) / 12);

  /* ================================================================ parts */

  /** a parrot's hooked beak, seen from the front */
  function parrotBeak(d, k) {
    const { fy, S4 } = k, c = d.muzzleColor;
    return `<path d="M-11,${f(fy + 5)} Q0,${f(fy - 1)} 11,${f(fy + 5)} Q12,${f(fy + 15)} 2,${f(fy + 24)} Q0,${f(fy + 26)} -2,${f(fy + 24)} Q-12,${f(fy + 15)} -11,${f(fy + 5)} Z" fill="${c}" ${S4}/>` +
      `<path d="M-6,${f(fy + 13)} Q0,${f(fy + 17)} 6,${f(fy + 13)}" fill="none" stroke="${sh(c, -0.35)}" stroke-width="3" stroke-linecap="round"/>` +
      `<ellipse cx="-4" cy="${f(fy + 6)}" rx="3.5" ry="1.8" fill="#fff" opacity=".55"/>`;
  }

  /** a feather or leaf: a pointed oval from base (bx,by) to tip at angle a (deg), length L, width W */
  function leaf(bx, by, a, L, W, fill, stroke) {
    const r = (a * Math.PI) / 180, ux = Math.cos(r), uy = Math.sin(r), px = -uy, py = ux;
    const tx = bx + ux * L, ty = by + uy * L;
    const m1 = [bx + ux * L * 0.45 + px * W, by + uy * L * 0.45 + py * W];
    const m2 = [bx + ux * L * 0.45 - px * W, by + uy * L * 0.45 - py * W];
    return `<path d="M${f(bx + px * W * 0.45)},${f(by + py * W * 0.45)} Q${f(m1[0])},${f(m1[1])} ${f(tx)},${f(ty)} Q${f(m2[0])},${f(m2[1])} ${f(bx - px * W * 0.45)},${f(by - py * W * 0.45)} Z" fill="${fill}" ${stroke}/>`;
  }

  /** a spike: a narrow triangle from base (bx,by) at angle a (deg), with a dark tip */
  function spine(bx, by, a, L, W, fill, tip, S4) {
    const r = (a * Math.PI) / 180, ux = Math.cos(r), uy = Math.sin(r), px = -uy * W, py = ux * W;
    const tx = bx + ux * L, ty = by + uy * L;
    const k = 0.62, mx = bx + ux * L * k, my = by + uy * L * k;
    return `<path d="M${f(bx + px)},${f(by + py)} L${f(tx)},${f(ty)} L${f(bx - px)},${f(by - py)} Z" fill="${fill}" ${S4}/>` +
      `<path d="M${f(mx + px * (1 - k))},${f(my + py * (1 - k))} L${f(tx)},${f(ty)} L${f(mx - px * (1 - k))},${f(my - py * (1 - k))} Z" fill="${tip}" stroke="${tip}" stroke-width="2" stroke-linejoin="round"/>`;
  }

  const parts = {
    ears: {
      /** joey: tall pointed kangaroo ears, set wide */
      roo(d, k) {
        const { w, h, S, both } = k;
        return both((s) => `<g transform="rotate(${s * 16} ${f(s * w * 0.5)} ${f(-h * 0.88)})">` +
          `<path d="M${f(s * w * 0.5 - 15)},${f(-h * 0.86)} C${f(s * w * 0.5 - 19)},${f(-h * 1.08)} ${f(s * w * 0.5 - 5)},${f(-h * 1.26)} ${f(s * w * 0.5)},${f(-h * 1.31)} C${f(s * w * 0.5 + 5)},${f(-h * 1.26)} ${f(s * w * 0.5 + 19)},${f(-h * 1.08)} ${f(s * w * 0.5 + 15)},${f(-h * 0.86)} Z" fill="${d.body}" ${S}/>` +
          `<path d="M${f(s * w * 0.5 - 7)},${f(-h * 0.9)} C${f(s * w * 0.5 - 9)},${f(-h * 1.06)} ${f(s * w * 0.5 - 3)},${f(-h * 1.17)} ${f(s * w * 0.5)},${f(-h * 1.21)} C${f(s * w * 0.5 + 3)},${f(-h * 1.17)} ${f(s * w * 0.5 + 9)},${f(-h * 1.06)} ${f(s * w * 0.5 + 7)},${f(-h * 0.9)} Z" fill="${d.earInner}"/></g>`);
      },
      /** wombat: small, rounded, a little pointed */
      wombat(d, k) {
        const { w, h, S, both } = k;
        return both((s) => {
          const x = s * w * 0.6, y = -h * 0.9;
          return `<path d="M${f(x - s * 16)},${f(y + 8)} Q${f(x - s * 8)},${f(y - 24)} ${f(x + s * 8)},${f(y - 22)} Q${f(x + s * 20)},${f(y - 8)} ${f(x + s * 18)},${f(y + 12)} Z" fill="${d.body}" ${S}/>` +
            `<path d="M${f(x - s * 7)},${f(y + 4)} Q${f(x - s * 2)},${f(y - 14)} ${f(x + s * 7)},${f(y - 12)} Q${f(x + s * 12)},${f(y - 4)} ${f(x + s * 10)},${f(y + 6)} Z" fill="${d.earInner}"/>`;
        });
      },
      /** sugar glider: big, thin, upright ovals */
      glider(d, k) {
        const { w, h, S, both } = k;
        return both((s) => `<g transform="rotate(${s * 24} ${f(s * w * 0.66)} ${f(-h * 0.98)})">` +
          `<ellipse cx="${f(s * w * 0.66)}" cy="${f(-h * 0.98)}" rx="17" ry="25" fill="${d.body}" ${S}/>` +
          `<ellipse cx="${f(s * w * 0.66)}" cy="${f(-h * 0.97)}" rx="9" ry="16" fill="${d.earInner}"/></g>`);
      },
      /** bilby: very long rabbit-like ears splayed in a V, pointed at the tips */
      bilby(d, k) {
        const { w, h, S, both } = k;
        return both((s) => `<g transform="rotate(${s * 24} ${f(s * w * 0.3)} ${f(-h * 0.86)})">` +
          `<path d="M${f(s * w * 0.3 - 17)},${f(-h * 0.84)} C${f(s * w * 0.3 - 24)},${f(-h * 1.12)} ${f(s * w * 0.3 - 8)},${f(-h * 1.44)} ${f(s * w * 0.3)},${f(-h * 1.5)} C${f(s * w * 0.3 + 8)},${f(-h * 1.44)} ${f(s * w * 0.3 + 24)},${f(-h * 1.12)} ${f(s * w * 0.3 + 17)},${f(-h * 0.84)} Z" fill="${d.body}" ${S}/>` +
          `<path d="M${f(s * w * 0.3 - 8)},${f(-h * 0.9)} C${f(s * w * 0.3 - 12)},${f(-h * 1.12)} ${f(s * w * 0.3 - 4)},${f(-h * 1.34)} ${f(s * w * 0.3)},${f(-h * 1.39)} C${f(s * w * 0.3 + 4)},${f(-h * 1.34)} ${f(s * w * 0.3 + 12)},${f(-h * 1.12)} ${f(s * w * 0.3 + 8)},${f(-h * 0.9)} Z" fill="${d.earInner}"/></g>`);
      },
    },

    back: {
      /** galah: a short, rounded pale crest */
      galahCrest(d, k) {
        const { h, S4 } = k, c = d.crestColor;
        return leaf(-4, -h * 0.9, -112, 34, 13, c, S4) + leaf(4, -h * 0.92, -82, 36, 13, c, S4) + leaf(10, -h * 0.9, -58, 28, 11, c, S4);
      },
      /** cockatoo: a tall fan of sulphur-yellow feathers */
      cockyCrest(d, k) {
        const { h, S4 } = k, c = d.crestColor;
        return [[-14, -122, 46], [-6, -102, 62], [4, -82, 66], [12, -62, 56], [18, -44, 40]]
          .map(([x, a, L]) => leaf(x, -h * 0.9, a, L, 12, c, S4)).join('');
      },
      /** kookaburra: a rufous barred tail cocked up behind */
      kookaTail(d, k) {
        const { w, h, S, id } = k;
        const p = `M${f(w * 0.3)},${f(-h * 0.16)} Q${f(w + 4)},${f(-h * 0.5)} ${f(w + 18)},${f(-h * 0.76)} Q${f(w + 34)},${f(-h * 0.8)} ${f(w + 36)},${f(-h * 0.6)} Q${f(w + 22)},${f(-h * 0.3)} ${f(w * 0.5)},${f(-h * 0.02)} Z`;
        return `<g class="c-tail"><clipPath id="${id}k"><path d="${p}"/></clipPath><path d="${p}" fill="${d.tailColor}"/>` +
          `<g clip-path="url(#${id}k)" stroke="${sh(d.tailColor, -0.35)}" stroke-width="5.5">` +
          [0.45, 0.65, 0.85].map((q) => `<path d="M${f(w * 0.3 + 30 * q + 6)},${f(-h * (0.1 + 0.64 * q) - 16)} l28,18"/>`).join('') +
          `</g><path d="${p}" fill="none" ${S}/></g>`;
      },
      /** echidna: cream spines with dark tips, all over the back */
      echidnaSpines(d, k) {
        const { w, h, S4 } = k;
        let out = '';
        const n = 13;
        for (let i = 0; i < n; i++) {
          const a = -196 + (i * 212) / (n - 1);
          const r = (a * Math.PI) / 180;
          const bx = Math.cos(r) * w * 0.8, by = -h * 0.52 + Math.sin(r) * h * 0.42;
          out += spine(bx, by, a, i % 2 ? 38 : 44, 10, d.spineColor, d.spineTip, S4);
        }
        return out;
      },
      /** sugar glider: the furry gliding membrane, stretched from wrist to ankle */
      patagium(d, k) {
        const { w, h, S, both } = k, c = d.wingColor;
        return both((s) => `<path d="M${f(s * w * 0.7)},${f(-h * 0.62)} L${f(s * (w + 30))},${f(-h * 0.5)} ` +
          `Q${f(s * (w + 22))},${f(-h * 0.36)} ${f(s * (w + 30))},${f(-h * 0.22)} Q${f(s * (w + 20))},${f(-h * 0.12)} ${f(s * (w + 22))},${f(-h * 0.02)} ` +
          `L${f(s * w * 0.5)},-6 Z" fill="${c}" ${S}/>`);
      },
      /** frill-neck lizard: the big umbrella frill around its head */
      frill(d, k) {
        const { w, h, S } = k;
        const cx = 0, cy = -h * 0.6, n = 11;
        const ring = (R, inner) => {
          const pts = [];
          for (let i = 0; i <= n * 2; i++) {
            const a = ((-205 + (i * 230) / (n * 2)) * Math.PI) / 180;
            const rr = i % 2 ? R * inner : R;
            pts.push(`${f(cx + Math.cos(a) * rr)},${f(cy + Math.sin(a) * rr * 0.92)}`);
          }
          return pts;
        };
        const outer = ring(w + 36, 0.88), mid = ring(w + 14, 0.94);
        let ribs = '';
        for (let i = 0; i <= n * 2; i += 2) {
          const a = ((-205 + (i * 230) / (n * 2)) * Math.PI) / 180;
          ribs += `<path d="M${f(cx + Math.cos(a) * (w - 4))},${f(cy + Math.sin(a) * (w - 4) * 0.92)} L${f(cx + Math.cos(a) * (w + 30))},${f(cy + Math.sin(a) * (w + 30) * 0.92)}" stroke="${d.frillRib}" stroke-width="4" stroke-linecap="round"/>`;
        }
        return `<polygon points="${outer.join(' ')} ${f(cx)},${f(cy)}" fill="${d.frillColor}" ${S}/>` +
          `<polygon points="${mid.join(' ')} ${f(cx)},${f(cy)}" fill="${d.frillInner}"/>` + ribs;
      },
      /** frill-neck lizard: a long tail curling along the ground */
      lizardTail(d, k) {
        const { w, h, tube } = k;
        return `<g class="c-tail">${tube(`M${f(w * 0.5)},-12 C${w + 20},-4 ${w + 40},-10 ${w + 46},${f(-h * 0.2)} C${w + 50},${f(-h * 0.3)} ${w + 40},${f(-h * 0.36)} ${w + 34},${f(-h * 0.3)}`, d.body, 12)}</g>`;
      },
      /** bilby: a thin black tail with a white crested tip */
      bilbyTail(d, k) {
        const { w, h, tube } = k;
        return `<g class="c-tail">${tube(`M${f(w * 0.5)},-14 C${w + 18},-10 ${w + 26},-24 ${w + 30},${f(-h * 0.34)}`, '#4a4352', 7)}` +
          `${tube(`M${w + 28},${f(-h * 0.28)} C${w + 31},${f(-h * 0.38)} ${w + 32},${f(-h * 0.46)} ${w + 30},${f(-h * 0.54)}`, '#fdfaf3', 11)}</g>`;
      },
      /** mole cricket: short, soft antennae with a little curl */
      cricketAntennae(d, k) {
        const { w, h, both } = k;
        return both((s) => {
          const p = `M${f(s * w * 0.16)},${f(-h * 0.92)} Q${f(s * w * 0.2)},${f(-h * 1.14)} ${f(s * w * 0.48)},${f(-h * 1.16)} Q${f(s * w * 0.62)},${f(-h * 1.16)} ${f(s * w * 0.6)},${f(-h * 1.08)}`;
          return `<path d="${p}" fill="none" stroke="${O}" stroke-width="11" stroke-linecap="round"/><path d="${p}" fill="none" stroke="${d.antennaColor}" stroke-width="4" stroke-linecap="round"/>`;
        });
      },
    },

    marks: {
      /** galah: pale pink cap, grey wings wrapped round the flanks */
      galah(d, k) {
        const { w, h, both } = k;
        return `<ellipse cx="0" cy="${f(-h * 1.04)}" rx="${f(w * 0.78)}" ry="${f(h * 0.24)}" fill="${d.capColor}"/>` +
          both((s) => `<ellipse cx="${f(s * w * 1.02)}" cy="${f(-h * 0.3)}" rx="${f(w * 0.42)}" ry="${f(h * 0.44)}" fill="${d.greyColor}"/>`) +
          `<ellipse cx="0" cy="6" rx="${f(w * 0.7)}" ry="${f(h * 0.1)}" fill="${d.greyColor}"/>`;
      },
      /** kookaburra: brown wings on the flanks, a streaky crown and the dark eye stripe */
      kooka(d, k) {
        const { w, h, fy, ex, both } = k;
        const br = d.wingColor;
        return both((s) => `<ellipse cx="${f(s * w * 1.0)}" cy="${f(-h * 0.36)}" rx="${f(w * 0.4)}" ry="${f(h * 0.5)}" fill="${br}"/>`) +
          `<ellipse cx="0" cy="${f(-h * 1.02)}" rx="${f(w * 0.62)}" ry="${f(h * 0.2)}" fill="${d.crownColor}"/>` +
          [-14, 0, 14].map((x) => `<path d="M${x},${f(-h * 0.98)} L${f(x * 1.2)},${f(-h * 0.86)}" stroke="${sh(d.crownColor, -0.3)}" stroke-width="4" stroke-linecap="round"/>`).join('') +
          both((s) => `<path d="M${f(s * (w * ex + 2))},${f(fy - 1)} Q${f(s * (w * 0.72))},${f(fy - 5)} ${f(s * (w + 6))},${f(fy + 4)} L${f(s * (w + 6))},${f(fy + 15)} Q${f(s * w * 0.72)},${f(fy + 7)} ${f(s * (w * ex + 2))},${f(fy + 8)} Z" fill="${d.stripeColor}"/>`);
      },
      /** emu chick: long cream and brown stripes, a spotty head */
      emu(d, k) {
        const { w, h, fy, both } = k, c = d.markColor;
        const stripe = (x, top, wd) => `<path d="M${f(x)},${f(top)} C${f(x + 6)},${f(top * 0.66)} ${f(x - 6)},${f(top * 0.33)} ${f(x)},4" fill="none" stroke="${c}" stroke-width="${wd}" stroke-linecap="round"/>`;
        return both((s) => stripe(s * w * 0.5, -h * 0.9, 10) + stripe(s * w * 0.94, -h * 0.74, 16)) +
          `<path d="M0,${f(-h * 1.02)} L0,${f(fy - 20)}" stroke="${c}" stroke-width="8" stroke-linecap="round"/>` +
          [[-0.3, 0.86], [0.3, 0.86], [-0.42, 0.74], [0.42, 0.74]].map(([x, y]) => `<circle cx="${f(x * w)}" cy="${f(-y * h)}" r="4" fill="${c}"/>`).join('');
      },
      /** sugar glider: the dark stripe down the forehead and dark rings round the eyes */
      glider(d, k) {
        const { w, h, fy, ex, both } = k, c = d.markColor;
        return `<path d="M-7,${f(-h * 1.02)} L7,${f(-h * 1.02)} L3,${f(fy + 2)} Q0,${f(fy + 5)} -3,${f(fy + 2)} Z" fill="${c}"/>` +
          both((s) => `<ellipse cx="${f(s * w * ex)}" cy="${f(fy)}" rx="14" ry="15" fill="${c}"/>` +
            `<path d="M${f(s * w * ex)},${f(fy - 10)} Q${f(s * w * 0.6)},${f(fy - 26)} ${f(s * w * 0.72)},${f(-h * 0.86)}" stroke="${c}" stroke-width="9" fill="none" stroke-linecap="round"/>`);
      },
      /** mole cricket: the velvety helmet (pronotum) and soft tummy bands */
      cricket(d, k) {
        const { w, h } = k, c = d.markColor;
        return `<path d="M${f(-w - 6)},${f(-h * 0.74)} Q0,${f(-h * 0.84)} ${f(w + 6)},${f(-h * 0.74)} L${f(w + 6)},${f(-h * 1.2)} L${f(-w - 6)},${f(-h * 1.2)} Z" fill="${c}"/>` +
          `<path d="M${f(-w * 0.46)},${f(-h * 0.9)} Q0,${f(-h * 0.98)} ${f(w * 0.46)},${f(-h * 0.9)}" stroke="${sh(c, 0.22)}" stroke-width="6" fill="none" stroke-linecap="round"/>` +
          `<path d="M0,${f(-h * 0.98)} L0,${f(-h * 0.8)}" stroke="${sh(c, -0.25)}" stroke-width="3.5" stroke-linecap="round"/>` +
          [0.2, 0.09].map((y, i) => `<path d="M${f(-w * (0.36 - i * 0.06))},${f(-h * y)} Q0,${f(-h * y + 6)} ${f(w * (0.36 - i * 0.06))},${f(-h * y)}" stroke="${sh(d.belly, -0.12)}" stroke-width="3.5" fill="none" stroke-linecap="round"/>`).join('');
      },
    },

    front: {
      /** joey: mum's pouch, with the joey peeking out of it */
      pouch(d, k) {
        const { w, h, S } = k, c = d.pouchColor;
        // a soft fur pocket: its opening is a smile, high at the sides
        const p = `M${f(-w - 6)},${f(-h * 0.46)} C${f(-w - 14)},${f(-h * 0.12)} ${f(-w * 0.62)},4 0,4 C${f(w * 0.62)},4 ${f(w + 14)},${f(-h * 0.12)} ${f(w + 6)},${f(-h * 0.46)} ` +
          `C${f(w * 0.5)},${f(-h * 0.3)} ${f(-w * 0.5)},${f(-h * 0.3)} ${f(-w - 6)},${f(-h * 0.46)} Z`;
        const shade = `M${f(-w + 2)},${f(-h * 0.5)} C${f(-w * 0.4)},${f(-h * 0.36)} ${f(w * 0.4)},${f(-h * 0.36)} ${f(w - 2)},${f(-h * 0.5)} L${f(w + 6)},${f(-h * 0.46)} C${f(w * 0.5)},${f(-h * 0.3)} ${f(-w * 0.5)},${f(-h * 0.3)} ${f(-w - 6)},${f(-h * 0.46)} Z`;
        return `<path d="${shade}" fill="${sh(d.body, -0.18)}"/><path d="${p}" fill="${c}" ${S}/>` +
          `<path d="M${f(-w + 2)},${f(-h * 0.39)} C${f(-w * 0.4)},${f(-h * 0.27)} ${f(w * 0.4)},${f(-h * 0.27)} ${f(w - 2)},${f(-h * 0.39)}" stroke="${sh(c, 0.35)}" stroke-width="5" fill="none" stroke-linecap="round"/>`;
      },
      /** echidna: a few short spines on top of the head */
      headSpines(d, k) {
        const { h, S4 } = k;
        return spine(-14, -h * 0.9, -108, 22, 6, d.spineColor, d.spineTip, S4) + spine(0, -h * 0.93, -90, 25, 6, d.spineColor, d.spineTip, S4) + spine(14, -h * 0.9, -72, 22, 6, d.spineColor, d.spineTip, S4);
      },
      /** emu chick: a little fuzz on top */
      fuzz(d, k) {
        const { h, S4 } = k, c = d.markColor;
        return leaf(-3, -h * 0.94, -118, 18, 6, c, S4) + leaf(0, -h * 0.95, -88, 22, 6, c, S4) + leaf(3, -h * 0.94, -60, 18, 6, c, S4);
      },
    },

    eyes: {
      /** a parrot's eye: the friendly dot eye with a bare pale ring round it */
      ringDot(d, k) {
        const { w, fy, ex, O: o, both } = k;
        return both((s) => {
          const x = s * w * ex;
          return `<circle cx="${f(x)}" cy="${f(fy)}" r="11" fill="${d.eyeRing}"/>` +
            `<ellipse cx="${f(x)}" cy="${f(fy)}" rx="6.5" ry="8" fill="${o}"/><circle cx="${f(x - 2)}" cy="${f(fy - 3)}" r="2.5" fill="#fff"/>`;
        });
      },
    },

    muzzle: {
      parrotBeak,
      /** kookaburra: the big kingfisher beak, dark on top, pale below */
      kookaBeak(d, k) {
        const { fy, S4 } = k;
        return `<path d="M12,${f(fy + 13)} C-4,${f(fy + 17)} -26,${f(fy + 22)} -42,${f(fy + 28)} C-26,${f(fy + 34)} -4,${f(fy + 32)} 12,${f(fy + 25)} Z" fill="${d.beakLow}" ${S4}/>` +
          `<path d="M14,${f(fy + 1)} C0,${f(fy - 3)} -30,${f(fy + 6)} -48,${f(fy + 24)} C-28,${f(fy + 20)} -4,${f(fy + 20)} 14,${f(fy + 17)} Q19,${f(fy + 9)} 14,${f(fy + 1)} Z" fill="${d.beakTop}" ${S4}/>` +
          `<path d="M4,${f(fy + 5)} Q-12,${f(fy + 5)} -24,${f(fy + 12)}" stroke="#fff" stroke-opacity=".35" stroke-width="3.5" fill="none" stroke-linecap="round"/>`;
      },
      /** platypus: the wide, soft duck bill */
      platyBill(d, k) {
        const { fy, S4 } = k, c = d.muzzleColor;
        return `<path d="M-31,${f(fy + 14)} C-33,${f(fy + 2)} 33,${f(fy + 2)} 31,${f(fy + 14)} C33,${f(fy + 30)} -33,${f(fy + 30)} -31,${f(fy + 14)} Z" fill="${c}" ${S4}/>` +
          `<path d="M-20,${f(fy + 19)} Q0,${f(fy + 24)} 20,${f(fy + 19)}" stroke="${sh(c, -0.35)}" stroke-width="3" fill="none" stroke-linecap="round"/>` +
          `<ellipse cx="-6" cy="${f(fy + 10)}" rx="2.4" ry="3" fill="${O}"/><ellipse cx="6" cy="${f(fy + 10)}" rx="2.4" ry="3" fill="${O}"/>` +
          `<ellipse cx="-16" cy="${f(fy + 9)}" rx="6" ry="2.4" fill="#fff" opacity=".3"/>`;
      },
      /** echidna: a long thin snout */
      echidnaSnout(d, k) {
        const { fy, tube } = k, c = d.muzzleColor;
        return tube(`M0,${f(fy + 6)} C0,${f(fy + 20)} 0,${f(fy + 30)} -3,${f(fy + 38)}`, c, 13) +
          `<ellipse cx="-3" cy="${f(fy + 39)}" rx="4.5" ry="3" fill="${O}"/>`;
      },
      /** bilby: a long pointy snout with a pink nose */
      bilbySnout(d, k) {
        const { fy, S4 } = k;
        return `<path d="M-15,${f(fy + 6)} Q0,${f(fy - 2)} 15,${f(fy + 6)} Q8,${f(fy + 24)} 2,${f(fy + 32)} Q0,${f(fy + 34)} -2,${f(fy + 32)} Q-8,${f(fy + 24)} -15,${f(fy + 6)} Z" fill="${d.muzzleColor}" ${S4}/>` +
          `<ellipse cx="0" cy="${f(fy + 30)}" rx="7" ry="5.5" fill="${d.noseColor}" ${S4}/>`;
      },
    },

    nose: {
      /** wombat: the big, square, leathery nose */
      wombat(d, k) {
        const { fy, S4 } = k, c = d.noseColor;
        return `<rect x="-18" y="${f(fy + 3)}" width="36" height="24" rx="11" fill="${c}" ${S4}/>` +
          `<path d="M-9,${f(fy + 17)} q3,-5 6,0 M3,${f(fy + 17)} q3,-5 6,0" stroke="${sh(c, -0.5)}" stroke-width="3" fill="none" stroke-linecap="round"/>` +
          `<ellipse cx="-7" cy="${f(fy + 8)}" rx="6" ry="2.5" fill="#fff" opacity=".35"/>`;
      },
      /** lizard: two little nostrils */
      nostrils(d, k) {
        const { fy } = k;
        return `<circle cx="-5" cy="${f(fy + 9)}" r="2.2" fill="${O}"/><circle cx="5" cy="${f(fy + 9)}" r="2.2" fill="${O}"/>`;
      },
    },

    mouth: {
      /** under the wombat's big nose */
      under(d, k) {
        const my = k.fy + 33;
        return `<path d="M-7,${f(my)} Q-3.5,${f(my + 5)} 0,${f(my)} Q3.5,${f(my + 5)} 7,${f(my)}" fill="none" stroke="${O}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>`;
      },
      /** a lizard's wide grin */
      grin(d, k) {
        const my = k.fy + 18;
        return `<path d="M-20,${f(my - 3)} Q0,${f(my + 11)} 20,${f(my - 3)}" fill="none" stroke="${O}" stroke-width="4" stroke-linecap="round"/>`;
      },
    },

    arms: {
      /** joey: little paws resting on the rim of the pouch */
      rimPaws(d, k) {
        const { w, h, S, both } = k, c = d.armColor || sh(d.body, -0.06);
        return both((s) => `<g class="${arm(s)}"><ellipse cx="${f(s * w * 0.5)}" cy="${f(-h * 0.36)}" rx="12" ry="9" fill="${c}" ${S}/>` +
          `<path d="M${f(s * w * 0.5 - 4)},${f(-h * 0.36 + 2)} l0,5 M${f(s * w * 0.5 + 4)},${f(-h * 0.36 + 2)} l0,5" stroke="${O}" stroke-width="2.5" stroke-linecap="round"/></g>`);
      },
      /** kookaburra: brown wings with the blue shoulder patch */
      kookaWing(d, k) {
        const { w, h, S, both } = k, c = d.armColor;
        return both((s) => `<g class="${arm(s)}"><path d="M${f(s * (w - 12))},${f(-h * 0.62)} Q${f(s * (w + 18))},${f(-h * 0.48)} ${f(s * (w - 2))},${f(-h * 0.16)} Q${f(s * (w - 18))},${f(-h * 0.34)} ${f(s * (w - 12))},${f(-h * 0.62)} Z" fill="${c}" ${S}/>` +
          [[-0.52, 3.5], [-0.45, 3], [-0.4, 3.2]].map(([y, r], i) => `<circle cx="${f(s * (w - 6 + i * 3))}" cy="${f(h * y)}" r="${r}" fill="${d.blueColor}"/>`).join('') + `</g>`);
      },
      /** sugar glider: paws out at the corners of its gliding membrane */
      gliderPaws(d, k) {
        const { w, h, S, both } = k, c = d.armColor;
        return both((s) => `<g class="${arm(s)}"><ellipse cx="${f(s * (w + 28))}" cy="${f(-h * 0.5)}" rx="9" ry="8" fill="${c}" ${S}/></g>`);
      },
      /** mole cricket: big, soft, shovel-shaped digging hands */
      shovels(d, k) {
        const { w, h, S, both } = k, c = d.armColor;
        // a broad digging hand: a wide palm and three fat, rounded fingers fanned outwards
        return both((s) => {
          const fingers = [-42, 0, 42].map((a) => {
            const r = (a * Math.PI) / 180, cx = s * (8 + Math.cos(r) * 17), cy = Math.sin(r) * 17;
            return `<ellipse cx="${f(cx)}" cy="${f(cy)}" rx="11" ry="7.5" fill="${c}" ${S} transform="rotate(${s * a} ${f(cx)} ${f(cy)})"/>`;
          }).join('');
          return `<g class="${arm(s)}"><g transform="translate(${f(s * (w - 4))} ${f(-h * 0.34)}) rotate(${s * 38})">${fingers}` +
            `<ellipse cx="${s * 4}" cy="0" rx="17" ry="15" fill="${c}" ${S}/>` +
            `<path d="M${s * -6},-7 Q${s * 3},-11 ${s * 12},-6" stroke="${sh(c, 0.3)}" stroke-width="3.5" fill="none" stroke-linecap="round"/></g></g>`;
        });
      },
    },

    feet: {
      /** emu chick: big three-toed feet */
      bigBird(d, k) {
        const { w, both } = k, c = d.feetColor;
        return both((s) => {
          const x = s * w * 0.34;
          const p = `M${f(x - 15)},4 L${f(x)},-12 L${f(x + 15)},4 M${f(x)},-12 L${f(x)},6`;
          return `<path d="${p}" fill="none" stroke="${O}" stroke-width="14" stroke-linecap="round" stroke-linejoin="round"/>` +
            `<path d="${p}" fill="none" stroke="${c}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>`;
        });
      },
      /** platypus: webbed feet */
      webbed(d, k) {
        const { w, S, both } = k, c = d.feetColor;
        return both((s) => {
          const x = s * w * 0.42;
          return `<path d="M${f(x - 18)},-2 Q${f(x - 20)},-14 ${f(x)},-14 Q${f(x + 20)},-14 ${f(x + 18)},-2 Q${f(x + 12)},4 ${f(x + 6)},0 Q${f(x)},5 ${f(x - 6)},0 Q${f(x - 12)},4 ${f(x - 18)},-2 Z" fill="${c}" ${S}/>`;
        });
      },
    },
  };

  /* ============================================================== friends */
  const CREAM = '#fdf3e4', WHITE = '#fdfaf3', PINK = '#f6b3bf';
  const friends = [
    { id: 'galah', name: 'Galah', body: '#f39cb4', back: ['galahCrest'], crestColor: '#fde1e8', marks: ['galah'], capColor: '#fbd0dc', greyColor: '#b7bcc6',
      arms: 'wing', armColor: '#a3a9b4', feet: 'bird', feetColor: '#a3a9b4', muzzle: 'parrotBeak', muzzleColor: '#f1e6d2', nose: 'none', mouth: 'none',
      eyes: 'ringDot', eyeRing: '#fde1e8', cheekColor: '#e8668a',
      call: 'galah', karaoke: ['bush', 'crow', 1300] },
    { id: 'cockatoo', name: 'Cockatoo', shape: 'tall', body: WHITE, back: ['cockyCrest'], crestColor: '#ffd84a',
      arms: 'wing', armColor: '#efebe0', feet: 'bird', feetColor: '#9a949c', muzzle: 'parrotBeak', muzzleColor: '#56505a', nose: 'none', mouth: 'none',
      eyes: 'ringDot', eyeRing: '#dcecf5', cheekColor: '#ffd36b',
      call: 'cockatoo', karaoke: ['bush', 'crow', 1000] },
    { id: 'kookaburra', name: 'Kookaburra', body: '#f6efe2', marks: ['kooka'], wingColor: '#9a6a47', crownColor: '#d9bf9c', stripeColor: '#6e4a33',
      back: ['kookaTail'], tailColor: '#c46f3c', arms: 'kookaWing', armColor: '#8a5d3e', blueColor: '#7fb6e0', feet: 'bird', feetColor: '#c9a27a',
      muzzle: 'kookaBeak', beakTop: '#4f4540', beakLow: '#efe3cc', nose: 'none', mouth: 'none', eyeX: 0.4,
      call: 'kooka', karaoke: ['bush', 'ah', 600] },
    { id: 'emu', name: 'Emu Chick', shape: 'tall', body: '#f0dfbb', belly: '#f8ecd2', marks: ['emu'], markColor: '#7a5640', front: ['fuzz'],
      arms: 'wing', armColor: '#e4cda2', feet: 'bigBird', feetColor: '#8f8994', muzzle: 'beak', muzzleColor: '#6f6873', nose: 'none', mouth: 'none',
      call: 'emu', karaoke: ['bush', 'hoot', 300] },
    { id: 'joey', name: 'Joey', say: 'It\'s a baby kangaroo, a joey!', shape: 'tall', body: '#e2ad7c', ears: 'roo', earInner: '#f4c3b4', muzzle: 'snout', muzzleColor: '#f6e2c8',
      front: ['pouch'], pouchColor: '#cf9764', arms: 'rimPaws', armColor: '#d79c6a', feet: 'none', faceY: 0.62,
      call: 'boing', karaoke: ['bush', 'bloop', 500] },
    { id: 'wombat', name: 'Wombat', shape: 'wide', body: '#a48d7b', ears: 'wombat', earInner: '#dcc3b4', marks: ['muzzlePatch'], faceColor: '#c9b4a2',
      nose: 'wombat', noseColor: '#4f403c', mouth: 'under', front: ['claws'], armColor: '#8f7868', feetColor: '#8f7868', faceY: 0.6,
      call: 'huff', karaoke: ['bush', 'oink', 150] },
    { id: 'platypus', name: 'Platypus', shape: 'wide', body: '#94694a', belly: '#d9b48c', back: ['paddleTail'], tailColor: '#7a5538',
      muzzle: 'platyBill', muzzleColor: '#6d7383', nose: 'none', mouth: 'none', feet: 'webbed', feetColor: '#6d7383', armColor: '#7f5a3f', faceY: 0.62,
      call: 'platypus', karaoke: ['water', 'croak', 260] },
    { id: 'echidna', name: 'Echidna', shape: 'small', body: '#80604a', back: ['echidnaSpines'], front: ['headSpines', 'claws'], spineColor: '#f4e2b2', spineTip: '#4f3a2c',
      muzzle: 'echidnaSnout', muzzleColor: '#4f3f36', nose: 'none', mouth: 'none', armColor: '#6b4f3c', feetColor: '#6b4f3c',
      call: 'sniff', karaoke: ['bush', 'sniff', 2600] },
    { id: 'sugarglider', name: 'Sugar Glider', shape: 'small', body: '#a9adbd', belly: '#f6f0e4', ears: 'glider', earInner: PINK,
      marks: ['glider'], markColor: '#4f4c5c', back: ['patagium'], wingColor: '#9da1b2', arms: 'gliderPaws', armColor: '#f3c6c9',
      eyes: 'big', noseColor: '#f18ea0', feetColor: '#f3c6c9',
      call: 'glider', karaoke: ['bush', 'squeak', 2200] },
    { id: 'frillneck', name: 'Frill-neck Lizard', body: '#e3bf7f', belly: '#f6e2b4', back: ['frill', 'lizardTail'], frillColor: '#f07d4e', frillInner: '#ffcf66', frillRib: '#cf5a35',
      marks: ['spots'], markColor: '#cfa264', spotPts: [[-0.72, 0.7, 7], [0.74, 0.66, 8], [-0.8, 0.44, 6], [0.82, 0.4, 6], [0.3, 0.95, 5], [-0.32, 0.93, 5]],
      nose: 'nostrils', mouth: 'grin', feetColor: '#cfa264', armColor: '#d6ad6c', cheekColor: '#f39a7b',
      call: 'frill', karaoke: ['bush', 'sniff', 3800] },
    { id: 'bilby', name: 'Bilby', shape: 'small', body: '#bdb3c8', belly: WHITE, ears: 'bilby', earInner: '#f6b8c8', back: ['bilbyTail'],
      muzzle: 'bilbySnout', muzzleColor: '#ece4ee', noseColor: '#f28fab', nose: 'none', mouth: 'none', whiskers: true, feetColor: '#e9c7d2', armColor: '#b0a6bd',
      call: 'squeak', karaoke: ['bush', 'squeak', 2400] },
    { id: 'molecricket', name: 'Mole Cricket', shape: 'wide', body: '#b9875c', belly: '#e2bd90', marks: ['cricket'], markColor: '#8c5d3c', back: ['cricketAntennae'], antennaColor: '#8c5d3c',
      arms: 'shovels', armColor: '#8c5d3c', eyes: 'big', mouth: 'u', nose: 'none', feetColor: '#8c5d3c', faceY: 0.5,
      call: 'churr', karaoke: ['bush', 'buzz', 420] },
  ];

  /* ================================================================ calls
   * Synth stand-ins for the new calls (sounds/<id>.mp3 replace them once loaded). */
  const calls = {
    galah: { len: 0.5, play: (k, t, o) => { k.say.crow(t, 1350, 0.16, o); k.say.crow(t + 0.24, 1500, 0.2, o); } },
    cockatoo: { len: 0.45, play: (k, t, o) => k.say.crow(t, 1050, 0.42, o) },
    kooka: {
      len: 1.5,
      play: (k, t, o) => {
        // koo-koo-koo-ka-ka-ka: a laugh that climbs and tumbles
        [560, 600, 640, 760, 820, 900, 820, 760, 700, 640, 600].forEach((hz, i) => k.say.ah(t + i * 0.12, hz, 0.1, o, 0.8));
        k.say.ooh(t + 1.35, 520, 0.14, o);
      },
    },
    emu: { len: 0.9, play: (k, t, o) => [0, 0.3, 0.6].forEach((g) => k.say.hoot(t + g, 150, 0.24, o, 1.2)) },
    huff: { len: 0.55, play: (k, t, o) => { k.say.ork(t, 170, 0.2, o, 0.8); k.say.oink(t + 0.28, 140, 0.24, o, 0.8); } },
    platypus: { len: 0.45, play: (k, t, o) => k.say.croak(t, 270, 0.42, o, 0.7) },
    glider: { len: 0.4, play: (k, t, o) => [0, 0.13, 0.26].forEach((g, i) => k.say.woof(t + g, 900 + i * 40, 0.08, o, 0.6)) },
    frill: { len: 0.5, play: (k, t, o) => { k.say.sniff(t, 4200, 0.3, o, 0.6); k.say.squeak(t + 0.32, 2200, 0.14, o); } },
    churr: { len: 0.7, play: (k, t, o) => { for (let i = 0; i < 12; i++) k.say.squeak(t + i * 0.055, 2500, 0.04, o, 0.8); } },
  };

  /* ================================================================ worlds */
  // only the full app has GC.Scenes (the contact sheets in tools/ load just the animals)
  const K = GC.Scenes ? GC.Scenes.kit : null;

  const props = K && (() => {
    const { P, S } = K;
    return {
      /** a gum tree: pale smooth trunk that forks, drooping grey-green leaf clumps */
      gum(x, y, s = 1, trunk = '#efe6d6', leafC = '#93b48a') {
        const t = `M${f(x - 9 * s)},${y} Q${f(x - 7 * s)},${f(y - 40 * s)} ${f(x - 4 * s)},${f(y - 62 * s)} L${f(x - 24 * s)},${f(y - 96 * s)} L${f(x - 15 * s)},${f(y - 100 * s)} L${f(x)},${f(y - 74 * s)} L${f(x + 16 * s)},${f(y - 104 * s)} L${f(x + 25 * s)},${f(y - 98 * s)} L${f(x + 6 * s)},${f(y - 62 * s)} Q${f(x + 8 * s)},${f(y - 40 * s)} ${f(x + 10 * s)},${y} Z`;
        const clump = (cx, cy, rx, ry, c) => `<ellipse cx="${f(cx)}" cy="${f(cy)}" rx="${f(rx)}" ry="${f(ry)}" fill="${c}" ${S()}/>`;
        const hang = (cx, cy) => `<path d="M${f(cx)},${f(cy)} q-2,${f(9 * s)} 1,${f(15 * s)}" stroke="${O}" stroke-width="3" fill="none" stroke-linecap="round"/>`;
        return `<g class="sway" style="--sd:${GC.rand(6, 9).toFixed(1)}s">` +
          `<path d="${t}" fill="${trunk}" ${S()}/>` +
          `<path d="M${f(x - 2 * s)},${f(y - 14 * s)} q${f(3 * s)},${f(-8 * s)} 0,${f(-18 * s)} M${f(x + 4 * s)},${f(y - 38 * s)} q${f(-3 * s)},${f(-6 * s)} 0,${f(-14 * s)}" stroke="${sh(trunk, -0.25)}" stroke-width="3" fill="none" stroke-linecap="round"/>` +
          clump(x - 30 * s, y - 104 * s, 30 * s, 17 * s, leafC) + clump(x + 30 * s, y - 108 * s, 30 * s, 17 * s, leafC) +
          clump(x, y - 124 * s, 34 * s, 19 * s, sh(leafC, 0.1)) +
          hang(x - 44 * s, y - 92 * s) + hang(x - 20 * s, y - 90 * s) + hang(x + 22 * s, y - 94 * s) + hang(x + 46 * s, y - 96 * s) +
          `<ellipse cx="${f(x - 8 * s)}" cy="${f(y - 130 * s)}" rx="${f(12 * s)}" ry="${f(5 * s)}" fill="${sh(leafC, 0.3)}"/></g>`;
      },
      /** a termite mound: a lumpy red-earth spire */
      mound(x, y, s = 1, c = '#c96f43') {
        const p = `M${f(x - 26 * s)},${y} Q${f(x - 28 * s)},${f(y - 22 * s)} ${f(x - 18 * s)},${f(y - 30 * s)} Q${f(x - 22 * s)},${f(y - 48 * s)} ${f(x - 12 * s)},${f(y - 58 * s)} ` +
          `Q${f(x - 10 * s)},${f(y - 78 * s)} ${f(x - 2 * s)},${f(y - 84 * s)} Q${f(x + 6 * s)},${f(y - 82 * s)} ${f(x + 7 * s)},${f(y - 66 * s)} Q${f(x + 16 * s)},${f(y - 62 * s)} ${f(x + 14 * s)},${f(y - 44 * s)} ` +
          `Q${f(x + 26 * s)},${f(y - 34 * s)} ${f(x + 22 * s)},${f(y - 16 * s)} Q${f(x + 28 * s)},${f(y - 8 * s)} ${f(x + 27 * s)},${y} Q${x},${f(y + 5 * s)} ${f(x - 26 * s)},${y} Z`;
        return `<path d="${p}" fill="${c}" ${S()}/>` +
          `<path d="M${f(x - 6 * s)},${f(y - 70 * s)} Q${f(x - 8 * s)},${f(y - 50 * s)} ${f(x - 4 * s)},${f(y - 30 * s)} M${f(x + 10 * s)},${f(y - 30 * s)} Q${f(x + 12 * s)},${f(y - 20 * s)} ${f(x + 8 * s)},${f(y - 8 * s)}" stroke="${sh(c, 0.3)}" stroke-width="3.5" fill="none" stroke-linecap="round"/>` +
          `<path d="M${f(x - 18 * s)},${f(y - 12 * s)} q4,-3 8,0 M${f(x + 2 * s)},${f(y - 48 * s)} q4,-3 8,0" stroke="${sh(c, -0.25)}" stroke-width="3" fill="none" stroke-linecap="round"/>`;
      },
      /** spinifex: a round hummock of spiky golden grass */
      spinifex(x, y, s = 1, c = '#c9c065') {
        let pts = `${f(x - 26 * s)},${y} `;
        const n = 11;
        for (let i = 0; i <= n; i++) {
          const a = Math.PI + (i / n) * Math.PI;
          const r = (i % 2 ? 22 : 30) * s;
          pts += `${f(x + Math.cos(a) * r)},${f(y + Math.sin(a) * r * 0.8)} `;
        }
        pts += `${f(x + 26 * s)},${y}`;
        return `<g class="sway" style="--sd:5s"><polygon points="${pts}" fill="${c}" ${S(3.5)}/>` +
          `<path d="M${x},${f(y - 2)} L${x},${f(y - 18 * s)} M${f(x - 8 * s)},${f(y - 2)} L${f(x - 12 * s)},${f(y - 14 * s)} M${f(x + 8 * s)},${f(y - 2)} L${f(x + 12 * s)},${f(y - 14 * s)}" stroke="${sh(c, -0.25)}" stroke-width="2.5" stroke-linecap="round"/></g>`;
      },
      /** Sturt's desert pea: red flowers with a dark glossy centre */
      pea(x, y, s = 1) {
        const fl = (a) => {
          const r = (a * Math.PI) / 180, fx = x + Math.cos(r) * 13 * s, fy2 = y - 22 * s + Math.sin(r) * 9 * s;
          return `<path d="M${f(fx)},${f(fy2 - 8 * s)} Q${f(fx + 9 * s)},${f(fy2)} ${f(fx)},${f(fy2 + 8 * s)} Q${f(fx - 9 * s)},${f(fy2)} ${f(fx)},${f(fy2 - 8 * s)} Z" fill="#e8463c" ${S(3)}/>` +
            `<circle cx="${f(fx)}" cy="${f(fy2 - 1 * s)}" r="${f(3.2 * s)}" fill="#2e2426"/>`;
        };
        return `<g class="bob" style="--bd:${GC.rand(3, 4.5).toFixed(1)}s"><path d="M${x},${y} L${x},${f(y - 20 * s)}" stroke="${O}" stroke-width="7" stroke-linecap="round"/><path d="M${x},${y} L${x},${f(y - 20 * s)}" stroke="#8fae7a" stroke-width="3" stroke-linecap="round"/>` +
          fl(200) + fl(-20) + fl(-90) + fl(90) + `</g>`;
      },
      /** a wattle bush: soft green with golden pompoms */
      wattle(x, y, s = 1) {
        let dots = '';
        const r = GC.seeded(Math.round(x * 7 + y));
        for (let i = 0; i < 11; i++) dots += `<circle cx="${f(x + (r() - 0.5) * 48 * s)}" cy="${f(y - 8 * s - r() * 30 * s)}" r="${f(4 * s)}" fill="#ffd23f" ${S(2)}/>`;
        return P.bush(x, y, s, '#8fae5f').replace('</g>', dots + '</g>');
      },
      /** a little opal glinting in the dirt */
      opal(u, v) {
        return `<g class="glow-pulse"><ellipse cx="${u}" cy="${v}" rx="7" ry="5" fill="#9fd8e8" ${S(2.5)} ${K.NS}/>` +
          `<ellipse cx="${u - 2}" cy="${v - 1}" rx="3" ry="2" fill="#f7a8c8"/><ellipse cx="${u + 3}" cy="${v + 1}" rx="2" ry="1.5" fill="#c5e88a"/></g>`;
      },
      /** sleeping in its burrow (upright in screen space): a mole cricket with its helmet and shovels */
      miniCricket(x, y) {
        return `<g class="burrow-critter">` +
          `<ellipse cx="${x - 16}" cy="${y - 7}" rx="7" ry="6" fill="#8c5d3c" ${S(3)}/><ellipse cx="${x + 16}" cy="${y - 7}" rx="7" ry="6" fill="#8c5d3c" ${S(3)}/>` +
          `<path d="M${x - 15},${y} Q${x - 17},${y - 24} ${x},${y - 26} Q${x + 17},${y - 24} ${x + 15},${y} Z" fill="#b9875c" ${S(3.5)}/>` +
          `<path d="M${x - 13},${y - 15} Q${x},${y - 18} ${x + 13},${y - 15} Q${x + 12},${y - 25} ${x},${y - 26} Q${x - 12},${y - 25} ${x - 13},${y - 15} Z" fill="#8c5d3c"/>` +
          `<path d="M${x - 15},${y} Q${x - 17},${y - 24} ${x},${y - 26} Q${x + 17},${y - 24} ${x + 15},${y} Z" fill="none" ${S(3.5)}/>` +
          `<path d="M${x - 5},${y - 26} q-3,-7 -8,-8 M${x + 5},${y - 26} q3,-7 8,-8" stroke="${O}" stroke-width="2.5" fill="none" stroke-linecap="round"/>` +
          `<g class="blink"><path d="M${x - 8},${y - 10} q3,3 6,0 M${x + 2},${y - 10} q3,3 6,0" stroke="${O}" stroke-width="2.2" fill="none" stroke-linecap="round"/></g></g>`;
      },
      /** sleeping in its bank burrow: a platypus, bill and all */
      miniPlatypus(x, y) {
        return `<g class="burrow-critter">` +
          `<path d="M${x - 16},${y} Q${x - 18},${y - 20} ${x},${y - 22} Q${x + 18},${y - 20} ${x + 16},${y} Z" fill="#94694a" ${S(3.5)}/>` +
          `<ellipse cx="${x}" cy="${y - 6}" rx="11" ry="5" fill="#6d7383" ${S(3)}/>` +
          `<g class="blink"><path d="M${x - 8},${y - 13} q3,3 6,0 M${x + 2},${y - 13} q3,3 6,0" stroke="${O}" stroke-width="2.2" fill="none" stroke-linecap="round"/></g></g>`;
      },
    };
  })();

  /* the two worlds; only drawn when the app builds a scene (props exist then) */
  const scenes = [
    {
      id: 'outback', name: 'Red Dirt Outback', bg: '#f7d6ad', ring: '#5fb3c8', particles: 'reddust',
      top: '#dc7f50', left: '#c0663d', right: '#a3532f', lip: '#cf7347',
      sky: () => `<g class="sun-pulse"><circle cx="490" cy="96" r="40" fill="#ffc94a" ${K.S()}/></g>` + K.P.cloud(130, 130, 0.8, '#fff3e2') + K.gull(380, 150) + K.gull(410, 136),
      ground: () => `<ellipse cx="70" cy="60" rx="30" ry="18" fill="#e39364"/><ellipse cx="180" cy="200" rx="34" ry="20" fill="#e39364"/>` +
        `<path d="M20,150 Q70,130 120,150 T230,140" stroke="#cf7347" stroke-width="9" fill="none" stroke-linecap="round" ${K.NS}/>` +
        // the mole cricket's front door, with a little heap of dug-out dirt
        `<ellipse cx="200" cy="60" rx="16" ry="12" fill="#e39364" ${K.S(3)} ${K.NS}/><ellipse cx="196" cy="62" rx="8" ry="6" fill="#5a2f22"/>` +
        [[40, 200], [120, 30], [220, 120], [90, 110]].map(([u, v]) => `<circle cx="${u}" cy="${v}" r="4" fill="#b85f38"/>`).join(''),
      leftSide: (r) => K.strata(['#c0663d', '#cb7448', '#b55c36', '#c46a40']) +
        // the mole cricket's tunnel, winding down to its chamber
        `<path d="M200,12 Q190,34 160,40 T110,58 T70,76" stroke="#e8a27a" stroke-width="13" fill="none" stroke-linecap="round" ${K.NS}/>` +
        K.burrow(66, 80, 30, 20, '#c0663d') + K.pebbles(r, '#9a4a2a', 8, 30) + props.opal(150, 92) + props.opal(30, 40),
      rightSide: (r, c) => K.strata(['#a3532f', '#ae5d36', '#9a4c2b']) + K.burrow(150, 66, 36, 24, c) + K.pebbles(r, '#7f3e22', 9) + props.opal(60, 96),
      sideCritters: () => props.miniCricket(...K.leftPt(66, 96)) + K.P.burrowCritter(...K.shift(K.rightPt(150, 84), 4, 0), '#7d6a5c', '#fdfaf3'),
      back: () => props.mound(150, 342, 1.1) + props.gum(420, 330, 1.05) + props.mound(250, 296, 0.75, '#d07a4c') +
        props.spinifex(340, 292, 1.1) + props.spinifex(108, 374, 1.15) + K.P.rock(480, 368, 0.7, '#b86a48') + props.pea(214, 318, 1.1) + props.spinifex(468, 338, 0.95),
      front: () => props.spinifex(100, 406, 1.25) + props.pea(500, 404, 1.2) + K.P.rock(170, 444, 0.55, '#b86a48') + props.spinifex(440, 446, 0.75),
    },
    {
      id: 'billabong', name: 'Gum Tree Billabong', bg: '#d6e8d8', ring: '#f2b544', particles: 'gumleaves',
      top: '#9cc46a', left: '#a8774f', right: '#5fb3c8', lip: '#86b055', rightLip: '#4f9fb4',
      sky: () => K.P.cloud(120, 120, 0.9) + K.P.cloud(470, 160, 0.7) + `<g class="sun-pulse"><circle cx="500" cy="80" r="30" fill="#ffd86b" ${K.S()}/></g>`,
      ground: () => `<path d="M100,0 L240,0 L240,240 L120,240 Q70,190 110,140 Q150,90 100,40 Q90,18 100,0 Z" fill="#6cc0d4" ${K.S(4)} ${K.NS}/>` +
        `<path d="M150,30 Q180,40 200,70" stroke="#fff" stroke-opacity=".5" stroke-width="4" fill="none" stroke-linecap="round" ${K.NS}/>` +
        `<ellipse class="ripple" cx="190" cy="170" rx="14" ry="14" fill="none" stroke="#fff" stroke-opacity=".6" stroke-width="2.5" ${K.NS}/>` +
        `<ellipse cx="40" cy="190" rx="22" ry="14" fill="#b4d67e"/><ellipse cx="50" cy="40" rx="18" ry="12" fill="#b4d67e"/>`,
      leftSide: (r, c) => K.roots(r, '#7d5034', 4) + K.burrow(90, 66, 34, 22, c) +
        `<path d="M124,60 Q170,40 230,26" stroke="${sh(c, 0.18)}" stroke-width="12" fill="none" stroke-linecap="round" ${K.NS}/>` + K.pebbles(r, '#8f6545', 9),
      rightSide: () => K.waterSide('#5fb3c8'),
      sideCritters: () => props.miniPlatypus(...K.leftPt(90, 82)) + K.P.fish(...K.rightPt(70, 55), '#f3b54a', 1) + K.P.fish(...K.rightPt(170, 80), '#9fd8e8', -1),
      back: () => props.gum(170, 336, 1.15, '#efe6d6', '#8fb08a') + props.gum(330, 282, 0.9, '#e6d3c4', '#9cbc8c') + props.wattle(470, 352, 0.85) +
        K.P.reeds(430, 296, 0.8) + K.P.lilypad(400, 330, 0.8, true) + K.P.rock(110, 372, 0.7, '#a3a89f') + K.P.bird(158, 214, '#c9a27a') + K.P.tuft(250, 304),
      front: () => props.wattle(100, 404, 0.7) + K.P.reeds(500, 412, 0.8) + K.P.lilypad(430, 446, 0.7, true) + K.P.tuft(170, 434),
    },
  ];

  /* ============================================================ particles */
  const particles = {
    /** falling gum leaves: long and narrow, grey-green and a dry one or two */
    gumleaves: (i, x, y, st) => `<g transform="translate(${f(x)} -20)"><path class="p-fall p-spin" ${st} d="M0,-10 C4,-5 4,5 0,10 C-4,5 -4,-5 0,-10 Z" ` +
      `fill="${['#8fb08a', '#a9c08f', '#d9b25a'][i % 3]}" stroke="${O}" stroke-width="2"/></g>`,
    /** red dust drifting in the sun */
    reddust: (i, x, y, st, r) => `<g transform="translate(${f(x)} ${f(110 + y)})"><circle class="${i % 3 ? 'p-firefly' : 'p-rise'}" ${st} r="${f(2 + r() * 2)}" fill="${['#f6b98a', '#fde3c8', '#e98e5e'][i % 3]}"/></g>`,
  };

  /* ===================================================== Egg karaoke band
   * A bush band: the banjo has the tune, the flute answers, ukulele strums,
   * upright bass walks, and the spoons click the backbeat. */
  const instruments = {
    banjo: { syn: (k, n, t, d, g, o) => k.banjo(n, t, 0.08 * g, o), gain: 0.34, home: 69 },
    spoons: { syn: (k, n, t, d, g) => { k.claves(t, 0.06 * g); k.claves(t + 0.03, 0.04 * g); }, gain: 0.42 },
  };
  const worlds = {
    bush: { bpm: 122, lead: 'banjo', second: 'flute', comp: 'uke', compStyle: 'strum', bass: 'bass', bassStyle: 'walk', sparkle: 'glock', kick: 'kick', back: 'spoons', tick: 'shaker', perc: 'woodblock', chirp: 'kooka' },
  };
  const chirps = {
    /** a kookaburra laugh made of the chord's notes: koo-koo-ka-ka-ka, climbing then tumbling */
    kooka(p, k, t, chord, hi, o) {
      const seq = [hi[0], hi[1], hi[2], hi[2], hi[1], hi[2], hi[1], hi[0]];
      seq.forEach((n, i) => (i < 2 ? k.say.ooh : k.say.ah)(t + i * 0.07, midi(n - 12), 0.06, o, 0.55));
    },
  };

  GC.Packs.register({
    id: 'aussie', name: 'Aussie Bush', blurb: 'Galahs, wombats, a joey and a mole cricket', icon: 'paw',
    friends, parts, calls,
    scenes: props ? scenes : [],
    particles, worlds, chirps, instruments,
  });
})();

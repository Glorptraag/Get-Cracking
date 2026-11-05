/* Get Cracking — 40 hatchable friends.
 *
 * Every animal is a chunky "one-blob" chibi (head + body in one bean shape,
 * like the hamster / Chiku references) assembled from parts:
 *   back layer  : tails, wings, manes, quills, shells, ears
 *   body        : fill, clipped belly + markings, then a crisp outline pass
 *   front layer : arms, feet, floppy ears, face (eyes, cheeks, muzzle, mouth)
 *
 * Coordinates: feet sit on y = 0, the animal grows upward (negative y),
 * centred on x = 0. Roughly 200 wide x 200 tall.
 *
 * Groups carry class hooks used by CSS for idle loops:
 *   .c-squash (whole body bounce), .c-eyes (blink), .c-ears (wiggle),
 *   .c-arm-l / .c-arm-r (wave), .c-tail (wag)
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT;
  const S = `stroke="${O}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"`;
  const S4 = `stroke="${O}" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"`;
  const sh = GC.shade;
  const f = (n) => Math.round(n * 10) / 10;
  const both = (fn) => fn(-1) + fn(1);

  const SHAPES = {
    round: { w: 64, h: 128 },
    tall: { w: 56, h: 140 },
    wide: { w: 72, h: 118 },
    small: { w: 58, h: 118 },
  };

  function bodyPath(w, h) {
    return `M${-w},${f(-h * 0.45)} C${-w},${f(-h * 1.15)} ${w},${f(-h * 1.15)} ${w},${f(-h * 0.45)} ` +
      `C${w},${f(-h * 0.05)} ${f(w * 0.75)},0 0,0 C${f(-w * 0.75)},0 ${-w},${f(-h * 0.05)} ${-w},${f(-h * 0.45)} Z`;
  }

  /** A thick stroked "tube" with an outline: draws path twice. */
  function tube(d, color, width) {
    return `<path d="${d}" fill="none" stroke="${O}" stroke-width="${width + 9}" stroke-linecap="round" stroke-linejoin="round"/>` +
      `<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round"/>`;
  }

  function roundedTri(a, b, c, fill, inner) {
    let out = `<path d="M${f(a[0])},${f(a[1])} L${f(b[0])},${f(b[1])} L${f(c[0])},${f(c[1])} Z" fill="${fill}" ${S}/>`;
    if (inner) {
      const cx = (a[0] + b[0] + c[0]) / 3, cy = (a[1] + b[1] + c[1]) / 3;
      const k = 0.5;
      const p = (q) => [cx + (q[0] - cx) * k, cy + (q[1] - cy) * k + 3];
      const [ia, ib, ic] = [p(a), p(b), p(c)];
      out += `<path d="M${f(ia[0])},${f(ia[1])} L${f(ib[0])},${f(ib[1])} L${f(ic[0])},${f(ic[1])} Z" fill="${inner}" stroke="${inner}" stroke-width="5" stroke-linejoin="round"/>`;
    }
    return out;
  }

  /* ------------------------------------------------------------- ears */
  function ears(d, w, h) {
    const c = d.earColor || d.body;
    const ic = d.earInner || sh(c, 0.4);
    switch (d.ears) {
      case 'round':
        return both((s) => `<circle cx="${f(s * w * 0.62)}" cy="${f(-h * 0.86)}" r="19" fill="${c}" ${S}/>` +
          `<circle cx="${f(s * w * 0.62)}" cy="${f(-h * 0.86)}" r="9" fill="${ic}"/>`);
      case 'pointy':
        return both((s) => roundedTri([s * w * 0.16, -h * 0.9], [s * w * 0.72, -h * 1.22], [s * w * 0.9, -h * 0.62], c, ic));
      case 'tall':
        return both((s) => roundedTri([s * w * 0.12, -h * 0.9], [s * w * 0.62, -h * 1.32], [s * w * 0.9, -h * 0.7], c, ic));
      case 'bat':
        return both((s) => roundedTri([s * w * 0.12, -h * 0.88], [s * w * 0.98, -h * 1.32], [s * w * 0.95, -h * 0.56], c, ic));
      case 'tufts':
        return both((s) => roundedTri([s * w * 0.32, -h * 0.93], [s * w * 0.82, -h * 1.12], [s * w * 0.86, -h * 0.72], c));
      case 'long':
        return both((s) => `<g transform="rotate(${s * 10} ${s * 22} ${f(-h - 26)})">` +
          `<ellipse cx="${s * 22}" cy="${f(-h - 26)}" rx="15" ry="40" fill="${c}" ${S}/>` +
          `<ellipse cx="${s * 22}" cy="${f(-h - 22)}" rx="6.5" ry="27" fill="${ic}"/></g>`);
      case 'tiny':
        return both((s) => `<circle cx="${f(s * w * 0.5)}" cy="${f(-h * 0.93)}" r="10" fill="${c}" ${S}/>`);
      case 'bigRound':
        return both((s) => `<circle cx="${f(s * w * 0.72)}" cy="${f(-h * 0.9)}" r="30" fill="${c}" ${S}/>` +
          `<circle cx="${f(s * w * 0.72)}" cy="${f(-h * 0.9)}" r="18" fill="${ic}"/>`);
      case 'fluffy':
        return both((s) => `<circle cx="${f(s * w * 0.84)}" cy="${f(-h * 0.82)}" r="28" fill="${c}" ${S}/>` +
          `<circle cx="${f(s * w * 0.88)}" cy="${f(-h * 0.8)}" r="15" fill="${ic}"/>`);
      case 'side':
        return both((s) => `<circle cx="${f(s * (w + 3))}" cy="${f(-h * 0.58)}" r="17" fill="${c}" ${S}/>` +
          `<circle cx="${f(s * (w + 5))}" cy="${f(-h * 0.58)}" r="8.5" fill="${ic}"/>`);
      case 'elephant':
        return both((s) => `<ellipse cx="${f(s * (w + 10))}" cy="${f(-h * 0.6)}" rx="34" ry="42" fill="${c}" ${S}/>` +
          `<ellipse cx="${f(s * (w + 14))}" cy="${f(-h * 0.6)}" rx="21" ry="29" fill="${ic}"/>`);
      default:
        return '';
    }
  }

  // floppy ears are drawn in front of the body
  function earsFront(d, w, h) {
    const c = d.earColor || sh(d.body, -0.2);
    if (d.ears === 'floppy') {
      return both((s) => `<ellipse cx="${f(s * (w - 2))}" cy="${f(-h * 0.7)}" rx="16" ry="30" fill="${c}" ${S} transform="rotate(${s * 16} ${f(s * (w - 2))} ${f(-h * 0.7)})"/>`);
    }
    if (d.ears === 'goat') {
      return both((s) => `<ellipse cx="${f(s * (w + 6))}" cy="${f(-h * 0.72)}" rx="26" ry="12" fill="${c}" ${S} transform="rotate(${s * 22} ${f(s * (w + 6))} ${f(-h * 0.72)})"/>`);
    }
    return '';
  }

  /* -------------------------------------------- behind-the-body extras */
  function back(d, w, h, id) {
    let out = '';
    const a = d.accent || sh(d.body, -0.25);
    for (const x of d.back || []) {
      switch (x) {
        case 'tailFluffy': {
          const p = `M${f(w * 0.55)},${f(-h * 0.22)} C${w + 58},${f(-h * 0.16)} ${w + 62},${f(-h * 0.86)} ${w + 26},${f(-h * 1.02)} ` +
            `C${w + 20},${f(-h * 0.76)} ${w + 8},${f(-h * 0.52)} ${f(w * 0.7)},${f(-h * 0.46)} Z`;
          out += `<g class="c-tail"><clipPath id="${id}t"><path d="${p}"/></clipPath><path d="${p}" fill="${d.tailColor || d.body}"/>` +
            `<g clip-path="url(#${id}t)"><circle cx="${w + 30}" cy="${f(-h * 0.98)}" r="26" fill="${d.tailTip || '#fdf3e4'}"/></g>` +
            `<path d="${p}" fill="none" ${S}/></g>`;
          break;
        }
        case 'tailStriped': {
          const p = `M${f(w * 0.55)},${f(-h * 0.2)} C${w + 52},${f(-h * 0.18)} ${w + 56},${f(-h * 0.84)} ${w + 24},${f(-h * 0.98)} ` +
            `C${w + 18},${f(-h * 0.74)} ${w + 8},${f(-h * 0.5)} ${f(w * 0.7)},${f(-h * 0.44)} Z`;
          let stripes = '';
          for (let i = 0; i < 4; i++) {
            stripes += `<rect x="${w - 20}" y="${f(-h * (0.42 + i * 0.17))}" width="120" height="12" fill="${d.tailStripe || a}" transform="rotate(-28 ${w + 20} ${f(-h * 0.5)})"/>`;
          }
          out += `<g class="c-tail"><clipPath id="${id}t"><path d="${p}"/></clipPath><path d="${p}" fill="${d.tailColor || d.body}"/>` +
            `<g clip-path="url(#${id}t)">${stripes}</g><path d="${p}" fill="none" ${S}/></g>`;
          break;
        }
        case 'tailSquirrel': {
          const p = `M${f(w * 0.45)},${f(-h * 0.14)} C${w + 78},${f(-h * 0.08)} ${w + 74},${f(-h * 1.2)} ${w + 16},${f(-h * 1.18)} ` +
            `C${w - 12},${f(-h * 1.16)} ${w - 6},${f(-h * 0.9)} ${w + 16},${f(-h * 0.9)} ` +
            `C${w + 34},${f(-h * 0.88)} ${w + 22},${f(-h * 0.5)} ${f(w * 0.62)},${f(-h * 0.42)} Z`;
          out += `<g class="c-tail"><path d="${p}" fill="${d.tailColor || d.body}" ${S}/>` +
            `<path d="M${w + 10},${f(-h * 0.35)} C${w + 40},${f(-h * 0.45)} ${w + 44},${f(-h * 0.85)} ${w + 22},${f(-h * 1.05)}" fill="none" stroke="${sh(d.tailColor || d.body, 0.25)}" stroke-width="5" stroke-linecap="round"/></g>`;
          break;
        }
        case 'tailThin':
          out += `<g class="c-tail">${tube(`M${f(w * 0.6)},-12 C${w + 30},-6 ${w + 40},-40 ${w + 22},${f(-h * 0.42)} C${w + 10},${f(-h * 0.55)} ${w + 32},${f(-h * 0.62)} ${w + 36},${f(-h * 0.52)}`, d.tailColor || '#f4a7b0', 6)}</g>`;
          break;
        case 'tailCurl':
          out += `<g class="c-tail">${tube(`M${w - 6},${f(-h * 0.3)} C${w + 12},${f(-h * 0.26)} ${w + 22},${f(-h * 0.44)} ${w + 10},${f(-h * 0.5)} C${w},${f(-h * 0.54)} ${w + 2},${f(-h * 0.38)} ${w + 16},${f(-h * 0.36)}`, d.body, 7)}</g>`;
          break;
        case 'tailDino': {
          const p = `M${f(w * 0.5)},-6 C${w + 30},-4 ${w + 50},-20 ${w + 56},${f(-h * 0.34)} C${w + 40},${f(-h * 0.28)} ${w + 20},${f(-h * 0.36)} ${f(w * 0.6)},${f(-h * 0.4)} Z`;
          out += `<g class="c-tail"><path d="${p}" fill="${d.body}" ${S}/></g>`;
          break;
        }
        case 'batWings':
          out += both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}"><path d="M${f(s * w * 0.6)},${f(-h * 0.72)} Q${f(s * (w + 44))},${f(-h * 1.02)} ${f(s * (w + 52))},${f(-h * 0.52)} ` +
            `Q${f(s * (w + 36))},${f(-h * 0.5)} ${f(s * (w + 28))},${f(-h * 0.36)} Q${f(s * (w + 16))},${f(-h * 0.42)} ${f(s * w * 0.8)},${f(-h * 0.24)} Z" fill="${d.wingColor || a}" ${S}/></g>`);
          break;
        case 'dragonWings':
          out += both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}"><path d="M${f(s * w * 0.55)},${f(-h * 0.7)} Q${f(s * (w + 30))},${f(-h * 1.05)} ${f(s * (w + 40))},${f(-h * 0.78)} ` +
            `Q${f(s * (w + 26))},${f(-h * 0.66)} ${f(s * (w + 26))},${f(-h * 0.5)} Q${f(s * (w + 10))},${f(-h * 0.5)} ${f(s * w * 0.8)},${f(-h * 0.36)} Z" fill="${d.wingColor || a}" ${S}/></g>`);
          break;
        case 'mane': {
          const cx = 0, cy = -h * 0.6, R = w + 6;
          let bumps = '';
          for (let i = 0; i < 14; i++) {
            const t = (i / 14) * Math.PI * 2;
            bumps += `<circle cx="${f(cx + Math.cos(t) * R)}" cy="${f(cy + Math.sin(t) * R * 0.92)}" r="20" fill="${d.maneColor}" ${S}/>`;
          }
          out += bumps + `<ellipse cx="${cx}" cy="${f(cy)}" rx="${R}" ry="${f(R * 0.92)}" fill="${d.maneColor}"/>`;
          break;
        }
        case 'quills': {
          const cx = 0, cy = -h * 0.52, n = 20;
          let pts = [];
          for (let i = 0; i < n * 2; i++) {
            const t = (i / (n * 2)) * Math.PI * 2 - Math.PI / 2;
            const r = i % 2 === 0 ? 1.32 : 1.08;
            pts.push(`${f(cx + Math.cos(t) * w * r)},${f(cy + Math.sin(t) * h * 0.56 * r)}`);
          }
          out += `<polygon points="${pts.join(' ')}" fill="${d.quillColor}" ${S}/>`;
          break;
        }
        case 'fleece': {
          const cx = 0, cy = -h * 0.5;
          let bumps = '';
          for (let i = 0; i < 16; i++) {
            const t = (i / 16) * Math.PI * 2;
            bumps += `<circle cx="${f(cx + Math.cos(t) * (w + 4))}" cy="${f(cy + Math.sin(t) * (h * 0.52))}" r="19" fill="${d.fleeceColor}" ${S}/>`;
          }
          out += bumps + `<ellipse cx="${cx}" cy="${f(cy)}" rx="${w + 4}" ry="${f(h * 0.52)}" fill="${d.fleeceColor}"/>`;
          break;
        }
        case 'turtleShell': {
          const p = `M${-w - 20},${f(-h * 0.2)} C${-w - 24},${f(-h * 1.0)} ${w + 24},${f(-h * 1.0)} ${w + 20},${f(-h * 0.2)} Q0,${f(-h * 0.08)} ${-w - 20},${f(-h * 0.2)} Z`;
          out += `<clipPath id="${id}s"><path d="${p}"/></clipPath><path d="${p}" fill="${d.shellColor}"/>` +
            `<g clip-path="url(#${id}s)" fill="${d.shellSpot}">` +
            `<circle cx="${-w - 6}" cy="${f(-h * 0.5)}" r="16"/><circle cx="${w + 6}" cy="${f(-h * 0.5)}" r="16"/>` +
            `<circle cx="${-w + 8}" cy="${f(-h * 0.82)}" r="14"/><circle cx="${w - 8}" cy="${f(-h * 0.82)}" r="14"/></g>` +
            `<path d="${p}" fill="none" ${S}/>`;
          break;
        }
        case 'snailShell': {
          const cx = w * 0.45, cy = -h * 0.72, r = h * 0.5;
          out += `<circle cx="${f(cx)}" cy="${f(cy)}" r="${f(r)}" fill="${d.shellColor}" ${S}/>` +
            `<path d="M${f(cx)},${f(cy)} m-4,2 a6,6 0 1 1 10,-6 a14,14 0 1 1 -20,14 a24,24 0 1 1 36,-26 a34,34 0 1 1 -48,40" fill="none" stroke="${d.shellSpot}" stroke-width="6" stroke-linecap="round"/>`;
          break;
        }
        case 'gills':
          out += both((s) => [0, 1, 2].map((k) =>
            tube(`M${f(s * w * 0.7)},${f(-h * (0.78 - k * 0.12))} Q${f(s * (w + 14))},${f(-h * (0.86 - k * 0.12))} ${f(s * (w + 26))},${f(-h * (0.94 - k * 0.15))}`, d.gillColor, 9)
          ).join(''));
          break;
        case 'spikes':
          out += [-26, 0, 26].map((x, i) => roundedTri([x - 13, -h * 0.9 + Math.abs(x) * 0.15], [x, -h * 1.12 - (i === 1 ? 8 : 0) + Math.abs(x) * 0.15], [x + 13, -h * 0.9 + Math.abs(x) * 0.15], d.spikeColor)).join('');
          break;
        case 'horns':
          out += both((s) => tube(`M${f(s * w * 0.3)},${f(-h * 0.88)} Q${f(s * w * 0.42)},${f(-h * 1.08)} ${f(s * w * 0.62)},${f(-h * 1.1)}`, d.hornColor, 9));
          break;
        case 'nubs':
          out += both((s) => tube(`M${f(s * w * 0.36)},${f(-h * 0.9)} L${f(s * w * 0.44)},${f(-h * 1.05)}`, d.hornColor, 10));
          break;
        case 'antennae':
          out += both((s) => `<path d="M${f(s * w * 0.18)},${f(-h * 0.92)} Q${f(s * w * 0.2)},${f(-h * 1.16)} ${f(s * w * 0.46)},${f(-h * 1.24)}" fill="none" stroke="${O}" stroke-width="5" stroke-linecap="round"/>` +
            `<circle cx="${f(s * w * 0.46)}" cy="${f(-h * 1.24)}" r="7" fill="${d.antennaColor || O}" ${S4}/>`);
          break;
        case 'eyeStalks':
          out += both((s) => `<path d="M${f(s * w * 0.16)},${f(-h * 0.9)} L${f(s * w * 0.36)},${f(-h * 1.18)}" fill="none" stroke="${O}" stroke-width="15" stroke-linecap="round"/>` +
            `<path d="M${f(s * w * 0.16)},${f(-h * 0.9)} L${f(s * w * 0.36)},${f(-h * 1.18)}" fill="none" stroke="${d.body}" stroke-width="7" stroke-linecap="round"/>` +
            `<circle cx="${f(s * w * 0.36)}" cy="${f(-h * 1.2)}" r="11" fill="${d.body}" ${S4}/>`);
          break;
        case 'frogBumps':
          out += both((s) => `<circle cx="${f(s * w * 0.46)}" cy="${f(-h * 0.92)}" r="21" fill="${d.body}" ${S}/>`);
          break;
      }
    }
    return out;
  }

  /* ------------------------------------------- markings (inside body) */
  function markings(d, w, h, fy, ex) {
    let out = '';
    const m = d.markColor || sh(d.body, -0.3);
    for (const x of d.marks || []) {
      switch (x) {
        case 'stripes':
          for (const s of [-1, 1]) for (let k = 0; k < 3; k++) {
            const y = -h * (0.3 + k * 0.17);
            out += `<path d="M${f(s * (w + 6))},${f(y - 7)} L${f(s * (w - 22))},${f(y)} L${f(s * (w + 6))},${f(y + 7)} Z" fill="${m}" stroke="${m}" stroke-width="3" stroke-linejoin="round"/>`;
          }
          out += [-14, 0, 14].map((x) => `<path d="M${x - 6},${f(-h)} L${x},${f(-h * (x ? 0.88 : 0.84))} L${x + 6},${f(-h)} Z" fill="${m}" stroke="${m}" stroke-width="3" stroke-linejoin="round"/>`).join('');
          break;
        case 'spots': {
          const pts = d.spotPts || [[-0.55, 0.82, 9], [0.6, 0.78, 7], [-0.7, 0.4, 8], [0.66, 0.36, 10], [0.2, 0.95, 6], [-0.25, 0.22, 6]];
          out += pts.map(([x, y, r]) => `<circle cx="${f(x * w)}" cy="${f(-y * h)}" r="${r}" fill="${m}"/>`).join('');
          break;
        }
        case 'patches':
          out += `<ellipse cx="${f(-w * 0.72)}" cy="${f(-h * 0.8)}" rx="28" ry="22" fill="${m}" transform="rotate(-20 ${f(-w * 0.72)} ${f(-h * 0.8)})"/>` +
            `<ellipse cx="${f(w * 0.82)}" cy="${f(-h * 0.32)}" rx="24" ry="30" fill="${m}"/>` +
            `<ellipse cx="${f(-w * 0.3)}" cy="${f(-h * 0.08)}" rx="18" ry="12" fill="${m}"/>`;
          break;
        case 'mask':
          out += `<path d="M${-w - 4},${f(fy - 12)} Q0,${f(fy - 2)} ${w + 4},${f(fy - 12)} L${w + 4},${f(fy + 9)} Q${f(w * 0.3)},${f(fy + 12)} 0,${f(fy + 4)} Q${f(-w * 0.3)},${f(fy + 12)} ${-w - 4},${f(fy + 9)} Z" fill="${m}"/>`;
          break;
        case 'eyePatches':
          out += both((s) => `<ellipse cx="${f(s * w * ex)}" cy="${f(fy + 2)}" rx="15" ry="18" fill="${m}" transform="rotate(${s * -28} ${f(s * w * ex)} ${f(fy + 2)})"/>`);
          break;
        case 'eyePatch':
          out += `<ellipse cx="${f(w * ex + 2)}" cy="${f(fy - 1)}" rx="17" ry="16" fill="${m}"/>`;
          break;
        case 'faceMask':
          out += both((s) => `<circle cx="${f(s * w * 0.3)}" cy="${f(fy + 4)}" r="${f(w * 0.42)}" fill="${d.faceColor}"/>`);
          break;
        case 'faceHeart':
          out += both((s) => `<circle cx="${f(s * w * 0.3)}" cy="${f(fy)}" r="${f(w * 0.38)}" fill="${d.faceColor}"/>`) +
            `<ellipse cx="0" cy="${f(fy + 20)}" rx="${f(w * 0.52)}" ry="22" fill="${d.faceColor}"/>`;
          break;
        case 'lowerFace':
          out += `<path d="M${-w - 4},${f(fy + 4)} Q${f(-w * 0.35)},${f(fy + 2)} 0,${f(fy + 22)} Q${f(w * 0.35)},${f(fy + 2)} ${w + 4},${f(fy + 4)} L${w + 4},4 L${-w - 4},4 Z" fill="${d.faceColor}"/>`;
          break;
        case 'faceOval':
          out += `<ellipse cx="0" cy="${f(fy + 6)}" rx="${f(w * 0.74)}" ry="${f(h * 0.27)}" fill="${d.faceColor}"/>`;
          break;
        case 'muzzlePatch':
          out += `<ellipse cx="0" cy="${f(fy + 16)}" rx="${f(w * 0.56)}" ry="22" fill="${d.faceColor}"/>`;
          break;
        case 'redPanda':
          out += `<ellipse cx="0" cy="${f(fy + 18)}" rx="${f(w * 0.5)}" ry="17" fill="${d.faceColor}"/>` +
            both((s) => `<circle cx="${f(s * w * 0.4)}" cy="${f(fy - 17)}" r="6" fill="${d.faceColor}"/>` +
              `<ellipse cx="${f(s * w * 0.72)}" cy="${f(fy + 14)}" rx="13" ry="16" fill="${d.faceColor}"/>` +
              `<path d="M${f(s * w * ex)},${f(fy + 6)} Q${f(s * w * 0.42)},${f(fy + 24)} ${f(s * w * 0.3)},${f(fy + 36)}" stroke="${m}" stroke-width="8" fill="none" stroke-linecap="round"/>`);
          break;
        case 'slothEyes':
          out += both((s) => `<ellipse cx="${f(s * w * ex)}" cy="${f(fy + 4)}" rx="16" ry="9" fill="${m}" transform="rotate(${s * 22} ${f(s * w * ex)} ${f(fy + 4)})"/>`);
          break;
        case 'cap':
          out += `<ellipse cx="0" cy="${f(-h * 1.08)}" rx="${f(w * 0.85)}" ry="${f(h * 0.26)}" fill="${m}"/>`;
          break;
        case 'fawnSpots':
          out += [[-0.75, 0.62], [-0.6, 0.42], [-0.82, 0.3], [0.75, 0.6], [0.62, 0.4], [0.84, 0.28], [0.0, 0.98]]
            .map(([x, y]) => `<circle cx="${f(x * w)}" cy="${f(-y * h)}" r="5.5" fill="${m}"/>`).join('');
          break;
        case 'owlBelly':
          out += [[-14, 0.34], [14, 0.34], [0, 0.22], [-22, 0.16], [22, 0.16]]
            .map(([x, y]) => `<path d="M${x - 6},${f(-y * h)} Q${x},${f(-y * h + 7)} ${x + 6},${f(-y * h)}" fill="none" stroke="${m}" stroke-width="4" stroke-linecap="round"/>`).join('');
          break;
        case 'plastron':
          out += `<path d="M-30,${f(-h * 0.3)} L30,${f(-h * 0.3)} M-34,${f(-h * 0.16)} L34,${f(-h * 0.16)} M0,${f(-h * 0.48)} L0,0" stroke="${m}" stroke-width="4" stroke-linecap="round"/>`;
          break;
      }
    }
    return out;
  }

  /* ---------------------------------------------------------- face */
  function eyes(d, w, h, fy, ex) {
    if (d.eyes === 'none') return '';
    const ey = d.eyesOnBumps ? -h * 0.93 : fy;
    const exx = d.eyesOnBumps ? 0.46 : ex;
    if (d.eyes === 'stalk') {
      return both((s) => `<ellipse cx="${f(s * w * 0.36)}" cy="${f(-h * 1.2)}" rx="5.5" ry="6.5" fill="${O}"/>` +
        `<circle cx="${f(s * w * 0.36 - 1.8)}" cy="${f(-h * 1.2 - 2.4)}" r="2" fill="#fff"/>`);
    }
    return both((s) => {
      const x = s * w * exx;
      switch (d.eyes) {
        case 'big':
          return `<circle cx="${f(x)}" cy="${f(ey)}" r="10" fill="${O}"/><circle cx="${f(x - 3)}" cy="${f(ey - 4)}" r="3.6" fill="#fff"/><circle cx="${f(x + 3)}" cy="${f(ey + 3)}" r="1.6" fill="#fff"/>`;
        case 'ringed':
          return `<circle cx="${f(x)}" cy="${f(ey)}" r="9" fill="#fdfaf3"/><ellipse cx="${f(x)}" cy="${f(ey)}" rx="5.5" ry="6.5" fill="${O}"/><circle cx="${f(x - 2)}" cy="${f(ey - 2.5)}" r="2" fill="#fff"/>`;
        case 'happy':
          return `<path d="M${f(x - 7)},${f(ey + 2)} Q${f(x)},${f(ey - 8)} ${f(x + 7)},${f(ey + 2)}" fill="none" stroke="${O}" stroke-width="5" stroke-linecap="round"/>`;
        case 'tiny':
          return `<ellipse cx="${f(x)}" cy="${f(ey)}" rx="3.6" ry="4.2" fill="${O}"/>`;
        default:
          return `<ellipse cx="${f(x)}" cy="${f(ey)}" rx="6.5" ry="8" fill="${O}"/><circle cx="${f(x - 2)}" cy="${f(ey - 3)}" r="2.5" fill="#fff"/>`;
      }
    });
  }

  function muzzle(d, w, h, fy) {
    const mc = d.muzzleColor || sh(d.body, 0.5);
    switch (d.muzzle) {
      case 'snout':
        return `<ellipse cx="0" cy="${f(fy + 16)}" rx="${f(w * 0.34)}" ry="16" fill="${mc}"/>`;
      case 'pig': {
        const rx = d.snoutW || 17;
        return `<ellipse cx="0" cy="${f(fy + 16)}" rx="${rx}" ry="12" fill="${mc}" ${S4}/>` +
          `<ellipse cx="${-rx * 0.34}" cy="${f(fy + 16)}" rx="3" ry="4.5" fill="${O}"/><ellipse cx="${rx * 0.34}" cy="${f(fy + 16)}" rx="3" ry="4.5" fill="${O}"/>`;
      }
      case 'beak':
        return `<path d="M-9,${f(fy + 7)} L9,${f(fy + 7)} L0,${f(fy + 19)} Z" fill="${mc}" ${S4}/>`;
      case 'bill':
        return `<ellipse cx="0" cy="${f(fy + 14)}" rx="17" ry="9" fill="${mc}" ${S4}/><path d="M-11,${f(fy + 14)} Q0,${f(fy + 18)} 11,${f(fy + 14)}" fill="none" stroke="${O}" stroke-width="3" stroke-linecap="round"/>`;
      case 'trunk':
        return tube(`M0,${f(fy + 6)} C0,${f(fy + 28)} -2,${f(fy + 38)} -16,${f(fy + 42)}`, d.body, 17);
      case 'capy':
        return `<rect x="-27" y="${f(fy + 2)}" width="54" height="32" rx="16" fill="${mc}"/>` +
          `<ellipse cx="-9" cy="${f(fy + 11)}" rx="3" ry="4.5" fill="${O}"/><ellipse cx="9" cy="${f(fy + 11)}" rx="3" ry="4.5" fill="${O}"/>`;
      default:
        return '';
    }
  }

  function nose(d, fy) {
    const nc = d.noseColor || O;
    const ny = fy + (d.muzzle === 'snout' ? 9 : 8);
    switch (d.nose) {
      case 'none': return '';
      case 'big':
        return `<ellipse cx="0" cy="${f(fy + 11)}" rx="13" ry="10" fill="${nc}" ${nc === O ? '' : S4}/><ellipse cx="-4" cy="${f(fy + 7)}" rx="4" ry="2.5" fill="#fff" opacity=".7"/>`;
      default:
        return `<path d="M-6.5,${f(ny - 2)} Q0,${f(ny - 5)} 6.5,${f(ny - 2)} Q0,${f(ny + 7)} -6.5,${f(ny - 2)} Z" fill="${nc}" stroke="${nc}" stroke-width="3" stroke-linejoin="round"/>`;
    }
  }

  function mouth(d, fy) {
    const my = fy + (d.muzzle === 'snout' ? 17 : d.nose === 'big' ? 25 : d.muzzle === 'capy' ? 24 : 16);
    switch (d.mouth) {
      case 'none': return '';
      case 'u':
        return `<path d="M-6,${f(my)} Q0,${f(my + 7)} 6,${f(my)}" fill="none" stroke="${O}" stroke-width="4" stroke-linecap="round"/>`;
      case 'wide':
        return `<path d="M-16,${f(my - 2)} Q0,${f(my + 10)} 16,${f(my - 2)}" fill="none" stroke="${O}" stroke-width="4" stroke-linecap="round"/>`;
      case 'open':
        return `<path d="M-7,${f(my)} Q0,${f(my + 13)} 7,${f(my)} Z" fill="#c4505a" ${S4}/>`;
      case 'fang':
        return `<path d="M-7,${f(my)} Q-3.5,${f(my + 5)} 0,${f(my)} Q3.5,${f(my + 5)} 7,${f(my)}" fill="none" stroke="${O}" stroke-width="4" stroke-linecap="round"/>` +
          `<path d="M2,${f(my + 2)} L4.5,${f(my + 8)} L6.5,${f(my + 1)} Z" fill="#fff" stroke="${O}" stroke-width="2" stroke-linejoin="round"/>`;
      default: // 'w'
        return `<path d="M-7.5,${f(my)} Q-3.75,${f(my + 5.5)} 0,${f(my)} Q3.75,${f(my + 5.5)} 7.5,${f(my)}" fill="none" stroke="${O}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>`;
    }
  }

  function whiskers(d, w, fy) {
    if (!d.whiskers) return '';
    return both((s) => `<path d="M${f(s * w * 0.46)},${f(fy + 13)} L${f(s * w * 0.86)},${f(fy + 8)} M${f(s * w * 0.46)},${f(fy + 19)} L${f(s * w * 0.86)},${f(fy + 21)}" stroke="${O}" stroke-width="3" stroke-linecap="round"/>`);
  }

  function arms(d, w, h) {
    const c = d.armColor || sh(d.body, -0.06);
    switch (d.arms) {
      case 'none': return '';
      case 'wing':
        return both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}"><path d="M${f(s * (w - 12))},${f(-h * 0.6)} Q${f(s * (w + 18))},${f(-h * 0.46)} ${f(s * (w - 2))},${f(-h * 0.16)} Q${f(s * (w - 18))},${f(-h * 0.34)} ${f(s * (w - 12))},${f(-h * 0.6)} Z" fill="${c}" ${S}/></g>`);
      case 'flipper':
        return both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}"><ellipse cx="${f(s * (w - 2))}" cy="${f(-h * 0.34)}" rx="10" ry="22" fill="${c}" ${S} transform="rotate(${s * -30} ${f(s * (w - 2))} ${f(-h * 0.34)})"/></g>`);
      default:
        return both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}"><ellipse cx="${f(s * (w - 9))}" cy="${f(-h * 0.3)}" rx="11" ry="14" fill="${c}" ${S} transform="rotate(${s * -25} ${f(s * (w - 9))} ${f(-h * 0.3)})"/></g>`);
    }
  }

  function feet(d, w) {
    const c = d.feetColor || sh(d.body, -0.12);
    switch (d.feet) {
      case 'none': return '';
      case 'bird':
        return both((s) => `<path d="M${f(s * w * 0.32 - 10)},2 L${f(s * w * 0.32)},-10 L${f(s * w * 0.32 + 10)},2 M${f(s * w * 0.32)},-10 L${f(s * w * 0.32)},3" fill="none" stroke="${O}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>` +
          `<path d="M${f(s * w * 0.32 - 10)},2 L${f(s * w * 0.32)},-10 L${f(s * w * 0.32 + 10)},2 M${f(s * w * 0.32)},-10 L${f(s * w * 0.32)},3" fill="none" stroke="${d.feetColor || '#f7a531'}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>`);
      default:
        return both((s) => `<ellipse cx="${f(s * w * 0.42)}" cy="-4" rx="17" ry="9.5" fill="${c}" ${S}/>`);
    }
  }

  function front(d, w, h) {
    let out = '';
    for (const x of d.front || []) {
      switch (x) {
        case 'tuft': {
          const t = -h * 0.95, c = d.tuftColor || sh(d.body, -0.08);
          out += `<path d="M0,${f(t)} C-3,${f(t - 22)} 10,${f(t - 30)} 14,${f(t - 24)} C6,${f(t - 22)} 4,${f(t - 10)} 0,${f(t)} Z" fill="${c}" ${S4}/>` +
            `<path d="M0,${f(t)} C-6,${f(t - 14)} -18,${f(t - 18)} -20,${f(t - 10)} C-12,${f(t - 12)} -6,${f(t - 6)} 0,${f(t)} Z" fill="${c}" ${S4}/>`;
          break;
        }
        case 'horn': {
          const t = -h * 0.94;
          out += `<path d="M-11,${f(t + 4)} L0,${f(t - 46)} L11,${f(t + 4)} Z" fill="${d.hornColor}" ${S}/>` +
            `<path d="M-7,${f(t - 8)} L6,${f(t - 14)} M-4,${f(t - 22)} L4,${f(t - 27)}" stroke="${O}" stroke-width="3.5" stroke-linecap="round"/>`;
          break;
        }
        case 'pastelMane': {
          const cols = ['#f7a8c8', '#c5a8f0', '#9fd8e8', '#ffe08a'];
          out += cols.map((c, i) => `<circle cx="${f(-w * 0.55 + i * 13)}" cy="${f(-h * 0.9 - (i % 2) * 6)}" r="${15 - i}" fill="${c}" ${S4}/>`).join('');
          break;
        }
        case 'fleeceTuft':
          out += [-16, 0, 16].map((x) => `<circle cx="${x}" cy="${f(-h * 0.97 - (x ? 0 : 6))}" r="14" fill="${d.fleeceColor}" ${S4}/>`).join('');
          break;
        case 'leaf':
          out += `<path d="M0,${f(-h * 0.97)} L0,${f(-h * 1.12)}" stroke="${O}" stroke-width="5" stroke-linecap="round"/>` +
            `<path d="M0,${f(-h * 1.1)} C-6,${f(-h * 1.3)} -26,${f(-h * 1.28)} -28,${f(-h * 1.2)} C-20,${f(-h * 1.12)} -6,${f(-h * 1.1)} 0,${f(-h * 1.1)} Z" fill="#a9d36b" ${S4}/>` +
            `<path d="M0,${f(-h * 1.1)} C6,${f(-h * 1.28)} 24,${f(-h * 1.26)} 26,${f(-h * 1.18)} C18,${f(-h * 1.1)} 6,${f(-h * 1.1)} 0,${f(-h * 1.1)} Z" fill="#a9d36b" ${S4}/>`;
          break;
        case 'claws':
          out += both((s) => `<path d="M${f(s * (w - 14))},${f(-h * 0.2)} l${s * -3},8 M${f(s * (w - 8))},${f(-h * 0.2)} l0,9 M${f(s * (w - 2))},${f(-h * 0.22)} l${s * 3},8" stroke="${O}" stroke-width="3" stroke-linecap="round"/>`);
          break;
      }
    }
    return out;
  }

  /**
   * Render one animal to SVG markup.
   * @returns {string} a <g class="critter"> ... </g>
   */
  function render(d) {
    const { w, h } = SHAPES[d.shape || 'round'];
    const id = GC.uid('a');
    const fy = -h * (d.faceY || 0.56);
    const ex = d.eyeX || 0.36;
    const bp = bodyPath(w, h);
    const cheeks = d.cheeks === false ? '' : both((s) =>
      `<ellipse cx="${f(s * w * 0.62)}" cy="${f(fy + 15)}" rx="9" ry="5.5" fill="${d.cheekColor || '#f48f97'}" opacity=".7"/>`);
    const belly = d.belly ? `<ellipse cx="0" cy="${f(-h * 0.24)}" rx="${f(w * 0.62)}" ry="${f(h * 0.27)}" fill="${d.belly}"/>` : '';

    return `<g class="critter" data-animal="${d.id}">` +
      `<ellipse class="c-shadow" cx="0" cy="2" rx="${w + 6}" ry="10" fill="${O}" opacity=".18"/>` +
      `<g class="c-squash">` +
      `<g class="c-back">${back(d, w, h, id)}</g>` +
      `<g class="c-ears">${ears(d, w, h)}</g>` +
      `<clipPath id="${id}b"><path d="${bp}"/></clipPath>` +
      `<path d="${bp}" fill="${d.body}"/>` +
      `<g clip-path="url(#${id}b)">${belly}${markings(d, w, h, fy, ex)}` +
      `<path d="${bp}" fill="none" stroke="#fff" stroke-opacity=".25" stroke-width="10" transform="translate(-6 -6)"/></g>` +
      `<path d="${bp}" fill="none" ${S}/>` +
      `<g class="c-earsf">${earsFront(d, w, h)}</g>` +
      `${front(d, w, h)}` +
      `${arms(d, w, h)}` +
      `<g class="c-face">${cheeks}${muzzle(d, w, h, fy)}${whiskers(d, w, fy)}${nose(d, fy)}${mouth(d, fy)}` +
      `<g class="c-eyes">${eyes(d, w, h, fy, ex)}</g></g>` +
      `${feet(d, w)}` +
      `</g></g>`;
  }

  /* ----------------------------------------------------- the 40 friends */
  const CREAM = '#fdf3e4', WHITE = '#fdfaf3', PINK = '#f6b3bf', BEAK = '#f7a531';
  const LIST = [
    { id: 'chick', name: 'Chick', body: '#ffd84d', belly: '#ffe98c', front: ['tuft'], arms: 'wing', feet: 'bird', muzzle: 'beak', muzzleColor: BEAK, nose: 'none', mouth: 'none', armColor: '#ffcb2e' },
    { id: 'duckling', name: 'Duckling', body: '#ffe066', belly: '#fff2b0', front: ['tuft'], tuftColor: '#ffd23b', arms: 'wing', feet: 'bird', muzzle: 'bill', muzzleColor: BEAK, nose: 'none', mouth: 'none', armColor: '#ffd23b' },
    { id: 'penguin', name: 'Penguin', shape: 'tall', body: '#3d4e6e', belly: WHITE, marks: ['faceMask'], faceColor: WHITE, arms: 'flipper', feet: 'bird', muzzle: 'beak', muzzleColor: BEAK, nose: 'none', mouth: 'none' },
    { id: 'owl', name: 'Owl', body: '#a8754f', belly: '#e8c9a0', ears: 'tufts', marks: ['faceMask', 'owlBelly'], faceColor: '#f3e2c2', markColor: '#b98a62', eyes: 'big', arms: 'wing', feet: 'bird', muzzle: 'beak', muzzleColor: BEAK, nose: 'none', mouth: 'none' },
    { id: 'hamster', name: 'Hamster', shape: 'wide', body: '#eaa865', ears: 'round', earInner: PINK, marks: ['lowerFace'], faceColor: CREAM, mouth: 'w' },
    { id: 'bunny', name: 'Bunny', body: '#f3ece3', ears: 'long', earInner: PINK, muzzle: 'snout', muzzleColor: WHITE, noseColor: '#f18ea0', belly: WHITE },
    { id: 'fox', name: 'Fox', body: '#ef8b3a', ears: 'pointy', earInner: '#4a3030', marks: ['lowerFace'], faceColor: CREAM, back: ['tailFluffy'], tailColor: '#ef8b3a', feetColor: '#5a3a30', armColor: '#5a3a30' },
    { id: 'kitten', name: 'Kitten', body: '#b1aaa6', ears: 'pointy', earInner: PINK, marks: ['stripes'], markColor: '#858079', whiskers: true, noseColor: '#f18ea0', back: ['tailThin'], tailColor: '#b1aaa6' },
    { id: 'bearcub', name: 'Bear Cub', body: '#9a6845', ears: 'round', earInner: '#d4a27c', muzzle: 'snout', muzzleColor: '#ddb48c', belly: '#c89a72' },
    { id: 'panda', name: 'Panda', body: WHITE, ears: 'round', earColor: '#2e2a2b', earInner: '#2e2a2b', marks: ['eyePatches'], markColor: '#2e2a2b', eyes: 'ringed', armColor: '#2e2a2b', feetColor: '#2e2a2b' },
    { id: 'frog', name: 'Frog', shape: 'wide', body: '#7cc26a', belly: '#c9e6a0', back: ['frogBumps'], eyesOnBumps: true, mouth: 'wide', nose: 'none', feetColor: '#68ad58' },
    { id: 'turtle', name: 'Turtle', body: '#a5d47f', belly: '#f2e3a5', marks: ['plastron'], markColor: '#d8c57f', back: ['turtleShell'], shellColor: '#4f8f56', shellSpot: '#3c7444', mouth: 'u', nose: 'none' },
    { id: 'dino', name: 'Dino', body: '#76c3a6', belly: '#d8f0c8', back: ['spikes', 'tailDino'], spikeColor: '#f2a65a', marks: ['spots'], markColor: '#5aa98b', spotPts: [[-0.7, 0.75, 9], [0.72, 0.7, 8], [-0.75, 0.48, 6], [0.78, 0.45, 7]], mouth: 'open', nose: 'none' },
    { id: 'dragon', name: 'Dragon', body: '#a98ad8', belly: '#f6e3b4', back: ['dragonWings', 'horns'], wingColor: '#f29fc0', hornColor: '#f6e3b4', mouth: 'open', nose: 'none', cheekColor: '#f29fc0' },
    { id: 'mouse', name: 'Mouse', shape: 'small', body: '#b6aeb0', ears: 'bigRound', earInner: PINK, whiskers: true, noseColor: '#f18ea0', back: ['tailThin'], belly: '#d9d3d4' },
    { id: 'piglet', name: 'Piglet', shape: 'wide', body: '#f7b6c2', ears: 'pointy', earInner: '#ef8fa4', muzzle: 'pig', muzzleColor: '#f394aa', nose: 'none', back: ['tailCurl'], cheekColor: '#ef7f97' },
    { id: 'koala', name: 'Koala', body: '#a5aab3', ears: 'fluffy', earInner: '#eef0f3', nose: 'big', belly: '#e3e6ea' },
    { id: 'raccoon', name: 'Raccoon', body: '#9c9a9b', ears: 'pointy', earInner: '#4a4446', marks: ['mask'], markColor: '#4a4446', eyes: 'ringed', muzzle: 'snout', muzzleColor: '#f1ebe6', back: ['tailStriped'], tailStripe: '#4a4446', belly: '#cfcccd' },
    { id: 'tiger', name: 'Tiger Cub', body: '#f39a3d', ears: 'round', earInner: '#fbe3c6', marks: ['stripes'], markColor: '#4a2b22', muzzle: 'snout', muzzleColor: CREAM, belly: CREAM },
    { id: 'lion', name: 'Lion Cub', body: '#f3b64e', ears: 'round', earInner: '#fbe1b0', back: ['mane'], maneColor: '#c9682f', muzzle: 'snout', muzzleColor: '#fbe5b8' },
    { id: 'calf', name: 'Calf', body: WHITE, ears: 'goat', earColor: '#f1e4e4', marks: ['patches'], markColor: '#3d3536', back: ['nubs'], hornColor: '#f3e2b8', muzzle: 'pig', muzzleColor: '#f6b5bd', snoutW: 24, nose: 'none' },
    { id: 'lamb', name: 'Lamb', body: '#f5dcc8', back: ['fleece'], fleeceColor: WHITE, front: ['fleeceTuft'], ears: 'floppy', earColor: '#efcab0', mouth: 'u', noseColor: '#c98a7a' },
    { id: 'fawn', name: 'Fawn', body: '#c98a55', ears: 'tall', earInner: '#f3d2b5', marks: ['fawnSpots'], markColor: '#fbefdc', muzzle: 'snout', muzzleColor: '#f3dcc2', belly: '#efd2ae' },
    { id: 'hedgehog', name: 'Hedgehog', shape: 'small', body: '#f2d5b0', back: ['quills'], quillColor: '#8a5d3f', ears: 'tiny', nose: 'big' },
    { id: 'otter', name: 'Otter', shape: 'tall', body: '#8e6648', ears: 'tiny', marks: ['muzzlePatch'], faceColor: '#e8d2b2', whiskers: true, belly: '#c79c76', back: ['tailDino'] },
    { id: 'seal', name: 'Seal Pup', shape: 'wide', body: '#e1e8f0', marks: ['spots'], markColor: '#cad3de', whiskers: true, arms: 'flipper', feet: 'none', nose: 'big', eyes: 'big' },
    { id: 'axolotl', name: 'Axolotl', body: '#f8b5c8', belly: '#fde0e8', back: ['gills'], gillColor: '#e96f96', mouth: 'wide', nose: 'none', cheekColor: '#ee7d9f' },
    { id: 'bat', name: 'Bat', body: '#6a5679', belly: '#9a86aa', ears: 'bat', earInner: '#d4a8d0', back: ['batWings'], wingColor: '#4d3c5c', arms: 'none', mouth: 'fang', noseColor: '#2a1f30' },
    { id: 'mole', name: 'Mole', body: '#5e5459', ears: 'none', eyes: 'happy', nose: 'big', noseColor: '#f49ab2', arms: 'paw', armColor: '#f49ab2', front: ['claws'], feetColor: '#f49ab2', cheeks: false },
    { id: 'monkey', name: 'Monkey', body: '#9a6a48', ears: 'side', earInner: '#ecc9a2', marks: ['faceHeart'], faceColor: '#ecc9a2', back: ['tailThin'], tailColor: '#9a6a48', mouth: 'open' },
    { id: 'elephant', name: 'Elephant', shape: 'wide', body: '#a9b8cf', ears: 'elephant', earInner: '#f2b8c6', muzzle: 'trunk', nose: 'none', mouth: 'none' },
    { id: 'squirrel', name: 'Squirrel', body: '#c8743d', ears: 'pointy', earInner: '#f6dfc0', belly: '#f6dfc0', back: ['tailSquirrel'], tailColor: '#d4824a' },
    { id: 'puppy', name: 'Puppy', body: '#e6b880', ears: 'floppy', earColor: '#9a6a48', marks: ['eyePatch'], markColor: '#b4835a', muzzle: 'snout', muzzleColor: '#fbefdc', nose: 'big', mouth: 'open', back: ['tailCurl'] },
    { id: 'unicorn', name: 'Unicorn', body: '#fbf4ff', ears: 'pointy', earInner: PINK, front: ['pastelMane', 'horn'], hornColor: '#ffd86b', nose: 'none', mouth: 'u', cheekColor: '#f7a8c8' },
    { id: 'capybara', name: 'Capybara', shape: 'wide', body: '#b07d52', ears: 'tiny', muzzle: 'capy', muzzleColor: '#946541', nose: 'none', eyes: 'tiny', mouth: 'u' },
    { id: 'redpanda', name: 'Red Panda', body: '#d4643a', ears: 'pointy', earInner: CREAM, marks: ['redPanda'], faceColor: CREAM, markColor: '#a5452a', belly: '#5b3326', armColor: '#5b3326', feetColor: '#5b3326', back: ['tailStriped'], tailStripe: '#f2d7b0' },
    { id: 'sloth', name: 'Sloth', body: '#c4a684', marks: ['faceOval', 'slothEyes'], faceColor: '#efe1c8', markColor: '#6b4c36', eyes: 'ringed', front: ['claws'], mouth: 'u' },
    { id: 'ladybug', name: 'Ladybug', shape: 'wide', body: '#e8443a', marks: ['cap', 'spots'], markColor: '#2b2426', spotPts: [[-0.6, 0.28, 10], [0.6, 0.28, 10], [-0.78, 0.55, 7], [0.78, 0.55, 7], [0, 0.14, 8]], back: ['antennae'], nose: 'none', mouth: 'u', armColor: '#2b2426', feetColor: '#2b2426', faceY: 0.5 },
    { id: 'snail', name: 'Snail', shape: 'small', body: '#f2d39a', back: ['snailShell', 'eyeStalks'], shellColor: '#d98a5b', shellSpot: '#a85c3b', eyes: 'stalk', nose: 'none', mouth: 'u', arms: 'none', feet: 'none' },
    { id: 'goat', name: 'Baby Goat', body: '#f3efe8', ears: 'goat', earColor: '#e3d7c7', back: ['horns'], hornColor: '#cdbda4', muzzle: 'snout', muzzleColor: '#f6dcd6', noseColor: '#c98a7a', front: ['leaf'] },
  ];

  // default parts
  for (const a of LIST) {
    a.ears = a.ears || 'none';
    a.eyes = a.eyes || 'dot';
    a.mouth = a.mouth || 'w';
    a.arms = a.arms || 'paw';
    a.feet = a.feet || 'paw';
    a.nose = a.nose || 'small';
    a.muzzle = a.muzzle || 'none';
  }

  GC.Animals = {
    list: LIST,
    byId: Object.fromEntries(LIST.map((a) => [a.id, a])),
    render,
    /** Markup for a framed photo "friend" that hatches like an animal. */
    renderPhoto(url) {
      const id = GC.uid('p');
      return `<g class="critter critter-photo">` +
        `<ellipse class="c-shadow" cx="0" cy="2" rx="66" ry="10" fill="${O}" opacity=".18"/>` +
        `<g class="c-squash">` +
        `<g class="c-ears">${both((s) => `<circle cx="${s * 44}" cy="-128" r="18" fill="#f3c98b" ${S}/><circle cx="${s * 44}" cy="-128" r="8" fill="${PINK}"/>`)}</g>` +
        `<clipPath id="${id}"><circle cx="0" cy="-70" r="62"/></clipPath>` +
        `<circle cx="0" cy="-70" r="64" fill="#fdf3e4"/>` +
        `<image href="${url}" x="-62" y="-132" width="124" height="124" preserveAspectRatio="xMidYMid slice" clip-path="url(#${id})"/>` +
        `<circle cx="0" cy="-70" r="62" fill="none" stroke="#f3c98b" stroke-width="9"/>` +
        `<circle cx="0" cy="-70" r="67" fill="none" ${S}/>` +
        `${both((s) => `<g class="${s < 0 ? 'c-arm-l' : 'c-arm-r'}"><ellipse cx="${s * 62}" cy="-30" rx="12" ry="15" fill="#f3c98b" ${S} transform="rotate(${s * -25} ${s * 62} -30)"/></g>`)}` +
        `${both((s) => `<ellipse cx="${s * 26}" cy="-4" rx="17" ry="9.5" fill="#e9b673" ${S}/>`)}` +
        `</g></g>`;
    },
  };
})();

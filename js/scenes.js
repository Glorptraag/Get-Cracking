/* Get Cracking — 10 illustrated worlds.
 *
 * Each world is an isometric diorama block (like a little terrarium cut out
 * of the ground): a grassy top face where the egg sits, and two cut-away
 * side faces showing burrows, roots and sleepy critters.
 *
 * Stage coordinates: viewBox 0 0 600 720.
 *   top face diamond  L(60,370) T(300,250) R(540,370) B(300,490)
 *   side depth        115
 *   egg base / ring   centre (300,392)
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT;
  const sh = GC.shade;
  const S = (w = 4.5) => `stroke="${O}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round"`;
  const NS = 'vector-effect="non-scaling-stroke"';
  const D = 115; // block depth
  const f = (n) => Math.round(n * 10) / 10;

  const EGG = { x: 300, y: 392 };
  const RING = { cx: 300, cy: 392, rx: 150, ry: 74 };

  // face-local → screen
  const topPt = (u, v) => [60 + u + v, 370 - 0.5 * u + 0.5 * v];
  const leftPt = (u, v) => [60 + u, 370 + 0.5 * u + v];
  const rightPt = (u, v) => [300 + u, 490 - 0.5 * u + v];
  const TOP_M = 'matrix(1,-0.5,1,0.5,60,370)';
  const LEFT_M = 'matrix(1,0.5,0,1,60,370)';
  const RIGHT_M = 'matrix(1,-0.5,0,1,300,490)';

  /* =============================================================== props */
  const P = {
    pine(x, y, s, c = '#5a9a4e', c2 = '#7cc06a', snow) {
      const t = (yy, ww, hh, col) =>
        `<path d="M${f(x - ww)},${f(yy)} L${f(x)},${f(yy - hh)} L${f(x + ww)},${f(yy)} Q${x},${f(yy + 8 * s)} ${f(x - ww)},${f(yy)} Z" fill="${col}" ${S()}/>` +
        (snow ? `<path d="M${f(x - ww * 0.42)},${f(yy - hh * 0.58)} L${x},${f(yy - hh)} L${f(x + ww * 0.42)},${f(yy - hh * 0.58)} Q${f(x + ww * 0.15)},${f(yy - hh * 0.5)} ${x},${f(yy - hh * 0.62)} Q${f(x - ww * 0.15)},${f(yy - hh * 0.5)} ${f(x - ww * 0.42)},${f(yy - hh * 0.58)} Z" fill="#fbfdff" ${S(3.5)}/>` : '');
      return `<g class="sway" style="--sd:${GC.rand(5, 8).toFixed(1)}s">` +
        `<rect x="${f(x - 7 * s)}" y="${f(y - 26 * s)}" width="${f(14 * s)}" height="${f(28 * s)}" rx="3" fill="#8a5a3b" ${S()}/>` +
        t(y - 22 * s, 44 * s, 52 * s, c) + t(y - 58 * s, 36 * s, 48 * s, c2) + t(y - 92 * s, 27 * s, 44 * s, sh(c2, 0.12)) + `</g>`;
    },
    roundTree(x, y, s, c = '#7cbf5a', trunk = '#8a5a3b') {
      const r = 30 * s;
      return `<g class="sway" style="--sd:${GC.rand(5, 8).toFixed(1)}s">` +
        `<path d="M${f(x - 7 * s)},${y} L${f(x - 5 * s)},${f(y - 60 * s)} L${f(x + 5 * s)},${f(y - 60 * s)} L${f(x + 7 * s)},${y} Z" fill="${trunk}" ${S()}/>` +
        `<circle cx="${f(x - r * 0.75)}" cy="${f(y - 70 * s)}" r="${f(r * 0.8)}" fill="${c}" ${S()}/>` +
        `<circle cx="${f(x + r * 0.75)}" cy="${f(y - 72 * s)}" r="${f(r * 0.82)}" fill="${c}" ${S()}/>` +
        `<circle cx="${x}" cy="${f(y - 92 * s)}" r="${f(r)}" fill="${c}" ${S()}/>` +
        `<circle cx="${f(x - r * 0.3)}" cy="${f(y - 100 * s)}" r="${f(r * 0.35)}" fill="${sh(c, 0.25)}"/>` +
        `<path d="M${f(x - r * 1.2)},${f(y - 66 * s)} Q${x},${f(y - 50 * s)} ${f(x + r * 1.25)},${f(y - 68 * s)}" fill="${c}" stroke="none"/></g>`;
    },
    trunk(x, y, w = 26, c = '#8a5a3b') {
      // a tall trunk that runs out of the top of the picture (like the reference redwoods)
      return `<path d="M${x - w / 2 - 6},${y} Q${x - w / 2},${y - 40} ${x - w / 2},${y - 120} L${x - w / 2 + 4},-20 L${x + w / 2 - 4},-20 L${x + w / 2},${y - 120} Q${x + w / 2},${y - 40} ${x + w / 2 + 6},${y} Z" fill="${c}" ${S()}/>` +
        `<path d="M${x - 3},${y - 30} L${x - 2},${y - 160} M${x + 6},${y - 90} L${x + 7},${y - 230}" stroke="${sh(c, -0.25)}" stroke-width="3" stroke-linecap="round"/>`;
    },
    mushroom(x, y, s, cap = '#e8604f', spot = '#fdf3e4', glow) {
      return `<g class="${glow ? 'glow-pulse' : ''}">` +
        `<path d="M${f(x - 7 * s)},${y} Q${f(x - 6 * s)},${f(y - 16 * s)} ${f(x - 5 * s)},${f(y - 22 * s)} L${f(x + 5 * s)},${f(y - 22 * s)} Q${f(x + 6 * s)},${f(y - 16 * s)} ${f(x + 7 * s)},${y} Z" fill="#fbf1dc" ${S(4)}/>` +
        `<path d="M${f(x - 22 * s)},${f(y - 20 * s)} Q${f(x - 20 * s)},${f(y - 46 * s)} ${x},${f(y - 46 * s)} Q${f(x + 20 * s)},${f(y - 46 * s)} ${f(x + 22 * s)},${f(y - 20 * s)} Q${x},${f(y - 14 * s)} ${f(x - 22 * s)},${f(y - 20 * s)} Z" fill="${cap}" ${S(4)}/>` +
        `<circle cx="${f(x - 8 * s)}" cy="${f(y - 32 * s)}" r="${f(4 * s)}" fill="${spot}"/><circle cx="${f(x + 8 * s)}" cy="${f(y - 36 * s)}" r="${f(3 * s)}" fill="${spot}"/><circle cx="${f(x + 12 * s)}" cy="${f(y - 25 * s)}" r="${f(2.5 * s)}" fill="${spot}"/></g>`;
    },
    flower(x, y, s, petal = '#f7a8c8', center = '#ffd86b') {
      const r = 6 * s;
      let p = '';
      for (let i = 0; i < 5; i++) {
        const a = (i / 5) * Math.PI * 2 - Math.PI / 2;
        p += `<circle cx="${f(x + Math.cos(a) * r)}" cy="${f(y - 22 * s + Math.sin(a) * r)}" r="${f(r * 0.8)}" fill="${petal}" ${S(3)}/>`;
      }
      return `<g class="bob" style="--bd:${GC.rand(2.5, 4).toFixed(1)}s"><path d="M${x},${y} Q${f(x - 3 * s)},${f(y - 12 * s)} ${x},${f(y - 22 * s)}" stroke="${O}" stroke-width="${f(7 * Math.min(s, 1.2))}" fill="none" stroke-linecap="round"/>` +
        `<path d="M${x},${y} Q${f(x - 3 * s)},${f(y - 12 * s)} ${x},${f(y - 22 * s)}" stroke="#6aa84f" stroke-width="3" fill="none" stroke-linecap="round"/>` +
        p + `<circle cx="${x}" cy="${f(y - 22 * s)}" r="${f(r * 0.6)}" fill="${center}" ${S(3)}/></g>`;
    },
    tuft(x, y, s = 1, c = '#5f9a3e') {
      return `<path d="M${f(x - 10 * s)},${y} Q${f(x - 12 * s)},${f(y - 12 * s)} ${f(x - 16 * s)},${f(y - 18 * s)} Q${f(x - 4 * s)},${f(y - 12 * s)} ${f(x - 2 * s)},${f(y - 4 * s)} Q${f(x)},${f(y - 18 * s)} ${f(x + 4 * s)},${f(y - 24 * s)} Q${f(x + 6 * s)},${f(y - 12 * s)} ${f(x + 4 * s)},${f(y - 3 * s)} Q${f(x + 10 * s)},${f(y - 14 * s)} ${f(x + 16 * s)},${f(y - 16 * s)} Q${f(x + 12 * s)},${f(y - 6 * s)} ${f(x + 10 * s)},${y} Z" fill="${c}" ${S(3.5)}/>`;
    },
    fern(x, y, s = 1, c = '#4f9a5a') {
      let leaves = '';
      for (const side of [-1, 1]) for (let i = 0; i < 3; i++) {
        const yy = y - 8 * s - i * 9 * s;
        leaves += `<ellipse cx="${f(x + side * 10 * s)}" cy="${f(yy)}" rx="${f(10 * s)}" ry="${f(5 * s)}" fill="${c}" ${S(3)} transform="rotate(${side * -25} ${f(x + side * 10 * s)} ${f(yy)})"/>`;
      }
      return `<g class="sway" style="--sd:4s">${leaves}<path d="M${x},${y} L${x},${f(y - 34 * s)}" stroke="${O}" stroke-width="3" stroke-linecap="round"/></g>`;
    },
    rock(x, y, s = 1, c = '#9aa09a') {
      return `<path d="M${f(x - 22 * s)},${y} Q${f(x - 24 * s)},${f(y - 18 * s)} ${f(x - 8 * s)},${f(y - 22 * s)} Q${f(x + 6 * s)},${f(y - 30 * s)} ${f(x + 18 * s)},${f(y - 16 * s)} Q${f(x + 26 * s)},${f(y - 6 * s)} ${f(x + 20 * s)},${y} Q${x},${f(y + 5 * s)} ${f(x - 22 * s)},${y} Z" fill="${c}" ${S()}/>` +
        `<path d="M${f(x - 10 * s)},${f(y - 16 * s)} Q${f(x - 2 * s)},${f(y - 22 * s)} ${f(x + 6 * s)},${f(y - 20 * s)}" stroke="${sh(c, 0.35)}" stroke-width="3" fill="none" stroke-linecap="round"/>`;
    },
    bush(x, y, s = 1, c = '#6fae57') {
      return `<g class="sway" style="--sd:6s"><circle cx="${f(x - 14 * s)}" cy="${f(y - 12 * s)}" r="${f(14 * s)}" fill="${c}" ${S()}/><circle cx="${f(x + 14 * s)}" cy="${f(y - 12 * s)}" r="${f(14 * s)}" fill="${c}" ${S()}/>` +
        `<circle cx="${x}" cy="${f(y - 22 * s)}" r="${f(16 * s)}" fill="${c}" ${S()}/><path d="M${f(x - 26 * s)},${f(y - 6 * s)} L${f(x + 26 * s)},${f(y - 6 * s)} L${f(x + 22 * s)},${y} L${f(x - 22 * s)},${y} Z" fill="${c}"/>` +
        `<path d="M${f(x - 28 * s)},${f(y - 4 * s)} Q${x},${f(y + 4 * s)} ${f(x + 28 * s)},${f(y - 4 * s)}" stroke="${O}" stroke-width="4.5" fill="none" stroke-linecap="round"/></g>`;
    },
    candle(x, y, s = 1) {
      return `<g><path d="M${f(x - 12 * s)},${y} Q${x},${f(y + 6 * s)} ${f(x + 12 * s)},${y} Q${f(x + 12 * s)},${f(y - 10 * s)} ${x},${f(y - 10 * s)} Q${f(x - 12 * s)},${f(y - 10 * s)} ${f(x - 12 * s)},${y} Z" fill="#a9aaa0" ${S(3.5)}/>` +
        `<rect x="${f(x - 4 * s)}" y="${f(y - 26 * s)}" width="${f(8 * s)}" height="${f(18 * s)}" rx="2" fill="#fbf1dc" ${S(3)}/>` +
        `<circle class="flicker" cx="${x}" cy="${f(y - 33 * s)}" r="${f(13 * s)}" fill="#ffe28a" opacity=".35"/>` +
        `<path class="flicker" d="M${x},${f(y - 40 * s)} Q${f(x + 5 * s)},${f(y - 32 * s)} ${x},${f(y - 28 * s)} Q${f(x - 5 * s)},${f(y - 32 * s)} ${x},${f(y - 40 * s)} Z" fill="#ffc94a" ${S(2.5)}/></g>`;
    },
    cactus(x, y, s = 1, c = '#79b35b') {
      return `<g><path d="M${f(x - 10 * s)},${y} L${f(x - 10 * s)},${f(y - 58 * s)} Q${x},${f(y - 72 * s)} ${f(x + 10 * s)},${f(y - 58 * s)} L${f(x + 10 * s)},${y} Z" fill="${c}" ${S()}/>` +
        `<path d="M${f(x - 10 * s)},${f(y - 26 * s)} L${f(x - 22 * s)},${f(y - 26 * s)} Q${f(x - 28 * s)},${f(y - 28 * s)} ${f(x - 28 * s)},${f(y - 36 * s)} L${f(x - 28 * s)},${f(y - 46 * s)} Q${f(x - 22 * s)},${f(y - 54 * s)} ${f(x - 17 * s)},${f(y - 46 * s)} L${f(x - 17 * s)},${f(y - 36 * s)} L${f(x - 10 * s)},${f(y - 36 * s)}" fill="${c}" ${S()}/>` +
        `<path d="M${f(x + 10 * s)},${f(y - 34 * s)} L${f(x + 20 * s)},${f(y - 34 * s)} L${f(x + 20 * s)},${f(y - 48 * s)} Q${f(x + 25 * s)},${f(y - 55 * s)} ${f(x + 30 * s)},${f(y - 48 * s)} L${f(x + 30 * s)},${f(y - 30 * s)} Q${f(x + 28 * s)},${f(y - 24 * s)} ${f(x + 20 * s)},${f(y - 24 * s)} L${f(x + 10 * s)},${f(y - 24 * s)}" fill="${c}" ${S()}/>` +
        `<path d="M${x},${f(y - 8 * s)} L${x},${f(y - 54 * s)}" stroke="${sh(c, -0.2)}" stroke-width="3" stroke-linecap="round"/>` +
        `<circle cx="${x}" cy="${f(y - 66 * s)}" r="${f(5 * s)}" fill="#f7a8c8" ${S(3)}/></g>`;
    },
    palm(x, y, s = 1) {
      let fronds = '';
      for (const a of [-150, -115, -65, -30, -95]) {
        const r = (a * Math.PI) / 180;
        const ex = x + Math.cos(r) * 46 * s + 6 * s, ey = y - 90 * s + Math.sin(r) * 30 * s + 10 * s;
        fronds += `<path d="M${f(x + 6 * s)},${f(y - 92 * s)} Q${f((x + ex) / 2)},${f(ey - 26 * s)} ${f(ex)},${f(ey + 6 * s)} Q${f((x + ex) / 2 + 4)},${f(ey - 10 * s)} ${f(x + 6 * s)},${f(y - 88 * s)} Z" fill="#6fb35a" ${S(4)}/>`;
      }
      return `<g class="sway" style="--sd:6s"><path d="M${f(x - 7 * s)},${y} Q${f(x - 4 * s)},${f(y - 50 * s)} ${f(x + 2 * s)},${f(y - 92 * s)} L${f(x + 10 * s)},${f(y - 92 * s)} Q${f(x + 6 * s)},${f(y - 50 * s)} ${f(x + 7 * s)},${y} Z" fill="#b8875a" ${S()}/>${fronds}` +
        `<circle cx="${f(x + 2 * s)}" cy="${f(y - 86 * s)}" r="${f(5 * s)}" fill="#8a5a3b" ${S(3)}/><circle cx="${f(x + 11 * s)}" cy="${f(y - 84 * s)}" r="${f(5 * s)}" fill="#8a5a3b" ${S(3)}/></g>`;
    },
    reeds(x, y, s = 1) {
      return [-8, 0, 9].map((dx, i) => `<path d="M${x + dx},${y} Q${x + dx - 2},${f(y - 30 * s)} ${x + dx + 2},${f(y - (44 + i * 6) * s)}" stroke="${O}" stroke-width="7" fill="none" stroke-linecap="round"/>` +
        `<path d="M${x + dx},${y} Q${x + dx - 2},${f(y - 30 * s)} ${x + dx + 2},${f(y - (44 + i * 6) * s)}" stroke="#7aa84f" stroke-width="3" fill="none" stroke-linecap="round"/>` +
        (i !== 1 ? `<rect x="${f(x + dx - 3)}" y="${f(y - (44 + i * 6) * s)}" width="9" height="${f(16 * s)}" rx="4.5" fill="#8a5a3b" ${S(3)}/>` : '')).join('');
    },
    lilypad(x, y, s = 1, flower) {
      return `<path d="M${x},${y} L${f(x + 22 * s)},${f(y - 4 * s)} A${f(24 * s)},${f(12 * s)} 0 1 1 ${f(x + 18 * s)},${f(y + 6 * s)} Z" fill="#7cc26a" ${S(3.5)}/>` +
        (flower ? `<g transform="translate(${x - 4} ${y - 4})"><path d="M-8,0 L-4,-12 L0,-4 L4,-14 L8,-4 L12,-10 L12,2 Q2,6 -8,0 Z" fill="#f7b6c8" ${S(3)}/></g>` : '');
    },
    shell(x, y, s = 1, c = '#f7c4b0') {
      return `<path d="M${f(x - 12 * s)},${y} Q${f(x - 14 * s)},${f(y - 18 * s)} ${x},${f(y - 20 * s)} Q${f(x + 14 * s)},${f(y - 18 * s)} ${f(x + 12 * s)},${y} Q${x},${f(y + 4 * s)} ${f(x - 12 * s)},${y} Z" fill="${c}" ${S(3.5)}/>` +
        `<path d="M${x},${f(y + 1)} L${x},${f(y - 18 * s)} M${f(x - 6 * s)},${f(y)} L${f(x - 4 * s)},${f(y - 16 * s)} M${f(x + 6 * s)},${f(y)} L${f(x + 4 * s)},${f(y - 16 * s)}" stroke="${O}" stroke-width="2.5" stroke-linecap="round"/>`;
    },
    starfish(x, y, s = 1, c = '#f39a6b') {
      let pts = [];
      for (let i = 0; i < 10; i++) {
        const a = (i / 10) * Math.PI * 2 - Math.PI / 2, r = (i % 2 ? 6 : 15) * s;
        pts.push(`${f(x + Math.cos(a) * r)},${f(y + Math.sin(a) * r * 0.6)}`);
      }
      return `<polygon points="${pts.join(' ')}" fill="${c}" ${S(3.5)}/>`;
    },
    crystal(x, y, s = 1, c = '#9fd8e8') {
      return `<g class="glow-pulse"><path d="M${f(x - 8 * s)},${y} L${f(x - 10 * s)},${f(y - 22 * s)} L${x},${f(y - 36 * s)} L${f(x + 10 * s)},${f(y - 22 * s)} L${f(x + 8 * s)},${y} Z" fill="${c}" ${S(3.5)}/>` +
        `<path d="M${f(x + 6 * s)},${y} L${f(x + 14 * s)},${f(y - 14 * s)} L${f(x + 20 * s)},${f(y - 6 * s)} L${f(x + 16 * s)},${y} Z" fill="${sh(c, -0.15)}" ${S(3)}/>` +
        `<path d="M${f(x - 4 * s)},${f(y - 6 * s)} L${f(x - 5 * s)},${f(y - 22 * s)}" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".8"/></g>`;
    },
    seaweed(x, y, h = 70, c = '#6fbf7a') {
      return `<g class="sea-sway" style="--sd:${GC.rand(3, 5).toFixed(1)}s"><path d="M${x},${y} C${x - 14},${y - h * 0.3} ${x + 14},${y - h * 0.6} ${x},${y - h}" stroke="${O}" stroke-width="14" fill="none" stroke-linecap="round"/>` +
        `<path d="M${x},${y} C${x - 14},${y - h * 0.3} ${x + 14},${y - h * 0.6} ${x},${y - h}" stroke="${c}" stroke-width="6" fill="none" stroke-linecap="round"/></g>`;
    },
    coral(x, y, s = 1, c = '#f39a9a') {
      const b = (d) => `<path d="${d}" stroke="${O}" stroke-width="${f(13 * s)}" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="${d}" stroke="${c}" stroke-width="${f(6 * s)}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`;
      return b(`M${x},${y} L${x},${f(y - 30 * s)} M${x},${f(y - 16 * s)} L${f(x - 14 * s)},${f(y - 30 * s)} L${f(x - 14 * s)},${f(y - 40 * s)} M${x},${f(y - 20 * s)} L${f(x + 12 * s)},${f(y - 34 * s)} L${f(x + 12 * s)},${f(y - 44 * s)}`);
    },
    pumpkin(x, y, s = 1) {
      return `<ellipse cx="${x}" cy="${f(y - 12 * s)}" rx="${f(20 * s)}" ry="${f(14 * s)}" fill="#f29a3c" ${S()}/>` +
        `<path d="M${x},${f(y - 25 * s)} Q${f(x - 8 * s)},${f(y - 12 * s)} ${x},${f(y + 1)} M${x},${f(y - 25 * s)} Q${f(x + 8 * s)},${f(y - 12 * s)} ${x},${f(y + 1)}" stroke="${O}" stroke-width="3" fill="none"/>` +
        `<path d="M${x},${f(y - 25 * s)} Q${f(x + 2 * s)},${f(y - 34 * s)} ${f(x + 8 * s)},${f(y - 34 * s)}" stroke="${O}" stroke-width="7" fill="none" stroke-linecap="round"/><path d="M${x},${f(y - 25 * s)} Q${f(x + 2 * s)},${f(y - 34 * s)} ${f(x + 8 * s)},${f(y - 34 * s)}" stroke="#6a8a3e" stroke-width="3" fill="none" stroke-linecap="round"/>`;
    },
    lantern(x, y, s = 1) {
      return `<path d="M${x},${y} L${x},${f(y - 40 * s)}" stroke="${O}" stroke-width="4"/>` +
        `<circle class="flicker" cx="${x}" cy="${f(y - 50 * s)}" r="${f(18 * s)}" fill="#ffe28a" opacity=".35"/>` +
        `<rect x="${f(x - 8 * s)}" y="${f(y - 60 * s)}" width="${f(16 * s)}" height="${f(20 * s)}" rx="${f(5 * s)}" fill="#ffd86b" ${S(3.5)}/>` +
        `<path d="M${f(x - 10 * s)},${f(y - 60 * s)} L${f(x + 10 * s)},${f(y - 60 * s)}" stroke="${O}" stroke-width="5" stroke-linecap="round"/>`;
    },
    snowman(x, y, s = 1) {
      return `<circle cx="${x}" cy="${f(y - 14 * s)}" r="${f(15 * s)}" fill="#fbfdff" ${S()}/><circle cx="${x}" cy="${f(y - 38 * s)}" r="${f(11 * s)}" fill="#fbfdff" ${S()}/>` +
        `<circle cx="${f(x - 4 * s)}" cy="${f(y - 40 * s)}" r="1.8" fill="${O}"/><circle cx="${f(x + 4 * s)}" cy="${f(y - 40 * s)}" r="1.8" fill="${O}"/>` +
        `<path d="M${x},${f(y - 36 * s)} L${f(x + 9 * s)},${f(y - 34 * s)} L${x},${f(y - 33 * s)} Z" fill="#f29a3c" ${S(2)}/>` +
        `<path d="M${f(x - 12 * s)},${f(y - 30 * s)} Q${x},${f(y - 24 * s)} ${f(x + 12 * s)},${f(y - 30 * s)}" stroke="#e8604f" stroke-width="5" fill="none" stroke-linecap="round"/>`;
    },
    bird(x, y, c = '#9fd8e8') {
      return `<g class="bob" style="--bd:1.6s"><ellipse cx="${x}" cy="${y - 8}" rx="9" ry="8" fill="${c}" ${S(3.5)}/><circle cx="${x + 3}" cy="${y - 10}" r="1.6" fill="${O}"/>` +
        `<path d="M${x + 8},${y - 9} L${x + 13},${y - 7} L${x + 8},${y - 5} Z" fill="#f7a531" ${S(2)}/></g>`;
    },
    crab(x, y) {
      return `<g class="scuttle"><ellipse cx="${x}" cy="${y - 8}" rx="14" ry="9" fill="#ef6b55" ${S(3.5)}/>` +
        `<circle cx="${x - 16}" cy="${y - 16}" r="5" fill="#ef6b55" ${S(3)}/><circle cx="${x + 16}" cy="${y - 16}" r="5" fill="#ef6b55" ${S(3)}/>` +
        `<circle cx="${x - 4}" cy="${y - 11}" r="1.8" fill="${O}"/><circle cx="${x + 4}" cy="${y - 11}" r="1.8" fill="${O}"/></g>`;
    },
    butterfly(x, y, c = '#f7a8c8') {
      const wing = (k) => `<g transform="scale(${k} 1)">` +
        `<path d="M0,-1 C-5,-17 -21,-19 -20,-7 C-19,1 -8,2 0,-1 Z" fill="${c}" ${S(2.5)}/>` +
        `<path d="M0,1 C-4,12 -15,14 -14,6 C-13,1 -6,0 0,1 Z" fill="${sh(c, -0.12)}" ${S(2.5)}/>` +
        `<circle cx="-12" cy="-8" r="2.6" fill="#fdfaf3"/></g>`;
      return `<g class="flutter" style="--fx:${x}px;--fy:${y}px"><g class="flap">${wing(1)}${wing(-1)}</g>` +
        `<rect x="-2" y="-9" width="4" height="17" rx="2" fill="${O}"/>` +
        `<path d="M-1,-9 Q-4,-16 -7,-17 M1,-9 Q4,-16 7,-17" stroke="${O}" stroke-width="1.8" fill="none" stroke-linecap="round"/></g>`;
    },
    cloud(x, y, s = 1, c = '#fdfaf3') {
      return `<g class="drift" style="--dd:${GC.rand(50, 80).toFixed(0)}s"><path d="M${f(x - 40 * s)},${y} Q${f(x - 44 * s)},${f(y - 20 * s)} ${f(x - 20 * s)},${f(y - 20 * s)} Q${f(x - 14 * s)},${f(y - 40 * s)} ${f(x + 8 * s)},${f(y - 34 * s)} Q${f(x + 28 * s)},${f(y - 40 * s)} ${f(x + 32 * s)},${f(y - 20 * s)} Q${f(x + 50 * s)},${f(y - 18 * s)} ${f(x + 44 * s)},${y} Z" fill="${c}" ${S(4)}/></g>`;
    },
    /** a sleepy critter living in a side burrow (drawn upright in screen space) */
    burrowCritter(x, y, c = '#3d3536', eye = '#fdfaf3') {
      return `<g class="burrow-critter"><path d="M${x - 14},${y} Q${x - 16},${y - 22} ${x},${y - 24} Q${x + 16},${y - 22} ${x + 14},${y} Z" fill="${c}" ${S(3.5)}/>` +
        `<g class="blink"><ellipse cx="${x - 5}" cy="${y - 13}" rx="2.6" ry="3.2" fill="${eye}"/><ellipse cx="${x + 5}" cy="${y - 13}" rx="2.6" ry="3.2" fill="${eye}"/></g></g>`;
    },
    fish(x, y, c = '#f3b54a', dir = 1) {
      return `<g class="swim" style="--sx:${dir * 40}px;--sd:${GC.rand(5, 8).toFixed(1)}s"><g transform="translate(${x} ${y}) scale(${dir} 1)">` +
        `<path d="M-12,0 Q0,-10 12,0 Q0,10 -12,0 Z M-12,0 L-20,-7 L-20,7 Z" fill="${c}" ${S(3)}/><circle cx="6" cy="-2" r="1.6" fill="${O}"/></g></g>`;
    },
  };

  /* ===================================================== side-face parts */
  function lip(color, drips = true, rng) {
    let d = 'M0,-1 L240,-1 L240,12 ';
    for (let x = 240; x > 0; x -= 16) {
      const deep = drips && rng() < 0.25 ? 16 + rng() * 10 : 6 + rng() * 5;
      d += `Q${x - 8},${f(12 + deep)} ${x - 16},12 `;
    }
    d += 'Z';
    return `<path d="${d}" fill="${color}" ${S(4)} ${NS}/>`;
  }
  function pebbles(rng, c, n = 10, vMin = 24) {
    let s = '';
    for (let i = 0; i < n; i++) {
      const u = 10 + rng() * 220, v = vMin + rng() * (D - vMin - 10);
      s += `<ellipse cx="${f(u)}" cy="${f(v)}" rx="${f(3 + rng() * 4)}" ry="${f(2 + rng() * 3)}" fill="${c}" ${S(2.5)} ${NS}/>`;
    }
    return s;
  }
  function roots(rng, c = '#6b4430', n = 4) {
    let s = '';
    for (let i = 0; i < n; i++) {
      const u = 20 + rng() * 200, len = 30 + rng() * 40;
      const d = `M${f(u)},14 Q${f(u + (rng() - 0.5) * 30)},${f(14 + len * 0.5)} ${f(u + (rng() - 0.5) * 20)},${f(14 + len)}`;
      s += `<path d="${d}" stroke="${O}" stroke-width="9" fill="none" stroke-linecap="round" ${NS}/><path d="${d}" stroke="${c}" stroke-width="4.5" fill="none" stroke-linecap="round" ${NS}/>`;
    }
    return s;
  }
  function burrow(u, v, rx, ry, c) {
    return `<ellipse cx="${u}" cy="${v}" rx="${rx}" ry="${ry}" fill="${sh(c, 0.28)}" ${S(4.5)} ${NS}/>` +
      `<path d="M${u - rx + 6},${v + 4} Q${u},${v + ry + 2} ${u + rx - 6},${v + 4} L${u + rx - 8},${v + ry * 0.55} Q${u},${v + ry + 4} ${u - rx + 8},${v + ry * 0.55} Z" fill="${sh(c, 0.12)}"/>` +
      `<path d="M${u - rx * 0.7},${v - ry * 0.5} Q${u},${v - ry * 0.95} ${u + rx * 0.7},${v - ry * 0.5}" stroke="${sh(c, -0.12)}" stroke-width="3" fill="none" stroke-dasharray="2 6" stroke-linecap="round" ${NS}/>`;
  }
  function strata(colors) {
    let s = '', y = 14;
    const h = (D - 14) / colors.length;
    colors.forEach((c, i) => {
      s += `<path d="M0,${f(y)} Q60,${f(y - 5)} 120,${f(y + 3)} T240,${f(y)} L240,${f(y + h + 2)} L0,${f(y + h + 2)} Z" fill="${c}"/>`;
      y += h;
    });
    return s;
  }
  function waterSide(c) {
    return `<rect x="0" y="0" width="240" height="${D}" fill="${c}"/>` +
      `<path d="M0,26 Q30,20 60,26 T120,26 T180,26 T240,26" stroke="#fff" stroke-opacity=".35" stroke-width="3" fill="none" ${NS}/>` +
      `<path d="M0,60 Q30,54 60,60 T120,60 T180,60 T240,60" stroke="#fff" stroke-opacity=".2" stroke-width="3" fill="none" ${NS}/>` +
      `<path d="M0,${D - 16} Q40,${D - 24} 80,${D - 16} T160,${D - 16} T240,${D - 16} L240,${D} L0,${D} Z" fill="#e9cf96"/>`;
  }

  /* ========================================================== scenes */
  // Each draw*() returns markup for a layer. ctx = { rng }
  const SCENES = [
    {
      id: 'forest', name: 'Mossy Forest', bg: '#5e6f55', ring: '#f2b544', particles: 'fireflies',
      top: '#86b04f', left: '#b07c52', right: '#8a5e3c', lip: '#6f9a3c',
      sky: () => '',
      ground: () => `<path d="M10,40 Q60,10 120,30 Q180,10 230,44 L230,90 Q170,70 120,90 Q60,72 10,96 Z" fill="#76a046"/>` +
        `<path d="M20,170 Q80,150 140,176 Q200,160 230,190 L230,230 L20,230 Z" fill="#76a046"/>` +
        `<ellipse cx="200" cy="200" rx="22" ry="14" fill="#9cc25e"/><ellipse cx="40" cy="60" rx="18" ry="12" fill="#9cc25e"/>`,
      leftSide: (r, c) => roots(r, '#7d5034', 5) + burrow(70, 70, 34, 24, c) + pebbles(r, '#8f6545', 10),
      rightSide: (r, c) => roots(r, '#6b4430', 4) + burrow(170, 62, 36, 26, c) + pebbles(r, '#71492f', 10),
      sideCritters: () => P.burrowCritter(...shift(leftPt(70, 88), 0, 0), '#3d3536') + P.burrowCritter(...shift(rightPt(170, 82), 6, 0), '#3d3536', '#f7a8a0') + P.burrowCritter(...shift(rightPt(150, 84), 0, 0), '#4a3f40'),
      back: () => P.trunk(150, 336, 28) + P.trunk(452, 338, 26) + P.pine(220, 300, 1.05) + P.pine(380, 300, 0.95, '#4f8f48', '#6fb35e') + P.trunk(300, 268, 30, '#7d5034') +
        P.fern(110, 372, 1) + P.mushroom(130, 352, 0.7) + P.rock(470, 362, 0.9, '#a3a89f') + P.bird(470, 338) + P.bird(482, 340, '#bfe3f0') +
        P.candle(186, 346, 0.9) + P.candle(416, 346, 0.9) + P.tuft(250, 302, 1.1) + P.tuft(352, 300, 1),
      front: () => P.fern(96, 398, 0.9, '#5fae66') + P.mushroom(505, 396, 0.8, '#f2a65a') + P.tuft(160, 430, 0.9) + P.tuft(440, 430, 0.9) +
        P.candle(210, 442, 0.85) + P.candle(390, 442, 0.85),
    },
    {
      id: 'pond', name: 'Lily Pond', bg: '#9fcdc4', ring: '#f7a8c8', particles: 'dragonflies',
      top: '#8cc363', left: '#a8774f', right: '#5fb3c8', lip: '#78ad4f', rightLip: '#4f9fb4',
      ground: () => `<path d="M60,20 Q140,0 220,30 L232,232 L40,232 Q10,160 30,100 Q30,40 60,20 Z" fill="#6cc0d4" ${S(4)} ${NS}/>` +
        `<path d="M80,40 Q130,30 190,50" stroke="#fff" stroke-opacity=".5" stroke-width="4" fill="none" stroke-linecap="round" ${NS}/>` +
        `<ellipse class="ripple" cx="160" cy="170" rx="16" ry="16" fill="none" stroke="#fff" stroke-opacity=".6" stroke-width="2.5" ${NS}/>` +
        `<circle cx="98" cy="142" r="78" fill="#94c96a" ${S(4)} ${NS}/>`,
      leftSide: (r, c) => roots(r, '#7d5034', 3) + burrow(80, 66, 32, 22, c) + pebbles(r, '#8f6545', 9),
      rightSide: () => waterSide('#5fb3c8'),
      sideCritters: () => P.fish(...rightPt(70, 55), '#f3b54a', 1) + P.fish(...rightPt(160, 80), '#f39a9a', -1) + P.burrowCritter(...leftPt(80, 82), '#7a5a48'),
      back: () => P.reeds(130, 350) + P.reeds(470, 358, 0.9) + P.roundTree(200, 312, 0.9, '#7cbf5a') + P.lilypad(390, 300, 1, true) + P.lilypad(440, 322, 0.8) +
        P.rock(360, 290, 0.8, '#a3a89f') + P.tuft(250, 300) + P.bird(360, 272, '#ffe066'),
      front: () => P.lilypad(470, 420, 0.9, true) + P.lilypad(420, 452, 0.7) + P.flower(100, 396, 0.9, '#fdfaf3') + P.tuft(150, 424),
    },
    {
      id: 'mushroom', name: 'Mushroom Hollow', bg: '#5b4a6b', ring: '#9fd8e8', particles: 'spores',
      top: '#7d9a5a', left: '#7a5866', right: '#5f4351', lip: '#67864a',
      ground: () => `<ellipse cx="60" cy="60" rx="40" ry="26" fill="#8fae66"/><ellipse cx="190" cy="190" rx="34" ry="22" fill="#8fae66"/>` +
        `<circle cx="140" cy="40" r="6" fill="#c5a8f0"/><circle cx="40" cy="200" r="5" fill="#c5a8f0"/>`,
      leftSide: (r, c) => myco(r) + burrow(90, 64, 32, 22, c) + pebbles(r, '#694a57', 8),
      rightSide: (r, c) => myco(r) + burrow(150, 70, 30, 20, c) + pebbles(r, '#523946', 8),
      sideCritters: () => P.burrowCritter(...leftPt(90, 80), '#2e2533', '#9fd8e8') + P.burrowCritter(...rightPt(150, 84), '#2e2533', '#f7a8c8'),
      back: () => P.mushroom(170, 340, 2.6, '#e8604f') + P.mushroom(430, 344, 2.3, '#c5a8f0', '#fdf3e4', true) + P.mushroom(300, 286, 2.0, '#f2a65a') +
        P.mushroom(230, 306, 1, '#9fd8e8', '#fdf3e4', true) + P.mushroom(380, 304, 1.1, '#f7a8c8') + P.fern(110, 372, 0.9, '#5f8a52') + P.crystal(490, 368, 0.9, '#c5a8f0'),
      front: () => P.mushroom(100, 400, 1, '#9fd8e8', '#fdf3e4', true) + P.mushroom(500, 398, 0.9, '#e8604f') + P.mushroom(190, 448, 0.6, '#f7a8c8') + P.mushroom(410, 448, 0.6, '#c5a8f0', '#fff', true),
    },
    {
      id: 'snow', name: 'Snowy Pines', bg: '#c7d9e6', ring: '#e8604f', particles: 'snow',
      top: '#f4f8fb', left: '#9b7a68', right: '#7d5f50', lip: '#e6eef4',
      ground: () => `<path d="M30,120 Q80,100 130,120 T230,110" stroke="#d8e4ee" stroke-width="12" fill="none" stroke-linecap="round" ${NS}/>` +
        [[40, 40], [60, 50], [80, 42], [100, 52]].map(([u, v]) => `<ellipse cx="${u}" cy="${v}" rx="4" ry="5" fill="#c9d8e4"/>`).join('') +
        `<ellipse cx="190" cy="200" rx="30" ry="18" fill="#bfe0ee" ${S(3)} ${NS}/>`,
      leftSide: (r, c) => `<rect x="0" y="12" width="240" height="10" fill="#dfeaf2" opacity=".5"/>` + roots(r, '#6b4c3e', 3) + burrow(80, 70, 34, 22, c) + pebbles(r, '#86685a', 9),
      rightSide: (r, c) => `<rect x="0" y="12" width="240" height="10" fill="#dfeaf2" opacity=".4"/>` + burrow(160, 66, 34, 24, c) + pebbles(r, '#6b5044', 9) + icicles(),
      sideCritters: () => P.burrowCritter(...leftPt(80, 86), '#fdfaf3', '#3b2224') + P.burrowCritter(...rightPt(160, 84), '#8a5a3b'),
      back: () => P.pine(170, 330, 1.1, '#4f8f6a', '#6aaa84', true) + P.pine(300, 278, 1.25, '#4f8f6a', '#6aaa84', true) + P.pine(430, 330, 1.0, '#4f8f6a', '#6aaa84', true) +
        P.pine(230, 300, 0.7, '#4f8f6a', '#6aaa84', true) + P.snowman(470, 368, 1) + P.rock(110, 364, 0.8, '#b9c4cc'),
      front: () => P.pine(100, 402, 0.55, '#4f8f6a', '#6aaa84', true) + P.rock(500, 400, 0.6, '#b9c4cc') + P.bird(510, 384, '#e8604f'),
    },
    {
      id: 'meadow', name: 'Sunny Meadow', bg: '#f1e2bd', ring: '#e8604f', particles: 'petals',
      top: '#9fcf66', left: '#b5835a', right: '#946644', lip: '#86b84f',
      sky: () => `<g class="sun-pulse"><circle cx="500" cy="90" r="36" fill="#ffd86b" ${S()}/></g>` + P.cloud(110, 110, 1) + P.cloud(420, 170, 0.8),
      ground: () => `<path d="M0,150 Q60,130 120,140 T240,120" stroke="#b4dc7a" stroke-width="20" fill="none" ${NS}/>` +
        `<ellipse cx="50" cy="50" rx="24" ry="16" fill="#b4dc7a"/>`,
      leftSide: (r, c) => tunnels() + roots(r, '#7d5034', 3) + pebbles(r, '#9a6c48', 10) + worm(),
      rightSide: (r, c) => burrow(150, 66, 34, 24, c) + roots(r, '#6b4430', 3) + pebbles(r, '#7d5638', 10),
      sideCritters: () => P.burrowCritter(...rightPt(150, 84), '#9a6845'),
      back: () => P.roundTree(170, 330, 1.05, '#7cbf5a') + P.roundTree(430, 330, 0.95, '#93cc62') + P.bush(300, 282, 1.1, '#7cbf5a') +
        P.flower(230, 306, 1, '#f7a8c8') + P.flower(370, 306, 1, '#9fd8e8') + P.flower(120, 368, 1, '#ffd86b', '#f39a6b') + P.flower(480, 366, 1, '#c5a8f0') + P.tuft(260, 296) +
        P.butterfly(220, 230, '#f7a8c8') + P.butterfly(420, 250, '#9fd8e8'),
      front: () => P.flower(96, 398, 1.1, '#f39a6b') + P.flower(504, 398, 1.1, '#f7a8c8') + P.flower(170, 436, 0.8, '#fdfaf3') + P.flower(430, 436, 0.8, '#ffd86b', '#f39a6b') + P.tuft(140, 414) + P.tuft(460, 414),
    },
    {
      id: 'autumn', name: 'Autumn Woods', bg: '#ecc79b', ring: '#7d9a5a', particles: 'leaves',
      top: '#c9a54a', left: '#a8774f', right: '#865c3c', lip: '#b38d3a',
      sky: () => P.cloud(470, 120, 0.9, '#fbefdc'),
      ground: () => [[40, 60], [70, 180], [180, 40], [200, 200], [120, 20], [20, 130]].map(([u, v], i) =>
        `<ellipse cx="${u}" cy="${v}" rx="10" ry="6" fill="${['#e8604f', '#f29a3c', '#f2c14a'][i % 3]}" transform="rotate(${i * 40} ${u} ${v})"/>`).join(''),
      leftSide: (r, c) => roots(r, '#7d5034', 4) + burrow(84, 66, 38, 26, c) + acorns(84, 80) + pebbles(r, '#8f6545', 8),
      rightSide: (r, c) => roots(r, '#6b4430', 4) + burrow(160, 62, 30, 22, c) + pebbles(r, '#71492f', 9),
      sideCritters: () => P.burrowCritter(...rightPt(160, 78), '#c8743d'),
      back: () => P.roundTree(170, 330, 1.1, '#e8723c') + P.roundTree(430, 332, 1.0, '#f2b33c') + P.roundTree(300, 280, 1.2, '#d9553f') +
        P.pumpkin(120, 368, 1) + P.pumpkin(140, 380, 0.7) + P.bush(480, 368, 0.8, '#c9873a') + P.mushroom(230, 312, 0.8, '#8a5a3b'),
      front: () => P.pumpkin(500, 402, 0.9) + P.tuft(100, 400, 1, '#b38d3a') + P.mushroom(170, 440, 0.6, '#e8604f') + P.tuft(440, 432, 0.9, '#b38d3a'),
    },
    {
      id: 'desert', name: 'Desert Oasis', bg: '#f6d8ae', ring: '#4f9fb4', particles: 'motes',
      top: '#ecc78c', left: '#d79a62', right: '#bf7f4c', lip: '#e0b475',
      sky: () => `<g class="sun-pulse"><circle cx="110" cy="100" r="42" fill="#ffc94a" ${S()}/></g>` + P.cloud(470, 140, 0.7, '#fff6e6'),
      ground: () => `<ellipse cx="190" cy="60" rx="38" ry="26" fill="#6cc0d4" ${S(3.5)} ${NS}/>` +
        `<path d="M10,180 Q60,160 110,180 T230,170" stroke="#e0b475" stroke-width="8" fill="none" ${NS}/>` +
        `<path d="M20,90 Q60,80 100,92" stroke="#e0b475" stroke-width="6" fill="none" ${NS}/>`,
      leftSide: () => strata(['#d79a62', '#e2ad74', '#c98852', '#dba06a']) + fossil(),
      rightSide: () => strata(['#bf7f4c', '#c98d5a', '#b07040', '#c1814e']),
      sideCritters: () => '',
      back: () => P.cactus(170, 332, 1.2) + P.palm(380, 290, 1.1) + P.cactus(450, 338, 0.9, '#8ac466') + P.rock(250, 302, 0.9, '#d9a072') + P.rock(120, 368, 0.7, '#c98852') + P.reeds(420, 296, 0.6),
      front: () => P.cactus(500, 404, 0.6) + P.rock(110, 400, 0.6, '#d9a072') + P.flower(170, 436, 0.7, '#f39a6b'),
    },
    {
      id: 'beach', name: 'Tide Pool Beach', bg: '#bfe3ea', ring: '#f39a6b', particles: 'bubbles',
      top: '#f3dca6', left: '#e5c58a', right: '#5fb3c8', lip: '#e9cf96', rightLip: '#4f9fb4',
      sky: () => P.cloud(120, 120, 0.9) + P.cloud(480, 90, 0.7) + gull(420, 160) + gull(460, 140),
      ground: () => `<path d="M150,0 L240,0 L240,240 L200,240 Q150,200 170,150 Q190,100 150,60 Q130,30 150,0 Z" fill="#6cc0d4" ${S(4)} ${NS}/>` +
        `<path class="wave" d="M160,30 Q180,60 168,90 Q156,120 182,150" stroke="#fff" stroke-width="5" fill="none" stroke-linecap="round" ${NS}/>` +
        `<ellipse cx="60" cy="200" rx="26" ry="16" fill="#8fd0dc" ${S(3)} ${NS}/>`,
      leftSide: (r) => strata(['#e5c58a', '#dcb877', '#e8cb92']) + pebbles(r, '#f7c4b0', 6) + `<g transform="translate(150 70)"><path d="M-10,0 Q0,-14 10,0 Z" fill="#f7c4b0" ${S(3)} ${NS}/></g>`,
      rightSide: () => waterSide('#5fb3c8'),
      sideCritters: () => P.fish(...rightPt(80, 60), '#ffd86b', 1) + P.fish(...rightPt(170, 82), '#f7a8c8', -1) + P.crab(...leftPt(90, 100)),
      back: () => P.palm(170, 330, 1.15) + P.shell(250, 304, 1, '#f7c4b0') + P.starfish(380, 292, 1) + P.rock(440, 320, 0.8, '#a3a89f') + P.crab(130, 372) + P.shell(220, 330, 0.7, '#fdfaf3'),
      front: () => P.starfish(110, 398, 0.9, '#f7a8c8') + P.shell(490, 398, 0.9) + P.shell(180, 444, 0.7, '#c5a8f0') + P.starfish(420, 446, 0.6, '#ffd86b'),
    },
    {
      id: 'night', name: 'Moonlit Garden', bg: '#2a3354', ring: '#ffd86b', particles: 'fireflies', dark: true,
      top: '#4a7a62', left: '#5a4450', right: '#45343e', lip: '#3f6a54',
      sky: () => `<circle class="moon-glow" cx="480" cy="100" r="60" fill="#fff6c9" opacity=".18"/><circle cx="480" cy="100" r="34" fill="#fff3c4" ${S()}/>` +
        `<circle cx="470" cy="92" r="6" fill="#efe0a8"/><circle cx="490" cy="110" r="4" fill="#efe0a8"/>` + stars(),
      ground: () => `<path d="M20,120 Q120,90 220,120" stroke="#5c8d72" stroke-width="22" fill="none" ${NS}/>` +
        `<ellipse cx="60" cy="50" rx="20" ry="12" fill="#5c8d72"/>`,
      leftSide: (r, c) => myco(r, '#9fd8e8') + burrow(80, 66, 32, 22, c) + pebbles(r, '#6b5260', 8),
      rightSide: (r, c) => burrow(160, 66, 32, 22, c) + pebbles(r, '#574350', 8),
      sideCritters: () => P.crystal(...leftPt(150, 96), 0.8, '#9fd8e8') + P.burrowCritter(...leftPt(80, 82), '#2e2533', '#ffd86b') + P.crystal(...rightPt(70, 100), 0.7, '#c5a8f0') + P.burrowCritter(...rightPt(160, 82), '#2e2533', '#9fd8e8'),
      back: () => P.roundTree(170, 330, 1.05, '#3f7a5a') + P.roundTree(430, 330, 0.95, '#4a8a66') + P.lantern(300, 284, 1.1) +
        P.flower(230, 306, 1, '#c5a8f0', '#fff6c9') + P.flower(370, 306, 1, '#9fd8e8', '#fff6c9') + P.crystal(120, 370, 0.9, '#9fd8e8') + P.mushroom(480, 366, 0.8, '#c5a8f0', '#fff', true),
      front: () => P.flower(100, 398, 1, '#f7a8c8', '#fff6c9') + P.lantern(500, 404, 0.8) + P.mushroom(180, 444, 0.6, '#9fd8e8', '#fff', true) + P.flower(420, 440, 0.8, '#c5a8f0', '#fff6c9'),
    },
    {
      id: 'reef', name: 'Coral Reef Tank', bg: '#d4cdc0', ring: '#f39a9a', particles: 'bubbles', tank: true,
      top: '#efd9a8', left: '#c9a06a', right: '#a8804f', lip: '#e2c690',
      ground: () => `<ellipse cx="60" cy="70" rx="26" ry="16" fill="#e2c690"/><ellipse cx="190" cy="190" rx="30" ry="18" fill="#e2c690"/>` +
        [[30, 150], [90, 30], [210, 90], [150, 220]].map(([u, v]) => `<circle cx="${u}" cy="${v}" r="5" fill="#d1b27c"/>`).join(''),
      leftSide: (r) => strata(['#c9a06a', '#b98f5c']) + pebbles(r, '#9aa0b0', 14, 14) + pebbles(r, '#f7c4b0', 6, 14),
      rightSide: (r) => strata(['#a8804f', '#9a7445']) + pebbles(r, '#7f8698', 14, 14),
      sideCritters: () => '',
      back: () => P.seaweed(150, 340, 110) + P.seaweed(166, 344, 80, '#8ad08a') + P.coral(240, 304, 1.4, '#f39a9a') + P.coral(370, 300, 1.2, '#c5a8f0') +
        P.seaweed(450, 344, 100, '#5fae7a') + P.rock(300, 280, 1, '#9aa0b0') + P.coral(120, 372, 1, '#ffd86b') + P.starfish(470, 366, 0.9) +
        P.fish(210, 200, '#f3b54a', 1) + P.fish(400, 170, '#9fd8e8', -1) + P.fish(320, 130, '#f7a8c8', 1),
      front: () => P.coral(500, 404, 0.9, '#f39a6b') + P.shell(100, 398, 0.9) + P.seaweed(180, 448, 40) + P.seaweed(420, 448, 46, '#8ad08a'),
    },
  ];

  /* small helpers used above */
  function shift(p, dx, dy) { return [p[0] + dx, p[1] + dy]; }
  function myco(rng, c = '#e7d7a8') {
    let s = '';
    for (let i = 0; i < 4; i++) {
      const u = 20 + rng() * 200;
      s += `<path d="M${f(u)},14 Q${f(u + 20)},40 ${f(u - 10)},60 T${f(u + 10)},100" stroke="${c}" stroke-opacity=".55" stroke-width="2.5" fill="none" stroke-dasharray="1 5" stroke-linecap="round" class="glow-pulse" ${NS}/>`;
    }
    return s;
  }
  function icicles() {
    return [20, 60, 110, 170, 210].map((u) => `<path d="M${u - 5},12 L${u},${30 + (u % 3) * 6} L${u + 5},12 Z" fill="#e6f3fb" ${S(2.5)} ${NS}/>`).join('');
  }
  function tunnels() {
    return `<path d="M40,30 Q70,50 60,70 T110,96 T180,80" stroke="#d8b08a" stroke-width="10" fill="none" stroke-linecap="round" ${NS}/>` +
      [[62, 64], [110, 95], [160, 84]].map(([u, v]) => `<ellipse cx="${u}" cy="${v}" rx="3" ry="2" fill="${O}"/>`).join('');
  }
  function worm() {
    return `<path d="M170,40 q8,-8 16,0 t16,0" stroke="${O}" stroke-width="10" fill="none" stroke-linecap="round" ${NS}/><path d="M170,40 q8,-8 16,0 t16,0" stroke="#f4a7b0" stroke-width="5" fill="none" stroke-linecap="round" ${NS}/>`;
  }
  function acorns(u, v) {
    return [[-14, 6], [0, 8], [14, 6], [-6, 0], [8, 0]].map(([dx, dy]) => `<ellipse cx="${u + dx}" cy="${v + dy}" rx="5" ry="6" fill="#b5703a" ${S(2.5)} ${NS}/><path d="M${u + dx - 6},${v + dy - 3} L${u + dx + 6},${v + dy - 3}" stroke="#7d5034" stroke-width="4" ${NS}/>`).join('');
  }
  function fossil() {
    return `<g transform="translate(120 70)"><path d="M0,0 a6,6 0 1 1 8,-4 a12,12 0 1 1 -18,10 a18,18 0 1 1 26,-16" stroke="#f3dcb4" stroke-width="3" fill="none" stroke-linecap="round" ${NS}/></g>`;
  }
  function gull(x, y) {
    return `<g class="glide"><path d="M${x - 12},${y} Q${x - 6},${y - 8} ${x},${y} Q${x + 6},${y - 8} ${x + 12},${y}" stroke="${O}" stroke-width="3.5" fill="none" stroke-linecap="round"/></g>`;
  }
  function stars() {
    const r = GC.seeded(7);
    let s = '';
    for (let i = 0; i < 26; i++) {
      const x = r() * 600, y = r() * 230;
      s += `<circle class="twinkle" style="--td:${(2 + r() * 3).toFixed(1)}s;animation-delay:-${(r() * 4).toFixed(1)}s" cx="${f(x)}" cy="${f(y)}" r="${f(1.5 + r() * 2)}" fill="#fff6c9"/>`;
    }
    return s;
  }

  /* ===================================================== particles */
  function particles(type, n) {
    if (!type) return '';
    const r = GC.seeded(type.length * 31);
    let s = '';
    const count = n || 16;
    for (let i = 0; i < count; i++) {
      const x = r() * 600, y = r() * 420, dur = 6 + r() * 8, delay = -r() * dur;
      const st = `style="--dur:${dur.toFixed(1)}s;--dx:${((r() - 0.5) * 80).toFixed(0)}px;animation-delay:${delay.toFixed(1)}s"`;
      switch (type) {
        case 'fireflies':
          s += `<g transform="translate(${f(x)} ${f(120 + y * 0.8)})"><circle class="p-firefly" ${st} r="4" fill="#fff2a0"/></g>`;
          break;
        case 'spores':
          s += `<g transform="translate(${f(x)} ${f(250 + y * 0.6)})"><circle class="p-rise" ${st} r="${f(2 + r() * 2.5)}" fill="${r() < 0.5 ? '#9fd8e8' : '#e7d7a8'}"/></g>`;
          break;
        case 'bubbles':
          s += `<g transform="translate(${f(x)} ${f(330 + y * 0.5)})"><circle class="p-rise" ${st} r="${f(3 + r() * 5)}" fill="#fff" fill-opacity=".25" stroke="#fff" stroke-width="2"/></g>`;
          break;
        case 'snow':
          s += `<g transform="translate(${f(x)} -20)"><circle class="p-fall" ${st} r="${f(2.5 + r() * 3)}" fill="#fff"/></g>`;
          break;
        case 'leaves':
          s += `<g transform="translate(${f(x)} -20)"><path class="p-fall p-spin" ${st} d="M0,-7 C5,-4 5,4 0,7 C-5,4 -5,-4 0,-7 Z" fill="${['#e8604f', '#f29a3c', '#f2c14a'][i % 3]}" stroke="${O}" stroke-width="2"/></g>`;
          break;
        case 'petals':
          s += `<g transform="translate(${f(x)} -20)"><ellipse class="p-fall p-spin" ${st} rx="4" ry="6" fill="${['#f7a8c8', '#fdfaf3', '#ffd86b'][i % 3]}"/></g>`;
          break;
        case 'motes':
          s += `<g transform="translate(${f(x)} ${f(100 + y)})"><circle class="p-firefly" ${st} r="2.5" fill="#fff6e0"/></g>`;
          break;
        case 'dragonflies':
          if (i < 3) s += `<g class="flutter" style="--fx:${f(150 + r() * 300)}px;--fy:${f(180 + r() * 100)}px;animation-duration:${(9 + r() * 4).toFixed(1)}s"><g class="flap">` +
            `<ellipse cx="-7" cy="-2" rx="8" ry="3.5" fill="#cfeef5" ${S(2)}/><ellipse cx="7" cy="-2" rx="8" ry="3.5" fill="#cfeef5" ${S(2)}/><rect x="-2" y="-6" width="4" height="16" rx="2" fill="#4f9fb4"/></g></g>`;
          else s += `<g transform="translate(${f(x)} ${f(150 + y * 0.7)})"><circle class="p-firefly" ${st} r="2.5" fill="#fff"/></g>`;
          break;
      }
    }
    return `<g class="particles">${s}</g>`;
  }

  /* ===================================================== build */
  function tankGlass(sc) {
    // glass water volume above the seabed, like the cysketch terrarium
    const H = 230; // water height above top face
    const up = (p) => `${p[0]},${p[1] - H}`;
    const L = [60, 370], T = [300, 250], R = [540, 370], B = [300, 490];
    const back = `<polygon points="${L.join(',')} ${T.join(',')} ${R.join(',')} ${up(R)} ${up(T)} ${up(L)}" fill="#7fd1cf" fill-opacity=".28"/>` +
      `<polygon points="${up(L)} ${up(T)} ${up(R)} ${up(B)}" fill="#a8e6e0" fill-opacity=".35" class="water-top"/>` +
      `<path d="M${up(T)} L${T.join(',')}" stroke="#9ef0cf" stroke-width="3" opacity=".8"/>`;
    const front = `<g class="tank-front" fill="none" stroke="#9ef0cf" stroke-width="4" stroke-linejoin="round" opacity=".95">` +
      `<polygon points="${up(L)} ${up(T)} ${up(R)} ${up(B)}"/>` +
      `<path d="M${L.join(',')} L${up(L)} M${R.join(',')} L${up(R)}"/></g>` +
      `<path d="M${L[0] + 30},${L[1] - 30} L${L[0] + 30},${L[1] - 170}" stroke="#fff" stroke-opacity=".35" stroke-width="8" stroke-linecap="round"/>` +
      `<path d="M${R[0] - 40},${R[1] - 40} L${R[0] - 40},${R[1] - 150}" stroke="#fff" stroke-opacity=".25" stroke-width="6" stroke-linecap="round"/>`;
    return { back, front };
  }

  /**
   * Draw a scene into an <svg>. Returns handles for layering:
   *   { ringLayer, eggLayer, fxLayer }
   */
  function build(svg, sceneId, opts = {}) {
    const sc = SCENES.find((s) => s.id === sceneId) || SCENES[0];
    const rng = GC.seeded(sc.id.length * 977 + sc.id.charCodeAt(0));
    const L = [60, 370], T = [300, 250], R = [540, 370], B = [300, 490];
    const dn = (p) => `${p[0]},${p[1] + D}`;
    const tank = sc.tank ? tankGlass(sc) : null;

    const lipL = lip(sc.lip, true, rng);
    const lipR = lip(sc.rightLip || sc.lip, !sc.rightLip, rng);

    svg.setAttribute('viewBox', '0 0 600 720');
    svg.innerHTML =
      `<rect class="scene-bg" x="-400" y="-400" width="1400" height="1520" fill="${sc.bg}"/>` +
      `<g class="scene-sky">${sc.sky ? sc.sky() : ''}</g>` +
      `<ellipse cx="300" cy="${612}" rx="250" ry="40" fill="${O}" opacity=".14"/>` +
      (tank ? tank.back : '') +
      // left face
      `<polygon points="${L.join(',')} ${B.join(',')} ${dn(B)} ${dn(L)}" fill="${sc.left}"/>` +
      `<g transform="${LEFT_M}">${sc.leftSide(rng, sc.left)}${lipL}</g>` +
      `<polygon points="${L.join(',')} ${B.join(',')} ${dn(B)} ${dn(L)}" fill="none" ${S(5)}/>` +
      // right face
      `<polygon points="${B.join(',')} ${R.join(',')} ${dn(R)} ${dn(B)}" fill="${sc.right}"/>` +
      `<g transform="${RIGHT_M}">${sc.rightSide(rng, sc.right)}${lipR}</g>` +
      `<polygon points="${B.join(',')} ${R.join(',')} ${dn(R)} ${dn(B)}" fill="none" ${S(5)}/>` +
      `<polygon points="${B.join(',')} ${R.join(',')} ${dn(R)} ${dn(B)}" fill="${O}" opacity=".08"/>` +
      `<g class="side-critters">${sc.sideCritters ? sc.sideCritters() : ''}</g>` +
      // top face
      `<polygon points="${L.join(',')} ${T.join(',')} ${R.join(',')} ${B.join(',')}" fill="${sc.top}"/>` +
      `<g transform="${TOP_M}">${sc.ground(rng)}</g>` +
      `<polygon points="${L.join(',')} ${T.join(',')} ${R.join(',')} ${B.join(',')}" fill="none" ${S(5)}/>` +
      `<g class="props-back">${sc.back()}</g>` +
      `<g class="ring-layer"></g>` +
      `<g class="egg-layer"></g>` +
      `<g class="props-front">${sc.front()}</g>` +
      (tank ? tank.front : '') +
      (opts.particles === false ? '' : particles(sc.particles, sc.particles === 'fireflies' ? 18 : 16)) +
      `<g class="fx-layer"></g>`;
    svg.classList.toggle('scene-dark', !!sc.dark);
    svg.dataset.scene = sc.id;
    return {
      scene: sc,
      ringLayer: svg.querySelector('.ring-layer'),
      eggLayer: svg.querySelector('.egg-layer'),
      fxLayer: svg.querySelector('.fx-layer'),
    };
  }

  GC.Scenes = { list: SCENES, build, EGG, RING };
})();

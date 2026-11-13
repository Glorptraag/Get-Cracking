/* Get Cracking — drawn icons.
 *
 * Every icon in the app is drawn here in the same visual language as the
 * eggs and friends: chunky dark outline, flat warm fills, a 48×48 box.
 * No emoji anywhere, so the UI looks the same on every device.
 *
 *   GC.icon(name)          → '<svg …>' markup string
 *   GC.Icons.el(name)      → an <svg> element
 *   GC.Icons.has(name)     → is this a known icon?
 *   GC.Icons.fromEmoji(e)  → icon name for an emoji saved by older builds
 *
 * Static markup can ask for one with <span class="ico" data-icon="lock">;
 * those are filled in when this file loads.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT;
  const S = `stroke="${O}" stroke-width="3.5" stroke-linejoin="round" stroke-linecap="round"`;
  const L = (w = 3.5) => `fill="none" stroke="${O}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round"`;
  const SHINE = `fill="none" stroke="#fff" stroke-opacity=".65" stroke-width="3" stroke-linecap="round"`;
  const C = {
    cream: '#fdf3e4', teal: '#62b5c5', tealDk: '#4b9bab', gold: '#e0a43c', yellow: '#ffd86b', leaf: '#a9d36b',
    leafDk: '#7fb04a', berry: '#c9483f', clay: '#d98a64', wood: '#b98652', bark: '#9a5a3c', pink: '#f7a8c8',
    sky: '#9fd8e8', stone: '#cbbfae', grey: '#8d8784', lilac: '#c5a8f0', orange: '#f39a6b',
  };
  const f = (n) => +n.toFixed(1);
  const pt = (cx, cy, r, deg) => [f(cx + Math.cos((deg * Math.PI) / 180) * r), f(cy + Math.sin((deg * Math.PI) / 180) * r)];

  /** a toothed wheel: n teeth between radius r0 (root) and r1 (tip) */
  function gear(cx, cy, r0, r1, n) {
    const step = 360 / n, d = [];
    for (let i = 0; i < n; i++) {
      const a = i * step;
      d.push(pt(cx, cy, r0, a - step * 0.5), pt(cx, cy, r0, a - step * 0.28), pt(cx, cy, r1, a - step * 0.18), pt(cx, cy, r1, a + step * 0.18), pt(cx, cy, r0, a + step * 0.28));
    }
    return 'M' + d.map((p) => p.join(' ')).join(' L') + ' Z';
  }
  /** a pointed star or burst */
  function star(cx, cy, r0, r1, n, rot = -90) {
    const d = [];
    for (let i = 0; i < n * 2; i++) d.push(pt(cx, cy, i % 2 ? r0 : r1, rot + (i * 180) / n));
    return 'M' + d.map((p) => p.join(' ')).join(' L') + ' Z';
  }
  /** a fat curved arrow along a circle, drawn as an outlined ribbon with a head */
  function arcArrow(cx, cy, r, a0, a1, fill) {
    const [x0, y0] = pt(cx, cy, r, a0), [x1, y1] = pt(cx, cy, r, a1);
    const large = Math.abs(a1 - a0) > 180 ? 1 : 0, sweep = a1 > a0 ? 1 : 0;
    const arc = `M${x0} ${y0} A${r} ${r} 0 ${large} ${sweep} ${x1} ${y1}`;
    const dir = sweep ? 90 : -90; // tangent direction at the end
    const tip = pt(x1, y1, 7, a1 + dir), b1 = pt(x1, y1, 7.5, a1), b2 = pt(x1, y1, -7.5, a1);
    return `<path d="${arc}" fill="none" stroke="${O}" stroke-width="10" stroke-linecap="round"/>` +
      `<path d="${arc}" fill="none" stroke="${fill}" stroke-width="3.6" stroke-linecap="round"/>` +
      `<path d="M${b1.join(' ')} L${tip.join(' ')} L${b2.join(' ')} Z" fill="${fill}" ${S}/>`;
  }
  const EGG = 'M24 4 C33 4 38 19 38 28 C38 37 32 44 24 44 C16 44 10 37 10 28 C10 19 15 4 24 4 Z';
  const chickFace = (cx, cy) =>
    `<circle cx="${cx - 4}" cy="${cy - 1}" r="1.9" fill="${O}"/><circle cx="${cx + 4}" cy="${cy - 1}" r="1.9" fill="${O}"/>` +
    `<path d="M${cx - 2.6} ${cy + 2.5} L${cx + 2.6} ${cy + 2.5} L${cx} ${cy + 5.6} Z" fill="${C.orange}" stroke="${O}" stroke-width="2.2" stroke-linejoin="round"/>`;

  const ICONS = {
    /* ---------- setup + navigation */
    tree: `<path d="M20.5 29 V42 H27.5 V29" fill="${C.bark}" ${S}/>` +
      `<path d="M24 5 C33 5 39 11 39 19 C39 27 33 32 24 32 C15 32 9 27 9 19 C9 11 15 5 24 5 Z" fill="${C.leaf}" ${S}/>` +
      `<path d="M15 19 C15 14 18 11 22 10" ${SHINE}/><path d="M6 42 H42" ${L()}/>`,
    notes: `<path d="M17 35 V14 L36 9 V31" ${L()}/><path d="M17 13.5 L36 8.5 V15 L17 20 Z" fill="${O}"/>` +
      `<ellipse cx="12" cy="36" rx="6.3" ry="5" transform="rotate(-20 12 36)" fill="${C.teal}" ${S}/>` +
      `<ellipse cx="31" cy="32" rx="6.3" ry="5" transform="rotate(-20 31 32)" fill="${C.teal}" ${S}/>`,
    note: `<path d="M27 34 V7 C30 12 37 13 37 21" ${L()}/>` +
      `<ellipse cx="21" cy="35" rx="7.4" ry="5.8" transform="rotate(-20 21 35)" fill="${C.gold}" ${S}/>`,
    book: `<path d="M3 14 V41 C10 39 18 39 24 43 C30 39 38 39 45 41 V14" fill="${C.berry}" ${S}/>` +
      `<path d="M24 13 C19 9 12 8 6 10 V37 C12 35 19 36 24 40 Z" fill="${C.cream}" ${S}/>` +
      `<path d="M24 13 C29 9 36 8 42 10 V37 C36 35 29 36 24 40 Z" fill="${C.cream}" ${S}/>` +
      `<path d="M10 17 C13 16 17 16 20 18 M10 23 C13 22 17 22 20 24 M28 18 C31 16 35 16 38 17 M28 24 C31 22 35 22 38 23" fill="none" stroke="${O}" stroke-opacity=".35" stroke-width="2.4" stroke-linecap="round"/>`,
    gear: `<path d="${gear(24, 24, 14.5, 20.5, 8)}" fill="${C.stone}" ${S}/>` +
      `<circle cx="24" cy="24" r="6.5" fill="${C.cream}" ${S}/>`,

    /* ---------- timer screen */
    tap: `<rect x="17" y="2.5" width="10" height="27" rx="5" fill="#fbd3a8" ${S}/>` +
      `<path d="M14 23 H35 C38 23 40 25 40 28 V33 C40 40 35 45 28 45 H25 C17 45 11 40 11 32 V26 C11 24 12 23 14 23 Z" fill="#fbd3a8" ${S}/>` +
      `<path d="M17 24 V32 M27 24 V30 M33.5 24 V30" fill="none" stroke="${O}" stroke-width="3" stroke-linecap="round"/>` +
      `<path d="M20 8 V14" ${SHINE}/>`,
    lock: `<path d="M15 22 V16 C15 10.5 19 7 24 7 C29 7 33 10.5 33 16 V22" fill="none" stroke="${O}" stroke-width="9" stroke-linecap="round"/>` +
      `<path d="M15 22 V16 C15 10.5 19 7 24 7 C29 7 33 10.5 33 16 V22" fill="none" stroke="${C.stone}" stroke-width="3" stroke-linecap="round"/>` +
      `<rect x="9" y="21" width="30" height="22" rx="6" fill="${C.gold}" ${S}/>` +
      `<path d="M24 28 V35" stroke="${O}" stroke-width="5" stroke-linecap="round"/><circle cx="24" cy="28.5" r="3.6" fill="${O}"/>`,
    egg: `<path d="${EGG}" fill="#fbf1dc" ${S}/>` +
      `<circle cx="20" cy="17" r="3.2" fill="#a9cf8b"/><circle cx="29" cy="24" r="4.2" fill="#a9cf8b"/><circle cx="19" cy="32" r="3.6" fill="#a9cf8b"/><circle cx="29" cy="37" r="2.6" fill="#a9cf8b"/>` +
      `<path d="M15 30 C14 22 16 14 20 9" ${SHINE}/>`,
    pause: `<rect x="11" y="9" width="9" height="30" rx="3.5" fill="${C.teal}" ${S}/><rect x="28" y="9" width="9" height="30" rx="3.5" fill="${C.teal}" ${S}/>`,
    play: `<path d="M15 9.5 C15 7.5 17 6.5 18.7 7.5 L39 21.5 C40.6 22.6 40.6 25.4 39 26.5 L18.7 40.5 C17 41.5 15 40.5 15 38.5 Z" fill="${C.leaf}" ${S}/>`,
    stop: `<rect x="10" y="10" width="28" height="28" rx="6" fill="${C.berry}" ${S}/>`,
    hatch: `<path d="M24 8 C22.5 5 25 3.5 27 5" ${L(3)}/><circle cx="24" cy="20" r="11.5" fill="${C.yellow}" ${S}/>${chickFace(24, 19)}` +
      `<path d="M9 29 L14 24 L19 30 L24 25 L29 30 L34 24 L39 29 C39 39 33 45 24 45 C15 45 9 39 9 29 Z" fill="#fbf1dc" ${S}/>`,
    again: arcArrow(24, 24, 14, 200, 340, C.leafDk) + arcArrow(24, 24, 14, 20, 160, C.teal),
    reset: arcArrow(24, 25, 13.5, -40, 230, C.teal),
    close: `<path d="M14 14 L34 34 M34 14 L14 34" fill="none" stroke="${O}" stroke-width="6" stroke-linecap="round"/>`,
    minus: `<path d="M11 24 H37" fill="none" stroke="${O}" stroke-width="6" stroke-linecap="round"/>`,
    plus: `<path d="M24 11 V37 M11 24 H37" fill="none" stroke="${O}" stroke-width="6" stroke-linecap="round"/>`,

    /* ---------- settings choices */
    dice: `<g transform="rotate(-10 24 24)"><rect x="8" y="8" width="32" height="32" rx="8" fill="${C.cream}" ${S}/>` +
      [[16, 16], [32, 16], [24, 24], [16, 32], [32, 32]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3.2" fill="${C.berry}"/>`).join('') + `</g>`,
    bird: `<path d="M13 27 L4 21 L6 33 Z" fill="${C.tealDk}" ${S}/><circle cx="22" cy="26" r="13" fill="${C.teal}" ${S}/>` +
      `<path d="M14 26 C17 33 25 33 28 27" fill="none" stroke="${O}" stroke-width="3" stroke-linecap="round"/>` +
      `<circle cx="27" cy="21" r="2.1" fill="${O}"/><path d="M34 20 L42 23 L34 26.5 Z" fill="${C.gold}" ${S}/>` +
      `<path d="M19 39 V44 M25 39 V44" ${L(3)}/>`,
    chick: `<path d="M24 10 C22.5 6.5 25 5 27 6.5" ${L(3)}/><circle cx="24" cy="27" r="15" fill="${C.yellow}" ${S}/>${chickFace(24, 24)}` +
      `<path d="M10.5 30 C13 35 17 35 18 32" fill="none" stroke="${O}" stroke-width="3" stroke-linecap="round"/><path d="M37.5 30 C35 35 31 35 30 32" fill="none" stroke="${O}" stroke-width="3" stroke-linecap="round"/>` +
      `<circle cx="16" cy="29" r="2.4" fill="${C.pink}"/><circle cx="32" cy="29" r="2.4" fill="${C.pink}"/>`,
    rain: `<path d="M13 30 C6.5 30 5.5 21 12 19.5 C12 11.5 22 8.5 26 14.5 C30 10.5 38.5 13 37.5 20 C43.5 21 42.5 30 36 30 Z" fill="${C.cream}" ${S}/>` +
      [[15, 35], [24, 38], [33, 35]].map(([x, y]) => `<path d="M${x} ${y} C${x + 2.6} ${y + 3.4} ${x + 3} ${y + 6.4} ${x} ${y + 6.8} C${x - 3} ${y + 6.4} ${x - 2.6} ${y + 3.4} ${x} ${y} Z" fill="${C.sky}" stroke="${O}" stroke-width="2.6" stroke-linejoin="round"/>`).join(''),
    clock: `<path d="M15 41 L12.5 45 M33 41 L35.5 45" ${L()}/><circle cx="24" cy="25" r="17" fill="${C.gold}" ${S}/>` +
      `<circle cx="24" cy="25" r="12" fill="${C.cream}" ${S}/><path d="M24 25 V17.5 M24 25 L29 28" ${L()}/>` +
      `<circle cx="24" cy="25" r="2" fill="${O}"/><circle cx="24" cy="5.5" r="3" fill="${C.gold}" ${S}/>`,
    quiet: `<path d="M7 19 H15 L25 10.5 V37.5 L15 29 H7 Z" fill="${C.stone}" ${S}/>` +
      `<path d="M31 19 L41 29 M41 19 L31 29" fill="none" stroke="${O}" stroke-width="4.5" stroke-linecap="round"/>`,
    tada: `<path d="M6 43 L15 17 L32 34 Z" fill="${C.gold}" ${S}/><path d="M10.5 31 L20 38.5 M13 24 L26 34.5" fill="none" stroke="${C.berry}" stroke-width="3.4" stroke-linecap="round"/>` +
      `<path d="M6 43 L15 17 L32 34 Z" fill="none" ${S}/>` +
      `<path d="${star(32, 11, 2.4, 6, 4)}" fill="${C.yellow}" stroke="${O}" stroke-width="2.4" stroke-linejoin="round"/>` +
      `<circle cx="41" cy="22" r="3" fill="${C.pink}" stroke="${O}" stroke-width="2.4"/><circle cx="22" cy="7" r="2.6" fill="${C.sky}" stroke="${O}" stroke-width="2.4"/>` +
      `<path d="M37 33 C40 31 41 35 44 33" fill="none" stroke="${O}" stroke-width="2.6" stroke-linecap="round"/>`,
    bell: `<circle cx="24" cy="39" r="4" fill="${C.gold}" ${S}/><circle cx="24" cy="6.5" r="2.8" fill="${C.gold}" ${S}/>` +
      `<path d="M24 8.5 C15 8.5 12.5 16 12.5 23 V30 L8 36 H40 L35.5 30 V23 C35.5 16 33 8.5 24 8.5 Z" fill="${C.yellow}" ${S}/>` +
      `<path d="M17.5 28 V22 C17.5 18 19 15.5 21 14.5" ${SHINE}/>`,
    bubbles: [[19, 27, 13], [36, 14, 7.5], [37, 36, 5]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${C.sky}" fill-opacity=".85" ${S}/>` +
      `<path d="M${f(x - r * 0.55)} ${f(y - r * 0.05)} A${f(r * 0.58)} ${f(r * 0.58)} 0 0 1 ${f(x - r * 0.05)} ${f(y - r * 0.55)}" ${SHINE}/>`).join(''),
    roll: `<path d="M3 20 H11 M1 28 H9 M4 36 H11" fill="none" stroke="${O}" stroke-width="3.4" stroke-linecap="round"/>` +
      `<g transform="rotate(32 27 26)"><path d="M27 6 C35 6 40 20 40 27 C40 36 34 42 27 42 C20 42 14 36 14 27 C14 20 19 6 27 6 Z" fill="#fbf1dc" ${S}/>` +
      `<path d="M14.5 27 L19 23 L23 28 L27 23.5 L31 28 L35 23 L39.5 27" ${L(3)}/></g>`,
    boom: `<path d="${star(24, 24, 11, 21, 9)}" fill="${C.orange}" ${S}/><path d="${star(24, 24, 6, 11.5, 7, -70)}" fill="${C.yellow}" ${S}/>`,
    bricks: `<rect x="5" y="9" width="17" height="10" rx="2" fill="${C.clay}" ${S}/><rect x="22" y="9" width="17" height="10" rx="2" fill="${C.clay}" ${S}/>` +
      `<rect x="13" y="19" width="17" height="10" rx="2" fill="${C.clay}" ${S}/><rect x="30" y="19" width="13" height="10" rx="2" fill="${C.clay}" ${S}/>` +
      `<rect x="5" y="19" width="8" height="10" rx="2" fill="${C.clay}" ${S}/>` +
      `<rect x="5" y="29" width="17" height="10" rx="2" fill="${C.clay}" ${S}/><rect x="22" y="29" width="17" height="10" rx="2" fill="${C.clay}" ${S}/>` +
      `<path d="M40 36 L45 41 L40 44 Z M36 42 L39 46 L34 46 Z" fill="${C.clay}" stroke="${O}" stroke-width="2.6" stroke-linejoin="round"/>`,
    paw: `<path d="M24 24 C31 24 37 31 37 36 C37 41 33 43 29 42 C26.5 41.5 25.5 40.5 24 40.5 C22.5 40.5 21.5 41.5 19 42 C15 43 11 41 11 36 C11 31 17 24 24 24 Z" fill="${C.wood}" ${S}/>` +
      [[11, 20, -20], [19, 12, -6], [29, 12, 6], [37, 20, 20]].map(([x, y, r]) => `<ellipse cx="${x}" cy="${y}" rx="4.6" ry="6" transform="rotate(${r} ${x} ${y})" fill="${C.wood}" ${S}/>`).join(''),
    camera: `<path d="M17 13 L19.5 8 H28.5 L31 13" fill="${C.stone}" ${S}/><rect x="5" y="13" width="38" height="27" rx="6" fill="${C.teal}" ${S}/>` +
      `<circle cx="24" cy="26.5" r="9" fill="${C.cream}" ${S}/><circle cx="24" cy="26.5" r="4" fill="${O}"/><circle cx="22.4" cy="24.8" r="1.4" fill="#fff"/>` +
      `<rect x="34" y="17" width="5" height="3.4" rx="1.4" fill="${C.yellow}" stroke="${O}" stroke-width="2.2"/>`,
    gift: `<path d="M24 14 C20 6 12 6 13 11 C14 15 20 14 24 14 C28 14 34 15 35 11 C36 6 28 6 24 14 Z" fill="${C.gold}" ${S}/>` +
      `<rect x="9" y="21" width="30" height="22" rx="3" fill="${C.berry}" ${S}/><rect x="6" y="14" width="36" height="8" rx="3" fill="${C.berry}" ${S}/>` +
      `<path d="M24 14 V43" stroke="${O}" stroke-width="9.5"/><path d="M24 15.6 V41.3" stroke="${C.gold}" stroke-width="3"/>`,
    broom: `<path d="M38 5 L25 25" fill="none" stroke="${O}" stroke-width="7.5" stroke-linecap="round"/><path d="M38 5 L25 25" fill="none" stroke="${C.wood}" stroke-width="2.6" stroke-linecap="round"/>` +
      `<path d="M20 21 L31 28 L24 44 C18 44 9 39 6 34 Z" fill="${C.gold}" ${S}/><path d="M12 33 C15 36 18 38 21 39 M17 27 C14 31 12 33 9 35" fill="none" stroke="${O}" stroke-opacity=".45" stroke-width="2.4" stroke-linecap="round"/>` +
      `<path d="M19.5 21 L31.5 28.5" fill="none" stroke="${O}" stroke-width="6" stroke-linecap="round"/><path d="M19.5 21 L31.5 28.5" fill="none" stroke="${C.berry}" stroke-width="2" stroke-linecap="round"/>`,
    picture: `<rect x="5" y="8" width="38" height="32" rx="4" fill="${C.gold}" ${S}/><rect x="10.5" y="13.5" width="27" height="21" rx="1.5" fill="${C.sky}" ${S}/>` +
      `<circle cx="31" cy="20" r="3.4" fill="${C.yellow}" stroke="${O}" stroke-width="2.4"/>` +
      `<path d="M10.5 34.5 V30 C14 25 18 24 23 29 C27 26 32 26 37.5 31 V34.5 Z" fill="${C.leaf}" ${S}/>`,

    /* ---------- "next up" card */
    teddy: `<ellipse cx="24" cy="37" rx="11.5" ry="8.5" fill="${C.wood}" ${S}/><circle cx="14" cy="11" r="5" fill="${C.wood}" ${S}/><circle cx="34" cy="11" r="5" fill="${C.wood}" ${S}/>` +
      `<circle cx="24" cy="20" r="11.5" fill="${C.wood}" ${S}/><ellipse cx="24" cy="24.5" rx="5.5" ry="4.4" fill="${C.cream}" ${S}/>` +
      `<circle cx="19.5" cy="17.5" r="1.9" fill="${O}"/><circle cx="28.5" cy="17.5" r="1.9" fill="${O}"/><ellipse cx="24" cy="23" rx="2" ry="1.5" fill="${O}"/>` +
      `<ellipse cx="24" cy="38" rx="5" ry="4" fill="${C.cream}"/>`,
    bath: [[15, 12, 4.5], [24, 8, 3.2], [31, 14, 5]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${C.sky}" stroke="${O}" stroke-width="2.6"/>`).join('') +
      `<path d="M12 39 L9.5 44 M36 39 L38.5 44" ${L()}/>` +
      `<path d="M4 22 H44 V26 C44 34 38 40 30 40 H18 C10 40 4 34 4 26 Z" fill="#fff" ${S}/><path d="M7 27 H41" stroke="${C.teal}" stroke-width="3.2" stroke-linecap="round"/>`,
    bowl: `<path d="M39 6 L28 21" fill="none" stroke="${O}" stroke-width="6.5" stroke-linecap="round"/><path d="M39 6 L28 21" fill="none" stroke="${C.stone}" stroke-width="2" stroke-linecap="round"/>` +
      `<ellipse cx="24" cy="22" rx="18" ry="5" fill="${C.cream}" ${S}/>` +
      `<circle cx="17" cy="21" r="2" fill="${C.gold}"/><circle cx="24" cy="23" r="2" fill="${C.clay}"/><circle cx="30" cy="20.5" r="2" fill="${C.gold}"/>` +
      `<path d="M6 23 C6 34 14 41 24 41 C34 41 42 34 42 23 C38 26 31 27 24 27 C17 27 10 26 6 23 Z" fill="${C.teal}" ${S}/>`,
    sock: `<path d="M16 5 H31 V25 L38 30 C43 33.5 41.5 43 34 43 H24 C18 43 15.5 39 15.5 34 Z" fill="${C.berry}" ${S}/>` +
      `<rect x="14.5" y="4.5" width="18" height="8" rx="2.5" fill="${C.cream}" ${S}/>` +
      `<path d="M15.5 32 C20 31 23 34 22.5 43 M34 33 C38 34 40 36 40.5 39" fill="none" stroke="${C.cream}" stroke-width="3.5" stroke-linecap="round"/>` +
      `<path d="M16 5 H31 V25 L38 30 C43 33.5 41.5 43 34 43 H24 C18 43 15.5 39 15.5 34 Z M15.5 12.5 V5" fill="none" ${S}/>`,
    tooth: `<path d="M13.5 9 C17.5 5 21.5 8 24 9.5 C26.5 8 30.5 5 34.5 9 C40 14.5 36.5 24 34.5 30 C33 36 32.5 43 29 43 C25.5 43 26.5 32 24 32 C21.5 32 22.5 43 19 43 C15.5 43 15 36 13.5 30 C11.5 24 8 14.5 13.5 9 Z" fill="#fff" ${S}/>` +
      `<path d="M15 14 C16 11.5 18 11 20 12" ${L(2.6)} stroke-opacity=".3"/><path d="${star(39, 8, 1.6, 4.6, 4)}" fill="${C.yellow}" stroke="${O}" stroke-width="2" stroke-linejoin="round"/>`,
    books: `<rect x="6" y="33" width="36" height="9" rx="2.5" fill="${C.teal}" ${S}/><rect x="9" y="24" width="31" height="9" rx="2.5" fill="${C.berry}" ${S}/>` +
      `<rect x="7" y="15" width="33" height="9" rx="2.5" fill="${C.gold}" ${S}/>` +
      `<path d="M36 33 V42 M13 24 V33 M35 15 V24" stroke="${C.cream}" stroke-width="2.6"/>` +
      `<path d="M16 6 L26 4 L28 15 L18 15 Z" fill="${C.leaf}" ${S}/>`,
    bed: `<path d="M7 33 V43 M41 33 V43" ${L(4)}/><rect x="4" y="10" width="7" height="26" rx="3" fill="${C.wood}" ${S}/>` +
      `<rect x="9" y="28" width="35" height="9" rx="3" fill="${C.cream}" ${S}/>` +
      `<ellipse cx="17.5" cy="24" rx="6.5" ry="4.5" fill="#fff" ${S}/>` +
      `<path d="M22 21 C30 19 38 20 44 23 V33 H22 Z" fill="${C.teal}" ${S}/><path d="M27 25 C32 24 37 24 41 26" fill="none" stroke="${C.cream}" stroke-width="2.6" stroke-linecap="round"/>`,
    car: `<path d="M14 21 L18 12 H31 L36 21" fill="${C.sky}" ${S}/><path d="M24.5 12 V21" ${L(3)}/>` +
      `<path d="M5 30 C5 24 8 21 13 21 H37 C42 21 44 25 44 30 V34 H5 Z" fill="${C.berry}" ${S}/>` +
      `<circle cx="14" cy="35" r="5.5" fill="${C.grey}" ${S}/><circle cx="35" cy="35" r="5.5" fill="${C.grey}" ${S}/>` +
      `<circle cx="14" cy="35" r="1.8" fill="${C.cream}"/><circle cx="35" cy="35" r="1.8" fill="${C.cream}"/>` +
      `<rect x="39" y="24.5" width="4" height="3" rx="1" fill="${C.yellow}"/>`,
    puzzle: `<path d="M8 14 H18 C16 6 30 6 28 14 H38 V23 C45 21 45 35 38 33 V42 H28 C30 35 16 35 18 42 H8 Z" fill="${C.leaf}" ${S}/>` +
      `<path d="M12 19 C12 17 13 17.5 15 17.5" ${SHINE}/>`,
    paint: `<path d="M24 6 C36 6 44 13 44 22 C44 29 38 30 34 29 C30 28 28 31 30 35 C32 39 29 43 23 42 C12 41 4 34 4 24 C4 13 12 6 24 6 Z" fill="${C.cream}" ${S}/>` +
      `<circle cx="14" cy="22" r="3.4" fill="${C.berry}" stroke="${O}" stroke-width="2.2"/><circle cx="19" cy="13.5" r="3.4" fill="${C.yellow}" stroke="${O}" stroke-width="2.2"/>` +
      `<circle cx="29" cy="12.5" r="3.4" fill="${C.teal}" stroke="${O}" stroke-width="2.2"/><circle cx="37" cy="19" r="3.4" fill="${C.leaf}" stroke="${O}" stroke-width="2.2"/>` +
      `<circle cx="16.5" cy="32" r="3.6" fill="#e9e4dc" stroke="${O}" stroke-width="2.6"/>`,
    apple: `<path d="M24 14 C24 10 25 7 27 5" ${L()}/><path d="M26 11 C29 5 36 5 38 8 C34 12 29 12 26 11 Z" fill="${C.leaf}" ${S}/>` +
      `<path d="M24 15 C19 11 8 12 8 24 C8 34 15 43 21 43 C23 43 23 42 24 42 C25 42 25 43 27 43 C33 43 40 34 40 24 C40 12 29 11 24 15 Z" fill="${C.berry}" ${S}/>` +
      `<path d="M13 22 C13 19 15 17 17.5 16.5" ${SHINE}/>`,
    coat: `<path d="M17 6 L24 11 L31 6 L39 10 L45 29 L39.5 31 L36 23 V43 H12 V23 L8.5 31 L3 29 L9 10 Z" fill="${C.teal}" ${S}/>` +
      `<path d="M24 11 V43" ${L(3)}/><path d="M17 6 L24 11 L20 17 L15 9 M31 6 L24 11 L28 17 L33 9" fill="${C.tealDk}" ${S}/>` +
      `<circle cx="20.5" cy="25" r="1.8" fill="${C.cream}" stroke="${O}" stroke-width="1.8"/><circle cx="20.5" cy="33" r="1.8" fill="${C.cream}" stroke="${O}" stroke-width="1.8"/>` +
      `<path d="M28 30 H33" ${L(3)}/>`,
    crayon: `<g transform="rotate(-45 24 24)"><path d="M4 18 H34 L44 24 L34 30 H4 C2.5 30 2 29 2 28 V20 C2 19 2.5 18 4 18 Z" fill="${C.berry}" ${S}/>` +
      `<path d="M10 18 V30 M26 18 V30" fill="none" stroke="${C.cream}" stroke-width="3"/><path d="M40 21.5 L44 24 L40 26.5 Z" fill="${O}"/>` +
      `<path d="M4 18 H34 L44 24 L34 30 H4 C2.5 30 2 29 2 28 V20 C2 19 2.5 18 4 18 Z M34 18 V30" fill="none" ${S}/></g>`,
    toilet: `<rect x="9" y="4" width="18" height="16" rx="3" fill="#fff" ${S}/><path d="M17 43 L19 33 H29 L31 43 Z" fill="#fff" ${S}/>` +
      `<path d="M6 21 H42 C42 30 35 35 24 35 C13 35 6 30 6 21 Z" fill="#fff" ${S}/><ellipse cx="24" cy="21" rx="18" ry="3.6" fill="${C.sky}" ${S}/>` +
      `<path d="M13 9 H17" ${L(3)}/>`,
    shoe: `<path d="M2 23 H8 M1 30 H6" fill="none" stroke="${O}" stroke-width="3.2" stroke-linecap="round"/>` +
      `<path d="M10 37 C10 27 12 17 18 15 C21 18 25 18 27 16 L32 26 C38 27 45 29 45 34 V37 Z" fill="${C.teal}" ${S}/>` +
      `<path d="M9 37 H46 V40 C46 42 45 43 43 43 H12 C10 43 9 42 9 40 Z" fill="${C.cream}" ${S}/>` +
      `<path d="M22 21 L26 19.5 M24 25 L28.5 23" fill="none" stroke="${C.cream}" stroke-width="2.6" stroke-linecap="round"/>`,
    star: `<path d="${star(24, 25.5, 9.5, 20, 5)}" fill="${C.yellow}" ${S}/><path d="M16 22 L19.5 20" ${SHINE}/>`,
  };
  /** emoji that older builds saved in settings → the icon that replaces it */
  const FROM_EMOJI = {
    '🧸': 'teddy', '🛁': 'bath', '🥣': 'bowl', '🧦': 'sock', '🦷': 'tooth', '📚': 'books', '🛏️': 'bed', '🛏': 'bed',
    '🚗': 'car', '🧩': 'puzzle', '🎨': 'paint', '🍎': 'apple', '🧥': 'coat', '🖍️': 'crayon', '🖍': 'crayon',
    '🚽': 'toilet', '🏃': 'shoe', '⭐': 'star',
  };

  function icon(name, cls) {
    const body = ICONS[name] || ICONS.star;
    return `<svg class="gc-ico${cls ? ' ' + cls : ''}" viewBox="0 0 48 48" aria-hidden="true" focusable="false">${body}</svg>`;
  }
  function el(name, cls) {
    const t = document.createElement('span');
    t.innerHTML = icon(name, cls);
    return t.firstChild;
  }
  function hydrate(root) {
    (root || document).querySelectorAll('[data-icon]').forEach((n) => { n.innerHTML = icon(n.dataset.icon); });
  }

  GC.icon = icon;
  GC.Icons = {
    el, hydrate,
    has: (n) => Object.prototype.hasOwnProperty.call(ICONS, n),
    fromEmoji: (e) => FROM_EMOJI[e] || null,
    names: () => Object.keys(ICONS),
  };
  if (document.readyState !== 'loading') hydrate(); else document.addEventListener('DOMContentLoaded', () => hydrate());
})();

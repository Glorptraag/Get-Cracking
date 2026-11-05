/* Get Cracking — the egg.
 *
 * The egg is the progress bar. It cracks in 8 stepped "landmarks" so a
 * child who can't read numbers can still see time passing:
 *
 *   step 1  hairline crack near the top
 *   step 2-5 the main zig-zag crack runs across the shell
 *   step 6  a little hole opens — someone is peeking out!
 *   step 7  warm light leaks through the cracks
 *   step 8  extra cracks, the egg starts hopping
 *
 * Coordinates: base of the egg at (0,0), egg grows up to y = -170.
 */
(function () {
  'use strict';
  const GC = window.GC;
  const O = GC.OUT;
  const S = `stroke="${O}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"`;

  const EGG_PATH = 'M0,-170 C40,-170 64,-96 64,-58 C64,-20 36,0 0,0 C-36,0 -64,-20 -64,-58 C-64,-96 -40,-170 0,-170 Z';
  const ZIG = [[-68, -74], [-50, -88], [-36, -72], [-20, -92], [-4, -74], [12, -94], [28, -74], [44, -90], [68, -76]];
  const zigStr = ZIG.map((p) => p.join(',')).join(' ');
  const TOP_POLY = `${zigStr} 80,-220 -80,-220`;
  const BOTTOM_POLY = `${zigStr} 80,20 -80,20`;

  const BRANCHES = [
    { step: 1, pts: [[-30, -140], [-22, -128], [-27, -117], [-17, -108]] },
    { step: 3, pts: [[14, -150], [20, -138], [12, -128], [18, -118]] },
    { step: 5, pts: [[34, -62], [40, -50], [31, -40]] },
    { step: 8, pts: [[-44, -66], [-50, -52], [-42, -42], [-47, -30]] },
    { step: 8, pts: [[-6, -152], [-12, -160]] },
  ];
  /** fraction of the timer at which each crack step happens */
  const STEP_AT = [0.1, 0.22, 0.34, 0.46, 0.58, 0.7, 0.8, 0.9];
  const MAIN_LEN_BY_STEP = [0, 0, 0.22, 0.46, 0.72, 1, 1, 1, 1];

  const PALETTES = [
    { shell: '#fbf1dc', spot: '#a9cf8b' },
    { shell: '#dff1e4', spot: '#7cbf9e' },
    { shell: '#dcecf6', spot: '#86b6dc' },
    { shell: '#fde3d3', spot: '#f19c82' },
    { shell: '#ece2f6', spot: '#b49ad9' },
    { shell: '#fff1c2', spot: '#f3b54a' },
  ];

  function patternMarkup(kind, spot) {
    switch (kind) {
      case 'band':
        return `<path d="M-70,-112 L-52,-124 L-36,-110 L-20,-124 L-4,-110 L12,-124 L28,-110 L44,-124 L60,-110 L72,-118 L72,-100 L-70,-96 Z" fill="${spot}"/>` +
          `<circle cx="-30" cy="-40" r="7" fill="${spot}"/><circle cx="20" cy="-30" r="9" fill="${spot}"/><circle cx="-6" cy="-150" r="6" fill="${spot}"/>`;
      case 'stripes':
        return [-140, -104, -46].map((y, i) => `<path d="M-70,${y} Q0,${y + 14} 70,${y}" fill="none" stroke="${spot}" stroke-width="${i === 1 ? 12 : 9}"/>`).join('') +
          `<circle cx="-24" cy="-122" r="5" fill="${spot}"/><circle cx="26" cy="-70" r="6" fill="${spot}"/>`;
      default: // spots
        return [[-30, -132, 10], [24, -146, 7], [32, -108, 12], [-40, -86, 8], [-8, -104, 6], [10, -60, 11], [-30, -36, 9], [40, -40, 7], [-48, -58, 5]]
          .map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${spot}"/>`).join('');
    }
  }

  function eggBody(clipId, pal, pattern) {
    return `<path d="${EGG_PATH}" fill="${pal.shell}"/>` +
      `<g clip-path="url(#${clipId})">${patternMarkup(pattern, pal.spot)}` +
      `<path d="M-40,-60 C-44,-110 -26,-150 -6,-160" fill="none" stroke="#fff" stroke-opacity=".7" stroke-width="9" stroke-linecap="round"/>` +
      `<path d="${EGG_PATH}" fill="none" stroke="${O}" stroke-opacity=".12" stroke-width="16" transform="translate(7 4)"/></g>` +
      `<path d="${EGG_PATH}" fill="none" ${S}/>`;
  }

  class Egg {
    /**
     * @param {SVGGElement} parent  group to draw into (scene coordinates)
     * @param {{x:number,y:number,scale?:number,palette?:object,pattern?:string}} opt
     */
    constructor(parent, opt = {}) {
      this.opt = opt;
      this.step = 0;
      this.pal = opt.palette || GC.pick(PALETTES);
      this.pattern = opt.pattern || GC.pick(['spots', 'band', 'stripes']);
      const id = (this.id = GC.uid('egg'));
      const sc = opt.scale || 1;
      const root = (this.root = GC.el('g', { class: 'egg-root', transform: `translate(${opt.x || 0} ${opt.y || 0}) scale(${sc})` }, parent));

      const branchMarkup = BRANCHES.map((b, i) =>
        `<polyline class="crack-branch" data-step="${b.step}" points="${b.pts.map((p) => p.join(',')).join(' ')}" pathLength="1"/>`).join('');

      root.innerHTML =
        `<defs>` +
        `<clipPath id="${id}c"><path d="${EGG_PATH}"/></clipPath>` +
        `<clipPath id="${id}t"><polygon points="${TOP_POLY}"/></clipPath>` +
        `<clipPath id="${id}b"><polygon points="${BOTTOM_POLY}"/></clipPath>` +
        `<filter id="${id}glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>` +
        `</defs>` +
        `<g class="egg-rays">${this._rays()}</g>` +
        `<ellipse class="egg-shadow" cx="0" cy="2" rx="70" ry="13" fill="${O}" opacity=".2"/>` +
        `<circle class="egg-halo" cx="0" cy="-86" r="104" fill="#fff3b0" filter="url(#${id}glow)"/>` +
        `<g class="egg-wobble"><g class="egg-squash">` +
        `<g class="egg-bottom" clip-path="url(#${id}b)">${eggBody(id + 'c', this.pal, this.pattern)}</g>` +
        `<g transform="translate(0 -118)"><g class="egg-top-fly"><g transform="translate(0 118)">` +
        `<g class="egg-top" clip-path="url(#${id}t)">${eggBody(id + 'c', this.pal, this.pattern)}` +
        `<g class="egg-hole"><path d="M14,-128 L22,-138 L34,-134 L40,-122 L34,-110 L22,-108 L14,-116 Z" fill="#2a1a1c" ${S}/>` +
        `<g class="egg-peek-eyes"><ellipse cx="22" cy="-122" rx="2.6" ry="3.4" fill="#fff"/><ellipse cx="32" cy="-122" rx="2.6" ry="3.4" fill="#fff"/></g></g>` +
        `</g>` +
        `<polyline class="egg-edge" points="${zigStr}" fill="none" ${S}/>` +
        `</g></g></g>` +
        `<polyline class="egg-edge" points="${zigStr}" fill="none" ${S}/>` +
        `<g class="egg-cracks" clip-path="url(#${id}c)">` +
        `<g class="crack-glow" filter="url(#${id}glow)"><polyline points="${zigStr}" pathLength="1" class="crack-main-glow"/>${branchMarkup}</g>` +
        `<polyline points="${zigStr}" pathLength="1" class="crack-main"/>${branchMarkup}` +
        `</g>` +
        `</g></g>` +
        `<g class="egg-friend-clip" clip-path="url(#${id}t)"><g class="egg-friend-pos"></g></g>` +
        `<g class="egg-friend-free"></g>` +
        `<g class="egg-fx"></g>`;

      this.q = (sel) => root.querySelector(sel);
      this.wobbleEl = this.q('.egg-wobble');
      this.squashEl = this.q('.egg-squash');
      this.main = this.q('.crack-main');
      this.mainGlow = this.q('.crack-main-glow');
      this.fx = this.q('.egg-fx');
      this.setStep(0, true);
      this.root.addEventListener('pointerdown', () => this.boop());
    }

    _rays() {
      let s = '';
      for (let i = 0; i < 12; i++) {
        const a = (i / 12) * Math.PI * 2, b = a + Math.PI / 12;
        s += `<path d="M0,0 L${Math.cos(a) * 230},${Math.sin(a) * 230} L${Math.cos(b) * 230},${Math.sin(b) * 230} Z"/>`;
      }
      return `<g transform="translate(0 -80)"><g class="egg-rays-spin" fill="#fff6c9">${s}</g></g>`;
    }

    static stepFor(fraction) {
      let n = 0;
      for (let i = 0; i < STEP_AT.length; i++) if (fraction >= STEP_AT[i]) n = i + 1;
      return n;
    }
    static get STEP_AT() { return STEP_AT; }

    /** Advance to a crack step. Cracks never heal, even if time is added. */
    setStep(n, silent) {
      if (n < this.step && !silent) return false;
      const changed = n !== this.step;
      this.step = n;
      const len = MAIN_LEN_BY_STEP[n];
      for (const el of [this.main, this.mainGlow]) {
        el.style.strokeDasharray = `${len} 2`;
      }
      this.root.querySelectorAll('.crack-branch').forEach((b) => {
        b.classList.toggle('on', n >= +b.dataset.step);
      });
      this.root.classList.toggle('peek', n >= 6);
      this.root.classList.toggle('glowing', n >= 7);
      this.wobbleEl.dataset.level = n >= 8 ? 3 : n >= 5 ? 2 : n >= 1 ? 1 : 0;
      if (changed && !silent) {
        this.shake();
        this.chips(4);
      }
      return changed;
    }

    shake() {
      this.squashEl.animate([
        { transform: 'rotate(0deg)' }, { transform: 'rotate(-6deg)' }, { transform: 'rotate(5deg)' },
        { transform: 'rotate(-3deg)' }, { transform: 'rotate(0deg)' },
      ], { duration: 420, easing: 'ease-out' });
    }

    boop() {
      if (this.hatched || this.root.classList.contains('ready')) return;
      this.squashEl.animate([
        { transform: 'scale(1,1)' }, { transform: 'scale(1.08,.9)' }, { transform: 'scale(.96,1.05)' }, { transform: 'scale(1,1)' },
      ], { duration: 380, easing: 'ease-out' });
      if (this.onBoop) this.onBoop();
    }

    setReady(on) { this.root.classList.toggle('ready', !!on); }
    setPaused(on) { this.root.classList.toggle('paused', !!on); }

    /** little shell chips that pop off the egg */
    chips(n, big) {
      if (GC.prefersReducedMotion() && !big) return;
      for (let i = 0; i < n; i++) {
        const x = GC.rand(-40, 40), y = GC.rand(-130, -70);
        const g = GC.el('g', { transform: `translate(${x} ${y})` }, this.fx);
        const s = big ? GC.rand(10, 18) : GC.rand(5, 9);
        const p = GC.el('path', {
          d: `M0,${-s} L${s},${s * 0.6} L${-s * 0.8},${s * 0.4} Z`, fill: this.pal.shell,
          stroke: O, 'stroke-width': big ? 4 : 3, 'stroke-linejoin': 'round',
        }, g);
        const dx = GC.rand(-1, 1) * (big ? 240 : 90), dy = big ? GC.rand(-260, -120) : GC.rand(-90, -40);
        p.animate([
          { transform: 'translate(0,0) rotate(0deg)', opacity: 1 },
          { transform: `translate(${dx * 0.6}px,${dy}px) rotate(${GC.rand(-300, 300)}deg)`, opacity: 1, offset: 0.5 },
          { transform: `translate(${dx}px,${dy * 0.2 + 160}px) rotate(${GC.rand(-500, 500)}deg)`, opacity: 0 },
        ], { duration: big ? 1300 : 800, easing: 'cubic-bezier(.2,.7,.4,1)' }).finished.then(() => g.remove());
      }
    }

    confetti(n = 26) {
      const cols = ['#f7a8c8', '#ffd86b', '#9fd8e8', '#a9d36b', '#f39a6b', '#c5a8f0'];
      for (let i = 0; i < n; i++) {
        const g = GC.el('g', { transform: `translate(0 -90)` }, this.fx);
        const kind = i % 3;
        const c = GC.pick(cols);
        if (kind === 0) GC.el('path', { d: 'M0,-9 L2.6,-2.6 L9,0 L2.6,2.6 L0,9 L-2.6,2.6 L-9,0 L-2.6,-2.6 Z', fill: c, stroke: O, 'stroke-width': 2.5, 'stroke-linejoin': 'round' }, g);
        else if (kind === 1) GC.el('circle', { r: 6, fill: c, stroke: O, 'stroke-width': 2.5 }, g);
        else GC.el('path', { d: 'M0,-10 C6,-6 6,6 0,10 C-6,6 -6,-6 0,-10 Z', fill: c, stroke: O, 'stroke-width': 2.5 }, g);
        const ang = GC.rand(-Math.PI * 0.95, -Math.PI * 0.05);
        const dist = GC.rand(140, 300);
        const dx = Math.cos(ang) * dist, dy = Math.sin(ang) * dist;
        g.firstChild.animate([
          { transform: 'translate(0,0) scale(.2) rotate(0deg)', opacity: 1 },
          { transform: `translate(${dx}px,${dy}px) scale(1) rotate(${GC.rand(-200, 200)}deg)`, opacity: 1, offset: 0.45 },
          { transform: `translate(${dx * 1.2}px,${dy + 260}px) scale(.9) rotate(${GC.rand(-400, 400)}deg)`, opacity: 0 },
        ], { duration: GC.rand(1600, 2400), easing: 'cubic-bezier(.15,.8,.35,1)' }).finished.then(() => g.remove());
      }
    }

    /**
     * The big moment. Squash → stretch → lid pops off → friend peeks up out
     * of the shell → hops out in front and starts its happy loop.
     * @param {string} friendMarkup  SVG markup from GC.Animals.render / renderPhoto
     * @param {{onPop?:Function}} hooks
     */
    async hatch(friendMarkup, hooks = {}) {
      if (this.hatched) return;
      this.hatched = true;
      const reduce = GC.prefersReducedMotion();
      this.root.classList.remove('ready', 'paused');
      this.wobbleEl.dataset.level = 0;
      const clipPos = this.q('.egg-friend-pos');
      const free = this.q('.egg-friend-free');
      clipPos.innerHTML = `<g class="friend-anim">${friendMarkup}</g>`;
      const friend = clipPos.firstChild;
      friend.style.opacity = '0';

      // 1. squash + stretch (anticipation)
      await this.squashEl.animate([
        { transform: 'scale(1,1)' }, { transform: 'scale(1.14,.84)', offset: 0.6 }, { transform: 'scale(.9,1.12)' },
      ], { duration: reduce ? 200 : 520, easing: 'cubic-bezier(.5,0,.5,1)', fill: 'forwards' }).finished;

      // 2. lid flies off
      this.root.classList.add('hatched');
      const dir = Math.random() < 0.5 ? -1 : 1;
      this.q('.egg-top-fly').animate([
        { transform: 'translate(0,0) rotate(0deg)', opacity: 1 },
        { transform: `translate(${dir * 120}px,-230px) rotate(${dir * 160}deg)`, opacity: 1, offset: 0.55 },
        { transform: `translate(${dir * 210}px,40px) rotate(${dir * 320}deg)`, opacity: 0 },
      ], { duration: reduce ? 400 : 1200, easing: 'cubic-bezier(.2,.6,.4,1)', fill: 'forwards' });
      this.squashEl.animate([{ transform: 'scale(.9,1.12)' }, { transform: 'scale(1.05,.96)' }, { transform: 'scale(1,1)' }],
        { duration: 360, easing: 'ease-out', fill: 'forwards' });
      this.chips(10, true);
      if (!reduce) this.confetti();
      if (hooks.onPop) hooks.onPop();

      // 3. friend pops up, peeking from inside the bottom shell
      friend.style.opacity = '1';
      await friend.animate([
        { transform: 'translate(0px,90px) scale(.55,.55)' },
        { transform: 'translate(0px,-62px) scale(.78,.98)', offset: 0.5 },
        { transform: 'translate(0px,-40px) scale(.86,.74)', offset: 0.75 },
        { transform: 'translate(0px,-46px) scale(.8,.8)' },
      ], { duration: reduce ? 300 : 720, easing: 'cubic-bezier(.3,.7,.4,1)', fill: 'forwards' }).finished;
      await wait(reduce ? 100 : 380);

      // 4. hop out in front of the shell
      const up = friend.animate([
        { transform: 'translate(0px,-46px) scale(.8,.8)' },
        { transform: 'translate(0px,-52px) scale(.9,.66)', offset: 0.3 },
        { transform: 'translate(0px,-150px) scale(.86,.98)' },
      ], { duration: reduce ? 150 : 380, easing: 'cubic-bezier(.3,.8,.5,1)', fill: 'forwards' });
      await up.finished;
      // reparent above the shell, unclipped
      free.appendChild(friend);
      up.cancel();
      await friend.animate([
        { transform: 'translate(0px,-150px) scale(.86,.98)' },
        { transform: 'translate(0px,56px) scale(1.02,1.02)', offset: 0.7 },
        { transform: 'translate(0px,56px) scale(1.18,.82)', offset: 0.82 },
        { transform: 'translate(0px,56px) scale(.96,1.06)', offset: 0.92 },
        { transform: 'translate(0px,56px) scale(1,1)' },
      ], { duration: reduce ? 250 : 700, easing: 'cubic-bezier(.45,0,.6,1)', fill: 'forwards' }).finished;
      friend.style.transform = 'translate(0px,56px)';
      friend.getAnimations().forEach((a) => a.cancel());
      friend.classList.add('idle');
      this.friend = friend;
      friend.addEventListener('pointerdown', (e) => { e.stopPropagation(); this.cheer(); });
    }

    /** tap the hatched friend: a happy jump, repeatable */
    cheer() {
      if (!this.friend || this._cheering) return;
      this._cheering = true;
      const inner = this.friend.querySelector('.critter');
      inner.animate([
        { transform: 'translate(0,0) scale(1,1)' }, { transform: 'translate(0,0) scale(1.15,.85)', offset: 0.15 },
        { transform: 'translate(0,-70px) scale(.9,1.12)', offset: 0.5 }, { transform: 'translate(0,0) scale(1.12,.88)', offset: 0.82 },
        { transform: 'translate(0,0) scale(1,1)' },
      ], { duration: 700, easing: 'ease-in-out' }).finished.then(() => { this._cheering = false; });
      this.confetti(8);
      if (this.onCheer) this.onCheer();
    }
  }

  function wait(ms) { return new Promise((r) => setTimeout(r, ms)); }

  GC.Egg = Egg;
  GC.EGG_PALETTES = PALETTES;
})();

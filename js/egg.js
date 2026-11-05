/* Get Cracking — the egg.
 *
 * The egg is the progress bar. It cracks in 8 stepped "landmarks" so a
 * child who can't read numbers can still see time passing:
 *
 *   step 1  hairline crack near the top
 *   step 2-5 the main zig-zag crack runs across the shell
 *   step 6-8 more cracks branch off, and every crack gets wider and
 *            deeper at each step; by step 8 the egg is hopping
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

  const BRANCHES = [
    { step: 1, pts: [[-30, -140], [-22, -128], [-27, -117], [-17, -108]] },
    { step: 3, pts: [[14, -150], [20, -138], [12, -128], [18, -118]] },
    { step: 5, pts: [[34, -62], [40, -50], [31, -40]] },
    { step: 6, pts: [[12, -94], [22, -106], [16, -116], [28, -128], [38, -122]] },
    { step: 6, pts: [[-36, -72], [-30, -58], [-38, -48]] },
    { step: 7, pts: [[-4, -74], [-12, -60], [-3, -50], [-10, -36]] },
    { step: 7, pts: [[-20, -92], [-26, -104], [-17, -108]] },
    { step: 8, pts: [[-44, -66], [-50, -52], [-42, -42], [-47, -30]] },
    { step: 8, pts: [[44, -90], [50, -104], [42, -114], [46, -126]] },
    { step: 8, pts: [[-6, -152], [-12, -160]] },
  ];
  /** fraction of the timer at which each crack step happens */
  const STEP_AT = [0.1, 0.22, 0.34, 0.46, 0.58, 0.7, 0.8, 0.9];
  const MAIN_LEN_BY_STEP = [0, 0, 0.22, 0.46, 0.72, 1, 1, 1, 1];
  /** crack line width at each step: the cracks deepen as time passes */
  const CRACK_W_BY_STEP = [3, 3, 3.6, 4.2, 4.8, 5.4, 6.2, 7, 8];
  const crackW = (n) => CRACK_W_BY_STEP[n];
  const branchW = (n) => +(CRACK_W_BY_STEP[n] * 0.78).toFixed(2);

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
        `<filter id="${id}glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>` +
        `</defs>` +
        `<g class="egg-rays">${this._rays()}</g>` +
        `<ellipse class="egg-shadow" cx="0" cy="2" rx="70" ry="13" fill="${O}" opacity=".2"/>` +
        `<circle class="egg-halo" cx="0" cy="-86" r="104" fill="#fff3b0" filter="url(#${id}glow)"/>` +
        `<g class="egg-wobble"><g class="egg-squash">` +
        `${eggBody(id + 'c', this.pal, this.pattern)}` +
        `<g class="egg-cracks" clip-path="url(#${id}c)">` +
        `<polyline points="${zigStr}" pathLength="1" class="crack-main"/>${branchMarkup}` +
        `</g>` +
        `</g></g>` +
        `<g class="shell-back"></g>` +
        `<g class="egg-friend"></g>` +
        `<g class="shell-front"></g>` +
        `<g class="egg-fx"></g>`;

      this.q = (sel) => root.querySelector(sel);
      this.wobbleEl = this.q('.egg-wobble');
      this.squashEl = this.q('.egg-squash');
      this.main = this.q('.crack-main');
      this.cracksEl = this.q('.egg-cracks');
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
      this.main.style.strokeDasharray = `${len} 2`;
      this.cracksEl.style.setProperty('--crack-w', crackW(n));
      this.cracksEl.style.setProperty('--branch-w', branchW(n));
      this.root.querySelectorAll('.crack-branch').forEach((b) => {
        b.classList.toggle('on', n >= +b.dataset.step);
      });
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

    /** a few little shell chips that pop off when the egg cracks a step */
    chips(n) {
      if (GC.prefersReducedMotion()) return;
      for (let i = 0; i < n; i++) {
        const g = GC.el('g', { transform: `translate(${GC.rand(-40, 40)} ${GC.rand(-130, -70)})` }, this.fx);
        const s = GC.rand(5, 9);
        const p = GC.el('path', {
          d: `M0,${-s} L${s},${s * 0.6} L${-s * 0.8},${s * 0.4} Z`, fill: this.pal.shell,
          stroke: O, 'stroke-width': 3, 'stroke-linejoin': 'round',
        }, g);
        const dx = GC.rand(-90, 90), dy = GC.rand(-90, -40);
        p.animate([
          { transform: 'translate(0,0) rotate(0deg)', opacity: 1 },
          { transform: `translate(${dx * 0.6}px,${dy}px) rotate(${GC.rand(-300, 300)}deg)`, opacity: 1, offset: 0.5 },
          { transform: `translate(${dx}px,${dy * 0.2 + 160}px) rotate(${GC.rand(-500, 500)}deg)`, opacity: 0 },
        ], { duration: 800, easing: 'cubic-bezier(.2,.7,.4,1)' }).finished.then(() => g.remove());
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

    /** The cracks exactly as they look right now, as static markup for shell pieces. */
    _crackMarkup() {
      if (this._cracks != null) return this._cracks;
      const n = this.step, len = MAIN_LEN_BY_STEP[n];
      const st = `fill="none" stroke="${O}" stroke-linecap="round" stroke-linejoin="round"`;
      let m = `<g clip-path="url(#${this.id}c)">`;
      if (len > 0) m += `<polyline points="${zigStr}" pathLength="1" stroke-dasharray="${len} 2" stroke-width="${crackW(n)}" ${st}/>`;
      for (const b of BRANCHES) if (n >= b.step) m += `<polyline points="${b.pts.map((p) => p.join(',')).join(' ')}" stroke-width="${branchW(n)}" ${st}/>`;
      m += `</g>`;
      return (this._cracks = m);
    }

    /** Build the context object handed to a shell effect (see js/shellfx.js). */
    _shellCtx(release) {
      const self = this;
      const ts = () => GC.timeScale || 1;
      const ctx = {
        front: this.q('.shell-front'),
        back: this.q('.shell-back'),
        pal: this.pal,
        pattern: this.pattern,
        EGG_PATH, ZIG,
        ground: 48,
        bounds: { left: -330, right: 330, top: -480, bottom: 230 },
        reduce: GC.prefersReducedMotion(),
        release,
        rand: GC.rand,
        sfx: GC.Sound ? {
          crack: () => GC.Sound.crack(), clink: (p) => GC.Sound.clink(p), thud: (p) => GC.Sound.thud(p), whoosh: () => GC.Sound.whoosh(),
        } : { crack() {}, clink() {}, thud() {}, whoosh() {} },
        wait: (ms) => new Promise((r) => setTimeout(r, ms * ts())),
        animate(el, keyframes, opts = {}) {
          const o = Object.assign({}, opts);
          if (o.duration) o.duration *= ts();
          if (o.delay) o.delay *= ts();
          if (o.endDelay) o.endDelay *= ts();
          return el.animate(keyframes, o).finished.catch(() => {});
        },
        /**
         * A shell fragment: the egg's painted shell clipped to `points`
         * (egg-local polygon, may extend past the egg silhouette). Returns
         * { el, cx, cy } — `el` is a <g> whose local origin is the piece's
         * centroid, so translate/rotate animations spin it about its middle.
         */
        piece(points, opts = {}) {
          const layer = opts.layer || ctx.front;
          let cx = 0, cy = 0;
          for (const [x, y] of points) { cx += x; cy += y; }
          cx /= points.length; cy /= points.length;
          if (opts.cx != null) cx = opts.cx;
          if (opts.cy != null) cy = opts.cy;
          const pid = GC.uid('pc');
          const pts = points.map((p) => p.join(',')).join(' ');
          const wrap = GC.el('g', { transform: `translate(${cx.toFixed(1)} ${cy.toFixed(1)})`, class: 'shell-piece' }, layer);
          const el = GC.el('g', {}, wrap);
          el.innerHTML = `<g transform="translate(${(-cx).toFixed(1)} ${(-cy).toFixed(1)})">` +
            `<clipPath id="${pid}"><polygon points="${pts}"/></clipPath>` +
            `<g clip-path="url(#${pid})">${eggBody(self.id + 'c', self.pal, self.pattern)}${self._crackMarkup()}` +
            `<g clip-path="url(#${self.id}c)"><polygon points="${pts}" fill="none" stroke="${O}" stroke-width="${opts.edge || 4.5}" stroke-linejoin="round"/></g></g></g>`;
          return { el, wrap, cx, cy };
        },
        /** a soft ground shadow at egg-local (x, y) */
        shadow(x, y, rx = 20, layer) {
          return GC.el('ellipse', { cx: x, cy: y, rx, ry: rx * 0.28, fill: O, opacity: 0.18 }, layer || ctx.back);
        },
        /** a cartoon dust puff */
        puff(x, y, r = 18, layer) {
          const g = GC.el('g', { transform: `translate(${x} ${y})` }, layer || ctx.front);
          const c = GC.el('circle', { r, fill: '#fdf3e4', stroke: O, 'stroke-width': 3.5, opacity: 0.9 }, g);
          ctx.animate(c, [{ transform: 'scale(.2)', opacity: 0.9 }, { transform: 'scale(1.3)', opacity: 0 }], { duration: 600, easing: 'ease-out' }).then(() => g.remove());
          return g;
        },
      };
      return ctx;
    }

    /**
     * The big moment.
     *   1. anticipation: squash → stretch (shared by every style)
     *   2. the intact egg is swapped for loose shell pieces and the chosen
     *      shell effect (roll / boom / crumble …) takes over
     *   3. when the effect calls ctx.release() the friend springs up and
     *      lands in front with a squash-and-settle bounce, then idles
     * @param {string} friendMarkup  SVG markup from GC.Animals.render / renderPhoto
     * @param {{onPop?:Function, style?:string}} hooks
     */
    async hatch(friendMarkup, hooks = {}) {
      if (this.hatched) return;
      this.hatched = true;
      const reduce = GC.prefersReducedMotion();
      const ts = () => GC.timeScale || 1;
      const anim = (el, k, o) => el.animate(k, Object.assign({}, o, { duration: o.duration * ts() })).finished.catch(() => {});
      this.root.classList.remove('ready', 'paused');
      this.wobbleEl.dataset.level = 0;
      const holder = this.q('.egg-friend');
      holder.innerHTML = `<g class="friend-anim" style="opacity:0">${friendMarkup}</g>`;
      const friend = holder.firstChild;

      // 1. anticipation
      await anim(this.squashEl, [
        { transform: 'scale(1,1)' }, { transform: 'scale(1.14,.84)', offset: 0.6 }, { transform: 'scale(.9,1.12)' },
      ], { duration: reduce ? 200 : 520, easing: 'cubic-bezier(.5,0,.5,1)', fill: 'forwards' });

      // 2. hand over to the shell effect
      const fx = GC.ShellFX.pick(hooks.style || this.opt.style);
      this.root.classList.add('hatched');
      this.wobbleEl.style.visibility = 'hidden';
      let release;
      const released = new Promise((r) => (release = r));
      let done = false;
      const ctx = this._shellCtx(() => { if (!done) { done = true; release(); } });
      Promise.resolve().then(() => fx.run(ctx)).catch((e) => { console.error('shell fx failed', e); }).then(() => ctx.release());
      await Promise.race([released, new Promise((r) => setTimeout(r, 3500 * ts()))]);
      this.style = fx.id;

      // 3. friend springs out
      if (!reduce) this.confetti();
      if (hooks.onPop) hooks.onPop();
      friend.style.opacity = '1';
      await anim(friend, [
        { transform: 'translate(0px,-30px) scale(.25,.25)' },
        { transform: 'translate(0px,-170px) scale(.86,1.12)', offset: 0.45 },
        { transform: 'translate(0px,-190px) scale(1,1)', offset: 0.55 },
        { transform: 'translate(0px,48px) scale(1,1.04)', offset: 0.82 },
        { transform: 'translate(0px,48px) scale(1.2,.8)', offset: 0.9 },
        { transform: 'translate(0px,48px) scale(.96,1.06)', offset: 0.96 },
        { transform: 'translate(0px,48px) scale(1,1)' },
      ], { duration: reduce ? 300 : 1150, easing: 'cubic-bezier(.4,0,.6,1)', fill: 'forwards' });
      friend.style.transform = 'translate(0px,48px)';
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

  GC.Egg = Egg;
})();

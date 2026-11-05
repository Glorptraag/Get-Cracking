/* Get Cracking — shell effect registry.
 *
 * A "shell effect" decides what the eggshell physically does when the egg
 * hatches: roll away, explode, crumble… Each effect lives in its own file in
 * js/hatch/ and registers itself here. They are interchangeable.
 *
 * ─────────────────────────────── CONTRACT ───────────────────────────────
 *
 *   GC.ShellFX.register({
 *     id:   'roll',              // unique, lowercase
 *     name: 'Roll away',         // shown in settings
 *     icon: '🛞',                // one emoji for the settings chip
 *     async run(ctx) { ... },    // see below
 *   });
 *
 * When run(ctx) is called the shared anticipation (squash → stretch) has
 * already played and the intact egg is hidden. The effect must:
 *
 *   1. Build shell pieces with ctx.piece(points) so they look exactly like
 *      the egg that was just on screen (same colour + pattern).
 *   2. Call ctx.release() exactly once, at the moment the friend should
 *      spring out (usually 0–700 ms in). If you never call it, the core
 *      calls it for you when run() resolves, or after 3.5 s as a fallback.
 *   3. Resolve its promise when its main motion is done (aim ≤ 2.5 s).
 *      Pieces may stay resting on the ground afterwards (that's fine and
 *      encouraged — a little rubble pile is charming).
 *
 * After release the friend jumps from the egg's centre up to y ≈ -190 and
 * lands at (0, ctx.ground) in ~1.1 s. Keep the friend visible:
 *   - anything in ctx.front draws OVER the friend: by ~400 ms after
 *     release, front pieces must be clear of the box x ∈ [-75, 75],
 *     y ∈ [-200, 60]; move lingering pieces to ctx.back or off to the sides.
 *   - anything in ctx.back draws behind the friend (rubble, shadows).
 *
 * Coordinates are egg-local: the egg's base is (0,0), the egg spans
 * x ∈ [-64, 64], y ∈ [-170, 0]. +y is toward the viewer / down the screen.
 * The ground is a plane: a piece "resting on the ground" at depth d has its
 * bottom at y ≈ d, where d ∈ [-20, 70] (higher = nearer the viewer).
 * Stay inside ctx.bounds or fade out before leaving it.
 *
 * Always animate through ctx.animate() and wait through ctx.wait(): they
 * honour GC.timeScale so the lab page can play everything in slow motion.
 * Never use raw setTimeout / el.animate in an effect.
 *
 *   ctx.front / ctx.back      SVG <g> layers (egg-local coords)
 *   ctx.pal                   { shell, spot } colours of this egg
 *   ctx.EGG_PATH, ctx.ZIG     the egg outline path, the zig-zag crack points
 *   ctx.piece(points, opts?)  → { el, wrap, cx, cy }. el's origin is the
 *                             piece centroid, so CSS transforms on el
 *                             (translate/rotate/scale) pivot around it.
 *                             opts: { layer: ctx.back, edge: strokeWidth, cx, cy }
 *                             Move a piece between layers by re-appending wrap.
 *   ctx.shadow(x, y, rx, layer?)  ground shadow ellipse element
 *   ctx.puff(x, y, r, layer?)     self-removing dust puff
 *   ctx.animate(el, keyframes, options) → Promise (resolves when finished)
 *   ctx.wait(ms) → Promise
 *   ctx.rand(a, b)
 *   ctx.sfx.crack() / clink(pitch 0..1) / thud(pitch 0..1) / whoosh()
 *   ctx.reduce                prefers-reduced-motion: keep it ≤ 400 ms, no
 *                             flying pieces — e.g. just fade the halves apart.
 *   ctx.ground                y where the friend lands (48)
 *   ctx.bounds                { left, right, top, bottom } visible area
 */
(function () {
  'use strict';
  const GC = window.GC;
  const reg = new Map();

  GC.timeScale = GC.timeScale || 1;

  GC.ShellFX = {
    register(fx) {
      if (!fx || !fx.id || typeof fx.run !== 'function') throw new Error('ShellFX.register needs { id, run }');
      reg.set(fx.id, fx);
    },
    get(id) { return reg.get(id); },
    /** user-facing styles (excludes hidden fallbacks) */
    list() { return [...reg.values()].filter((f) => !f.hidden); },
    /** id, 'random', or undefined → an effect (never throws) */
    pick(id) {
      if (id && id !== 'random' && reg.has(id)) return reg.get(id);
      const pool = this.list();
      return pool.length ? GC.pick(pool) : reg.get('classic');
    },
  };

  /* Fallback / reference effect: the halves just split and slide apart.
     Real effects live in js/hatch/*.js. */
  GC.ShellFX.register({
    id: 'classic', name: 'Split', icon: '🥚', hidden: true,
    async run(ctx) {
      const top = ctx.piece([[-90, -230], [90, -230], ...ctx.ZIG.slice().reverse()]);
      const bot = ctx.piece([...ctx.ZIG, [90, 20], [-90, 20]], { layer: ctx.back });
      ctx.release();
      await Promise.all([
        ctx.animate(top.el, [{ transform: 'translate(0,0) rotate(0)' }, { transform: 'translate(-160px,-40px) rotate(-60deg)', opacity: 0 }], { duration: 700, easing: 'ease-in', fill: 'forwards' }),
        ctx.animate(bot.el, [{ transform: 'translate(0,0)' }, { transform: 'translate(150px,10px) rotate(30deg)', opacity: 0 }], { duration: 700, easing: 'ease-in', fill: 'forwards' }),
      ]);
    },
  });
})();

/* Timer stress test — drives the real app with a fake clock.
 *   node tests/timer.test.js            (serves the repo itself on :8766)
 * Checks tick accuracy, crack landmarks, pause, ±time, tap-to-hatch wait,
 * auto hatch, the grown-up clock text, and throttled (hidden) tabs. */
const { chromium } = require('playwright');
const http = require('http'), fs = require('fs'), path = require('path');

const ROOT = path.resolve(__dirname, '..');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.svg': 'image/svg+xml', '.png': 'image/png', '.webmanifest': 'application/json' };
const server = http.createServer((req, res) => {
  const f = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
  fs.readFile(f, (err, data) => {
    if (err) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'content-type': TYPES[path.extname(f)] || 'application/octet-stream' }); res.end(data);
  });
}).listen(8766);

let pass = 0, fail = 0;
const ok = (cond, msg) => { if (cond) { pass++; console.log('  ✓', msg); } else { fail++; console.log('  ✗', msg); } };

async function fresh(browser, settings) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p = await ctx.newPage();
  const errs = [];
  p.on('pageerror', (e) => errs.push(e.message));
  await p.clock.install({ time: new Date('2026-11-05T09:00:00') });
  await p.addInitScript((s) => {
    localStorage.setItem('gc.settings.v1', JSON.stringify(Object.assign({ fullscreen: false, seenHint: true }, s)));
  }, settings);
  await p.goto('http://localhost:8766/index.html');
  await p.clock.runFor(300);
  // instrument: record every crack step with the (fake) elapsed time
  await p.evaluate(() => {
    window.log = { steps: [], cracks: 0, knocks: 0, ready: 0, tunes: [] };
    const orig = GC.Egg.prototype.setStep;
    GC.Egg.prototype.setStep = function (n, silent) {
      const r = GC.app.run;
      if (!silent && r && this === r.egg && n > this.step) log.steps.push({ n, at: Date.now() - r.t0 });
      return orig.call(this, n, silent);
    };
    for (const k of ['crack', 'knock', 'ready']) { const o = GC.Sound[k].bind(GC.Sound); GC.Sound[k] = () => { log[k === 'crack' ? 'cracks' : k === 'knock' ? 'knocks' : 'ready']++; o(); }; }
    const et = GC.Sound.endTune.bind(GC.Sound); GC.Sound.endTune = (id) => { log.tunes.push(id); return et(id); };
  });
  return { p, errs, ctx };
}
const start = (p) => p.evaluate(async () => { await GC.app.startRun(); GC.app.run.t0 = Date.now(); });
const state = (p) => p.evaluate(() => { const r = GC.app.run; return r && { phase: r.phase, rem: r.phase === 'paused' ? r.remaining : r.endAt - Date.now(), total: r.total, step: r.egg.step, pill: document.getElementById('time-pill').textContent }; });

(async () => {
  const browser = await chromium.launch();
  const STEP_AT = [0.1, 0.22, 0.34, 0.46, 0.58, 0.7, 0.8, 0.9];

  console.log('\n1. 5-minute timer, 1 s ticks — landmarks + exact finish');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 5, seconds: 0, hatchMode: 'tap' });
    await start(p);
    let s = await state(p);
    ok(s.pill === '5:00', `clock starts at 5:00 (got ${s.pill})`);
    await p.clock.runFor(400);
    ok((await state(p)).pill === '5:00', 'still 5:00 after 0.4 s (rounds up, never shows 4:59 early)');
    await p.clock.runFor(700);
    ok((await state(p)).pill === '4:59', 'shows 4:59 after 1.1 s');
    for (let t = 2; t < 300; t++) await p.clock.runFor(1000);
    await p.clock.runFor(-100 + 900); // now ≈ 299.9 s
    s = await state(p);
    ok(s.phase === 'running', `still running at ~299.9 s (phase ${s.phase})`);
    await p.clock.runFor(150);
    s = await state(p);
    ok(s.phase === 'ready', `time's up within 50 ms of 5:00 (phase ${s.phase})`);
    const log = await p.evaluate(() => log);
    ok(log.steps.length === 8 && log.steps.every((x, i) => x.n === i + 1), `8 crack steps, in order, once each (${log.steps.map((x) => x.n).join(',')})`);
    const worst = Math.max(...log.steps.map((x, i) => Math.abs(x.at - STEP_AT[i] * 300000)));
    ok(worst <= 50, `every crack lands on its landmark (worst error ${worst} ms)`);
    ok(log.cracks === 8, `crack sound played 8 times (${log.cracks})`);
    ok(log.ready === 1, 'soft "time\'s up" sparkle played once, no alarm');
    ok(errs.length === 0, 'no page errors' + (errs.length ? ': ' + errs.join(' | ') : ''));
    await ctx.close();
  }

  console.log('\n2. 60-minute timer, fast-forwarded in 10 s jumps');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 60, seconds: 0, hatchMode: 'tap' });
    await start(p);
    for (let t = 0; t < 359; t++) await p.clock.fastForward(10000);
    let s = await state(p);
    ok(s.phase === 'running' && Math.abs(s.rem - 10000) < 300, `10 s left at 59:50 (rem ${s.rem} ms)`);
    ok(s.step === 8, 'all 8 cracks done before the end');
    await p.clock.fastForward(10000); await p.clock.runFor(1100);
    ok((await state(p)).phase === 'ready', 'finishes at 60:00');
    const log = await p.evaluate(() => log);
    const worst = Math.max(...log.steps.map((x, i) => Math.abs(x.at - STEP_AT[i] * 3600000)));
    ok(worst <= 11000, `landmarks within one 10 s jump (worst ${worst} ms)`);
    ok(errs.length === 0, 'no page errors');
    await ctx.close();
  }

  console.log('\n3. Pause / resume');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 2, seconds: 0, hatchMode: 'tap' });
    await start(p);
    await p.clock.runFor(30000);
    await p.evaluate(() => GC.app.setPaused(true));
    const a = await state(p);
    await p.clock.runFor(120000);
    const b = await state(p);
    ok(b.phase === 'paused' && b.rem === a.rem, `2 paused minutes cost nothing (${a.rem} → ${b.rem} ms)`);
    ok(b.pill === a.pill, `clock frozen at ${b.pill}`);
    const stepsPaused = (await p.evaluate(() => log.steps.length));
    await p.evaluate(() => GC.app.setPaused(false));
    await p.clock.runFor(a.rem - 200);
    ok((await state(p)).phase === 'running', 'still running 200 ms before the shifted end');
    await p.clock.runFor(400);
    ok((await state(p)).phase === 'ready', 'finishes exactly when the paused time runs out');
    ok(stepsPaused <= 2, 'no cracks while paused');
    // rapid pause spam
    ok(errs.length === 0, 'no page errors');
    await ctx.close();
  }

  console.log('\n4. ±1 minute, floors, and cracks never heal');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 1, seconds: 0, hatchMode: 'tap' });
    await start(p);
    await p.clock.runFor(45000);
    const before = await state(p);
    await p.evaluate(() => GC.app.adjust(60000));
    const after = await state(p);
    ok(Math.abs(after.rem - before.rem - 60000) < 5, `+1 adds exactly a minute (${before.rem} → ${after.rem})`);
    ok(after.step >= before.step, `cracks kept (step ${before.step} → ${after.step})`);
    await p.evaluate(() => { for (let i = 0; i < 10; i++) GC.app.adjust(-60000); });
    const floor = await state(p);
    ok(Math.abs(floor.rem - 5000) < 5, `−1 spam floors at 5 s instead of ending instantly (${floor.rem} ms)`);
    ok(floor.phase === 'running', 'still running after −1 spam');
    await p.clock.runFor(5200);
    ok((await state(p)).phase === 'ready', 'then finishes on time');
    ok(errs.length === 0, 'no page errors');
    await ctx.close();
  }

  console.log('\n5. Hatch waits for you (tap mode)');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 0, seconds: 15, hatchMode: 'tap' });
    await start(p);
    await p.clock.runFor(16000);
    for (let i = 0; i < 60; i++) await p.clock.runFor(10000); // 10 minutes away
    const s = await state(p);
    ok(s.phase === 'ready', 'still waiting after 10 minutes — the payoff is not missed');
    const log = await p.evaluate(() => log);
    ok(log.knocks === 60, `gentle knock every 5 s, stops after 5 min so it never nags forever (${log.knocks})`);
    ok(log.tunes.length === 0, 'tune not wasted while nobody is looking');
    ok(await p.evaluate(() => document.getElementById('hatch-pill').classList.contains('show')), '"Tap the egg!" showing');
    ok(errs.length === 0, 'no page errors');
    await ctx.close();
  }

  console.log('\n6. Auto hatch');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 0, seconds: 10, hatchMode: 'auto' });
    await start(p);
    await p.clock.runFor(10100);
    const s = await state(p);
    ok(s.phase === 'hatching' || s.phase === 'hatched', `hatches by itself at 0 (phase ${s.phase})`);
    ok(errs.length === 0, 'no page errors');
    await ctx.close();
  }

  console.log('\n7. Hidden/throttled tab (no animation frames)');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 0, seconds: 20, hatchMode: 'tap' });
    await p.evaluate(() => { window.requestAnimationFrame = () => 0; });
    await start(p);
    await p.clock.runFor(20000 + 1000);
    const s = await state(p);
    ok(s.phase === 'ready', 'backup ticker still finishes the timer (≤ 1 s late)');
    ok((await p.evaluate(() => log.steps.length)) === 8, 'all cracks still happen');
    ok(errs.length === 0, 'no page errors');
    await ctx.close();
  }

  console.log('\n8. Start/stop abuse — 40 runs, stop mid-hatch, restart');
  {
    const { p, errs, ctx } = await fresh(browser, { minutes: 0, seconds: 10, hatchMode: 'auto', music: 'musicbox' });
    for (let i = 0; i < 40; i++) {
      await start(p);
      if (i % 3 === 0) { await p.clock.fastForward(10000); await p.clock.runFor(300); } else await p.clock.runFor(800);
      await p.evaluate((i) => (i % 2 ? GC.app.stopToSetup() : GC.app.startRun()), i);
    }
    await p.evaluate(() => GC.app.stopToSetup());
    const leaks = await p.evaluate(() => ({ musicTimer: !!GC.Sound._timer, run: !!GC.app.run, eggs: document.querySelectorAll('#stage .egg-root').length }));
    ok(!leaks.run, 'no run left behind');
    ok(!leaks.musicTimer, 'no music scheduler left running');
    ok(leaks.eggs <= 1, `stage holds at most one egg (${leaks.eggs})`);
    ok(errs.length === 0, 'no page errors' + (errs.length ? ': ' + errs.slice(0, 3).join(' | ') : ''));
    await ctx.close();
  }

  console.log(`\n${pass} passed, ${fail} failed`);
  await browser.close(); server.close();
  process.exit(fail ? 1 : 0);
})();

/* Hatch stress test — every hatch style inside the real app.
 *   node tests/hatch.test.js
 * CPU throttled 4× (≈ mid-range phone). Checks: one hatch per egg even under
 * tap spam, the friend is never covered once landed, frame pacing, stop
 * mid-hatch, hatch-now while paused, back-to-back hatches (DOM / timer leaks),
 * reduced motion, and that the recorded sounds (sounds/) load and are used. */
const { chromium } = require('playwright');
const http = require('http'), fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..');
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.svg': 'image/svg+xml', '.png': 'image/png', '.webmanifest': 'application/json', '.json': 'application/json', '.mp3': 'audio/mpeg' };
const server = http.createServer((req, res) => {
  const f = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
  fs.readFile(f, (err, d) => { if (err) { res.writeHead(404); return res.end(); } res.writeHead(200, { 'content-type': TYPES[path.extname(f)] || 'application/octet-stream' }); res.end(d); });
}).listen(8767);
let pass = 0, fail = 0;
const ok = (c, m) => { c ? pass++ : fail++; console.log(c ? '  ✓' : '  ✗', m); };

async function page(browser, settings, opts = {}) {
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, reducedMotion: opts.reduce ? 'reduce' : 'no-preference' });
  const p = await ctx.newPage();
  const errs = [];
  p.on('pageerror', (e) => errs.push(e.message));
  p.on('console', (m) => { if (m.type() === 'error') errs.push(m.text()); });
  await p.addInitScript((s) => localStorage.setItem('gc.settings.v1', JSON.stringify(Object.assign({ fullscreen: false, seenHint: true, minutes: 0, seconds: 10, hatchMode: 'tap', music: 'musicbox' }, s))), settings);
  await p.goto('http://localhost:8767/index.html');
  await p.waitForTimeout(400);
  if (opts.throttle) { const cdp = await ctx.newCDPSession(p); await cdp.send('Emulation.setCPUThrottlingRate', { rate: opts.throttle }); }
  await p.evaluate(() => {
    window.T = { hatches: 0, tunes: 0, pops: 0 };
    const h = GC.Egg.prototype.hatch;
    GC.Egg.prototype.hatch = function (...a) { if (this === (GC.app.run && GC.app.run.egg)) T.hatches++; return h.apply(this, a); };
    const et = GC.Sound.endTune.bind(GC.Sound); GC.Sound.endTune = (...a) => { T.tunes++; return et(...a); };
    const pop = GC.Sound.pop.bind(GC.Sound); GC.Sound.pop = () => { T.pops++; pop(); };
    window.frames_ = [];
    let last = performance.now();
    const f = (t) => { frames_.push(t - last); last = t; requestAnimationFrame(f); };
    requestAnimationFrame(f);
  });
  return { p, ctx, errs };
}
const toReady = async (p) => {
  await p.evaluate(() => GC.app.startRun());
  await p.waitForTimeout(300);
  await p.evaluate(() => { GC.app.run.endAt = Date.now(); });
  await p.waitForFunction(() => GC.app.run && GC.app.run.phase === 'ready', null, { timeout: 5000 });
};
const coverage = (p) => p.evaluate(() => {
  const r = GC.app.run, egg = r.egg;
  const fr = egg.friend.querySelector('.c-squash').getBoundingClientRect();
  const box = { l: fr.left + fr.width * 0.15, r: fr.right - fr.width * 0.15, t: fr.top + fr.height * 0.1, b: fr.bottom - fr.height * 0.1 };
  let covered = 0, area = 0;
  for (const el of egg.root.querySelectorAll('.shell-front > *')) {
    const bb = el.getBoundingClientRect();
    const op = +getComputedStyle(el).opacity * +getComputedStyle(el.firstElementChild || el).opacity;
    if (op < 0.05 || !bb.width) continue;
    const ix = Math.max(0, Math.min(bb.right, box.r) - Math.max(bb.left, box.l));
    const iy = Math.max(0, Math.min(bb.bottom, box.b) - Math.max(bb.top, box.t));
    if (ix * iy > 40) { covered++; area += ix * iy; }
  }
  return { covered, area: Math.round(area), friendVisible: fr.width > 60, rubble: egg.root.querySelectorAll('.shell-piece').length };
});

(async () => {
  const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });

  for (const style of ['roll', 'boom', 'crumble']) {
    console.log(`\n■ ${style} — CPU ×4, tap spam`);
    const { p, ctx, errs } = await page(browser, { hatchStyle: style }, { throttle: 4 });
    await toReady(p);
    await p.evaluate(() => { frames_.length = 0; });
    const t0 = Date.now();
    for (let i = 0; i < 5; i++) { await p.mouse.click(195, 420); await p.waitForTimeout(40); }
    await p.waitForFunction(() => GC.app.run.phase === 'hatched', null, { timeout: 8000 }).catch(() => {});
    const took = Date.now() - t0;
    const st = await p.evaluate(() => ({ phase: GC.app.run.phase, style: GC.app.run.egg.style, ...T, fr: frames_.slice() }));
    ok(st.phase === 'hatched', `hatched (${took} ms under 4× CPU)`);
    ok(st.style === style, `ran the chosen style (${st.style})`);
    ok(st.hatches === 1 && st.tunes === 1 && st.pops === 1, `5 rapid taps → 1 hatch, 1 pop, 1 tune (${st.hatches}/${st.pops}/${st.tunes})`);
    const sorted = st.fr.slice().sort((a, b) => a - b);
    const p95 = sorted[Math.floor(sorted.length * 0.95)], worst = sorted[sorted.length - 1];
    const avgFps = 1000 / (st.fr.reduce((a, b) => a + b, 0) / st.fr.length);
    ok(p95 < 50 && avgFps > 30, `smooth on a slow phone: avg ${avgFps.toFixed(0)} fps, p95 frame ${p95.toFixed(0)} ms, worst ${worst.toFixed(0)} ms`);
    await p.waitForTimeout(1200);
    const cov = await coverage(p);
    ok(cov.friendVisible && cov.covered === 0, `friend fully visible after landing (${cov.covered} shell pieces over it)`);
    ok(cov.rubble <= 40, `rubble kept light (${cov.rubble} pieces on screen)`);
    await p.screenshot({ path: path.join(process.argv[2] || '/tmp', `hatch-${style}-end.png`) });
    ok(errs.length === 0, 'no page errors' + (errs.length ? ': ' + errs.slice(0, 3).join(' | ') : ''));
    await ctx.close();
  }

  console.log('\n■ abuse — stop mid-hatch, hatch-now while paused, 2×15 back-to-back hatches');
  {
    const { p, ctx, errs } = await page(browser, { hatchStyle: 'random' });
    for (const at of [100, 400, 900, 1600]) {
      await toReady(p);
      await p.mouse.click(195, 420);
      await p.waitForTimeout(at);
      await p.evaluate(() => GC.app.stopToSetup());
    }
    await p.waitForTimeout(2500); // let any orphaned effect promises settle
    ok(await p.evaluate(() => document.getElementById('setup').classList.contains('active') && !GC.app.run), 'stopping mid-hatch (at 100/400/900/1600 ms) returns cleanly to setup');
    await p.evaluate(() => GC.app.startRun()); await p.waitForTimeout(300);
    await p.evaluate(() => GC.app.setPaused(true));
    await p.evaluate(() => document.querySelector('.tray [data-act="hatch"]').click());
    await p.waitForFunction(() => GC.app.run.phase === 'hatched', null, { timeout: 6000 }).catch(() => {});
    ok(await p.evaluate(() => GC.app.run.phase) === 'hatched', '"Hatch now" while paused hatches');
    // n back-to-back "Again" → hatch cycles; returns the style and DOM size after each hatch
    const backToBack = async (n) => {
      const runs = [];
      for (let i = 0; i < n; i++) {
        await p.evaluate(() => { const r = GC.app.run; if (r) { r.endAt = Date.now(); } });
        await p.evaluate(() => document.querySelector('.tray [data-act="again"]').click());
        await p.waitForTimeout(150);
        await p.evaluate(() => { GC.app.run.endAt = Date.now(); });
        await p.waitForFunction(() => GC.app.run && GC.app.run.phase === 'ready', null, { timeout: 4000 });
        await p.mouse.click(195, 420);
        await p.waitForFunction(() => GC.app.run.phase === 'hatched', null, { timeout: 6000 });
        runs.push(await p.evaluate(() => ({ style: GC.app.run.egg.style, nodes: document.querySelectorAll('*').length })));
      }
      return runs;
    };
    const styles = {};
    for (const r of await backToBack(15)) styles[r.style] = (styles[r.style] || 0) + 1;
    ok(Object.keys(styles).length >= 2, `"Surprise me" rotates styles (${JSON.stringify(styles)})`);
    // Growth check on a fixed style. The DOM size after a hatch depends on the shell style
    // (crumble leaves ~1,300–1,440 nodes, boom/roll ~1,000–1,150), so comparing two
    // "Surprise me" hatches flakes. Within one style it still varies with the animal
    // (a friend is 27–50 nodes) and the rubble, so compare the average of the first 5
    // hatches with the last 5 and turn the difference into nodes added per hatch.
    // An absolute per-hatch limit, not a ratio: the 16 hatches above already sit in the
    // baseline, and a ratio loosens as the baseline grows (1.25× of ~1,350 would let
    // ~28 nodes/hatch through, i.e. a leaked friend every hatch). Without a leak this
    // measures within about ±7 nodes/hatch; leaking every friend measures ~42 (smallest
    // friend 27). 15 sits between the two with room on both sides.
    await p.evaluate(() => { GC.app.settings().hatchStyle = 'crumble'; });
    const fixed = await backToBack(15);
    const counts = fixed.map((r) => r.nodes);
    const avg = (a) => Math.round(a.reduce((s, v) => s + v, 0) / a.length);
    const first = avg(counts.slice(0, 5)), last = avg(counts.slice(10)), perHatch = (last - first) / 10;
    ok(fixed.every((r) => r.style === 'crumble'), 'fixed-style pass ran crumble every time');
    ok(perHatch < 15, `DOM doesn't grow across 15 crumble hatches (avg ${first} → ${last} nodes, ${perHatch.toFixed(1)}/hatch)`);
    ok(await p.evaluate(() => T.hatches) >= 31, 'every egg hatched');
    ok(errs.length === 0, 'no page errors' + (errs.length ? ': ' + errs.slice(0, 3).join(' | ') : ''));
    await ctx.close();
  }

  console.log('\n■ recorded sounds (ElevenLabs clips in sounds/)');
  {
    const { p, ctx, errs } = await page(browser, { hatchStyle: 'roll', endSound: 'band', sayName: true });
    await p.evaluate(() => {
      window.played = [];
      const smp = GC.Sound.sample.bind(GC.Sound);
      GC.Sound.sample = (key, ...a) => { const d = smp(key, ...a); if (d) played.push(key); return d; };
      window.spoke = 0;
      const say = GC.Sound.say.bind(GC.Sound); GC.Sound.say = (...a) => { spoke++; return say(...a); };
    });
    await toReady(p);
    const idx = JSON.parse(fs.readFileSync(path.join(ROOT, 'sounds', 'index.json'), 'utf8'));
    await p.waitForFunction((n) => Object.keys(GC.Samples.index ? GC.Samples.index.calls : {}).filter((k) => GC.Samples.has(k)).length >= n, Object.keys(idx.calls).length, { timeout: 15000 }).catch(() => {});
    const loaded = await p.evaluate(() => Object.keys(GC.Samples.index.calls).filter((k) => GC.Samples.has(k)).length);
    ok(loaded === Object.keys(idx.calls).length, `every animal call and effect loads (${loaded}/${Object.keys(idx.calls).length})`);
    await p.mouse.click(195, 420);
    await p.waitForFunction(() => GC.app.run.phase === 'hatched', null, { timeout: 8000 });
    const friend = await p.evaluate(() => GC.app.run.friend);
    const call = await p.evaluate((id) => GC.Band.FRIEND_CALL[id], friend.id);
    await p.waitForTimeout(1200);
    let st = await p.evaluate(() => ({ played: played.slice(), spoke }));
    ok(st.played.includes('pop'), 'the shell pop is the recording');
    ok(st.played.includes('voice/' + friend.id) && st.spoke === 0, `"It's ${friend.name}!" is the recorded voice, not the device voice (${st.played.filter((k) => k.startsWith('voice/')).join(', ') || 'none'}, device voice used ${st.spoke}×)`);
    // the friend's solo in the band comes later in the song
    await p.waitForFunction((c) => played.includes(c), call, { timeout: 20000 }).catch(() => {});
    st = await p.evaluate(() => ({ played: played.slice() }));
    ok(st.played.includes(call), `the ${friend.name} sings its solo with the recording (${call})`);
    const answers = st.played.filter((k) => idx.calls[k] !== undefined && k !== 'pop' && k !== 'crack');
    ok(answers.length >= 5, `the band's animal answers are recordings too (${answers.length} played)`);
    // a voice file that can't load falls back to the device voice
    const fell = await p.evaluate(() => { const before = spoke; GC.Sound.sayFriend({ kind: 'animal', id: 'nobody', name: 'Nobody' }); return spoke - before; });
    ok(fell === 1, 'a missing recording falls back to the device voice');
    ok(errs.length === 0, 'no page errors' + (errs.length ? ': ' + errs.slice(0, 3).join(' | ') : ''));
    await ctx.close();
  }

  console.log('\n■ reduced motion');
  for (const style of ['roll', 'boom', 'crumble']) {
    const { p, ctx, errs } = await page(browser, { hatchStyle: style }, { reduce: true });
    await toReady(p);
    const t0 = Date.now();
    await p.mouse.click(195, 420);
    await p.waitForFunction(() => GC.app.run.phase === 'hatched', null, { timeout: 5000 }).catch(() => {});
    const took = Date.now() - t0;
    ok(took < 1500 && errs.length === 0, `${style}: calm version finishes in ${took} ms`);
    await ctx.close();
  }

  console.log(`\n${pass} passed, ${fail} failed`);
  await browser.close(); server.close();
  process.exit(fail ? 1 : 0);
})();

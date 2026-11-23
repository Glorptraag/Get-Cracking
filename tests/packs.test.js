/* Content packs test — every pack (js/packs/*.js) inside the real app.
 *   node tests/packs.test.js [out/]          (out/ gets packs-<id>.png contact sheets)
 *   node tests/packs.test.js out/ aussie     (just one pack)
 * Checks, for every pack friend: it renders with no "undefined"/"NaN" in the markup
 * and a sensible size, its call and karaoke world exist, its sounds are listed in
 * sounds/index.json and the files are there (missing recordings are a warning: the
 * synth stand-in plays). Every pack world builds. Then in the app: hatching a pack
 * friend works, the karaoke and an animal band render with it with no errors, the
 * friend book groups it under its pack, and switching the pack off keeps it out
 * of the shuffle. */
const { chromium } = require('playwright');
const http = require('http'), fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..');
const OUT = process.argv[2] || null;
const ONLY = process.argv[3] || null;
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.svg': 'image/svg+xml', '.png': 'image/png', '.webmanifest': 'application/json', '.json': 'application/json', '.mp3': 'audio/mpeg' };
const PORT = 8771;
const server = http.createServer((req, res) => {
  const f = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
  fs.readFile(f, (err, d) => { if (err) { res.writeHead(404); return res.end(); } res.writeHead(200, { 'content-type': TYPES[path.extname(f)] || 'application/octet-stream' }); res.end(d); });
}).listen(PORT);
let pass = 0, fail = 0, warn = 0;
const ok = (c, m) => { c ? pass++ : fail++; console.log(c ? '  ✓' : '  ✗', m); };
const note = (m) => { warn++; console.log('  !', m); };

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const p = await ctx.newPage();
  const errs = [];
  p.on('pageerror', (e) => errs.push(e.message));
  p.on('console', (m) => { if (m.type() === 'error' && !/Failed to load resource/.test(m.text())) errs.push(m.text()); });
  await p.addInitScript(() => localStorage.setItem('gc.settings.v1', JSON.stringify({ fullscreen: false, seenHint: true, minutes: 0, seconds: 10, hatchMode: 'tap', music: 'off', tunesV: 3 })));
  await p.goto(`http://localhost:${PORT}/index.html`);
  await p.waitForTimeout(500);
  ok(!errs.length, `app loads with every pack registered (${errs.join(' | ') || 'no errors'})`);

  const idx = JSON.parse(fs.readFileSync(path.join(ROOT, 'sounds/index.json'), 'utf8'));
  const packs = (await p.evaluate(() => GC.Packs.list.filter((x) => !x.builtIn).map((x) => ({ id: x.id, name: x.name, friends: x.friends, scenes: x.scenes }))))
    .filter((x) => !ONLY || x.id === ONLY);
  if (!packs.length) console.log('  (no packs registered yet)');

  for (const pk of packs) {
    console.log(`\n${pk.name} (${pk.id}): ${pk.friends.length} friends, ${pk.scenes.length} worlds`);
    ok(pk.friends.length > 0, 'has friends');

    // every friend: markup, size, wiring
    const report = await p.evaluate((ids) => ids.map((id) => {
      const a = GC.Animals.byId[id];
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '-112 -218 224 232');
      svg.style.cssText = 'position:absolute;left:0;top:0;width:224px;height:232px';
      let markup = '', err = null;
      try { markup = GC.Animals.render(a); } catch (e) { err = e.message; }
      svg.innerHTML = markup;
      document.body.append(svg);
      const bb = svg.querySelector('.c-squash') ? svg.querySelector('.c-squash').getBBox() : { width: 0, height: 0, x: 0, y: 0 };
      svg.remove();
      return {
        id, name: a.name, err, bad: /undefined|NaN/.test(markup), w: bb.width, h: bb.height, x: bb.x, y: bb.y,
        call: GC.Band.FRIEND_CALL[id], hasCall: !!GC.Band.CALLS[GC.Band.FRIEND_CALL[id]],
        world: (GC.Karaoke.FRIENDS[id] || [])[0], hasWorld: !!GC.Karaoke.WORLDS[(GC.Karaoke.FRIENDS[id] || [])[0]],
        // a part that draws nothing is a typo or a missing part (render without it: same markup = it drew nothing)
        deadParts: ['back', 'marks', 'front', 'over'].flatMap((layer) => (a[layer] || []).filter((name) => {
          const strip = (m) => m.replace(/id="[^"]*"|url\(#[^)]*\)/g, '');
          const without = Object.assign({}, a, { [layer]: a[layer].filter((x) => x !== name) });
          return strip(GC.Animals.render(without)) === strip(markup);
        }).map((name) => `${layer}:${name}`)),
      };
    }), pk.friends);
    for (const r of report) {
      ok(!r.err && !r.bad, `${r.name}: renders cleanly${r.err ? ' — ' + r.err : r.bad ? ' — markup has undefined/NaN' : ''}`);
      ok(r.w > 80 && r.w < 300 && r.h > 90 && r.h < 300 && r.y > -260, `${r.name}: sensible size (${Math.round(r.w)}×${Math.round(r.h)}, top ${Math.round(r.y)})`);
      ok(!r.deadParts.length, `${r.name}: every part it names draws something${r.deadParts.length ? ' — missing: ' + r.deadParts.join(', ') : ''}`);
      ok(r.hasCall && r.hasWorld, `${r.name}: call "${r.call}" and karaoke world "${r.world}" exist`);
      const file = (k) => fs.existsSync(path.join(ROOT, 'sounds', k + '.mp3'));
      if (!(idx.voice[r.id] && file('voice/' + r.id))) note(`${r.name}: no recorded "It's a …!" line (sounds/voice/${r.id}.mp3); the device voice will say it`);
      if (!(idx.calls[r.call] && file(r.call))) note(`${r.name}: no recorded call sounds/${r.call}.mp3; the synth stand-in plays`);
      const k = idx.karaoke || {};
      if (!((k.sing || {})[r.id] && file('karaoke/sing/' + r.id))) note(`${r.name}: no karaoke voice sounds/karaoke/sing/${r.id}.mp3; the synth voice sings`);
      if (!((k.extra || {})[r.id] && file('karaoke/extra/' + r.id))) note(`${r.name}: no karaoke extra sound; the world's chirp answers`);
    }

    // every world builds
    for (const sid of pk.scenes) {
      const r = await p.evaluate((id) => {
        const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        document.body.append(svg);
        let err = null;
        try { GC.Scenes.build(svg, id); } catch (e) { err = e.message; }
        const bad = /undefined|NaN/.test(svg.innerHTML);
        const built = svg.dataset.scene === id;
        svg.remove();
        return { err, bad, built };
      }, sid);
      ok(!r.err && !r.bad && r.built, `world ${sid} builds cleanly${r.err ? ' — ' + r.err : r.bad ? ' — markup has undefined/NaN' : ''}`);
    }

    // Egg karaoke and an animal band render with a pack friend as the singer / soloist
    for (const id of pk.friends) {
      const r = await p.evaluate(async (fid) => {
        const out = {};
        for (const song of ['karaoke', 'band']) {
          try {
            const SR = 22050, real = new OfflineAudioContext(1, SR * 24, SR);
            let fake = 0;
            const proxy = new Proxy(real, { get(t, k) { if (k === 'currentTime') return fake; if (k === 'state') return 'running'; const v = t[k]; return typeof v === 'function' ? v.bind(t) : v; } });
            const savedAC = window.AudioContext;
            window.AudioContext = function () { return proxy; };
            const s = new GC.Sound.constructor();
            s.ensure();
            window.AudioContext = savedAC;
            const len = s.endTune(song, fid);
            const c = s._celeb;
            clearInterval(c.timer); clearTimeout(c.doneT); clearInterval(s._timer);
            for (let t = 0; t < len; t += 0.05) { fake = t; s._celebPump(); }
            const buf = await real.startRendering();
            const L = buf.getChannelData(0);
            let peak = 0, nan = 0;
            for (let i = 0; i < L.length; i++) { if (Number.isNaN(L[i])) nan++; else peak = Math.max(peak, Math.abs(L[i])); }
            out[song] = { len: +len.toFixed(1), peak: +peak.toFixed(2), nan, played: c.i === c.ev.length, solo: c.friendCall === GC.Band.FRIEND_CALL[fid] };
          } catch (e) { out[song] = { err: e.message }; }
        }
        return out;
      }, id);
      for (const song of ['karaoke', 'band']) {
        const x = r[song];
        ok(!x.err && x.nan === 0 && x.peak > 0.05 && x.peak < 1 && x.played && x.solo,
          `${id}: ${song === 'karaoke' ? 'Egg karaoke' : 'animal band'} plays with it (${x.err || `${x.len}s, peak ${x.peak}, every note ${x.played ? 'played' : 'NOT played'}, ends on its own call: ${x.solo}`})`);
      }
    }

    // hatch a pack friend in the real app
    errs.length = 0;
    const hatched = await p.evaluate(async (fid) => {
      GC.app.nextFriend(fid);
      GC.app.startRun();
      await new Promise((r) => setTimeout(r, 300));
      GC.app.run.endAt = Date.now();
      await new Promise((r) => setTimeout(r, 500));
      await GC.app.hatch();
      await new Promise((r) => setTimeout(r, 1500));
      const el = document.querySelector(`[data-animal="${fid}"]`);
      return { phase: GC.app.run && GC.app.run.phase, shown: !!el };
    }, pk.friends[0]);
    ok(hatched.shown, `${pk.friends[0]} hatches in the app`);
    ok(hatched.phase === 'hatched', `hatching works in the app (phase ${hatched.phase})`);
    ok(!errs.length, `no errors while hatching (${errs.join(' | ') || 'none'})`);
    await p.evaluate(() => GC.app.stopToSetup && GC.app.stopToSetup());

    // friend book groups the pack
    const book = await p.evaluate((name) => { GC.app.openSheet('book'); const hs = [...document.querySelectorAll('.book-pack')].map((x) => x.textContent); GC.app.closeSheet(); return hs; }, pk.name);
    ok(book.some((t) => t.startsWith(pk.name)), `friend book has a "${pk.name}" group`);

    // switching the pack off keeps it out of the shuffle
    const offOk = await p.evaluate((id) => {
      GC.app.openSheet('settings');
      const row = [...document.querySelectorAll('.sec .row')].find((r) => r.textContent.startsWith(GC.Packs.byId(id).name));
      const box = row && row.querySelector('input[type=checkbox]');
      if (!box) return 'no toggle';
      box.click();
      const outOfBag = !GC.app.bagItems.some((f) => GC.Animals.byId[f].pack === id);
      box.click();
      const back = GC.app.bagItems.some((f) => GC.Animals.byId[f].pack === id);
      GC.app.closeSheet();
      return outOfBag && back ? true : `out ${outOfBag}, back ${back}`;
    }, pk.id);
    ok(offOk === true, `switching the pack off in settings keeps it out of the shuffle (${offOk})`);

    if (OUT) {
      // contact sheets drawn inside the app page (all of the app is loaded there)
      fs.mkdirSync(OUT, { recursive: true });
      const sheet = await browser.newPage({ viewport: { width: 6 * 170 + 20, height: 600 }, deviceScaleFactor: 1 });
      await sheet.goto(`http://localhost:${PORT}/index.html`);
      await sheet.waitForTimeout(300);
      await sheet.evaluate((ids) => {
        document.body.innerHTML = '<div id="g" style="display:grid;grid-template-columns:repeat(6,166px);gap:4px;padding:10px;background:#d8d0c4"></div>';
        document.body.style.cssText = 'margin:0;background:#d8d0c4;overflow:auto;height:auto';
        for (const id of ids) {
          const a = GC.Animals.byId[id];
          const d = document.createElement('div');
          d.style.cssText = 'background:#ece6dc;border-radius:12px;text-align:center;font:14px sans-serif';
          d.innerHTML = `<svg viewBox="-110 -215 220 230" style="width:166px;height:174px">${GC.Animals.render(a)}</svg><div>${a.name}</div>`;
          g.append(d);
        }
      }, pk.friends);
      await sheet.screenshot({ path: path.join(OUT, `packs-${pk.id}.png`), fullPage: true });
      if (pk.scenes.length) {
        await sheet.evaluate((ids) => {
          g.innerHTML = '';
          g.style.gridTemplateColumns = 'repeat(3,330px)';
          for (const id of ids) {
            const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
            svg.style.cssText = 'width:330px;height:396px;display:block';
            g.append(svg);
            const h = GC.Scenes.build(svg, id);
            new GC.Egg(h.eggLayer, { x: GC.Scenes.EGG.x, y: GC.Scenes.EGG.y });
          }
        }, pk.scenes);
        await sheet.screenshot({ path: path.join(OUT, `packs-${pk.id}-worlds.png`), fullPage: true });
      }
      await sheet.close();
      console.log(`  → ${path.join(OUT, `packs-${pk.id}.png`)}`);
    }
  }

  console.log(`\n${pass} passed, ${fail} failed, ${warn} warnings`);
  await browser.close();
  server.close();
  process.exit(fail ? 1 : 0);
})();

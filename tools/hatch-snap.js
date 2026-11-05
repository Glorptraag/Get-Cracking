/* Contact sheet of a hatch, for reviewing motion without watching it.
 *   node tools/hatch-snap.js <fx-id> <out.png> [scene] [slow]
 * Frames are labelled with the time (in normal-speed ms) since the hatch began.
 * The shared anticipation squash takes the first ~520 ms; the effect starts after. */
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const [fx = 'classic', out = 'hatch.png', scene = 'forest', slow = '4'] = process.argv.slice(2);
  const S = +slow;
  const times = [0, 400, 560, 650, 750, 850, 950, 1100, 1250, 1450, 1700, 2000, 2400, 2900, 3500, 4500];
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 390, height: 520 } });
  const errs = [];
  p.on('pageerror', (e) => errs.push(e.message));
  p.on('console', (m) => { if (m.type() === 'error') errs.push(m.text()); });
  const url = 'file://' + path.resolve(__dirname, 'hatch-lab.html') + `?fx=${fx}&slow=${S}&snap=1&scene=${scene}`;
  await p.goto(url);
  await p.waitForTimeout(400);
  await p.evaluate(() => { window.labHatch(); });
  const t0 = Date.now();
  const shots = [];
  for (const t of times) {
    const wait = t * S - (Date.now() - t0);
    if (wait > 0) await p.waitForTimeout(wait);
    shots.push({ t, img: (await p.screenshot({ type: 'jpeg', quality: 70 })).toString('base64') });
  }
  const sheet = await b.newPage({ viewport: { width: 4 * 260 + 50, height: 800 } });
  await sheet.setContent(`<body style="margin:0;background:#222;font:14px sans-serif;color:#fff">
    <div style="display:grid;grid-template-columns:repeat(4,260px);gap:10px;padding:10px">
    ${shots.map((s) => `<div><img src="data:image/jpeg;base64,${s.img}" style="width:260px;display:block"><div>${fx} · ${s.t} ms</div></div>`).join('')}
    </div></body>`);
  await sheet.screenshot({ path: out, fullPage: true });
  console.log(errs.length ? 'ERRORS:\n' + errs.join('\n') : 'ok, no page errors');
  await b.close();
})();

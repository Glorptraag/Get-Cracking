/* Audio stress test.
 *   node tests/audio.test.js [outDir]
 * A. Offline-renders every hatching tune and countdown track through the real
 *    Sound graph, checks levels (no clipping, no dead air, tunes decay to
 *    silence) and writes WAVs to outDir so a human can listen.
 * B. Runs the live scheduler in a real AudioContext and abuses it: main-thread
 *    stalls, double starts, stop/start spam, pause/resume. */
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const OUT = process.argv[2] || path.join(__dirname, 'out');
fs.mkdirSync(OUT, { recursive: true });
let pass = 0, fail = 0;
const ok = (c, m) => { c ? pass++ : fail++; console.log(c ? '  ✓' : '  ✗', m); };
const db = (x) => (x > 0 ? (20 * Math.log10(x)).toFixed(1) : '-inf');

(async () => {
  const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });
  let p = await browser.newPage();
  const errs = [];
  p.on('pageerror', (e) => errs.push(e.message));
  await p.goto('file://' + path.resolve(__dirname, '..', 'tools', 'hatch-lab.html'));
  await p.waitForTimeout(300);

  await p.evaluate(() => {
    window.renderWith = async (seconds, drive) => {
      const SR = 44100;
      const real = new OfflineAudioContext(2, SR * seconds, SR);
      let fake = 0;
      const proxy = new Proxy(real, {
        get(t, k) { if (k === 'currentTime') return fake; if (k === 'state') return 'running'; const v = t[k]; return typeof v === 'function' ? v.bind(t) : v; },
      });
      const savedAC = window.AudioContext;
      window.AudioContext = function () { return proxy; };
      const s = new GC.Sound.constructor();
      s.ensure();
      window.AudioContext = savedAC;
      const notes = [];
      const tone = s.tone.bind(s);
      s.tone = (f, t, d, o) => { notes.push(t); return tone(f, t, d, o); };
      const declared = drive(s, (t) => (fake = t)) || 0;
      clearInterval(s._timer);
      const buf = await real.startRendering();
      const L = buf.getChannelData(0), R = buf.getChannelData(1);
      let peak = 0, clip = 0, nan = 0;
      const win = SR / 4, rms = [];
      for (let i = 0; i < L.length; i += win) {
        let acc = 0;
        for (let j = i; j < Math.min(i + win, L.length); j++) {
          const a = Math.max(Math.abs(L[j]), Math.abs(R[j]));
          if (Number.isNaN(L[j])) nan++;
          if (a > peak) peak = a;
          if (a >= 0.999) clip++;
          acc += L[j] * L[j];
        }
        rms.push(Math.sqrt(acc / win));
      }
      // 16-bit WAV
      const n = L.length, data = new DataView(new ArrayBuffer(44 + n * 4));
      const w = (o, str) => [...str].forEach((c, i) => data.setUint8(o + i, c.charCodeAt(0)));
      w(0, 'RIFF'); data.setUint32(4, 36 + n * 4, true); w(8, 'WAVEfmt '); data.setUint32(16, 16, true);
      data.setUint16(20, 1, true); data.setUint16(22, 2, true); data.setUint32(24, SR, true); data.setUint32(28, SR * 4, true);
      data.setUint16(32, 4, true); data.setUint16(34, 16, true); w(36, 'data'); data.setUint32(40, n * 4, true);
      for (let i = 0; i < n; i++) {
        data.setInt16(44 + i * 4, Math.max(-1, Math.min(1, L[i])) * 32767, true);
        data.setInt16(46 + i * 4, Math.max(-1, Math.min(1, R[i])) * 32767, true);
      }
      let bin = ''; const u8 = new Uint8Array(data.buffer);
      for (let i = 0; i < u8.length; i += 0x8000) bin += String.fromCharCode.apply(null, u8.subarray(i, i + 0x8000));
      return { peak, clip, nan, rms, declared, notes, wav: btoa(bin) };
    };
  });

  console.log('\nA1. Hatching tunes (offline render)');
  for (const e of await p.evaluate(() => GC.END_SOUNDS.filter((x) => !x.band).map((x) => x.id))) {
    const r = await p.evaluate((id) => renderWith(6, (s) => s.endTune(id)), e);
    fs.writeFileSync(path.join(OUT, `tune-${e}.wav`), Buffer.from(r.wav, 'base64'));
    const loud = Math.max(...r.rms);
    const endIdx = Math.ceil((r.declared + 1) * 4);
    const tail = Math.max(...r.rms.slice(endIdx));
    ok(r.nan === 0 && r.peak > 0.05, `${e}: plays (peak ${db(r.peak)} dBFS)`);
    ok(r.clip === 0, `${e}: no clipping`);
    ok(tail < loud * 0.03, `${e}: fully decays after its ${r.declared}s (tail ${db(tail)} dB vs ${db(loud)} dB) — no stuck notes`);
    ok(r.declared >= 2.5 && r.declared <= 4.5, `${e}: celebratory length ${r.declared}s`);
  }

  console.log('\nA1b. Animal bands (offline render, every song × a few friends)');
  const bands = await p.evaluate(() => GC.END_SOUNDS.filter((x) => x.band && x.id !== 'karaoke').map((x) => x.id));
  const friends = ['elephant', 'kitten', 'unicorn', 'snail', null];
  for (const e of bands) {
    for (const fr of friends) {
      const r = await p.evaluate(([id, fr]) => renderWith(22, (s, setT) => {
        const len = s.endTune(id, fr);
        const c = s._celeb;
        clearInterval(c.timer); clearTimeout(c.doneT);
        for (let t = 0; t < len; t += 0.05) { setT(t); s._celebPump(); }
        window._lastBand = { solo: c.friendCall, events: c.ev.length, done: c.i };
        return len;
      }), [e, fr]);
      const meta = await p.evaluate(() => window._lastBand);
      const tag = `${e}${fr ? '-' + fr : ''}`;
      fs.writeFileSync(path.join(OUT, `band-${tag}.wav`), Buffer.from(r.wav, 'base64'));
      const loud = Math.max(...r.rms);
      const endIdx = Math.ceil((r.declared + 0.5) * 4);
      const tail = Math.max(0, ...r.rms.slice(endIdx));
      const body = r.rms.slice(2, Math.floor((r.declared - 2.6) * 4));
      const gaps = body.filter((x) => x < loud * 0.02).length;
      ok(r.nan === 0 && r.peak > 0.1, `${tag}: plays (peak ${db(r.peak)} dBFS, ${meta.events} events, solo: ${meta.solo})`);
      ok(r.clip === 0, `${tag}: no clipping`);
      ok(meta.done === meta.events, `${tag}: every scheduled note played (${meta.done}/${meta.events})`);
      ok(gaps <= 2, `${tag}: no dead air in the song (${gaps} silent ¼ s)`);
      ok(tail < loud * 0.03, `${tag}: rings out and stops after ${r.declared.toFixed(1)}s (tail ${db(tail)} dB vs ${db(loud)} dB)`);
      ok(r.declared >= 9 && r.declared <= 20, `${tag}: a proper song, not too long (${r.declared.toFixed(1)}s)`);
      if (fr) ok(meta.solo === (await p.evaluate((f) => GC.Band.FRIEND_CALL[f], fr)), `${tag}: the ${fr} takes the solo`);
    }
  }

  // Egg karaoke: one friend from each world (+ a random one), checked like the bands
  const karaoke = async (label, friends, wantRecorded) => {
    for (const fr of friends) {
      const r = await p.evaluate((fr) => renderWith(24, (s, setT) => {
        let sung = 0;
        s.onSing = () => sung++;
        const len = s.endTune('karaoke', fr);
        const c = s._celeb;
        clearInterval(c.timer); clearTimeout(c.doneT);
        for (let t = 0; t < len; t += 0.05) { setT(t); s._celebPump(); }
        window._lastK = { singer: c.singer, call: c.friendCall, world: c.world, recorded: c.recorded, events: c.ev.length, done: c.i, sung };
        return len;
      }), fr);
      const m = await p.evaluate(() => window._lastK);
      const tag = `karaoke-${label}-${fr || 'random'}`;
      fs.writeFileSync(path.join(OUT, `${tag}.wav`), Buffer.from(r.wav, 'base64'));
      const loud = Math.max(...r.rms);
      const tail = Math.max(0, ...r.rms.slice(Math.ceil((r.declared + 0.5) * 4)));
      const gaps = r.rms.slice(2, Math.floor((r.declared - 2.6) * 4)).filter((x) => x < loud * 0.02).length;
      ok(r.nan === 0 && r.peak > 0.1, `${tag}: plays (peak ${db(r.peak)} dBFS, ${m.world}, ${m.events} events)`);
      ok(r.clip === 0, `${tag}: no clipping`);
      ok(m.done === m.events, `${tag}: every scheduled note played (${m.done}/${m.events})`);
      ok(gaps <= 2, `${tag}: no dead air (${gaps} silent ¼ s)`);
      ok(tail < loud * 0.03, `${tag}: rings out and stops after ${r.declared.toFixed(1)}s (tail ${db(tail)} dB vs ${db(loud)} dB)`);
      ok(r.declared >= 12 && r.declared <= 22, `${tag}: song length ${r.declared.toFixed(1)}s`);
      ok(m.sung >= 30, `${tag}: the friend sings the tune (${m.sung} notes)`);
      if (fr) ok(m.singer === fr && m.call === (await p.evaluate((f) => GC.Band.FRIEND_CALL[f], fr)), `${tag}: the ${fr} is the singer and ends on its own call`);
      ok(m.recorded === wantRecorded, `${tag}: ${wantRecorded ? 'sings with its recorded voice' : 'synth voice when recordings are unavailable'}`);
    }
  };
  console.log('\nA1c. Egg karaoke, synthesised fallback (opened from disk: no recordings)');
  ok((await p.evaluate(() => GC.END_SOUNDS[0].id)) === 'karaoke', 'Egg karaoke is first in the list');
  await karaoke('synth', ['kitten', 'owl', 'elephant', 'seal', 'dragon', null], false);

  console.log('\nA1d. Egg karaoke with the ElevenLabs recordings (served over http)');
  const server = require('http').createServer((req, res) => {
    // the lab page lives in tools/, so its relative sounds/ is the app's sounds/
    const f = path.join(__dirname, '..', decodeURIComponent(req.url.split('?')[0]).replace(/^\/tools\/sounds\//, '/sounds/'));
    if (!f.startsWith(path.join(__dirname, '..')) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': f.endsWith('.html') ? 'text/html' : f.endsWith('.js') ? 'text/javascript' : f.endsWith('.json') ? 'application/json' : 'audio/mpeg' });
    fs.createReadStream(f).pipe(res);
  });
  await new Promise((r) => server.listen(0, r));
  const hp = await browser.newPage();
  hp.on('pageerror', (e) => errs.push(e.message));
  await hp.goto(`http://localhost:${server.address().port}/tools/hatch-lab.html`);
  const files = await hp.evaluate(async () => {
    const ctx = new AudioContext();
    await GC.Samples.load(ctx);
    const k = GC.Samples.index.karaoke;
    const extras = Object.keys(k.extra);
    await Promise.all(extras.map((id) => GC.Samples.want(ctx, 'karaoke/extra/' + id)));
    const bad = [];
    for (const kind of ['inst', 'sing', 'extra']) for (const id of Object.keys(k[kind])) if (!GC.Samples.has(`karaoke/${kind}/${id}`)) bad.push(`${kind}/${id}`);
    const pitched = Object.values(k.inst).filter((x) => x.m != null).length;
    return { inst: Object.keys(k.inst).length, sing: Object.keys(k.sing).length, extra: extras.length, bad, pitched, friends: Object.keys(GC.Karaoke.FRIENDS).length };
  });
  ok(files.sing === files.friends && files.extra === files.friends, `every friend has a singing voice and an extra sound (${files.sing} + ${files.extra} for ${files.friends} friends)`);
  ok(files.inst >= 19 && files.pitched >= 9, `the band's instruments are recorded and tuned (${files.inst}, ${files.pitched} pitched)`);
  ok(files.bad.length === 0, `every recording loads and decodes${files.bad.length ? ': ' + files.bad.join(', ') : ''}`);
  // reuse the offline renderer on the http page
  const renderSrc = await p.evaluate(() => window.renderWith.toString());
  await hp.evaluate((src) => { window.renderWith = eval('(' + src + ')'); }, renderSrc);
  const p0 = p; // karaoke() renders on page p: point it at the http page for this pass
  p = hp;
  await karaoke('recorded', ['kitten', 'owl', 'elephant', 'seal', 'dragon', 'ladybug'], true);
  p = p0;
  await hp.close();
  server.close();

  console.log('\nA2. Countdown music (offline render, 16 s, final-stretch twinkle from 10 s)');
  for (const m of ['musicbox', 'marimba', 'forest', 'rain', 'ticktock']) {
    const r = await p.evaluate((id) => renderWith(16, (s, setT) => {
      s.startMusic(id);
      for (let t = 0; t < 15.5; t += 0.06) { setT(t); if (t > 10) s.setTension(1); s._schedule(); }
    }), m);
    fs.writeFileSync(path.join(OUT, `music-${m}.wav`), Buffer.from(r.wav, 'base64'));
    const body = r.rms.slice(8, 60); // 2 s … 15 s
    const quiet = Math.min(...body), loud = Math.max(...body);
    ok(r.nan === 0 && r.clip === 0, `${m}: clean (peak ${db(r.peak)} dBFS, no clipping)`);
    if (m === 'ticktock') {
      const secs = []; for (let i = 0; i + 4 <= body.length; i += 4) secs.push(Math.max(...body.slice(i, i + 4)));
      ok(Math.min(...secs) > loud * 0.3, `${m}: a tick in every second (weakest second ${db(Math.min(...secs))} dB)`);
    } else ok(quiet > loud * 0.04, `${m}: no dead air (quietest ¼ s ${db(quiet)} dB, loudest ${db(loud)} dB)`);
    ok(r.peak < 0.6, `${m}: sits under the celebration so the hatch tune stands out`);
    if (m === 'musicbox' || m === 'marimba') {
      const before = r.notes.filter((t) => t > 4 && t < 9).length / 5, after = r.notes.filter((t) => t > 10.5 && t < 15.5).length / 5;
      ok(after > before * 1.15, `${m}: final stretch adds twinkle (${before.toFixed(1)} → ${after.toFixed(1)} notes/s)`);
    }
  }

  console.log('\nB. Live scheduler abuse (real AudioContext)');
  const live = await p.evaluate(async () => {
    const S = GC.Sound;
    S.ensure();
    await S.ctx.resume();
    const log = [];
    const tone = S.tone.bind(S);
    S.tone = (f, t, d, o) => { log.push({ t, now: S.ctx.currentTime, f }); return tone(f, t, d, o); };
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const out = { running: S.ctx.state };
    S.startMusic('musicbox');
    await sleep(3000);
    const mel = log.filter((n) => n.f > 400).map((n) => n.t);
    const steps = mel.slice(1).map((t, i) => t - mel[i]);
    const grid = 60 / 76 / 2;
    out.offGrid = steps.filter((d) => Math.abs(d / grid - Math.round(d / grid)) > 0.001).length;
    out.late = log.filter((n) => n.t < n.now - 0.005).length;
    // stall the main thread for 700 ms
    const before = log.length;
    const t0 = performance.now(); while (performance.now() - t0 < 700) {}
    await sleep(1500);
    const after = log.slice(before);
    const times = after.map((n) => n.t).sort((a, b) => a - b);
    let burst = 0;
    for (let i = 2; i < times.length; i++) if (times[i] - times[i - 2] < 0.01) burst++;
    out.burst = burst; out.dropped = S.dropped || 0;
    out.lateAfterStall = after.filter((n) => n.t < n.now - 0.005).length;
    // double start must not double the notes
    S.startMusic('musicbox'); S.startMusic('musicbox'); S.startMusic('marimba');
    log.length = 0; await sleep(2000);
    const mt = log.map((n) => n.t.toFixed(4) + ':' + n.f.toFixed(1));
    out.dupes = mt.length - new Set(mt).size;
    out.marimbaRate = log.length / 2;
    // stop/start spam then stop
    for (let i = 0; i < 50; i++) { S.startMusic(i % 2 ? 'rain' : 'forest'); S.stopMusic(0.05); }
    S.startMusic('ticktock'); S.pauseMusic(); log.length = 0; await sleep(1200);
    out.whilePaused = log.length;
    S.resumeMusic(); await sleep(1300);
    out.afterResume = log.length;
    S.stopMusic(0.05); log.length = 0; await sleep(1200);
    out.afterStop = log.length;
    out.timerLeft = !!S._timer;
    return out;
  });
  ok(live.running === 'running', 'AudioContext runs');
  ok(live.offGrid === 0, `every note lands exactly on the beat grid (${live.offGrid} off-grid)`);
  ok(live.late === 0, `no note scheduled in the past (${live.late})`);
  ok(live.burst === 0, `700 ms main-thread stall: no machine-gun burst of missed notes (${live.burst} clusters, ${live.dropped} skipped)`);
  ok(live.lateAfterStall <= 1, `music back on the beat after the stall (${live.lateAfterStall} late)`);
  ok(live.dupes === 0, `double/triple start never doubles notes (${live.dupes} dupes)`);
  ok(live.marimbaRate > 2 && live.marimbaRate < 8, `switching track mid-way plays only the new track (${live.marimbaRate} notes/s)`);
  ok(live.whilePaused === 0, `paused = silent (${live.whilePaused} notes)`);
  ok(live.afterResume > 0, 'resume brings the music back');
  ok(live.afterStop === 0 && !live.timerLeft, 'stop = silent, scheduler cleared');

  console.log('\nC. Animal band live (real AudioContext)');
  const band = await p.evaluate(async () => {
    const S = GC.Sound;
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const out = {};
    const len = S.endTune('farm', 'piglet');
    out.len = len;
    out.solo = S._celeb.friendCall;
    await sleep(1200);
    const c1 = S._celeb, played1 = c1.i;
    out.pumping = played1 > 0 && played1 < c1.ev.length; // scheduled a little at a time, not all at once
    // a 700 ms main-thread stall: the notes it made us miss are skipped, not fired in a burst
    const dropped0 = S.dropped || 0;
    const t0 = performance.now(); while (performance.now() - t0 < 700) {}
    await sleep(300);
    out.skipped = (S.dropped || 0) - dropped0;
    out.stillGoing = c1.i > played1 && !!c1.timer;
    // starting another song replaces the first
    S.endTune('band', 'kitten');
    out.replaced = S._celeb !== c1 && !c1.timer;
    // a short jingle stops a band that is playing
    S.endTune('chimes');
    out.jingleStops = !S._celeb;
    // countdown music starting (a new egg) stops it too
    S.endTune('jungle'); S.startMusic('musicbox'); out.musicStops = !S._celeb; S.stopMusic(0.05);
    // stop mid-song: nothing more is scheduled
    S.endTune('band');
    await sleep(500);
    const c = S._celeb; S.stopCelebration(0.05);
    const at = c.i; await sleep(800);
    out.stopHolds = c.i === at && !c.timer;
    out.tapCall = S.friendCall('elephant') > 0 && S.friendCall('nobody') === 0;
    return out;
  });
  ok(band.len > 9 && band.len < 20, `farm song length ${band.len.toFixed(1)}s`);
  ok(band.solo === 'oink', `the piglet takes the solo (${band.solo})`);
  ok(band.pumping, 'song is scheduled a little ahead at a time, not all at once');
  ok(band.stillGoing, `700 ms stall: the song carries on (${band.skipped} missed notes skipped, not burst)`);
  ok(band.replaced, 'starting another song replaces the first (never two bands at once)');
  ok(band.jingleStops, 'picking a short jingle stops a band that is playing');
  ok(band.musicStops, 'a new egg (countdown music) stops the band');
  ok(band.stopHolds, 'stop mid-song: nothing more is scheduled');
  ok(band.tapCall, 'tapping a friend plays its own call');
  ok(errs.filter((e) => !/resume|InvalidState/.test(e)).length === 0, 'no page errors' + (errs.length ? ': ' + errs.join(' | ') : ''));

  console.log(`\n${pass} passed, ${fail} failed — WAVs in ${OUT}`);
  await browser.close();
  process.exit(fail ? 1 : 0);
})();

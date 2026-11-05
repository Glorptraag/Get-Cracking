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
  const p = await browser.newPage();
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
  for (const e of await p.evaluate(() => GC.END_SOUNDS.map((x) => x.id))) {
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
  ok(errs.filter((e) => !/resume|InvalidState/.test(e)).length === 0, 'no page errors' + (errs.length ? ': ' + errs.join(' | ') : ''));

  console.log(`\n${pass} passed, ${fail} failed — WAVs in ${OUT}`);
  await browser.close();
  process.exit(fail ? 1 : 0);
})();

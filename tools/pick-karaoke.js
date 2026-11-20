/* Choose, level and pitch the Egg karaoke recordings.
 *
 *   node tools/pick-karaoke.js <takesDir>
 *
 * For every sound in tools/karaoke.json it levels each take made by
 * tools/gen-sounds.js --manifest tools/karaoke.json, measures it (onsets, pitch,
 * how steady the pitch is) and keeps the best one, unless the manifest names a
 * "take". Scores:
 *   inst (pitched)  one clean onset and a steady, clear pitch
 *   inst (drum)     one hit, short
 *   sing            one syllable, short; a clear pitch is a bonus (the app tunes it)
 *   extra           not silent, not a long ramble
 * Writes sounds/karaoke/{inst,sing,extra}/<id>.mp3 and a "karaoke" section in
 * sounds/index.json: inst/sing → { d: seconds, m: MIDI pitch or null }, extra → seconds.
 * The app pitches every note from m (null = play it relative to its natural pitch).
 * A full report of every take's measurements goes to <takesDir>/karaoke-report.json.
 */
const fs = require('fs'), path = require('path');
const { level, analyse, peakDb } = require('./level');
const dir = process.argv[2];
if (!dir) { console.error('usage: node tools/pick-karaoke.js <takesDir>'); process.exit(1); }
const ROOT = path.join(__dirname, '..');
const man = JSON.parse(fs.readFileSync(path.join(__dirname, 'karaoke.json'), 'utf8'));
const fileId = (id) => id.replace(/\//g, '_');
const tmp = path.join(dir, 'leveled');
fs.mkdirSync(tmp, { recursive: true });

function score(s, a) {
  const kind = s.id.split('/')[0];
  const one = -Math.abs(a.onsets - 1);
  if (kind === 'inst' && s.pitched) return 2 * a.clarity - 0.5 * Math.min(a.spread, 6) + 1.5 * one + (a.dur < 0.25 ? -5 : 0);
  if (kind === 'inst') return 1.5 * one - Math.max(0, a.dur - 0.7);
  if (kind === 'sing') return 1.2 * one + a.clarity - 0.15 * Math.min(a.spread, 6) - 2 * Math.max(0, a.dur - 0.75) + (a.dur < 0.12 ? -5 : 0);
  return (a.dur > 0.25 ? 1 : -5) - 0.3 * Math.max(0, a.onsets - 4);
}

const index = { inst: {}, sing: {}, extra: {} };
const report = {}, missing = [];
for (const s of man.sounds) {
  const kind = s.id.split('/')[0], name = s.id.split('/')[1];
  const takes = [];
  for (let n = 1; fs.existsSync(path.join(dir, `${fileId(s.id)}-${n}.mp3`)); n++) {
    const src = path.join(dir, `${fileId(s.id)}-${n}.mp3`), out = path.join(tmp, `${fileId(s.id)}-${n}.mp3`);
    // a take that came back (nearly) silent is no good, however loud we make it
    const pk = peakDb(src);
    if (pk < -40) { takes.push({ n, bad: `silent (peak ${pk} dB)` }); continue; }
    try {
      level(src, out, { maxDur: kind === 'sing' ? 0.9 : kind === 'extra' ? 1.4 : 0 });
      const a = analyse(out);
      takes.push({ n, out, a, score: +score(s, a).toFixed(2) });
    } catch (e) { takes.push({ n, bad: 'unreadable' }); }
  }
  const good = takes.filter((t) => !t.bad);
  if (!good.length) { console.log(`NO GOOD TAKE ${s.id}: ${takes.map((t) => t.bad).join(', ') || 'none'}`); missing.push(s.id); continue; }
  const pick = (s.take && good.find((t) => t.n === s.take)) || good.reduce((b, t) => (t.score > b.score ? t : b));
  report[s.id] = { picked: pick.n, takes: takes.map(({ n, a, score, bad }) => ({ n, score, bad, ...a })) };
  const dst = path.join(ROOT, 'sounds', 'karaoke', kind, `${name}.mp3`);
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  fs.copyFileSync(pick.out, dst);
  const a = pick.a;
  // only trust a pitch the detector heard clearly; otherwise the app plays it relative
  const pitched = kind === 'inst' ? s.pitched && a.clarity >= 0.5 && a.spread < 1.5 : a.clarity >= 0.35 && a.spread < 4;
  if (kind === 'extra') index.extra[name] = a.dur;
  else index[kind][name] = { d: a.dur, m: pitched ? +a.midi.toFixed(2) : null };
  console.log(`${s.id.padEnd(16)} take ${pick.n}/${takes.length}  ${a.dur.toFixed(2)}s  onsets ${a.onsets}  ` +
    `pitch ${a.midi === null ? '  -  ' : a.midi.toFixed(1)}${pitched ? '' : ' (relative)'}  clarity ${a.clarity}  spread ${a.spread}  score ${pick.score}`);
}

const idxPath = path.join(ROOT, 'sounds', 'index.json');
const idx = JSON.parse(fs.readFileSync(idxPath, 'utf8'));
idx.karaoke = index;
fs.writeFileSync(idxPath, JSON.stringify(idx, null, 1) + '\n');
fs.writeFileSync(path.join(dir, 'karaoke-report.json'), JSON.stringify(report, null, 1));
if (missing.length) { console.log(`\nno usable take for: ${missing.join(',')} (generate more takes with --takes and run again)`); process.exitCode = 2; }
console.log(`${Object.keys(index.inst).length} instruments, ${Object.keys(index.sing).length} singers, ${Object.keys(index.extra).length} extras → sounds/karaoke/`);

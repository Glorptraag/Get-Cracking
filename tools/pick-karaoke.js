/* Choose, level and pitch the Egg karaoke recordings.
 *
 *   node tools/pick-karaoke.js <takesDir> [--only sing/fox,sing/owl]
 *
 * For every sound in tools/karaoke.json it levels each take made by
 * tools/gen-sounds.js --manifest tools/karaoke.json, measures it (onsets, pitch,
 * how steady the pitch is) and keeps the best one, unless the manifest names a
 * "take" (or "fromTake": ignore takes made before the prompt changed). Scores:
 *   inst (pitched)  one clean onset and a steady, clear pitch
 *   inst (drum)     one hit, short
 *   sing            one syllable that holds a clear pitch for as long as possible
 *   extra           not silent, not a long ramble
 * Writes sounds/karaoke/{inst,sing,extra}/<id>.mp3 and a "karaoke" section in
 * sounds/index.json: inst/sing → { d: seconds, m: MIDI pitch or null }, extra → seconds.
 * The app pitches every instrument note from m. For a friend, m decides its part:
 * a call that holds a clear pitch (SINGS below) sings the tune, and the song moves
 * to that friend's key; anything else (a grunt, a sniff, a shell knock) gets
 * m: null and is played as it is, like a percussion instrument, never re-pitched.
 * A full report of every take's measurements goes to <takesDir>/karaoke-report.json.
 */
const fs = require('fs'), path = require('path');
const { level, analyse, voice, peakDb } = require('./level');
const dir = process.argv[2];
if (!dir) { console.error('usage: node tools/pick-karaoke.js <takesDir> [--only id,id]'); process.exit(1); }
const onlyAt = process.argv.indexOf('--only');
const only = onlyAt > 0 ? process.argv[onlyAt + 1].split(',') : null; // re-pick just these, keep the rest
const ROOT = path.join(__dirname, '..');
const man = JSON.parse(fs.readFileSync(path.join(__dirname, 'karaoke.json'), 'utf8'));
const fileId = (id) => id.replace(/\//g, '_');
const tmp = path.join(dir, 'leveled');
fs.mkdirSync(tmp, { recursive: true });

/** can this call carry a tune? a clear, fairly steady pitch held long enough to hear */
const SINGS = (a) => a.clarity >= 0.6 && a.spread < 6 && a.voiced >= 0.15;

function score(s, a) {
  const kind = s.id.split('/')[0];
  const one = -Math.abs(a.onsets - 1);
  if (kind === 'sing') {
    const tonal = a.clarity >= 0.6 && a.spread < 6;
    // a note to sing: the longer it holds its pitch the better. Not a note: short and single is best
    return (tonal ? 2 + 3 * Math.min(a.voiced, 0.45) : -Math.max(0, a.eff - 0.4)) + one - 0.1 * Math.min(a.spread, 6) - 2 * Math.max(0, a.dur - 0.85) + (a.eff < 0.03 ? -3 : 0);
  }
  if (kind === 'inst' && s.pitched) return 2 * a.clarity - 0.5 * Math.min(a.spread, 6) + 1.5 * one + (a.dur < 0.25 ? -5 : 0);
  if (kind === 'inst') return 1.5 * one - Math.max(0, a.dur - 0.7);
  return (a.dur > 0.25 ? 1 : -5) - 0.3 * Math.max(0, a.onsets - 4);
}

const idxPath = path.join(ROOT, 'sounds', 'index.json');
const idx = JSON.parse(fs.readFileSync(idxPath, 'utf8'));
const reportPath = path.join(dir, 'karaoke-report.json');
const index = only && idx.karaoke ? idx.karaoke : { inst: {}, sing: {}, extra: {} };
const report = only && fs.existsSync(reportPath) ? JSON.parse(fs.readFileSync(reportPath, 'utf8')) : {};
const missing = [];
for (const s of man.sounds) {
  if (only && !only.includes(s.id)) continue;
  const kind = s.id.split('/')[0], name = s.id.split('/')[1];
  const takes = [];
  // fromTake: the prompt changed at that take, so the earlier ones are for the old prompt
  for (let n = s.fromTake || 1; fs.existsSync(path.join(dir, `${fileId(s.id)}-${n}.mp3`)); n++) {
    const src = path.join(dir, `${fileId(s.id)}-${n}.mp3`), out = path.join(tmp, `${fileId(s.id)}-${n}.mp3`);
    // a take that came back (nearly) silent is no good, however loud we make it
    const pk = peakDb(src);
    if (pk < -40) { takes.push({ n, bad: `silent (peak ${pk} dB)` }); continue; }
    try {
      level(src, out, { maxDur: kind === 'sing' ? 0.9 : kind === 'extra' ? 1.4 : 0 });
      const a = kind === 'sing' ? voice(out) : analyse(out);
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
  const pitched = kind === 'inst' ? s.pitched && a.clarity >= 0.5 && a.spread < 1.5 : kind === 'sing' && SINGS(a);
  if (kind === 'extra') index.extra[name] = a.dur;
  else index[kind][name] = { d: a.dur, m: pitched ? +a.midi.toFixed(2) : null };
  console.log(`${s.id.padEnd(16)} take ${pick.n} (best of ${good.length})  ${a.dur.toFixed(2)}s  onsets ${a.onsets}  ` +
    `pitch ${a.midi === null ? '  -  ' : a.midi.toFixed(1)}${pitched ? '' : kind === 'sing' ? ' (as it is)' : ' (relative)'}  clarity ${a.clarity}  spread ${a.spread}` +
    `${kind === 'sing' ? `  voiced ${a.voiced}s` : ''}  score ${pick.score}`);
}

idx.karaoke = index;
fs.writeFileSync(idxPath, JSON.stringify(idx, null, 1) + '\n');
fs.writeFileSync(reportPath, JSON.stringify(report, null, 1));
if (missing.length) { console.log(`\nno usable take for: ${missing.join(',')} (generate more takes with --takes and run again)`); process.exitCode = 2; }
const sings = Object.keys(index.sing).filter((k) => index.sing[k].m != null), plays = Object.keys(index.sing).filter((k) => index.sing[k].m == null);
console.log(`\n${sings.length} friends sing the tune: ${sings.join(' ')}\n${plays.length} play their sound as it is: ${plays.join(' ')}`);
console.log(`${Object.keys(index.inst).length} instruments, ${Object.keys(index.sing).length} singers, ${Object.keys(index.extra).length} extras → sounds/karaoke/`);

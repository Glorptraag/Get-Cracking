/* Turn the chosen ElevenLabs takes into the files the app ships.
 *
 *   node tools/pick-sounds.js <takesDir>
 *
 * For each sound in tools/sounds.json it takes the chosen take ("take"), and for
 * each voice line the recording in <takesDir>/voice/. It then trims silence at
 * both ends, adds tiny fades so nothing clicks, levels everything to the same
 * loudness (-14 LUFS momentary peak, -1 dBFS ceiling) and writes small mono
 * MP3s to sounds/ and sounds/voice/. The app trims level per use at playback.
 * Also writes sounds/index.json, which the app and the service worker read.
 */
const fs = require('fs'), path = require('path');
const { execFileSync } = require('child_process');
const dir = process.argv[2];
if (!dir) { console.error('usage: node tools/pick-sounds.js <takesDir>'); process.exit(1); }
const ROOT = path.join(__dirname, '..');
const man = JSON.parse(fs.readFileSync(path.join(__dirname, 'sounds.json'), 'utf8'));
const TARGET = -14;
const ff = (a) => execFileSync('ffmpeg', ['-hide_banner', '-nostats', '-y', ...a], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
const trim = 'aformat=channel_layouts=mono,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.01,' +
  'areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.06,afade=t=in:d=0.04,areverse,afade=t=in:d=0.004';

function process1(src, dst) {
  const tmp = dst + '.wav';
  ff(['-loglevel', 'error', '-i', src, '-af', trim, '-ar', '44100', tmp]);
  // loudest 400 ms of the clip, so a short quack and a long moo come out equally loud
  let r = '';
  try { execFileSync('ffmpeg', ['-hide_banner', '-nostats', '-i', tmp, '-af', 'ebur128', '-f', 'null', '-'], { stdio: ['ignore', 'pipe', 'pipe'] }); } catch (e) { r = String(e.stderr); }
  r = r || execFileSync('sh', ['-c', `ffmpeg -hide_banner -nostats -i "${tmp}" -af ebur128 -f null - 2>&1`], { encoding: 'utf8' });
  const ms = [...r.matchAll(/M:\s*(-?[0-9.]+)/g)].map((m) => +m[1]).filter((x) => x > -70);
  let gain;
  if (ms.length) gain = (TARGET - Math.max(...ms)).toFixed(2);
  else { // shorter than one loudness window (a quick crack): level by its peak instead
    const pk = +(execFileSync('sh', ['-c', `ffmpeg -hide_banner -nostats -i "${tmp}" -af volumedetect -f null - 2>&1`], { encoding: 'utf8' }).match(/max_volume:\s*(-?[0-9.]+)/) || [0, -20])[1];
    gain = (-3 - pk).toFixed(2);
  }
  ff(['-loglevel', 'error', '-i', tmp, '-af', `volume=${gain}dB,alimiter=limit=0.89:attack=1:release=30:level=disabled`, '-c:a', 'libmp3lame', '-b:a', '64k', '-ac', '1', dst]);
  fs.unlinkSync(tmp);
  const dur = +execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', dst], { encoding: 'utf8' });
  return { dur: +dur.toFixed(3), gain: +gain };
}

fs.mkdirSync(path.join(ROOT, 'sounds', 'voice'), { recursive: true });
const index = { calls: {}, voice: {} };
for (const s of man.sounds) {
  const r = process1(path.join(dir, `${s.id}-${s.take}.mp3`), path.join(ROOT, 'sounds', `${s.id}.mp3`));
  index.calls[s.id] = r.dur;
  console.log(`${s.id.padEnd(8)} take ${s.take}  ${r.dur}s  ${r.gain > 0 ? '+' : ''}${r.gain} dB`);
}
for (const f of fs.readdirSync(path.join(dir, 'voice')).filter((f) => f.endsWith('.mp3')).sort()) {
  const id = f.replace('.mp3', '');
  const r = process1(path.join(dir, 'voice', f), path.join(ROOT, 'sounds', 'voice', f));
  index.voice[id] = r.dur;
}
fs.writeFileSync(path.join(ROOT, 'sounds', 'index.json'), JSON.stringify(index, null, 1) + '\n');
console.log(`${Object.keys(index.calls).length} calls, ${Object.keys(index.voice).length} voice lines → sounds/`);

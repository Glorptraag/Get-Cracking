/* Shared by tools/pick-sounds.js and tools/pick-karaoke.js: trim, level, encode,
 * and (for the karaoke) measure a recording's pitch and onsets.
 *
 *   level(src, dst)  trim silence at both ends, tiny fades so nothing clicks,
 *                    level to -14 LUFS momentary peak (-1 dBFS ceiling), write a
 *                    small mono MP3. Returns { dur, gain }.
 *   analyse(file)    { dur, onsets, midi, clarity, spread } where midi is the
 *                    median pitch of the loud part (YIN), or null if unpitched.
 *   voice(file)      the same for an animal's call, heard the way a singer is judged:
 *                    a wide pitch range (70 Hz to 9 kHz, so a mouse's squeak counts),
 *                    eff = seconds within 15 dB of the loudest point, and
 *                    voiced = seconds of clear, steady pitch. A call can only sing a
 *                    tune if it holds a pitch long enough to hear it.
 *   peakDb(file)     loudest sample in dBFS (a take that came back near-silent is useless)
 */
const fs = require('fs');
const { execFileSync } = require('child_process');

const TARGET = -14;
const ff = (a) => execFileSync('ffmpeg', ['-hide_banner', '-nostats', '-y', ...a], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
const ffErr = (a) => { // ffmpeg writes its measurements to stderr
  try { execFileSync('ffmpeg', ['-hide_banner', '-nostats', ...a, '-f', 'null', '-'], { stdio: ['ignore', 'pipe', 'pipe'] }); return ''; } catch (e) { return String(e.stderr); }
};
const measure = (file, af) => ffErr(['-i', file, '-af', af]) ||
  execFileSync('sh', ['-c', `ffmpeg -hide_banner -nostats -i "${file}" -af ${af} -f null - 2>&1`], { encoding: 'utf8' });
const TRIM = 'aformat=channel_layouts=mono,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.01,' +
  'areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.06,afade=t=in:d=0.04,areverse,afade=t=in:d=0.004';

function level(src, dst, o = {}) {
  const tmp = dst + '.wav';
  ff(['-loglevel', 'error', '-i', src, '-af', TRIM + (o.maxDur ? `,atrim=0:${o.maxDur},areverse,afade=t=in:d=0.05,areverse` : ''), '-ar', '44100', tmp]);
  // loudest 400 ms of the clip, so a short quack and a long moo come out equally loud
  const ms = [...measure(tmp, 'ebur128').matchAll(/M:\s*(-?[0-9.]+)/g)].map((m) => +m[1]).filter((x) => x > -70);
  let gain;
  if (ms.length) gain = (TARGET - Math.max(...ms)).toFixed(2);
  else { // shorter than one loudness window (a quick crack): level by its peak instead
    const pk = +(measure(tmp, 'volumedetect').match(/max_volume:\s*(-?[0-9.]+)/) || [0, -20])[1];
    gain = (-3 - pk).toFixed(2);
  }
  ff(['-loglevel', 'error', '-i', tmp, '-af', `volume=${gain}dB,alimiter=limit=0.89:attack=1:release=30:level=disabled`, '-c:a', 'libmp3lame', '-b:a', '64k', '-ac', '1', dst]);
  fs.unlinkSync(tmp);
  const dur = +execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', dst], { encoding: 'utf8' });
  return { dur: +dur.toFixed(3), gain: +gain };
}

/** decode to mono float samples at sr */
function pcm(file, sr) {
  const buf = execFileSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-i', file, '-ac', '1', '-ar', String(sr), '-f', 'f32le', '-'], { maxBuffer: 64 << 20 });
  return new Float32Array(buf.buffer, buf.byteOffset, buf.length / 4);
}

/** YIN pitch of one frame: Hz or 0 (unvoiced) */
function yin(x, start, W, tauMin, tauMax, sr, thresh = 0.15) {
  const d = new Float32Array(tauMax + 2);
  for (let tau = 1; tau <= tauMax; tau++) {
    let s = 0;
    for (let j = 0; j < W; j++) { const v = x[start + j] - x[start + j + tau]; s += v * v; }
    d[tau] = s;
  }
  // cumulative mean normalised difference
  let run = 0;
  for (let tau = 1; tau <= tauMax; tau++) {
    run += d[tau];
    d[tau] = run ? (d[tau] * tau) / run : 1;
  }
  d[0] = 1;
  for (let tau = tauMin; tau < tauMax; tau++) {
    if (d[tau] < thresh && d[tau] <= d[tau + 1]) {
      while (tau + 1 < tauMax && d[tau + 1] < d[tau]) tau++;
      const a = d[tau - 1], b = d[tau], c = d[tau + 1];
      const den = a + c - 2 * b;
      const t = den ? tau + (a - c) / (2 * den) : tau;
      return sr / t;
    }
  }
  return 0;
}

function analyse(file) {
  const SR = 22050;
  const x = pcm(file, SR);
  const dur = x.length / SR;
  // 10 ms energy envelope
  const hop = Math.round(SR * 0.01), env = [];
  for (let i = 0; i + hop <= x.length; i += hop) {
    let s = 0; for (let j = i; j < i + hop; j++) s += x[j] * x[j];
    env.push(10 * Math.log10(s / hop + 1e-12));
  }
  const top = Math.max(...env);
  // onsets: rises to within 12 dB of the loudest point, after a dip of 18 dB or more
  let onsets = 0, armed = true;
  for (const e of env) {
    if (armed && e > top - 12) { onsets++; armed = false; } else if (!armed && e < top - 18) armed = true;
  }
  // pitch: YIN over the frames within 20 dB of the loudest
  const W = 1024, tauMin = Math.floor(SR / 4200), tauMax = Math.ceil(SR / 38), fhop = 256;
  const f0 = [];
  let loud = 0;
  for (let i = 0; i + W + tauMax < x.length; i += fhop) {
    const ei = Math.min(env.length - 1, Math.floor((i + W / 2) / hop));
    if (env[ei] < top - 20) continue;
    loud++;
    const f = yin(x, i, W, tauMin, tauMax, SR);
    if (f) f0.push(69 + 12 * Math.log2(f / 440));
  }
  f0.sort((a, b) => a - b);
  const med = f0.length ? f0[Math.floor(f0.length / 2)] : null;
  // spread: semitones between the 20th and 80th percentile (a steady note is small)
  const spread = f0.length > 2 ? f0[Math.floor(f0.length * 0.8)] - f0[Math.floor(f0.length * 0.2)] : 99;
  const clarity = loud ? f0.length / loud : 0;
  return { dur: +dur.toFixed(3), onsets, midi: med === null ? null : +med.toFixed(2), clarity: +clarity.toFixed(2), spread: +spread.toFixed(2) };
}

function voice(file) {
  const SR = 44100, x = pcm(file, SR), hop = 441, env = [];
  for (let i = 0; i + hop <= x.length; i += hop) {
    let s = 0; for (let j = i; j < i + hop; j++) s += x[j] * x[j];
    env.push(10 * Math.log10(s / hop + 1e-12));
  }
  const top = Math.max(...env);
  const eff = env.filter((e) => e > top - 15).length * 0.01;
  let onsets = 0, armed = true;
  for (const e of env) {
    if (armed && e > top - 12) { onsets++; armed = false; } else if (!armed && e < top - 18) armed = true;
  }
  const W = 1536, tauMin = Math.floor(SR / 9000), tauMax = Math.ceil(SR / 70);
  const f0 = [];
  let loud = 0;
  for (let i = 0; i + W + tauMax + 2 < x.length; i += hop) {
    const ei = Math.min(env.length - 1, Math.floor((i + W / 2) / hop));
    if (env[ei] < top - 15) continue;
    loud++;
    const f = yin(x, i, W, tauMin, tauMax, SR);
    if (f) f0.push(69 + 12 * Math.log2(f / 440));
  }
  const voiced = f0.length * 0.01;
  f0.sort((a, b) => a - b);
  const med = f0.length ? f0[Math.floor(f0.length / 2)] : null;
  const spread = f0.length > 2 ? f0[Math.floor(f0.length * 0.8)] - f0[Math.floor(f0.length * 0.2)] : 99;
  return { dur: +(x.length / SR).toFixed(3), eff: +eff.toFixed(2), onsets, midi: med === null ? null : +med.toFixed(2),
    clarity: loud ? +(f0.length / loud).toFixed(2) : 0, spread: +spread.toFixed(2), voiced: +voiced.toFixed(2) };
}

/** loudest sample in dBFS */
const peakDb = (file) => +(measure(file, 'volumedetect').match(/max_volume:\s*(-?[0-9.]+)/) || [0, -99])[1];

module.exports = { level, analyse, voice, pcm, peakDb };

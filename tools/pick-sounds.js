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
const { level } = require('./level');
const dir = process.argv[2];
if (!dir) { console.error('usage: node tools/pick-sounds.js <takesDir>'); process.exit(1); }
const ROOT = path.join(__dirname, '..');
const man = JSON.parse(fs.readFileSync(path.join(__dirname, 'sounds.json'), 'utf8'));
fs.mkdirSync(path.join(ROOT, 'sounds', 'voice'), { recursive: true });
const idxPath = path.join(ROOT, 'sounds', 'index.json');
const old = fs.existsSync(idxPath) ? JSON.parse(fs.readFileSync(idxPath, 'utf8')) : {};
const index = { calls: {}, voice: {} };
if (old.karaoke) index.karaoke = old.karaoke; // written by tools/pick-karaoke.js
for (const s of man.sounds) {
  const r = level(path.join(dir, `${s.id}-${s.take}.mp3`), path.join(ROOT, 'sounds', `${s.id}.mp3`));
  index.calls[s.id] = r.dur;
  console.log(`${s.id.padEnd(8)} take ${s.take}  ${r.dur}s  ${r.gain > 0 ? '+' : ''}${r.gain} dB`);
}
for (const f of fs.readdirSync(path.join(dir, 'voice')).filter((f) => f.endsWith('.mp3')).sort()) {
  const id = f.replace('.mp3', '');
  const r = level(path.join(dir, 'voice', f), path.join(ROOT, 'sounds', 'voice', f));
  index.voice[id] = r.dur;
}
fs.writeFileSync(idxPath, JSON.stringify(index, null, 1) + '\n');
console.log(`${Object.keys(index.calls).length} calls, ${Object.keys(index.voice).length} voice lines → sounds/`);

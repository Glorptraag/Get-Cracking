/* Record each Advent Eggs friend's hatch line ("It's Mary!") with ElevenLabs.
 *
 *   ELEVENLABS_API_KEY=… node AdventEggs/tools/gen-voice.js <takesDir> [--budget 600]
 *
 * Reads the lines from Model/Friends.swift so they can never drift, uses the same
 * voice and settings as Get Cracking's tools/gen-voice.js, never re-records a line
 * it already has, and writes AdventEggs/AdventEggs/Resources/Voice/day-NN.mp3.
 */
const fs = require('fs'), path = require('path');
const { execFileSync } = require('child_process');
const args = process.argv.slice(2), dir = args[0];
if (!dir) { console.error('usage: node gen-voice.js <takesDir> [--budget 600]'); process.exit(1); }
const i = args.indexOf('--budget'), BUDGET = i > 0 ? +args[i + 1] : 600;
const VOICE = 'cgSgspJ2msm6clMCkdW9'; // "Jessica", as in Get Cracking
const MODEL = 'eleven_multilingual_v2';
const SETTINGS = { stability: 0.45, similarity_boost: 0.75, style: 0.35, use_speaker_boost: true };
const KEY = process.env.ELEVENLABS_API_KEY || 'proxy-injected';

const root = path.join(__dirname, '..', 'AdventEggs');
const src = fs.readFileSync(path.join(root, 'Model', 'Friends.swift'), 'utf8');
const lines = [...src.matchAll(/Friend\(day: (\d+), name: "[^"]+", spoken: "([^"]+)"/g)]
  .map((m) => ({ id: `day-${m[1].padStart(2, '0')}`, text: m[2] }));
if (lines.length !== 25) { console.error(`expected 25 lines, found ${lines.length}`); process.exit(1); }

const outDir = path.join(root, 'Resources', 'Voice');
fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(dir, { recursive: true });
const ledgerPath = path.join(dir, 'ledger.json');
const ledger = fs.existsSync(ledgerPath) ? JSON.parse(fs.readFileSync(ledgerPath, 'utf8')) : { spent: 0, requests: [] };
for (const l of lines) {
  const take = path.join(dir, `${l.id}.mp3`);
  if (!fs.existsSync(take)) {
    const worst = l.text.length * 2;
    if (ledger.spent + worst > BUDGET) { console.log(`STOP: budget ${BUDGET} would be exceeded (spent ${ledger.spent})`); process.exit(2); }
    const hdr = take + '.headers';
    const code = execFileSync('curl', ['-sS', '-X', 'POST', `https://api.elevenlabs.io/v1/text-to-speech/${VOICE}?output_format=mp3_44100_64`,
      '-H', 'Content-Type: application/json', '-H', `xi-api-key: ${KEY}`,
      '--data-binary', JSON.stringify({ text: l.text, model_id: MODEL, voice_settings: SETTINGS }),
      '-D', hdr, '-o', take + '.part', '-w', '%{http_code}'], { encoding: 'utf8' }).trim();
    const h = fs.readFileSync(hdr, 'utf8'); fs.unlinkSync(hdr);
    const cost = +((h.match(/^character-cost:\s*(\d+)/im) || [])[1] || 0);
    if (code !== '200') { console.log(`FAIL ${l.id}: HTTP ${code} ${fs.readFileSync(take + '.part', 'utf8').slice(0, 300)}`); fs.unlinkSync(take + '.part'); process.exit(3); }
    fs.renameSync(take + '.part', take);
    ledger.spent += cost || worst; ledger.requests.push({ id: l.id, text: l.text, cost: cost || null });
    fs.writeFileSync(ledgerPath, JSON.stringify(ledger, null, 1));
    console.log(`${l.id} "${l.text}"  cost ${cost}  (spent ${ledger.spent})`);
  }
  fs.copyFileSync(take, path.join(outDir, `${l.id}.mp3`));
}
console.log(`done, spent ${ledger.spent} credits`);

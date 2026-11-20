/* Record "It's a Fox!" for every friend with ElevenLabs text-to-speech.
 *
 *   ELEVENLABS_API_KEY=… node tools/gen-voice.js <takesDir> [--budget 3000]
 *
 * Uses the same ledger and budget as tools/gen-sounds.js and never re-records a
 * line it already has. The voice and its settings are fixed here so lines match.
 */
const fs = require('fs'), path = require('path');
const { execFileSync } = require('child_process');
global.window = { GC: {} };
const args = process.argv.slice(2), dir = args[0];
if (!dir) { console.error('usage: node tools/gen-voice.js <takesDir> [--budget 3000]'); process.exit(1); }
const i = args.indexOf('--budget'), BUDGET = i > 0 ? +args[i + 1] : 3000;
const VOICE = 'cgSgspJ2msm6clMCkdW9'; // "Jessica": bright, playful
const MODEL = 'eleven_multilingual_v2';
const SETTINGS = { stability: 0.45, similarity_boost: 0.75, style: 0.35, use_speaker_boost: true };
const KEY = process.env.ELEVENLABS_API_KEY || 'proxy-injected';

// the friend names, read from the app itself so they can never drift
const src = fs.readFileSync(path.join(__dirname, '..', 'js', 'animals.js'), 'utf8');
const names = [...src.matchAll(/\{ id: '([a-z]+)', name: '([^']+)'/g)].map((m) => ({ id: m[1], name: m[2] }));
// "an Owl", "an Elephant", but "a Unicorn" (it starts with a "you" sound)
const article = (n) => (/^[aeiou]/i.test(n) && !/^(uni|use|eu)/i.test(n) ? 'an' : 'a');
const lines = names.map((a) => ({ id: a.id, text: `It's ${article(a.name)} ${a.name}!` })).concat([{ id: 'peekaboo', text: 'Peekaboo!' }]);

fs.mkdirSync(path.join(dir, 'voice'), { recursive: true });
const ledgerPath = path.join(dir, 'ledger.json');
const ledger = fs.existsSync(ledgerPath) ? JSON.parse(fs.readFileSync(ledgerPath, 'utf8')) : { spent: 0, requests: [] };
for (const l of lines) {
  const out = path.join(dir, 'voice', `${l.id}.mp3`);
  if (fs.existsSync(out)) continue;
  const worst = l.text.length * 2;
  if (ledger.spent + worst > BUDGET) { console.log(`STOP: budget ${BUDGET} would be exceeded (spent ${ledger.spent})`); process.exit(2); }
  const hdr = out + '.headers';
  const code = execFileSync('curl', ['-sS', '-X', 'POST', `https://api.elevenlabs.io/v1/text-to-speech/${VOICE}?output_format=mp3_44100_64`,
    '-H', 'Content-Type: application/json', '-H', `xi-api-key: ${KEY}`,
    '--data-binary', JSON.stringify({ text: l.text, model_id: MODEL, voice_settings: SETTINGS }),
    '-D', hdr, '-o', out + '.part', '-w', '%{http_code}'], { encoding: 'utf8' }).trim();
  const h = fs.readFileSync(hdr, 'utf8'); fs.unlinkSync(hdr);
  const cost = +((h.match(/^character-cost:\s*(\d+)/im) || [])[1] || 0);
  if (code !== '200') { console.log(`FAIL ${l.id}: HTTP ${code} ${fs.readFileSync(out + '.part', 'utf8').slice(0, 300)}`); fs.unlinkSync(out + '.part'); process.exit(3); }
  fs.renameSync(out + '.part', out);
  // re-read the ledger: gen-sounds.js may be writing to it at the same time
  const now = fs.existsSync(ledgerPath) ? JSON.parse(fs.readFileSync(ledgerPath, 'utf8')) : ledger;
  now.spent += cost || worst; now.requests.push({ id: 'voice-' + l.id, text: l.text, cost: cost || null });
  fs.writeFileSync(ledgerPath, JSON.stringify(now, null, 1)); Object.assign(ledger, now);
  console.log(`${l.id.padEnd(9)} "${l.text}"  cost ${cost}  (spent ${ledger.spent})`);
}
console.log(`done, spent ${ledger.spent} credits`);

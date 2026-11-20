/* Generate the recorded animal calls with the ElevenLabs Sound Effects API.
 *
 *   ELEVENLABS_API_KEY=… node tools/gen-sounds.js <takesDir> [--takes 2] [--budget 3000] [--only moo,quack]
 *                                             [--manifest tools/karaoke.json]
 *
 * - Prompts live in tools/sounds.json (or --manifest). Raw takes go to <takesDir> (not the repo).
 *   Ids may contain a slash (inst/marimba); the take is saved as inst_marimba-1.mp3.
 * - Never re-requests a take that already exists, so re-running costs nothing extra.
 * - Reads the credit cost of every request from the API's Character-Cost header,
 *   keeps a running ledger in <takesDir>/ledger.json, and stops before --budget.
 * Then run tools/pick-sounds.js to trim, level and copy the chosen takes into sounds/.
 */
const fs = require('fs'), path = require('path');
const { execFileSync } = require('child_process');
const args = process.argv.slice(2);
const dir = args[0];
if (!dir) { console.error('usage: node tools/gen-sounds.js <takesDir> [--takes 2] [--budget 3000] [--only a,b]'); process.exit(1); }
const opt = (n, d) => { const i = args.indexOf('--' + n); return i > 0 ? args[i + 1] : d; };
const TAKES = +opt('takes', 2), BUDGET = +opt('budget', 3000);
const only = opt('only', '') ? opt('only', '').split(',') : null;
const fileId = (id) => id.replace(/\//g, '_');
const man = JSON.parse(fs.readFileSync(opt('manifest', path.join(__dirname, 'sounds.json')), 'utf8'));
fs.mkdirSync(dir, { recursive: true });
const ledgerPath = path.join(dir, 'ledger.json');
const ledger = fs.existsSync(ledgerPath) ? JSON.parse(fs.readFileSync(ledgerPath, 'utf8')) : { spent: 0, requests: [] };
const save = () => fs.writeFileSync(ledgerPath, JSON.stringify(ledger, null, 1));
const KEY = process.env.ELEVENLABS_API_KEY || 'proxy-injected';

for (const s of man.sounds) {
  if (only && !only.includes(s.id)) continue;
  for (let take = 1; take <= TAKES; take++) {
    const out = path.join(dir, `${fileId(s.id)}-${take}.mp3`);
    if (fs.existsSync(out)) continue;
    // worst case for this request, so one call can never cross the budget
    const worst = Math.max(20, Math.ceil(s.s * 40));
    if (ledger.spent + worst > BUDGET) { console.log(`STOP: budget ${BUDGET} would be exceeded (spent ${ledger.spent})`); save(); process.exit(2); }
    const body = JSON.stringify({ text: `${s.prompt}, ${(s.inst && man.commonInst) || man.common}`, duration_seconds: s.s, prompt_influence: 0.6 });
    const hdr = out + '.headers';
    const code = execFileSync('curl', ['-sS', '-X', 'POST', 'https://api.elevenlabs.io/v1/sound-generation',
      '-H', 'Content-Type: application/json', '-H', `xi-api-key: ${KEY}`, '--data-binary', body,
      '-D', hdr, '-o', out + '.part', '-w', '%{http_code}'], { encoding: 'utf8' }).trim();
    const h = fs.readFileSync(hdr, 'utf8'); fs.unlinkSync(hdr);
    const cost = +((h.match(/character-cost:\s*(\d+)/i) || [])[1] || 0);
    if (code !== '200') {
      const err = fs.readFileSync(out + '.part', 'utf8').slice(0, 300); fs.unlinkSync(out + '.part');
      console.log(`FAIL ${s.id}-${take}: HTTP ${code} ${err}`); save(); process.exit(3);
    }
    fs.renameSync(out + '.part', out);
    ledger.spent += cost || worst; // if the header ever goes missing, count the worst case
    ledger.requests.push({ id: s.id, take, seconds: s.s, cost: cost || null });
    save();
    console.log(`${s.id}-${take}  ${s.s}s  cost ${cost}  (spent ${ledger.spent})`);
  }
}
console.log(`done, spent ${ledger.spent} credits`);

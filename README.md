# Get Cracking

A visual timer for little ones that doesn't use words. The countdown runs around an egg that cracks as time passes. When time is up, the egg hatches into an animated friend who joins a little band for a song instead of an alarm.

- **40 hatchable friends**, all drawn in SVG from one parametric chibi renderer. A shuffle bag makes sure every friend appears once before any repeats.
- **10 illustrated worlds**: isometric cut-away dioramas with burrows, sleepy critters and looping ambient animation (fireflies, snow, leaves, bubbles).
- **Custom photos** can hatch from the egg instead of an animal, or mixed in with them.
- **Egg karaoke** (the default hatching song): a little band plays an original ~19-second tune, and the friend who just hatched is one of the players. The tune passes between instruments; the friend adds off-beat stabs and its second sound (a purr, a snort, a splash…) in the verse, sings the hook with the lead instrument in the chorus, and takes a short solo break. Each world (meadow, woodland, jungle, water or magic) has its own band of recorded instruments.
- **Animal bands** for the hatch: three ~15-second celebration songs, each a full band plus a chorus of animal voices (moo, quack, baa, woof, meow, oink, ribbit, hoot, elephant trumpet, roar, neigh, rooster and more). The friend who just hatched always gets the solo, and tapping it afterwards makes it call again.
- **Real animal sounds and a real voice.** The animal calls, the egg crack and pop, "It's a Fox!" for every friend, and Egg karaoke's band and singing voices are recordings generated with ElevenLabs (`sounds/`, about 1.1 MB). Everything else is synthesised live with Web Audio, and the melodies are original.
- **Countdown music** (6 choices) and **hatching tunes** (Egg karaoke, 3 animal bands, 4 short jingles).
- **Runs fully offline.** No login, no account, no network requests, and nothing leaves the device. The recordings ship with the app and are cached for offline use like everything else.

## Run it

Open `index.html` in a browser; it works straight from disk. To get offline install (PWA), serve the folder over http(s):

```sh
python3 -m http.server 8000   # then open http://localhost:8000
```

On a phone or tablet, use **Add to Home Screen**. The service worker caches everything on the first visit.

## How it behaves

- **Setting the time:** the setup screen is an egg-timer dial. Twist (or tap) the ring to set whole minutes; one full turn is 60. The − / + buttons step 15 s below 3 minutes and 1 minute above, and repeat while held. Arrow keys work on the dial too (`buildDial`, `wireDial`, `stepTime` in `js/app.js`).
- **Cracking:** the egg cracks in 8 steps at fixed fractions of the timer (`STEP_AT` in `js/egg.js`). Each step runs the cracks further, branches new ones, and draws them all wider and deeper (`CRACK_W_BY_STEP`). Cracks never heal when time is added.
- **Clock:** a big mm:ss clock sits centred at the top of the timer screen. It can be hidden in settings ("Show the clock").
- **Ground ring:** the ring around the egg empties as time runs out, and its pebbles light up at each crack step (`buildRing` in `js/app.js`).
- **Idle egg:** it breathes, and wobbles more at later steps. Tapping it squashes it and never changes the timer.
- **Time's up:** a soft chime plays, never an alarm. With "Wait for a tap" (the default) the egg glows and knocks every 5 s for up to 5 minutes, and a tap anywhere hatches it (`timeUp()`).
- **Friend's name:** after the hatch, the recorded voice says "It's a Fox!" / "It's an Owl!" (or "Peekaboo!" for a photo) while the band dips under it. The device voice is only a fallback (`Sound.sayFriend`).
- **Hatch:** a shared squash-and-stretch, then the chosen hatch style breaks the shell (`js/shellfx.js`, `js/hatch/*.js`). The friend jumps out, lands and loops idle animations. Tapping it makes it jump again and say hello in its own voice (`Sound.friendCall`).
- **Egg karaoke** (`js/karaoke.js`), the default hatching song:
  - *Shape:* a count-in on the sticks while the friend says hello. In the verse, the lead instrument plays the first line and a second instrument takes the next, with a soft counter-line under each. The friend plays off-beat stabs on the chord and answers with its extra sound, and the band chirps back and echoes. In the chorus the whole band plays (tune, counter-melody, sparkle up high) and the friend sings the hook with the lead. Then a stop for the friend's solo break (its full call) and a "ta-daaa" with everyone.
  - *The friend's part:* each friend has a short recorded syllable (`sounds/karaoke/sing/`) whose pitch was measured when it was picked; friends with no call of their own (turtle, mole, snail, axolotl, ladybug) hum instead. The app moves it by whole octaves to sit near its natural pitch, then tunes every note with `playbackRate`. It is mixed level with the instruments: one part in the band, not a soloist on top.
  - *The worlds:* meadow (piano lead, flute, ukulele, upright bass, claps, egg shaker, wood block, glockenspiel, cheeps and slide whistle), woodland (flute lead, kalimba, harp, upright bass, wood block, birdsong trills), jungle (steel pan lead, marimba, tuba oom-pah, bongos, parrot whistles), water (kalimba lead, glockenspiel, piano, flute, soft snare, bubble bloops) and magic (harp lead, flute, piano, tuba, glockenspiel, sparkles). The chirps and tones always play the current chord's notes.
  - *Band:* every instrument is one recorded note (`sounds/karaoke/inst/`) pitched to each note of the song, so it is always in time and in key.
  - *Fallback:* anything not loaded yet, or the app opened from disk, plays on the synth kit from `band.js` instead (the voice too), so the song always works. The choice is made once at the start, so a song never switches voice halfway.
  - *On screen:* the friend bops on every note it sings and music notes float up (`Egg.sing`). Reduced motion turns this off.
- **Animal bands** (`js/band.js`): every song has the same shape so children learn it: intro, four bars where the band plays a line and an animal answers, two bars where the animals sing the tune, everyone cheers, the hatched friend's solo, then a big ta-da chord. The answering animals are shuffled each time.
  - *Animal band*: a proper marching band. It opens with the drum major's whistle and a snare roll, then plays a dotted march tune on trumpets (with a harmony line) over tuba oom-pah, trombones, French horns, marching bass drum, flammed snare, hand cymbals, glockenspiel and a piccolo. A kazoo joins the animal choir, the finale steps up a key, and it ends "ta-daaa… bum-BUM!"
  - *Jungle jam*: steel drum, marimba, ukulele, bongos, shaker, claves, bass, pan flute; monkeys, elephants, parrots, frogs, lions
  - *Farmyard hoedown*: fiddle, banjo, harmonica, jug, washboard, cowbell, hand claps, slide whistle; cows, sheep, pigs, ducks, dogs, horses, goats and a rooster to start
  - Each of the 40 friends has a call (`FRIEND_CALL`). The voices are one small synth (`_voice`: oscillators → vowel formant filters → tremolo/vibrato), so the same moo can be a cow or a calf, and the animals can sing pitched notes.
  - Songs are scheduled a little ahead at a time, like the countdown music, so the hatch animation stays smooth and the song stops at once on New egg / Stop. The band ducks while the device voice says the friend's name.
- **Countdown music:** gains an extra twinkle in the last 10% of the timer (`Sound.setTension`).
- **Grown-up controls:** Pause, ±1 min, Hatch now, New egg and Stop sit behind the lock button. It needs a press-and-hold (1–3 s); a quick tap only shows a reminder (`holdable()`). Escape opens it on a keyboard. On-screen pause and ±1 buttons are optional.
- **Also:** an optional "Next up" card after the hatch, the screen kept awake during a run (Wake Lock), and a friend book that collects every animal hatched.

## Files

```
index.html            setup screen + timer screen + sheets
css/app.css           visual language and every animation loop
js/util.js            helpers, seeded RNG, shuffle bag
js/icons.js           every UI icon, drawn in SVG (no emoji)
js/animals.js         the 40 friends + photo "friend"
js/egg.js             egg, crack stages, hatch choreography
js/shellfx.js         hatch-style registry + the contract every style follows
js/hatch/*.js         one file per hatch style (roll, boom, crumble)
js/scenes.js          the 10 diorama worlds + ambient particles
js/samples.js         loads the recorded sounds in sounds/ (falls back to synth if missing)
js/audio.js           Web Audio music, sfx, short end jingles, the friend's name
js/band.js            the three animal bands: instruments, animal voices, songs; the shared song player
js/karaoke.js         Egg karaoke: the friend sings, five world arrangements
js/store.js           localStorage settings / friend book, IndexedDB photos
js/app.js             timer state machine, gestures, settings UI
sw.js, manifest.webmanifest, icons/   offline PWA
sounds/               recorded animal calls + effects; sounds/voice/ "It's a …!" lines;
                      sounds/karaoke/ the karaoke band (inst/), voices (sing/) and ad-libs (extra/); index.json
tools/*.html          dev contact sheets for checking every animal / scene
tools/sounds.json     the prompt (and chosen take) for every recorded sound
tools/karaoke.json    the prompt for every Egg karaoke recording
tools/gen-sounds.js   generate sounds with ElevenLabs (budget-capped, never re-buys; --manifest for karaoke)
tools/gen-voice.js    record "It's a …!" for every friend with ElevenLabs
tools/pick-sounds.js  trim, level and encode the chosen takes into sounds/
tools/pick-karaoke.js score every karaoke take, keep the best, measure its pitch, write sounds/karaoke/
tools/level.js        shared trim/level/encode, plus onset and YIN pitch measurement
tools/hatch-lab.html  play any hatch style, in slow motion if needed
tools/hatch-snap.js   node tools/hatch-snap.js <style> out.png: a 16-frame contact sheet of a hatch
```

## Tests

These use the Playwright and Chromium that come with the dev environment. No install step is needed.

```sh
node tests/timer.test.js            # fake-clock timer stress test (~10 min)
node tests/audio.test.js out/       # renders every tune + track to WAV and checks them
node tests/hatch.test.js out/       # every hatch style in the real app, CPU throttled 4×
```

- **Timer:** finishes within 50 ms on a 5-minute timer. Every crack lands within 8 ms of its landmark. Also covers a 60-minute run, pause and resume, ±1 minute with a 5-second floor, the tap-to-hatch wait, a throttled hidden tab, and start/stop abuse.
- **Audio:**
  - the tunes don't clip, they fully decay (no stuck notes), and there are no silent gaps in the music
  - every animal band renders with 5 different friends: no clipping, no dead air, every note plays, the right friend takes the solo; live, a stall skips notes instead of bursting, a new song/jingle/egg stops the old one, and Stop is silent at once
  - Egg karaoke renders for a friend from every world, both on the synth fallback and (served over http) with the recordings: no clipping, no dead air, every note plays, the hatched friend sings the tune and ends on its own call, and every one of the 99 karaoke recordings loads and decodes
  - the final-stretch twinkle is there
  - notes land exactly on the beat, and a 700 ms stall doesn't produce a burst of missed notes
  - double-starting the music never doubles the notes
  - pause and stop are silent
- **Hatch:**
  - 5 rapid taps give exactly 1 hatch, 1 pop and 1 tune, and no shell covers the friend after it lands
  - frame pacing holds on a slow CPU
  - stopping mid-hatch is clean, and the DOM doesn't grow over 15 back-to-back hatches
  - the reduced-motion versions finish in under 1.5 s
  - in the real app, Egg karaoke is the default: the friend sings in its recorded voice, its extra sound and call play, the band is the recorded instruments, and the friend bops along

## Adding a hatch style

Hatch styles are interchangeable plug-ins. Each file in `js/hatch/` calls `GC.ShellFX.register({ id, name, icon, run(ctx) })`, where `icon` names a drawing in `js/icons.js`, and follows the contract documented at the top of `js/shellfx.js`:

- build shell pieces with `ctx.piece(polygon)`
- call `ctx.release()` when the friend should spring out
- animate only through `ctx.animate` and wait only through `ctx.wait`, so slow motion works
- keep pieces off the friend once it has landed

Because no style touches shared code, several can be built in parallel. Add the new script tag to `index.html`, `tools/hatch-lab.html` and the `sw.js` file list, and it shows up in settings automatically.

## Recorded sounds

The animal calls, egg crack, shell pop and the "It's a Fox!" voice (ElevenLabs voice "Jessica") were generated once with ElevenLabs and are committed in `sounds/`. The app never contacts ElevenLabs. To change or add one:

```sh
export ELEVENLABS_API_KEY=…                           # needs Sound Effects + Text to Speech access
node tools/gen-sounds.js takes/ --takes 2 --budget 3000  # new prompts in tools/sounds.json
node tools/gen-voice.js takes/                           # a line for any new friend in js/animals.js
node tools/pick-sounds.js takes/                         # set "take" in sounds.json first
```

The generators read each request's cost from the API, keep a ledger in `takes/ledger.json`, stop before `--budget` and never re-request a take they already have. Sound effects cost 10 credits per second and a voice line about 5. Generating everything once (two takes of each sound, 41 voice lines) cost under 1,000 credits.

Every recording has a synthesised stand-in, which plays until it loads, or always when the app is opened straight from disk (browsers won't fetch files there). The animal choir in the three bands stays synthesised.

### Egg karaoke recordings

Egg karaoke's 19 instrument notes, 40 singing syllables and 40 extra sounds were made with ElevenLabs Sound Effects from the prompts in `tools/karaoke.json` (3 takes of each note and syllable, 2 of each extra, plus cartoon hums for the five quiet friends; about 1,960 credits). The picker scores every take and keeps the best one. It rejects takes that came back silent, prefers one clean onset and a steady pitch, and measures the pitch the app tunes from. Pin a take with `"take": n` in the manifest if your ears disagree, or set `"fromTake": n` after changing a prompt so older takes are ignored.

```sh
node tools/gen-sounds.js takes/ --manifest tools/karaoke.json --takes 3 --budget 2500
node tools/pick-karaoke.js takes/      # writes sounds/karaoke/ and the karaoke section of sounds/index.json
```

The full song could not be made with ElevenLabs Music: the API key used here doesn't have the `music_generation` permission. Building the song from recorded notes also keeps the singer exactly in time and in tune with the band, which a pre-mixed track couldn't.

## Not possible on the web (yet)

The **Lock Screen / Live Activity** timer that reviewers asked for needs a native iOS or Android wrapper. The state machine in `app.js` is built so it can be ported to one.

## Credits

Animal sounds, effects, voice lines and Egg karaoke's instruments and voices: generated with [ElevenLabs](https://elevenlabs.io) (Sound Effects and Text to Speech). Check that your ElevenLabs plan's terms cover how you publish the app.

Fonts: [Fredoka](https://fonts.google.com/specimen/Fredoka) and [Patrick Hand SC](https://fonts.google.com/specimen/Patrick+Hand+SC), both under the SIL Open Font License, bundled in `fonts/` so the app works offline.

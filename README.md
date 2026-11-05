# Get Cracking 🥚

A visual timer for little ones that doesn't use words. The countdown runs around an egg that cracks as time passes. When time is up, the egg hatches into an animated friend and a cheerful tune plays instead of an alarm.

- **40 hatchable friends**, all drawn in SVG from one parametric chibi renderer. A shuffle bag makes sure every friend appears once before any repeats.
- **10 illustrated worlds**: isometric cut-away dioramas with burrows, sleepy critters and looping ambient animation (fireflies, snow, leaves, bubbles).
- **Custom photos** can hatch from the egg instead of an animal, or mixed in with them.
- **Countdown music** (6 choices) and **hatching tunes** (4 choices). All of it is synthesised live with Web Audio, and the melodies are original.
- **Runs fully offline.** No login, no account, no network requests, and nothing leaves the device.

## Run it

Open `index.html` in a browser; it works straight from disk. To get offline install (PWA), serve the folder over http(s):

```sh
python3 -m http.server 8000   # then open http://localhost:8000
```

On a phone or tablet, use **Add to Home Screen**. The service worker caches everything on the first visit.

## How it behaves

- **Cracking:** the egg cracks in 8 steps at fixed fractions of the timer (`STEP_AT` in `js/egg.js`). Cracks never heal when time is added.
- **Ground ring:** the ring around the egg empties as time runs out, and its pebbles light up at each crack step (`buildRing` in `js/app.js`).
- **Idle egg:** it breathes, and wobbles more at later steps. Tapping it squashes it and never changes the timer.
- **Time's up:** a soft chime plays, never an alarm. With "Wait for a tap" (the default) the egg glows and knocks every 5 s for up to 5 minutes, and a tap anywhere hatches it (`timeUp()`).
- **Hatch:** a shared squash-and-stretch, then the chosen hatch style breaks the shell (`js/shellfx.js`, `js/hatch/*.js`). The friend jumps out, lands and loops idle animations. Tapping it makes it jump again.
- **Countdown music:** gains an extra twinkle in the last 10% of the timer (`Sound.setTension`).
- **Grown-up controls:** Pause, ±1 min, Hatch now, New egg and Stop sit behind the 🔒. It needs a press-and-hold (1–3 s); a quick tap only shows a reminder (`holdable()`). Escape opens it on a keyboard. On-screen pause and ±1 buttons are optional.
- **Also:** an optional "Next up" card after the hatch, the screen kept awake during a run (Wake Lock), and a friend book that collects every animal hatched.

## Files

```
index.html            setup screen + timer screen + sheets
css/app.css           visual language and every animation loop
js/util.js            helpers, seeded RNG, shuffle bag
js/animals.js         the 40 friends + photo "friend"
js/egg.js             egg, crack stages, hatch choreography
js/shellfx.js         hatch-style registry + the contract every style follows
js/hatch/*.js         one file per hatch style (roll, boom, crumble)
js/scenes.js          the 10 diorama worlds + ambient particles
js/audio.js           Web Audio music, sfx, end tunes, speech
js/store.js           localStorage settings / friend book, IndexedDB photos
js/app.js             timer state machine, gestures, settings UI
sw.js, manifest.webmanifest, icons/   offline PWA
tools/*.html          dev contact sheets for checking every animal / scene
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
  - the final-stretch twinkle is there
  - notes land exactly on the beat, and a 700 ms stall doesn't produce a burst of missed notes
  - double-starting the music never doubles the notes
  - pause and stop are silent
- **Hatch:**
  - 5 rapid taps give exactly 1 hatch, 1 pop and 1 tune, and no shell covers the friend after it lands
  - frame pacing holds on a slow CPU
  - stopping mid-hatch is clean, and the DOM doesn't grow over 15 back-to-back hatches
  - the reduced-motion versions finish in under 1.5 s

## Adding a hatch style

Hatch styles are interchangeable plug-ins. Each file in `js/hatch/` calls `GC.ShellFX.register({ id, name, icon, run(ctx) })` and follows the contract documented at the top of `js/shellfx.js`:

- build shell pieces with `ctx.piece(polygon)`
- call `ctx.release()` when the friend should spring out
- animate only through `ctx.animate` and wait only through `ctx.wait`, so slow motion works
- keep pieces off the friend once it has landed

Because no style touches shared code, several can be built in parallel. Add the new script tag to `index.html`, `tools/hatch-lab.html` and the `sw.js` file list, and it shows up in settings automatically.

## Not possible on the web (yet)

The **Lock Screen / Live Activity** timer that reviewers asked for needs a native iOS or Android wrapper. The state machine in `app.js` is built so it can be ported to one.

## Credits

Fonts: [Fredoka](https://fonts.google.com/specimen/Fredoka) and [Patrick Hand SC](https://fonts.google.com/specimen/Patrick+Hand+SC), both under the SIL Open Font License, bundled in `fonts/` so the app works offline.

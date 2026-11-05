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

## How the design decisions map to code

| Idea | Where |
| --- | --- |
| **The egg is the progress bar.** It cracks in 8 stepped landmarks: a hairline crack, then the main zig-zag crack in 4 steps, then a peek-hole with eyes, then light leaking out, then extra cracks while the egg hops. Cracks never heal, even if time is added. | `js/egg.js` (`STEP_AT`, `setStep`) |
| **A continuous cue as well.** A ground ring on the diorama empties as time runs out. Its pebbles light up at each crack step, so the ring and the egg tell the same story. | `buildRing` in `js/app.js` |
| **The idle egg is alive.** It breathes, and its wobbles get bigger at each stage. Tapping it gives a harmless "boop" and never changes the timer. | CSS `egg-breathe / egg-wobble / egg-hop` |
| **The hatch.** Squash for anticipation, stretch, the lid flies off, the friend peeks out of the shell (clipped to the shell rim), then hops out in front with a squash-and-settle bounce. | `Egg.hatch()` |
| **Shells that do something physical.** After a shared squash-and-stretch, the intact egg is swapped for loose shell pieces and a *hatch style* takes over: **Roll away**, **Kaboom** or **Crumble** (the Looney Tunes falling-teeth gag). Grown-ups can pick one or let it be a surprise, and preview each one in settings. | `js/shellfx.js`, `js/hatch/*.js` |
| **The reward lingers.** After hatching, the friend loops hops, blinks, waves and wags. Tapping it makes it jump again. | CSS `.idle …` |
| **Ending on a celebration.** Time's up plays a soft sparkle, never an alarm. The full tune plays on the hatch. | `Sound.ready()`, `Sound.endTune()` |
| **Sound as a time cue.** Ambient music signals that something is in progress. It gains a twinkle layer in the final 10%. | `Sound.setTension()` |
| **The hatch waits for you.** By default the egg glows, wiggles and gently knocks until the child taps it, so nobody misses the payoff. A tap anywhere on the screen counts. | `timeUp()` |
| **Touch safety.** No tempting buttons on the timer screen. Grown-up controls sit behind a dim 🔒 that needs a press-and-hold (1–3 s, configurable). A quick tap only shows a "Grown-ups: press & hold" tip, so the gesture teaches itself. Pause and ±1 minute buttons can be shown if a family wants them. | `holdable()`, the tray |
| **A parent exit is always there.** The 🔒 tray has Pause, ±1 min, Hatch now, New egg and Stop. Escape opens it on a keyboard. | `wireTimer()` |
| **Next up card.** After the hatch, an optional card shows what comes next (an emoji or a photo of the bath, the reading corner and so on), which turns the reward into a transition cue. | `secNext()` |
| **Screen stays on** during a run (Wake Lock), with optional fullscreen. | `keepAwake()` |
| **Friend book.** A sticker-book collection of everyone who has hatched. | `secBook()` |

`prefers-reduced-motion` turns off the ambient loops and shortens the hatch.

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

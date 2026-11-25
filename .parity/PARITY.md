# Parity: Get Cracking web (main) ↔ iPhone (ios-swiftui)

**Direction: web → iPhone only.** Ports are made on `parity/to-mac-*` branches cut from `ios-swiftui` and opened as draft PRs into `ios-swiftui`. Nothing is ever ported, opened or merged into `main`. iPhone-only changes are recorded here, never ported back.

**Never merge the SwiftUI branch.** Claude never merges `ios-swiftui` anywhere, and never merges a port PR into it: the owner reviews, builds in Xcode and merges every `parity/to-mac-*` PR themselves. (The skill calls the native side "mac"; here it is the iPhone app, iOS 17.)

**Where these notes live.** The repo has two real branches: `main` (the web app, live on Vercel) and `ios-swiftui` (the Swift app for the App Store). These notes live in `ios-swiftui:.parity/` (outside `GetCracking/`, so they never ship in the app). Claude never commits to `ios-swiftui`, so each notes update rides in its port PR (`parity/to-mac-*`) and lands when the owner merges it. There is no `parity-state` branch on GitHub any more.

The shared parity script reads its state from a `parity-state` branch, so each run builds a local, never-pushed one from the newest notes: the newest unmerged `origin/parity/to-mac-*` branch if there is one, otherwise `origin/ios-swiftui`:

```bash
src=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' 'refs/remotes/origin/parity/to-mac-*' | head -1)
[ -n "$src" ] && git cat-file -e "$src:.parity/config" 2>/dev/null || src=origin/ios-swiftui
git branch -f parity-state "$(git commit-tree "$src:.parity" -m "parity: local copy of $src:.parity")"
```

To update the notes, edit `.parity/` on the port branch and commit as `parity: state [<port branch>]`; never push `parity-state`.

Baseline: the iPhone app was ported from web commit `c4600dd`, so web tracking starts there. The next sync picks up everything `main` has gained since.

## Features

| Feature | web | mac | notes |
|---|---|---|---|
| Timer | done | done | state machine, pause, ±1 min with a 5 s floor, tap-to-hatch wait, keep screen awake |
| Setup screen | done | done | egg-timer dial from 2f810aa: `UI/SetupView.swift`, rules in `Model/TimeDial.swift` (parity/to-mac-20261123-ui). Keyboard keys → VoiceOver adjust; no landscape layout (portrait-only app) |
| Timer screen | done | done | big centred mm:ss clock from 982859f, frozen time on pause (c4600dd) |
| Drawn icons | done | done | js/icons.js → `Art/Icons.swift` (54 icons as path data) + `UI/IconView.swift`; iPhone-only extra: a nest icon for The Whole Nest |
| Egg and cracking | done | done | plain deepening cracks (STEP_AT, MAIN_LEN_BY_STEP, CRACK_W_BY_STEP) in `Art/EggArt.swift`. Hatch styles get `ctx.clear`, the friend's own keep-clear box (web fix in claude/epic-hypatia-3w52rk) |
| Hatch styles | done | done | Roll away, Kaboom, Crumble |
| 40 friends | done | done | the Classic pack |
| 10 worlds | done | done | |
| Photo friends | done | done | IndexedDB on web, PhotosPicker on iPhone |
| Friend book | done | done | |
| Next-up card | done | done | |
| Grown-up tray | done | done | hold-to-open |
| Music and sounds | done | done | countdown music, effects, 4 end jingles |
| Animal bands | done | done | Animal band, Jungle jam, Farmyard hoedown; friend solo; tap the friend for its call. Ported in parity/to-mac-20261120-0720 (not compile-checked) |
| Recorded sounds | done | done | 37 ElevenLabs animal calls + crack + pop; "It's a Fox!" voice lines (device voice only as fallback); "a/an" names. Ported in parity/to-mac-20261120-0720 |
| Settings and storage | done | done | |
| Visual style | done | done | |
| Shared helpers | done | done | |
| Offline / install | done | n/a | PWA service worker on web; a native app is offline by nature |
| Egg karaoke | done | done | web 464ee4e..0fbc670 plus the pack worlds (bush, jingle). Ported in parity/to-mac-20261123-karaoke (merged into -store): `Audio/Karaoke.swift`, `KaraokeData.swift`, `KaraokeIndex.swift` (generated from sounds/index.json), `UI/SingBop.swift`. Mono (no panning); the app's own compressor and reverb. Free, and the default song. `Tests/KaraokeChecks` compares keys and bends with the web |
| Content packs | done | done | web 8e30287 (js/packs.js). iPhone: `Monetization/Packs.swift` registry, per-pack toggles (`Settings.packsOff`), friend book grouped by pack |
| Aussie Bush pack | done | done | web js/packs/aussie.js → `Art/Packs/AussieArt.swift`, `AussieWorlds.swift` (parity/to-mac-20261123-packart); audio in -karaoke. `Tests/ArtChecks` pixel-matched the web renders in CI |
| Christmas pack | done | done | web js/packs/christmas.js → `Art/Packs/ChristmasArt.swift`, `ChristmasWorld.swift`; audio in -karaoke |
| The Whole Nest | n/a | done | iPhone-only, never ported back: the web stays free in full. One A$5.99 non-consumable (`com.glorptraag.getcracking.wholenest`) unlocks all friends, worlds, songs, unlimited photo friends and every pack; free tier = timer, 12 starter friends, 3 worlds, Egg karaoke, Animal band + jingles, 1 photo friend. Parental gate, locks in pickers and friend book. See MONETIZATION.md and APP_STORE.md (parity/to-mac-20261123-store) |

## Idioms

- Ports land on a branch from the web commit they came from; the web sync point only moves once every web change before it is handled. Run 1 (2026-11-20) ported the audio commits (9e02873, cf0f7fb, 3866e54) and deferred 982859f and 2f810aa, so WEB_SYNCED stayed at c4600dd. The next run lists those audio files again: classify them as already matched.
- Web Audio node graph (oscillators, BiquadFilters, gains) → voices rendered sample by sample in the Synth render callback (`SynthVoice`, `VSpec` in Audio/Sound.swift). The band's lookahead pump → `Celebration` events run inside the render callback, under the same lock.
- Web stereo panning (StereoPannerNode) → dropped: the iPhone synth renders mono. Channel levels are kept (`Kit.g`).
- Web ConvolverNode room → a small Schroeder reverb (`Room`).
- Recordings: `sounds/<id>.mp3` → `Resources/Sounds/call-<id>.mp3`, `sounds/voice/<id>.mp3` → `voice-<id>.mp3` (the synchronised folder flattens into the bundle, so names must not collide). The parity script filters .mp3 as noise: copy new or changed recordings by hand when sounds/ changes. Egg karaoke: `sounds/karaoke/inst|sing|extra/<id>.mp3` → `kinst-<id>.mp3`, `ksing-<id>.mp3`, `kextra-<id>.mp3`; regenerate `Audio/KaraokeIndex.swift` from the `karaoke` section of sounds/index.json.
- Web pack parts (`GC.Animals.parts.<layer>[name]`) → `AnimalParts` / `PartKit` in Art/Animals.swift, one function per part (big closures time out the Swift compiler); each pack's art lives in `Art/Packs/<Pack>Art.swift` and `<Pack>World(s).swift`, and its `Pack` entry in Monetization/Packs.swift.

- Web SVG drawing → the iPhone app's own vector scene graph (`Core/VNode.swift`, `Core/Renderer.swift`, SwiftUI `Canvas`); port drawings as path data, don't rasterise.
- Web Audio synth → `AVAudioEngine` synth in `Audio/Sound.swift`; `speechSynthesis` → `AVSpeechSynthesizer`.
- `localStorage` → `Model/Store.swift`; IndexedDB photos → on-device files via `PhotosPicker`.
- Wake Lock → `UIApplication.shared.isIdleTimerDisabled`.
- Build check: `xcodebuild -scheme GetCracking -destination 'generic/platform=iOS Simulator'` (needs a Mac). Cloud runs compile-check on GitHub's macOS runner: `.github/workflows/getcracking-ios-build.yml` builds every push to a branch that touches the app (from parity/to-mac-20261123-store on), and runs `Tests/GateChecks` (StoreKit-free gate decisions).
- Never declare a module-wide `typealias` that shadows a SwiftUI or Foundation name: the audio port's `typealias Path` hid SwiftUI's `Path` (now `PitchPath`).
- Web `starter: true` / `pack` on friends and worlds → `Packs.swift` (`Pack.starterFriends`, `starterScenes`); `GC.Packs.register` → a new `Pack` entry in `Packs.list` plus the art. Store gating (`FeatureGate`) is iPhone-only.
- Fredoka has no tabular figures, so `monospacedDigit()` (and the web's `font-variant-numeric: tabular-nums`) does nothing: the iPhone clock draws each digit in a fixed-width cell (`ClockDigits` in UI/TimerView.swift). The web clock still changes width every second (147 px at 1:11, 182 px at 0:08 on a 390 px phone); fix it there and record the port as already matched.

## iPhone-only polish (pre-launch pass)

- Launch screen is the `LaunchBackground` colour (the dimmed setup screen's average tone) instead of a white flash: `UILaunchScreen` in Config/Info.plist.
- The audio engine is restarted when the app returns to the foreground during a run (RootView), so the countdown music never stays silent.
- The "It's a Fox!" line is decoded off the main thread when the hatch starts (`Sound.preloadFriend`).

# Parity: Get Cracking web (main) ↔ iPhone (ios-swiftui)

**Direction: web → iPhone only.** Ports are made on `parity/to-mac-*` branches cut from `ios-swiftui` and opened as draft PRs into `ios-swiftui`. Nothing is ever ported, opened or merged into `main`. iPhone-only changes are recorded here, never ported back. (The skill calls the native side "mac"; here it is the iPhone app, iOS 17.)

Baseline: the iPhone app was ported from web commit `c4600dd`, so web tracking starts there. The next sync picks up everything `main` has gained since.

## Features

| Feature | web | mac | notes |
|---|---|---|---|
| Timer | done | done | state machine, pause, ±1 min with a 5 s floor, tap-to-hatch wait, keep screen awake |
| Setup screen | done | partial | web has the egg-timer dial (twist ring, −/+ hold-repeat, arrow keys) from 2f810aa; iPhone still has digit dials, a minute slider and presets |
| Timer screen | done | partial | web has the big centred mm:ss clock from 982859f; iPhone has the older time pill |
| Drawn icons | done | missing | web replaced emoji with drawn icons (js/icons.js, 982859f); the iPhone app was ported before that |
| Egg and cracking | done | partial | web has plain deepening cracks (CRACK_W_BY_STEP, 982859f); iPhone has the earlier crack style |
| Hatch styles | done | done | Roll away, Kaboom, Crumble |
| 40 friends | done | done | |
| 10 worlds | done | done | |
| Photo friends | done | done | IndexedDB on web, PhotosPicker on iPhone |
| Friend book | done | done | |
| Next-up card | done | done | |
| Grown-up tray | done | done | hold-to-open |
| Music and sounds | done | done | countdown music, effects, 4 end jingles; the name is said with the device voice on both |
| Settings and storage | done | done | |
| Visual style | done | done | |
| Shared helpers | done | done | |
| Offline / install | done | n/a | PWA service worker on web; a native app is offline by nature |

## Idioms

- Web SVG drawing → the iPhone app's own vector scene graph (`Core/VNode.swift`, `Core/Renderer.swift`, SwiftUI `Canvas`); port drawings as path data, don't rasterise.
- Web Audio synth → `AVAudioEngine` synth in `Audio/Sound.swift`; `speechSynthesis` → `AVSpeechSynthesizer`.
- `localStorage` → `Model/Store.swift`; IndexedDB photos → on-device files via `PhotosPicker`.
- Wake Lock → `UIApplication.shared.isIdleTimerDisabled`.
- Build check: `xcodebuild -scheme GetCracking -destination 'generic/platform=iOS Simulator'` (needs a Mac; cloud runs can't compile-check).

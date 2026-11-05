# Get Cracking 🥚 (iPhone app)

A visual timer for little ones that doesn't use words. The countdown runs around an egg that cracks as time passes. When time is up, the egg hatches into an animated friend and a cheerful tune plays instead of an alarm.

This branch is the **native SwiftUI iPhone app**, built for the App Store. It contains only the Xcode project; the original web/PWA version lives on `main`.

- **40 hatchable friends**, all drawn in vector from one parametric chibi renderer. A shuffle bag makes sure every friend appears once before any repeats.
- **10 illustrated worlds**: isometric cut-away dioramas with burrows, sleepy critters and looping ambient animation.
- **3 hatch styles** (Roll away, Kaboom, Crumble), plus "Surprise me".
- **Custom photos** can hatch from the egg instead of an animal, or mixed in with them.
- **Countdown music** (6 choices) and **hatching tunes** (4 choices), all synthesised live on the device. No audio files; the melodies are original.
- **Fully offline.** No login, no account, no ads, no network requests, no analytics. Settings, photos and the friend book stay on the device.

## Requirements

- Xcode 16 or newer (the project uses folder-synchronised groups).
- iOS 17.0 or newer. iPhone only, portrait.

## Run it

1. Open `GetCracking.xcodeproj`.
2. Select the **GetCracking** target → **Signing & Capabilities** → choose your **Team**.
3. Change the **Bundle Identifier** (`com.glorptraag.getcracking`) to one you own.
4. Pick an iPhone simulator or a device and press **Run**.

New Swift files dropped into `GetCracking/` are picked up automatically; there is no file list to maintain.

## Ship it to the App Store

1. In App Store Connect, create the app record with the same bundle ID.
2. In Xcode, set the version (`MARKETING_VERSION`, currently 1.0) and build number (`CURRENT_PROJECT_VERSION`).
3. **Product → Archive**, then **Distribute App → App Store Connect → Upload**.
4. In App Store Connect:
   - **App Privacy:** "Data Not Collected". The app makes no network requests and has no third-party SDKs.
   - **Age rating:** 4+.
   - **Export compliance:** already declared in `Config/Info.plist` (`ITSAppUsesNonExemptEncryption = NO`).
   - **Screenshots:** 6.9" and 6.5" iPhone screenshots are required. A 5-minute timer mid-crack and a freshly hatched friend show the app best.
   - If you list it in the **Kids** category, it already meets the main rules: no ads, no links out of the app, no purchases, no data collection, and the grown-up controls sit behind a press-and-hold.
5. Submit for review.

What's already set up for review:

- `GetCracking/Resources/PrivacyInfo.xcprivacy`: privacy manifest. It declares UserDefaults use (reason `CA92.1`) and no tracking.
- App icon at 1024 px, opaque, in `Assets.xcassets`.
- The photo picker is the system `PhotosPicker`, so the app never asks for photo-library permission.
- Audio uses the `.playback` session so the ring/silent switch doesn't mute the hatch tune, and it mixes with other audio rather than stopping it.

## How it behaves

- **Cracking:** the egg cracks in 8 steps at fixed fractions of the timer (`EggArt.stepAt`). Cracks never heal when time is added.
- **Ground ring:** the ring around the egg empties as time runs out, and its pebbles light up at each crack step (`Ring`).
- **Idle egg:** it breathes, and wobbles more at later steps. Tapping it squashes it and never changes the timer.
- **Time's up:** a soft chime plays, never an alarm. With "Wait for a tap" (the default) the egg glows and knocks every 5 s for up to 5 minutes, and a tap anywhere hatches it.
- **Hatch:** a shared squash-and-stretch, then the chosen hatch style breaks the shell. The friend jumps out, lands and loops idle animations. Tapping it makes it jump again.
- **Grown-up controls:** Pause, ±1 min, Hatch now, New egg and Stop sit behind the 🔒. It needs a press-and-hold (1–3 s); a quick tap only shows a reminder. On-screen pause and ±1 buttons are optional.
- **Also:** an optional "Next up" card after the hatch, the screen kept awake during a run, Reduce Motion support, and a friend book that collects every animal hatched.

## Code map

```
GetCracking.xcodeproj           the Xcode project (synchronised folder group)
Config/Info.plist               fonts + export-compliance keys (the rest is generated)
GetCracking/
  App/GetCrackingApp.swift      @main, RootView, sheet routing
  Core/
    VNode.swift                 tiny retained vector scene graph + shape builders
    SVGPath.swift               SVG path-data parser (M L H V C S Q T A Z)
    Motion.swift                keyframe animations (Web-Animations style) and idle loops
    Renderer.swift              draws a VNode tree into a SwiftUI Canvas; StageView
    Util.swift                  colours, seeded RNG, shuffle bag, easing curves
  Art/
    Animals.swift               the 40 friends + the photo "friend"
    Egg.swift                   egg, crack stages, hatch choreography, ShellCtx
    Scenes.swift, Props.swift   the 10 worlds and their props / particles
    Loops.swift                 every idle loop (sway, blink, hop, fireflies …)
    Hatch/ShellFX.swift         hatch-style registry and the contract every style follows
    Hatch/RollFX.swift          "Roll away"
    Hatch/BoomFX.swift          "Kaboom"
    Hatch/CrumbleFX.swift       "Crumble"
  Audio/Sound.swift             AVAudioEngine synth: music, sound effects, end tunes, speech
  Model/
    AppModel.swift              app state, the run controller (timer state machine), ground ring
    Store.swift                 settings, friend book, photo storage
  UI/
    SetupView.swift             "Who's in the egg?" screen
    TimerView.swift             the running timer, lock button, grown-up tray
    SheetView.swift             world, music, friend book and settings sheets
    Theme.swift                 colours, fonts, toy-style buttons, switch, flow layout, hold gesture
  Resources/                    asset catalog, fonts (Fredoka, Patrick Hand SC), privacy manifest
```

## Adding a hatch style

Hatch styles are interchangeable. Each is a type conforming to `ShellEffect` (`id`, `name`, `icon`, `run(_ ctx:)`), listed in `ShellFX.all`, following the contract at the top of `Art/Hatch/ShellFX.swift`:

- build shell pieces with `ctx.piece(points)`
- call `ctx.release()` when the friend should spring out
- keep front-layer pieces clear of the friend's landing area
- honour `ctx.reduce` (Reduce Motion)

## Fonts

Fredoka and Patrick Hand SC are licensed under the SIL Open Font License 1.1. Fredoka's variable font was instanced to static Regular, SemiBold and Bold TTFs for iOS.

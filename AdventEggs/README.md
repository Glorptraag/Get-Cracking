# Advent Eggs

An advent calendar for little ones, built on Get Cracking. It's a native SwiftUI app for iPhone and iPad (iOS 17+).

The calendar is a painted winter village at dusk: a church under the Christmas star, houses with snowy roofs and fairy lights, and gift boxes in the snow, with snow falling over it all. Every window, door and gift is one of the 25 numbered advent doors. As on a real advent calendar, the numbers are scattered, and Christmas Day is the church door. The painted-door idea is inspired by traditional illustrated advent calendars, but every drawing is original and is drawn in code in Get Cracking's chunky-outline style.

## How a day works

1. **The door opens on its day** at the opening time (a grown-up setting, 7:00 am by default). Tapping a door that isn't open yet makes it wiggle and says how many sleeps are left. A ready door glows. Tap it and it swings open on its hinge to show a lit room with an egg inside.
2. **Each egg is a 24-hour egg.** From the moment its door opens, it cracks in 8 steps over the next 24 hours, using Get Cracking's crack landmarks (`EggPainter.stepAt`). Eight pebbles under the egg light up as it cracks, and a small label shows the time left. Tapping a cracking egg just squashes it; it doesn't speed it up.
3. **Hatching.** When the 24 hours are up (just as the next door opens), the egg glows and knocks. A tap hatches it: the shell pops apart, the friend jumps out with a burst of sparkles, and a recorded voice says "It's Mary!".
4. **The gallery.** Every hatched friend is saved in the gallery, grouped by collection. Tap a friend to see it big and hear its name again. The doors in the calendar stay open and show the friend inside.

## The 25 friends

| Day | Friend | Collection |
|---|---|---|
| 1 | Gingerbread Pal | Christmas Baking |
| 2 | Joey | Aussie Babies |
| 3 | Nutcracker | The Nutcracker |
| 4 | Donkey | The Nativity |
| 5 | Christmas Tree Cookie | Christmas Baking |
| 6 | Koala | Aussie Babies |
| 7 | Clara | The Nutcracker |
| 8 | Lamb | The Nativity |
| 9 | Shortbread Star | Christmas Baking |
| 10 | Wombat | Aussie Babies |
| 11 | Sugar Plum Fairy | The Nutcracker |
| 12 | Shepherd | The Nativity |
| 13 | Christmas Pudding | Christmas Baking |
| 14 | Platypus | Aussie Babies |
| 15 | Mouse King | The Nutcracker |
| 16 | Angel | The Nativity |
| 17 | Echidna Puggle | Aussie Babies |
| 18 | Snowflake Fairy | The Nutcracker |
| 19 | Kookaburra | Aussie Babies |
| 20 | Melchior (gold) | The Nativity |
| 21 | Caspar (frankincense) | The Nativity |
| 22 | Balthazar (myrrh) | The Nativity |
| 23 | Joseph | The Nativity |
| 24 | Mary | The Nativity |
| 25 | Baby Jesus | The Nativity |

The collections take turns through December, and the Nativity builds towards Christmas Day. To change a friend, edit `Model/Friends.swift`. Each friend is a `Look`: body colour, ears, snout, headwear and extras such as wings, a staff, a crown, spines or a manger.

## Grown-up controls

- **Settings**: press and hold the gear. A quick tap only shows a reminder, as in Get Cracking. In settings you can:
  - set the door opening time
  - turn on **Let any door open**, to catch up or try the calendar out
  - turn sounds and the spoken names on or off
  - start the calendar again
- **Hatch now**: press and hold the lock on the egg screen. It makes that egg ready straight away.
- In January the whole calendar stays open, so nothing is missed after Christmas.

## Build and run

1. Open `AdventEggs/AdventEggs.xcodeproj` in **Xcode 16 or later**.
2. Select the **AdventEggs** target, open **Signing & Capabilities**, and choose your Team. Change the bundle ID (`com.getcracking.advent`) if it's taken.
3. Pick an iPhone or iPad simulator or a device, and press Run.

The project uses Xcode 16's synchronised folders, so any file you add under `AdventEggs/AdventEggs/` is part of the app automatically, with no project-file edits needed. `App/AdventEggsApp.swift` has SwiftUI previews of the calendar and of all 25 friends side by side.

To try every door outside December, hold the gear and turn on **Let any door open**. Then use **Hatch now** on the egg screen instead of waiting 24 hours.

## Files

```
AdventEggs.xcodeproj         Xcode project (folder-synchronised)
AdventEggs/
  App/AdventEggsApp.swift    entry point + previews
  Model/Friends.swift        the 25 friends, their collections and lines
  Model/Look.swift           what a friend is made of; shared colours
  Model/AdventStore.swift    doors, eggs, gallery, settings, the 24-hour egg clock
  Art/Draw.swift             shared drawing helpers (chunky outline style)
  Art/FriendPainter.swift    draws every friend (chibi bean + cookie shapes)
  Art/EggPainter.swift       the egg and its 8 crack steps (ported from js/egg.js)
  Art/SceneLayout.swift      the 1000 x 1500 scene board and the 25 door positions
  Art/VillagePainter.swift   sky, star, hills, church, houses, lights, door surrounds
  Views/CalendarView.swift   the calendar screen
  Views/DoorView.swift       one painted door that swings open
  Views/EggScreen.swift      the egg, the hatch, meeting the friend
  Views/GalleryView.swift    the gallery and the big friend card
  Views/SettingsView.swift   grown-up settings
  Views/Components.swift     friend view, snowfall, sparkles, hold button, pills
  Sound/SoundBox.swift       crack, pop and the recorded names
  Resources/Sounds/          crack.mp3, pop.mp3 (from Get Cracking)
  Resources/Voice/           day-01.mp3 … day-25.mp3, the "It's …!" lines
tools/gen-voice.js           records the name lines with ElevenLabs
```

## Recorded voice

The 25 "It's …!" lines were recorded with ElevenLabs text-to-speech in the same voice and settings as Get Cracking ("Jessica"), for 233 credits in total. The app never contacts ElevenLabs. If a recording is missing, the device voice says the line instead. To re-record after changing a `spoken:` line in `Friends.swift`:

```sh
node AdventEggs/tools/gen-voice.js takes/ --budget 600
```

It only records lines it doesn't already have in `takes/`, so delete a take to redo it.

## Saved data

Opened doors, hatched friends and settings are saved on the device in `UserDefaults`. Nothing leaves the device: no accounts and no network.

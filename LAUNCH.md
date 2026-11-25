# Get Cracking (iPhone): plan to the App Store

Written 25 Nov 2026. This file is the single list of what stands between the app and a public 1.0. Tick items here as they land. Nothing outside this file blocks the release.

## Goal

Paste this into a Claude Code session on the `ios-swiftui` branch:

```
/goal LAUNCH.md has every [agent] item ticked with its check shown in this conversation, and either (a) the output of `curl -s "https://itunes.apple.com/lookup?bundleId=com.belladouglas.getcracking&country=au"` printed here shows resultCount 1 and version 1.0, or (b) every unticked item left is tagged [Drew], in which case list them in order and stop. Do not add features or port anything new from the web app. Stop after 60 turns.
```

The goal checker only reads the conversation, so every item below names a command whose output proves it.

## Where it stands

- **The release candidate is not on this branch.** `ios-swiftui` has 40 friends, no karaoke, no packs, no purchase, and `APP_STORE.md` on the newer line says it does not compile. The real app is `claude/confident-bohr-z2ljcm` (25 Nov), which sits on `parity/to-mac-20261123-store`: 26 commits ahead of `ios-swiftui`, none behind, so it fast-forwards.
- That line has feature parity with the web app (65 friends, 13 worlds, karaoke, packs), StoreKit 2 with one non-consumable at A$5.99, a parental gate, a privacy manifest, and a CI workflow that runs about 158 standalone checks and a simulator build.
- `parity/to-mac` and `claude/peaceful-heisenberg-jgwkwu` are second ports of the same work and are not merged anywhere.
- The build number is `1` on every branch and nothing bumps it. App Store Connect refuses a second upload with the same number.
- There is no `.storekit` file, so the purchase cannot be tried in the simulator.
- The product ID is `com.glorptraag.getcracking.wholenest` while the bundle ID is now `com.belladouglas.getcracking`.
- CI does not archive or upload. No screenshots. Store text is drafted in `APP_STORE.md`.
- `APP_STORE.md` has an 11-test TestFlight script plus nine on-device checks, with no rule for when testing is finished.

## Why testing stalls, and the rule that stops it

Three things, all visible in the repository:

1. **No single trunk.** Fixes land on whichever branch the session was on. A TestFlight build can be cut from a branch that lacks yesterday's fix, so the same bug is found twice.
2. **Uploads fail or get confused** because the build number never changes.
3. **Twenty manual checks with no finish line.** Every pass finds something small, and each small thing restarts the pass.

The changes: one branch, automatic build numbers, machines check what machines can, one 20-minute hands-on pass, and a blocker rule.

**A blocker is one of:** a crash; a timer that ends at the wrong time or never hatches; no sound when the ringer is on; buy or restore not working; a child reaching the purchase or a link without the parental gate; anything App Review rejects. Nothing else is a blocker. A friend whose art is slightly off, a song that could be better mixed, or a missing web nicety goes on the 1.0.1 list.

## Phase 1: one trunk, frozen (agent, half a day)

- [ ] [agent] Fast-forward `ios-swiftui` to `claude/confident-bohr-z2ljcm` by pull request. Check: `git rev-list --left-right --count origin/ios-swiftui...origin/claude/confident-bohr-z2ljcm` prints `0 0`.
- [ ] [Drew] Delete or close `parity/to-mac`, `claude/peaceful-heisenberg-jgwkwu` and the dated `parity/to-mac-2026112x-*` branches once the line above is done. From then on every iOS change goes to `ios-swiftui` and nowhere else.
- [ ] [agent] Parity is closed for 1.0. Set `WEB_SYNCED` in `.parity/config` to the current `main` and note in `PARITY.md` that the next port happens after release.
- [ ] [agent] Build number from the commit count, set at archive time. Check: two archives from two commits show different `CFBundleVersion`.
- [ ] [Drew] Decide the product ID before creating it in App Store Connect, because it cannot be renamed after. Default: rename to `com.belladouglas.getcracking.wholenest` so it matches the bundle ID.
- [ ] [agent] Apply that ID in `ProductID.swift`, remove the "REPLACE the placeholders" comment, and add `Products.storekit` with the one product, attached to the scheme's run action. Check: the gate checks pass.

## Phase 2: machines check first (agent, 1 day)

- [ ] [agent] `tools/check.sh` runs the three check programs and the simulator build. The workflow calls it. The script is the source of truth, so it runs the same on the Mac if Actions minutes run out (macOS runners use them ten times faster). Check: green run URL or the script's last lines.
- [ ] [agent] DEBUG-only launch arguments that open the app in a named state: setup dial, timer at each of the 8 crack steps, time up, hatch, friend with karaoke playing, friend book, each pack's store card, paywall, parental gate, settings. A fast clock argument runs a 5-minute timer in 5 seconds.
- [ ] [agent] A screenshot step in CI, as Advent Eggs already does with `simctl`: launch each state, screenshot, push to `ci-screenshots`. Include one run of the fast clock from start to hatched. Check: the files on the branch.
- [ ] [agent] Checks for the timer across backgrounding: start, record the end time, simulate 3 minutes away, confirm the remaining time and the crack step are right. Add to `GateChecks`. Check: the check names in the log.
- [ ] [agent] A check that every one of the 65 friends has art, a name recording, and a call or karaoke part that resolves to a bundled file. Check: log line with the count.
- [ ] [agent] Read every screenshot. Fix what is broken, list what is only untidy under 1.0.1. Check: a table in the PR.

## Phase 3: store plumbing (in parallel)

- [ ] [Drew] App Store Connect: Paid Apps Agreement, tax, banking, Small Business Program (`APP_STORE.md` sections 1 and 2).
- [ ] [Drew] App record for `com.belladouglas.getcracking`, Kids Category and age band as in section 5. Made for Kids cannot be undone later.
- [ ] [Drew] Create the in-app purchase with the ID from phase 1, A$5.99, Family Sharing on.
- [ ] [Drew] App Store Connect API key (App Manager) in repository secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`.
- [ ] [agent] Confirm the privacy page is live. Check: `curl -sI https://getcrackingkids.vercel.app/privacy.html` shows 200.
- [ ] [agent] `tools/release.sh` and a workflow on `v*` tags: archive, export with the API key, upload to TestFlight. Check: the upload line in the log.
- [ ] [agent] Move the drafted store text and review notes from `APP_STORE.md` sections 8 and 10 into `fastlane/metadata`. Store screenshots at iPhone 6.9" from the screenshot step.

## Phase 4: one hands-on pass (Drew, 20 minutes, one build)

Tag `v1.0-rc1`, install from TestFlight on one iPhone. Do each line once, write "ok" or one sentence, and do not stop to fix anything. This replaces `APP_STORE.md` section 12 and checks S1 to S9.

1. Ringer on, 1-minute timer: music plays, the egg cracks, it hatches, the friend's name is spoken, karaoke plays. Is anything too loud, too quiet or ugly?
2. Ringer off: silent.
3. 3-minute timer, lock the phone for 2 minutes, unlock: the time is right and sound comes back.
4. Take a phone call or play a video mid-timer, return: sound comes back.
5. Hold the lock: pause, plus a minute, hatch now all work. A quick tap does nothing.
6. Open a locked pack: the parental gate appears. A wrong answer closes it.
7. Sandbox account: buy the Whole Nest. Both packs unlock at once.
8. Delete the app, reinstall, Restore Purchases from Settings: unlocked again.
9. Hatch a photo from your own library.
10. Flight mode for one whole timer: nothing breaks.

Sort the notes with the blocker rule. Blockers get fixed on `ios-swiftui` and tagged `rc2`, and only the failed lines are repeated. If those pass, testing is over.

## Phase 5: submit and release

- [ ] [agent] Upload metadata and screenshots with `fastlane deliver`, attach the build and the purchase.
- [ ] [Drew] Submit for review with **manual release** as soon as phase 2 is green. The hands-on pass can run while Apple reviews. The Christmas pack is the reason not to wait: it is worth most in the first two weeks of December.
- [ ] [Drew] When approved with no open blockers, press Release.
- [ ] [agent] Run the lookup command from the goal until it shows the app. Tag `v1.0`.

A rejection is handled like any blocker: fix, tag, resubmit, reply in Resolution Centre the same day. Kids Category reviews look hardest at the parental gate and at links out of the app, so the review notes say where each one is.

## Not in 1.0

iPad layout, anything the web app gains after today, new friends or packs, tuning of songs.

## 1.0.1 list

Add one line per item found during testing that is not a blocker.


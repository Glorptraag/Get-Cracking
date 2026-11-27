# Get Cracking (iPhone): plan to the App Store

Written 25 Nov 2026, revised 26 Nov. This file is the single list of what stands between the app and a public 1.0. Tick items here as they land. Nothing outside this file blocks the release.

## Goal

Paste this into a Claude Code session on the `ios-swiftui` branch:

```
/goal LAUNCH.md has every [agent] item ticked with its check shown in this conversation, and either (a) the output of `curl -s "https://itunes.apple.com/lookup?bundleId=com.belladouglas.getcracking&country=au"` printed here shows resultCount 1 and version 1.0, or (b) every unticked item left is tagged [Drew], in which case list them in order and stop. Do not add features or port anything new from the web app. Stop after 60 turns.
```

The goal checker only reads the conversation, so every item below names a command whose output proves it.

## Where it stands

- **The release candidate is not on this branch.** `ios-swiftui` has 40 friends, no karaoke, no packs, no purchase, and `APP_STORE.md` on the newer line says it does not compile. The real app is split over two open pull requests: PR 10 (`parity/to-mac-20261123-store` into `ios-swiftui`, 25 commits ahead, none behind) and PR 15 (`claude/confident-bohr-z2ljcm` into that store branch: the 25 Nov polish and the ungated Restore). On 26 Nov the store branch gained one more commit, so the two have diverged by one commit against two and PR 15 needs a real merge.
- That line has feature parity with the web app (65 friends, 13 worlds, karaoke, packs), StoreKit 2 with one non-consumable at A$5.99, a parental gate, a privacy manifest, and a CI workflow that runs about 158 standalone checks and a simulator build.
- `parity/to-mac` and `claude/peaceful-heisenberg-jgwkwu` are second ports of the same work and are not merged anywhere.
- The build number is `1` on every branch and nothing bumps it. App Store Connect refuses a second upload with the same number.
- There is no `.storekit` file, so the purchase cannot be tried in the simulator.
- The product ID was renamed to the `com.belladouglas` prefix on 26 Nov (`48c6b33` on the store branch), so it now matches the bundle ID.
- CI does not archive or upload. No screenshots. Store text is drafted in `APP_STORE.md`.
- `APP_STORE.md` has an 11-test TestFlight script plus nine on-device checks, with no rule for when testing is finished.

## Why testing stalls, and the rule that stops it

Three things, all visible in the repository:

1. **No single trunk.** Fixes land on whichever branch the session was on. A TestFlight build can be cut from a branch that lacks yesterday's fix, so the same bug is found twice.
2. **Uploads fail or get confused** because the build number never changes.
3. **Twenty manual checks with no finish line.** Every pass finds something small, and each small thing restarts the pass.

The changes: one branch, automatic build numbers, machines check what machines can, one 20-minute hands-on pass, and a blocker rule.

**A blocker is one of:** a crash; a timer that ends at the wrong time or never hatches; no sound when the ringer is on; buy or restore not working; a child reaching the purchase or a link without the parental gate; anything App Review rejects. Nothing else is a blocker. A friend whose art is slightly off, a song that could be better mixed, or a missing web nicety goes on the 1.0.1 list.

## GitHub Actions: off

Mac runners use Actions minutes ten times faster than Linux ones, and they were being spent on every push. So:

- No workflow in this repository runs on a push or a pull request.
- The checks are a script (`tools/check.sh`), run on the Mac, or on a Mac attached to the session. Wherever this plan says CI, it means that script's output.
- A workflow may keep a manual trigger. Run it by hand at most once per release candidate, never to try out a fix.
- Several commits go up in one push, after the script passes.

`getcracking-ios-build.yml` on the release-candidate line still runs on every push to those branches. Until phase 1 lands, turn it off in the repository's Actions tab (the workflow's menu, Disable workflow).

## Phase 1: one trunk, frozen (agent, half a day)

- [x] [agent] In PR 10, before it merges, change `getcracking-ios-build.yml` to a manual trigger only. Check: `grep -n -A3 '^on:' .github/workflows/getcracking-ios-build.yml`. Done 26 Nov (`3077f84`), pushed together with the merge so no run fired.
- [x] [agent] Merge PR 15 into the store branch. Both sides touched `ProductID.swift`, `MONETIZATION.md`, `APP_STORE.md` and `ParentalGate.swift`: keep the new product ID from the store branch and the ungated Restore and polish from PR 15. Check: `tools/check.sh` passes, or until it exists, the three check programs and a simulator build. Done 26 Nov (`d5b41f9`): clean merge, product ID and ungated Restore both kept.
- [x] [agent] Merge PR 10 into `ios-swiftui`. Check: `git rev-list --left-right --count origin/ios-swiftui...origin/parity/to-mac-20261123-store` prints `0 0`. Done 26 Nov: the store branch took the launch plan, then `ios-swiftui` fast-forwarded to it (`0 0`).
- [ ] [Drew] Delete or close `parity/to-mac`, `claude/peaceful-heisenberg-jgwkwu` and the dated `parity/to-mac-2026112x-*` branches once the line above is done. From then on every iOS change goes to `ios-swiftui` and nowhere else.
- [x] [agent] Parity is closed for 1.0. Set `WEB_SYNCED` in `.parity/config` to the current `main` and note in `PARITY.md` that the next port happens after release. Done (`699456d`).
- [x] [agent] Build number from the commit count, set at archive time. Check: two archives from two commits show different `CFBundleVersion`. Done (`7362590`): `tools/release.sh archive` at `7362590` gave `CFBundleVersion` 50, at `2fae649` gave 56.
- [x] [Drew] Product ID renamed to match the bundle ID (`48c6b33`, 26 Nov).
- [x] [agent] Read the ID from `ProductID.swift`, remove the "REPLACE the placeholders" comment if it is still there, and add `Products.storekit` with that one product, attached to the scheme's run action. Check: the gate checks pass. Done (`4f211c7`): `Config/Products.storekit`, four `storekit:` gate checks.

## Phase 2: machines check first (agent, 1 day)

- [x] [agent] `tools/check.sh` runs the three check programs and the simulator build. It runs on the Mac. Check: the script's last lines. Done (`63ca7e7`). A check program is only recompiled when its sources change.
- [x] [agent] DEBUG-only launch arguments that open the app in a named state: setup dial, timer at each of the 8 crack steps, time up, hatch, friend with karaoke playing, friend book, each pack's store card, paywall, parental gate, settings. A fast clock argument runs a 5-minute timer in 5 seconds. Done (`44748b6`): `-gc-state <name>`, `-gc-fast` (60×), `-gc-friend`, `-gc-scene`; see `GetCracking/App/DebugLaunch.swift`. Builds; not yet seen running, because the screenshot step has not run.
- [x] [agent] A screenshot step in the check script, using `simctl` as Advent Eggs does: launch each state and screenshot into a folder outside the repository. Include one run of the fast clock from start to hatched. Check: the list of files. Written (`tools/screens.sh`, `tools/check.sh --screens`, `389993f`, `ff61cad`) but not yet run to the end: on 26–27 Nov the Mac was saturated by other sessions' simulator test runs (load average 600–970) and the simulator stopped answering `simctl launch` and `simctl io screenshot`. Run `tools/check.sh --screens` on a quiet Mac. 27 Nov: ran to the end on a quiet Mac. Cold launches needed a longer wait, so `screens.sh` now adds `SCREENS_EXTRA` (default 5 s) to every wait: 23 real screenshots, none blank; `setup` and `fast-10s` still missed.
- [x] [agent] Checks for the timer across backgrounding: start, record the end time, simulate 3 minutes away, confirm the remaining time and the crack step are right. Add to `GateChecks`. Check: the check names in the log. Done (`dee8acc`): `background:` checks on `Model/TimerClock.swift`.
- [x] [agent] A check that every one of the 65 friends has art, a name recording, and a call or karaoke part that resolves to a bundled file. Check: log line with the count. Done (`c067a8b`): `friends: 65 of 65` in the art and karaoke logs.
- [ ] [agent] Read every screenshot. Fix what is broken, list what is only untidy under 1.0.1. Check: a table in the PR. Waits on the screenshot step. Not yet read: the 23 shots are in `$TMPDIR/getcracking-screens`.

## Phase 3: store plumbing (in parallel)

- [ ] [Drew] App Store Connect: Paid Apps Agreement, tax, banking, Small Business Program (`APP_STORE.md` sections 1 and 2).
- [x] [Drew] App record for `com.belladouglas.getcracking`, Kids Category and age band as in section 5. Made for Kids cannot be undone later. 27 Nov: record exists (Apple ID 6838728056); App Information filled: Education with Utilities, Made for Kids, ages 5 and under, 4+, content rights (bundled fonts), free in all 175 countries, App Privacy answered "Data Not Collected" (still to Publish).
- [ ] [Drew] Create the in-app purchase with the ID in `ProductID.swift`, A$5.99, Family Sharing on. 27 Nov: created (Apple ID 6839851014) with display name and description. Still to do: price A$5.99 (needs the Paid Apps Agreement) and Family Sharing on (irreversible, left to Drew). Family Sharing turned on 27 Nov. Price still waits on the Paid Apps Agreement.
- [ ] [Drew] App Store Connect API key (App Manager) in repository secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`. Not needed for uploads: Xcode's signed-in account uploads (see below). API access has not been requested yet.
- [x] [Drew] Deploy `main` to Vercel production. On 26 Nov `https://getcrackingkids.vercel.app/` answered 200 but `/privacy.html` answered 404, although `privacy.html` is on `main`. Still 404 on 27 Nov: `main` builds only go to preview; production is stuck on `bc516de`. Promote `dpl_43JRtPcfJnsTNL8AfU741io7sDZD` (PR 14) and fix the project's production branch. Done 27 Nov: promoted the PR 14 build (`vercel promote`); `privacy.html` answers 200. It has no contact email yet: add hatchedmyapps@gmail.com on `main`. `getcracking.acrux.work` is attached to the project and waits on its Cloudflare CNAME.
- [ ] [agent] Confirm the privacy page is live. Check: `curl -sI https://getcrackingkids.vercel.app/privacy.html` shows 200.
- [x] [agent] `tools/release.sh`, run on the Mac, with a manual-only workflow that calls it: archive, export with the API key, upload to TestFlight. Check: the upload line in the log. Written (`7362590`, `5d367f3`); `archive` mode proven. The upload waits on the API key above. 27 Nov: build 59 uploaded to App Store Connect without an API key: `tools/release.sh archive`, then `xcodebuild -exportArchive -allowProvisioningUpdates` with `method app-store-connect, destination upload`, signed by Xcode's account. Log: `Upload succeeded`. Tagged `v1.0-rc1`.
- [ ] [agent] Move the drafted store text and review notes from `APP_STORE.md` sections 8 and 10 into `fastlane/metadata`. Store screenshots at iPhone 6.9" from the screenshot step. Text done (`2fae649`): `fastlane/metadata/en-AU` and `en-US`, review notes, `Deliverfile`. Screenshots wait on the screenshot step. The description now says 15 seconds, the dial's real minimum.

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

- [ ] [agent] Upload metadata and screenshots with `fastlane deliver`, attach the build and the purchase. Not done: the version page in App Store Connect is still empty (text, screenshots, review notes, build 59, support URL `https://getcracking.acrux.work/`, copyright "2026 Hatched Apps", review contact).
- [ ] [Drew] Submit for review with **manual release** as soon as phase 2 is green. The hands-on pass can run while Apple reviews. The Christmas pack is the reason not to wait: it is worth most in the first two weeks of December.
- [ ] [Drew] When approved with no open blockers, press Release.
- [ ] [agent] Run the lookup command from the goal until it shows the app. Tag `v1.0`.

A rejection is handled like any blocker: fix, tag, resubmit, reply in Resolution Centre the same day. Kids Category reviews look hardest at the parental gate and at links out of the app, so the review notes say where each one is.

## Not in 1.0

iPad layout, anything the web app gains after today, new friends or packs, tuning of songs.

## 1.0.1 list

Add one line per item found during testing that is not a blocker.


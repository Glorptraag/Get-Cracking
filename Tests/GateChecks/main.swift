// Gate decision checks for The Whole Nest, with no StoreKit and no test target.
// CI compiles this with the app's own Packs.swift and FeatureGate.swift:
//
//   swiftc GetCracking/Monetization/Packs.swift GetCracking/Monetization/FeatureGate.swift \
//          Tests/GateChecks/main.swift -o gatecheck && ./gatecheck
//
// It lives outside GetCracking/ so it never ships in the app.

import Foundation

var failures = 0
func check(_ ok: Bool, _ what: String) {
    print((ok ? "PASS  " : "FAIL  ") + what)
    if !ok { failures += 1 }
}

let freeTier = FeatureGate(ownsWholeNest: false)
let nest = FeatureGate(ownsWholeNest: true)

// the starter set
check(Packs.classic.friends.count == 40, "Classic has 40 friends")
check(Packs.classic.scenes.count == 10, "Classic has 10 worlds")
check(Packs.classic.starterFriends.count == 12, "12 starter friends")
check(Packs.classic.starterScenes == ["meadow", "forest", "pond"], "3 starter worlds: meadow, forest, pond")
check(Packs.classic.starterFriends.isSubset(of: Set(Packs.classic.friends)), "starter friends are Classic friends")
check(Set(Packs.allFriends).count == Packs.allFriends.count, "no friend is in two packs")

// free friend allowed, locked friend locked
check(freeTier.friend("chick"), "free: chick is allowed")
check(freeTier.friend("dino"), "free: dino is allowed")
check(!freeTier.friend("dragon"), "free: dragon is locked")
check(!freeTier.friend("unicorn"), "free: unicorn is locked")
check(freeTier.scene("meadow") && !freeTier.scene("reef"), "free: meadow allowed, reef locked")
check(freeTier.endSound("karaoke"), "free: Egg karaoke (the default song) allowed")
check(Packs.defaultEndSound == "karaoke", "Egg karaoke is the default hatching song")
check(freeTier.endSound("band") && freeTier.endSound("tada"), "free: Animal band and the jingles allowed")
check(!freeTier.endSound("jungle") && !freeTier.endSound("farm"), "free: Jungle jam and Farmyard hoedown locked")

// owned: everything allowed
check(Packs.allFriends.allSatisfy(nest.friend), "nest: every friend allowed")
check(Packs.allScenes.allSatisfy(nest.scene), "nest: every world allowed")
check(["karaoke", "band", "jungle", "farm", "tada"].allSatisfy(nest.endSound), "nest: every song allowed")
check(Packs.list.allSatisfy(nest.pack), "nest: every pack allowed")

// shuffle pool = owned only
check(Set(freeTier.friendPool) == Packs.classic.starterFriends, "free: friend shuffle = the 12 starters")
check(freeTier.friendPool.allSatisfy(freeTier.friend), "free: nothing locked in the friend shuffle")
check(Set(freeTier.scenePool) == Packs.classic.starterScenes, "free: world shuffle = the 3 starters")
check(nest.friendPool == Packs.allFriends, "nest: friend shuffle = all friends")
check(nest.scenePool == Packs.allScenes, "nest: world shuffle = all worlds")

// photos (live count, so removing one frees the slot)
check(freeTier.canAddPhoto(liveCount: 0), "free: first photo allowed")
check(!freeTier.canAddPhoto(liveCount: 1), "free: second photo locked")
check(!freeTier.canAddPhoto(liveCount: 5), "free: photos kept after a downgrade, no new ones")
check(nest.canAddPhoto(liveCount: 50) && nest.photosLeft(liveCount: 50) == nil, "nest: unlimited photos")

// downgrade: settings that point at locked things fall back, found friends stay visible
check(freeTier.effectiveScene("reef") == "random" && freeTier.effectiveScene("pond") == "pond", "free: locked world plays as Surprise me")
check(freeTier.effectiveEndSound("jungle") == "karaoke", "free: locked song plays Egg karaoke")
check(!freeTier.bookShowsLock(friend: "dragon", timesFound: 3), "free: a dragon already found stays in the book")
check(freeTier.bookShowsLock(friend: "dragon", timesFound: 0), "free: an unfound dragon shows a lock")
check(!freeTier.bookShowsLock(friend: "chick", timesFound: 0), "free: an unfound chick shows no lock")

// a whole free pack (future seasonal freebie) opens without the unlock
let gift = Pack(id: "gift", name: "Gift", blurb: "", friends: ["x"], scenes: ["y"], isFree: true)
check(freeTier.pack(gift), "free: a free pack is allowed")

// the Aussie Bush and Christmas packs (web js/packs/aussie.js, christmas.js), in web order
let aussieFriends = ["galah", "cockatoo", "kookaburra", "emu", "joey", "wombat",
                     "platypus", "echidna", "sugarglider", "frillneck", "bilby", "molecricket"]
let christmasFriends = ["gingerbread", "treecookie", "shortbread", "pudding", "nutcracker", "sugarplum", "mouseking",
                        "snowfairy", "angel", "reindeer", "robin", "snowman", "xmasbeetle"]
check(Packs.list.map(\.id) == ["classic", "aussie", "christmas"], "packs: classic, aussie, christmas")
check(Packs.byId("aussie")?.friends == aussieFriends, "Aussie Bush has its 12 friends in web order")
check(Packs.byId("aussie")?.scenes == ["outback", "billabong"], "Aussie Bush has outback and billabong")
check(Packs.byId("christmas")?.friends == christmasFriends, "Christmas has its 13 friends in web order")
check(Packs.byId("christmas")?.scenes == ["xmasvillage"], "Christmas has the village")
check(Packs.allFriends.count == 65 && Set(Packs.allFriends).count == 65, "65 friends, no id twice")
check(Packs.allScenes.count == 13 && Set(Packs.allScenes).count == 13, "13 worlds, no id twice")
for p in [Packs.aussie, Packs.christmas] {
    check(!p.isFree && p.starterFriends.isEmpty && p.starterScenes.isEmpty, "\(p.id): paid, no starter items")
    check(!freeTier.pack(p), "free: \(p.id) pack locked")
    check(nest.pack(p), "nest: \(p.id) pack open")
    check(!p.friends.contains(where: freeTier.friend) && !p.scenes.contains(where: freeTier.scene), "free: every \(p.id) friend and world locked")
    check(p.friends.allSatisfy(nest.friend) && p.scenes.allSatisfy(nest.scene), "nest: every \(p.id) friend and world open")
    check(freeTier.friendPool.allSatisfy { !p.friends.contains($0) }, "free: no \(p.id) friend in the shuffle")
    check(Set(p.friends).isSubset(of: Set(nest.friendPool)), "nest: \(p.id) friends in the shuffle")
}
check(freeTier.effectiveScene("xmasvillage") == "random", "free: a locked pack world plays as Surprise me")
check(freeTier.bookShowsLock(friend: "galah", timesFound: 0), "free: an unfound galah shows a lock")

// switching packs off (Settings.packsOff) keeps them out of the shuffles
check(nest.friendPool(packsOff: []) == nest.friendPool, "nest, all on: friend shuffle = every friend")
let noXmas = nest.friendPool(packsOff: ["christmas"])
check(!noXmas.contains(where: christmasFriends.contains) && Set(aussieFriends).isSubset(of: Set(noXmas)), "nest, Christmas off: no Christmas friend in the shuffle")
check(!nest.scenePool(packsOff: ["christmas"]).contains("xmasvillage"), "nest, Christmas off: no village in the world shuffle")
check(nest.friendPool(packsOff: ["aussie", "christmas"]) == Packs.classic.friends, "nest, both packs off: Classic friends only")
check(nest.scenePool(packsOff: ["aussie"]) == Packs.classic.scenes + ["xmasvillage"], "nest, Aussie off: no outback or billabong")
check(nest.friendPool(packsOff: ["classic"]) == aussieFriends + christmasFriends, "nest, Classic off: pack friends only")
check(nest.friendPool(packsOff: ["classic", "aussie", "christmas"]) == Packs.classic.friends, "nest, everything off: Classic still plays")
check(Set(freeTier.friendPool(packsOff: ["classic"])) == Packs.classic.starterFriends, "free, Classic off (packs locked): the starters still play")
check(Set(freeTier.scenePool(packsOff: ["classic", "aussie", "christmas"])) == Packs.classic.starterScenes, "free, everything off: the starter worlds")
check(freeTier.friendPool(packsOff: ["aussie", "christmas"]).allSatisfy(freeTier.friend), "free: nothing locked in a pack-filtered shuffle")

// The setup dial (Model/TimeDial.swift), against the web's stepTime / wireDial (js/app.js, 2f810aa)
print("\nThe egg-timer dial")
check(TimeDial.minSecs == 15 && TimeDial.maxSecs == 3600, "dial: 15 s … 60 min")
check(TimeDial.step(165, 1) == 180 && TimeDial.step(165, -1) == 150, "dial: at 2:45, + → 3:00 and − → 2:30 (15 s steps)")
check(TimeDial.step(180, 1) == 240 && TimeDial.step(180, -1) == 165, "dial: at 3:00, + → 4:00 (1 min) and − → 2:45 (15 s)")
check(TimeDial.step(3540, 1) == 3600 && TimeDial.step(3540, -1) == 3480, "dial: at 59:00, + → 60:00 and − → 58:00")
check(TimeDial.step(3600, 1) == 3600, "dial: + at 60:00 stays at the max")
check(TimeDial.step(15, -1) == 15 && TimeDial.step(30, -1) == 15, "dial: − never goes under 15 s")
check(TimeDial.step(10, 1) == 15 && TimeDial.step(270, -1) == 240 && TimeDial.step(200, 1) == 240 && TimeDial.step(200, -1) == 180,
      "dial: steps snap to their grid first (0:10 + → 0:15, 4:30 − → 4:00, 3:20 → 4:00 / 3:00)")
check(TimeDial.clamp(0) == 15 && TimeDial.clamp(-60) == 15 && TimeDial.clamp(4000) == 3600 && TimeDial.clamp(300) == 300, "dial: clamp to 15 s … 60 min")
func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-6 }
check(near(TimeDial.fraction(900), 0.25) && near(TimeDial.angle(900), .pi / 2) && near(TimeDial.angle(3600), 2 * .pi), "dial: one full turn is 60 minutes")
let k15 = TimeDial.knob(900), k30 = TimeDial.knob(1800), k0 = TimeDial.knob(0)
check(near(k15.x, 136) && near(k15.y, 0) && near(k30.x, 0) && near(k30.y, 136) && near(k0.x, 0) && near(k0.y, -136),
      "dial: the knob sits at 3 o'clock for 15 min, 6 for 30, 12 for 0")
check(TimeDial.touch(136, 0).minutes == 15 && TimeDial.touch(0, 136).minutes == 30 && TimeDial.touch(-136, 0).minutes == 45,
      "dial: a touch at 3, 6 and 9 o'clock reads 15, 30 and 45 minutes")
check(TimeDial.touch(0, -136).minutes == 0 && TimeDial.touch(-1, -136).minutes == 60 && TimeDial.touch(1, -136).minutes == 0,
      "dial: just left of the top reads 60, the top itself 0")
for m in [1, 7, 23, 44, 59] {
    let a = Double(m) / 60 * 2 * .pi
    check(TimeDial.touch(sin(a) * 120, -cos(a) * 120).minutes == m, "dial: angle ↔ minutes round trip at \(m) min")
}
check(near(TimeDial.touch(3, 4).dist, 5), "dial: touch distance")
check(TimeDial.onRing(136) && TimeDial.onRing(110) && TimeDial.onRing(176) && !TimeDial.onRing(109) && !TimeDial.onRing(177),
      "dial: only the ring (110 … 176 from the centre) turns it; the egg stays tappable")
check(TimeDial.ringMinutes(0, currentSecs: 50 * 60, first: true) == 60 && TimeDial.ringMinutes(0, currentSecs: 10 * 60, first: true) == 1,
      "dial: the top of the ring is 60 coming from above 30 min, 1 coming from below")
check(TimeDial.ringMinutes(10, currentSecs: 50 * 60, first: false) == 60 && TimeDial.ringMinutes(50, currentSecs: 10 * 60, first: false) == 1,
      "dial: a drag never wraps past the top")
check(TimeDial.ringMinutes(50, currentSecs: 10 * 60, first: true) == 50 && TimeDial.ringMinutes(20, currentSecs: 50 * 60, first: false) == 20,
      "dial: a first tap jumps anywhere; a drag elsewhere just follows")
check(TimeDial.spoken(300) == "5 minutes" && TimeDial.spoken(60) == "1 minute" && TimeDial.spoken(165) == "2 minutes 45 seconds"
      && TimeDial.spoken(15) == "15 seconds", "dial: VoiceOver reads the time as the web's aria-valuetext")

print(failures == 0 ? "All gate checks passed" : "\(failures) gate check(s) FAILED")
exit(failures == 0 ? 0 : 1)

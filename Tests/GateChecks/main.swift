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

print(failures == 0 ? "All gate checks passed" : "\(failures) gate check(s) FAILED")
exit(failures == 0 ? 0 : 1)

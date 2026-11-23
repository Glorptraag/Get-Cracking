// Egg karaoke checks, with no audio engine and no test target. CI compiles this
// with the app's own song data and pack registry, and runs it from the repo root:
//
//   swiftc GetCracking/Audio/KaraokeData.swift GetCracking/Audio/KaraokeIndex.swift \
//          GetCracking/Monetization/Packs.swift Tests/KaraokeChecks/main.swift -o karaokecheck && ./karaokecheck
//
// The expected values come from running the web app's js/karaoke.js
// (branch claude/epic-hypatia-3w52rk) with every recording loaded: the key and
// role it picks for each friend, and the pitch bend (semitones) of every note
// the friend sings, in song order. It lives outside GetCracking/ so it never ships.

import Foundation

var failures = 0
func check(_ ok: Bool, _ what: String) {
    print((ok ? "PASS  " : "FAIL  ") + what)
    if !ok { failures += 1 }
}

let sounds = "GetCracking/Resources/Sounds/"
func recording(_ name: String) -> Bool { FileManager.default.fileExists(atPath: sounds + name + ".mp3") }

// The pack friends (the `friends:` ids in the web's js/packs/aussie.js and
// js/packs/christmas.js). Their art is ported separately into Packs.swift, so
// they are listed here until then.
let aussie = ["galah", "cockatoo", "kookaburra", "emu", "joey", "wombat", "platypus", "echidna", "sugarglider", "frillneck", "bilby", "molecricket"]
let christmas = ["gingerbread", "treecookie", "shortbread", "pudding", "nutcracker", "sugarplum", "mouseking", "snowfairy", "angel",
                 "reindeer", "robin", "snowman", "xmasbeetle"]
check(aussie.count + christmas.count == 25, "25 pack friends listed")
var everyone: [String] = Packs.allFriends
for id in aussie + christmas where !everyone.contains(id) { everyone.append(id) }
check(everyone.count == 65, "65 friends: the Classic 40 and the 25 pack friends (\(everyone.count))")

// MARK: key choice and bend limits, against the web

/// web: role and key (semitones from C) for every friend
let webRole: [String: (String, Double)] = [
    "chick": ("sings", 2), "duckling": ("plays", 0), "penguin": ("sings", -6), "owl": ("sings", -5), "hamster": ("sings", -6), "bunny": ("plays", 0),
    "fox": ("plays", 0), "kitten": ("sings", -7), "bearcub": ("sings", 3), "panda": ("sings", -7), "frog": ("plays", 0), "turtle": ("plays", 0),
    "dino": ("sings", -4), "dragon": ("sings", -5), "mouse": ("plays", 0), "piglet": ("plays", 0), "koala": ("sings", -6), "raccoon": ("sings", -4),
    "tiger": ("sings", 1), "lion": ("sings", 3), "calf": ("sings", 4), "lamb": ("sings", -5), "fawn": ("sings", 1), "hedgehog": ("sings", -2),
    "otter": ("sings", -2), "seal": ("sings", -6), "axolotl": ("plays", 0), "bat": ("plays", 0), "mole": ("plays", 0), "monkey": ("sings", 0),
    "elephant": ("sings", -3), "squirrel": ("sings", 1), "puppy": ("sings", -5), "unicorn": ("plays", 0), "capybara": ("sings", 3), "redpanda": ("sings", 3),
    "sloth": ("plays", 0), "ladybug": ("plays", 0), "snail": ("plays", 0), "goat": ("sings", -6), "galah": ("sings", 2), "cockatoo": ("sings", -1),
    "kookaburra": ("sings", 0), "emu": ("plays", 0), "joey": ("plays", 0), "wombat": ("plays", 0), "platypus": ("sings", -6), "echidna": ("plays", 0),
    "sugarglider": ("sings", 4), "frillneck": ("plays", 0), "bilby": ("plays", 0), "molecricket": ("sings", -3), "gingerbread": ("plays", 0), "treecookie": ("sings", -7),
    "shortbread": ("sings", -6), "pudding": ("plays", 0), "nutcracker": ("plays", 0), "sugarplum": ("sings", -1), "mouseking": ("plays", 0), "snowfairy": ("plays", 0),
    "angel": ("sings", 0), "reindeer": ("plays", 0), "robin": ("sings", 2), "snowman": ("sings", -5), "xmasbeetle": ("plays", 0),
]
/// web: the bend of every sung note, in song order (hello, verse stabs, the hook, ta-da)
let webBends: [String: [Double]] = [
    "kitten": [-4.52, -4.52, 0.48, -2.52, -4.52, -2.52, -4.52, 0.48, 2.48, 4.48, 0.48, 2.48, -0.52, 0.48, -4.52, 0.48],
    "owl": [-4.38, -4.38, 0.62, -2.38, -4.38, -2.38, -4.38, 0.62, 2.62, 4.62, 0.62, 2.62, -0.38, 0.62, -4.38, 0.62],
    "elephant": [-4.55, -4.55, 0.45, -2.55, -4.55, -2.55, -4.55, 0.45, 2.45, 4.45, 0.45, 2.45, -0.55, 0.45, -4.55, 0.45],
    "galah": [-4.01, -4.01, 0.99, -2.01, -4.01, -2.01, -4.01, 0.99, 2.99, 4.99, 0.99, 2.99, -0.01, 0.99, -4.01, 0.99],
    "gingerbread": [-1.575, -1.575, 0.175, -0.875, -1.575, -0.875, -1.575, 0.175, 0.875, 1.575, 0.175, 0.875, -0.175, 0.175, -1.575, 0.175],
]
func close(_ a: [Double], _ b: [Double]) -> Bool { a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) < 0.001 } }

let notes = KaraokeData.sungNotes
check(notes == [67, 67, 72, 69, 67, 69, 67, 72, 74, 76, 72, 74, 71, 72, 67, 72], "the friend sings the web's 16 notes")
for id in ["kitten", "owl", "elephant", "galah", "gingerbread"] {
    let v = KaraokeData.voice(for: id, recorded: true)
    let bends = notes.map(v.bend)
    check(v.role.rawValue == webRole[id]?.0 && v.key == webRole[id]?.1, "\(id): \(v.role.rawValue) in key \(Int(v.key)), like the web")
    check(close(bends, webBends[id] ?? []), "\(id): every sung note bends exactly as on the web (max \(bends.map(abs).max() ?? 0))")
}
var sameRole = true, singsOK = true, playsOK = true, worst = (sings: 0.0, plays: 0.0)
for id in everyone {
    let v = KaraokeData.voice(for: id, recorded: true)
    if let w = webRole[id], v.role.rawValue != w.0 || v.key != w.1 { sameRole = false; print("      \(id): \(v.role) key \(v.key), web \(w)") }
    let m = notes.map { abs(v.bend($0)) }.max() ?? 0
    if v.role == .sings { worst.sings = max(worst.sings, m); if m > 5.6 { singsOK = false } }
    if v.role == .plays { worst.plays = max(worst.plays, m); if m > 2 { playsOK = false } }
}
check(sameRole, "all 65 friends: the same key and role as the web")
check(singsOK, "a singing voice is never bent more than 5.6 semitones (worst \(worst.sings))")
check(playsOK, "a sound that is not a note is never bent more than 2 semitones (worst \(worst.plays))")
check(KaraokeData.keyFor(KaraokeData.partMid) == 0 && KaraokeData.keyFor(71.5 + 12) == 0, "a call at the tune's middle keeps the song in C")
check(KaraokeData.keyFor(71.5 - 7) == -7 && KaraokeData.keyFor(71.5 + 4) == 4 && KaraokeData.keyFor(71.5 + 4.6) == -7, "keys stay in -7…4")
check(KaraokeData.jsRound(-2.5) == -2 && KaraokeData.jsRound(2.5) == 3, "rounding matches JavaScript's Math.round")
check(KaraokeData.voice(for: "kitten", recorded: false).role == .synth, "no recording loaded: the synth voice sings")

// MARK: every friend has its sounds

for id in everyone {
    var missing: [String] = []
    if let call = FriendCalls.all[id] { if !recording("call-" + call) { missing.append("call-\(call).mp3") } } else { missing.append("call") }
    if let f = KaraokeData.friends[id] { if KaraokeData.worlds[f.world] == nil { missing.append("world \(f.world)") } } else { missing.append("karaoke world") }
    if !recording("voice-" + id) { missing.append("voice-\(id).mp3") }
    if KaraokeData.sing[id] == nil || !recording("ksing-" + id) { missing.append("sing") }
    if KaraokeData.extra[id] == nil || !recording("kextra-" + id) { missing.append("extra") }
    check(missing.isEmpty, "\(id): call, karaoke world, voice, sing and extra" + (missing.isEmpty ? "" : " — missing \(missing)"))
}
check(Set(FriendCalls.all.keys) == Set(everyone), "every friend has exactly one call entry")
check(KaraokeData.friends.count == 65 && Set(KaraokeData.friends.keys) == Set(everyone), "every friend has a karaoke entry, and no stray ones")
check(Set(aussie.compactMap { KaraokeData.friends[$0]?.world }) == ["bush", "water"], "Aussie Bush friends play in the bush band (the platypus by the water)")
check(Set(christmas.compactMap { KaraokeData.friends[$0]?.world }) == ["jingle"], "Christmas friends play in the jingle band")

// MARK: every instrument a band plays has a recording or a synth stand-in

for (name, w) in KaraokeData.worlds.sorted(by: { $0.key < $1.key }) {
    let need = KaraokeData.instruments(of: w)
    let bad = need.filter { id in
        let recorded = KaraokeData.inst[id] != nil && recording("kinst-" + id)
        return !recorded && !KaraokeData.synthStandIns.contains(id)
    }
    let both = need.filter { KaraokeData.inst[$0] != nil && recording("kinst-" + $0) && KaraokeData.synthStandIns.contains($0) }
    check(bad.isEmpty, "\(name) (\(w.bpm) bpm, \(w.lead) lead): \(need.count) instruments, \(both.count) recorded with a stand-in" + (bad.isEmpty ? "" : " — missing \(bad.sorted())"))
}
check(Set(KaraokeData.worlds.keys) == ["meadow", "woodland", "jungle", "water", "magic", "bush", "jingle"], "7 karaoke worlds: 5 Classic, bush, jingle")
check(KaraokeData.worlds["bush"]?.lead == "banjo" && KaraokeData.worlds["bush"]?.back == "spoons" && KaraokeData.worlds["bush"]?.chirp == "kooka", "bush: banjo lead, spoons, kookaburra chirp")
check(KaraokeData.worlds["jingle"]?.lead == "celesta" && KaraokeData.worlds["jingle"]?.tick == "sleighbells" && KaraokeData.worlds["jingle"]?.chirp == "jingle", "jingle: celesta lead, sleigh bells, jingle chirp")
for id in KaraokeData.inst.keys.sorted() where !recording("kinst-" + id) { check(false, "kinst-\(id).mp3 is bundled") }
check(KaraokeData.inst.count == 23 && KaraokeData.sing.count == 65 && KaraokeData.extra.count == 65, "the web index: 23 instruments, 65 voices, 65 extra sounds")
check(KaraokeData.inst["glock"] == KaraokeData.Rec(d: 0.502, m: 105.49) && KaraokeData.sing["kitten"] == KaraokeData.Rec(d: 0.6, m: 76.52)
      && KaraokeData.sing["duckling"]?.m == nil && KaraokeData.extra["kitten"] == 1.2, "index spot checks match the web")
check(KaraokeData.octaveShift("glock", measured: 105.49) == 24 && KaraokeData.octaveShift("bass", measured: 43.07) == 0
      && KaraokeData.octaveShift("kick", measured: nil) == 0, "recorded notes fold by whole octaves around HOME")

print(failures == 0 ? "All karaoke checks passed" : "\(failures) karaoke check(s) FAILED")
exit(failures == 0 ? 0 : 1)

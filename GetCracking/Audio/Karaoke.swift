import Foundation

/// Egg karaoke, the default hatching song. The native twin of the web app's
/// js/karaoke.js.
///
/// A little band plays an original tune, and the friend who just hatched is one
/// of the players. The tune is carried by instruments and passed around: the
/// lead instrument plays the first verse line, a second instrument takes the
/// next, and in the chorus everyone plays, with a counter-melody and sparkle on
/// top. The friend's own recorded sound (Resources/Sounds/karaoke-sing-<id>.mp3)
/// is one more part in the band, and what it does with it depends on the sound:
///   sings   a call that holds a clear note (a meow, a moo, a hoot) sings in tune.
///           Like real karaoke, the whole song moves to that friend's key, so its
///           voice is only ever nudged a few notes and still sounds like itself.
///   plays   a sound that is not a note (a quack, a grunt, a sniff, a turtle's
///           shell knock, a snail's squelch, a bunny's thump) is never re-pitched:
///           the friend plays it as it is, in time, like a percussion instrument.
/// Which one is decided from the recording (a pitch in `singPitch` = sings).
/// Either way the friend plays:
///   - off-beat stabs through the verse, with its second sound (a purr, a snort,
///     a splash: karaoke-extra-<id>.mp3) and the world's chirps answering
///   - in the chorus it sings the hook together with the lead instrument
///   - one short solo break (its full call), then it joins the "ta-da"
///
/// Every instrument is a single recorded note (karaoke-inst-<id>.mp3), pitched
/// to each note here, so the band is always in time and in tune. Anything not
/// loaded is played by the synth kit in Band.swift instead, so the song always
/// works.
///
///   intro (count-in, hello) → verse (lead, then the second instrument, with the
///   friend's stabs and answers) → chorus (everyone, the friend on the hook)
///   → stop! the friend's solo break → ta-da.

private func midi(_ n: Double) -> Double { 440 * pow(2, (n - 69) / 12) }
/// JavaScript's Math.round (a half rounds up), so key and octave choices match the web
private func jsRound(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

enum Karaoke {
    static let dir = "karaoke/"

    // MARK: friends: their world, and the synthesised stand-in voice (a Kit syllable, Hz)

    struct Friend { let world: String; let synKind: String; let synHz: Double }

    static let friends: [String: Friend] = [
        "chick": Friend(world: "meadow", synKind: "cheep", synHz: 2400), "duckling": Friend(world: "meadow", synKind: "quack", synHz: 380),
        "penguin": Friend(world: "water", synKind: "quack", synHz: 450), "owl": Friend(world: "woodland", synKind: "hoot", synHz: 400),
        "hamster": Friend(world: "meadow", synKind: "squeak", synHz: 2000), "bunny": Friend(world: "meadow", synKind: "bloop", synHz: 260),
        "fox": Friend(world: "woodland", synKind: "woof", synHz: 600), "kitten": Friend(world: "meadow", synKind: "meow", synHz: 650),
        "bearcub": Friend(world: "woodland", synKind: "roar", synHz: 160), "panda": Friend(world: "jungle", synKind: "baa", synHz: 420),
        "frog": Friend(world: "water", synKind: "croak", synHz: 170), "turtle": Friend(world: "water", synKind: "bloop", synHz: 500),
        "dino": Friend(world: "magic", synKind: "roar", synHz: 140), "dragon": Friend(world: "magic", synKind: "roar", synHz: 150),
        "mouse": Friend(world: "meadow", synKind: "squeak", synHz: 2800), "piglet": Friend(world: "meadow", synKind: "oink", synHz: 210),
        "koala": Friend(world: "jungle", synKind: "oink", synHz: 140), "raccoon": Friend(world: "woodland", synKind: "squeak", synHz: 2200),
        "tiger": Friend(world: "jungle", synKind: "roar", synHz: 180), "lion": Friend(world: "jungle", synKind: "roar", synHz: 170),
        "calf": Friend(world: "meadow", synKind: "moo", synHz: 180), "lamb": Friend(world: "meadow", synKind: "baa", synHz: 420),
        "fawn": Friend(world: "woodland", synKind: "meow", synHz: 750), "hedgehog": Friend(world: "woodland", synKind: "squeak", synHz: 2300),
        "otter": Friend(world: "water", synKind: "squeak", synHz: 1800), "seal": Friend(world: "water", synKind: "ork", synHz: 300),
        "axolotl": Friend(world: "water", synKind: "bloop", synHz: 800), "bat": Friend(world: "woodland", synKind: "squeak", synHz: 3000),
        "mole": Friend(world: "woodland", synKind: "sniff", synHz: 2600), "monkey": Friend(world: "jungle", synKind: "ooh", synHz: 450),
        "elephant": Friend(world: "jungle", synKind: "trumpet", synHz: 520), "squirrel": Friend(world: "woodland", synKind: "squeak", synHz: 2500),
        "puppy": Friend(world: "meadow", synKind: "woof", synHz: 300), "unicorn": Friend(world: "magic", synKind: "neigh", synHz: 800),
        "capybara": Friend(world: "jungle", synKind: "squeak", synHz: 1500), "redpanda": Friend(world: "woodland", synKind: "squeak", synHz: 2000),
        "sloth": Friend(world: "jungle", synKind: "squeak", synHz: 1700), "ladybug": Friend(world: "woodland", synKind: "buzz", synHz: 240),
        "snail": Friend(world: "woodland", synKind: "bloop", synHz: 700), "goat": Friend(world: "meadow", synKind: "baa", synHz: 440),
    ]

    // MARK: worlds: lead and second carry the tune; comp, bass, sparkle and the drums fill out the band

    struct World {
        let bpm: Double
        let lead: String, second: String, comp: String, compStyle: String
        let bass: String, bassStyle: String, sparkle: String
        let kick: String, back: String, backGain: Double, tick: String, perc: String?
        let chirp: String
    }

    static let worlds: [String: World] = [
        "meadow": World(bpm: 124, lead: "piano", second: "flute", comp: "uke", compStyle: "strum", bass: "bass", bassStyle: "walk",
                        sparkle: "glock", kick: "kick", back: "clap", backGain: 1, tick: "shaker", perc: "woodblock", chirp: "cheeps"),
        "woodland": World(bpm: 116, lead: "flute", second: "kalimba", comp: "harp", compStyle: "arp", bass: "bass", bassStyle: "root5",
                          sparkle: "glock", kick: "kick", back: "woodblock", backGain: 1, tick: "shaker", perc: nil, chirp: "birds"),
        "jungle": World(bpm: 128, lead: "steelpan", second: "marimba", comp: "marimba", compStyle: "offbeat", bass: "tuba", bassStyle: "oompah",
                        sparkle: "glock", kick: "kick", back: "bongo", backGain: 1, tick: "shaker", perc: "woodblock", chirp: "parrot"),
        "water": World(bpm: 112, lead: "kalimba", second: "glock", comp: "piano", compStyle: "arp", bass: "bass", bassStyle: "root5",
                       sparkle: "flute", kick: "kick", back: "snare", backGain: 0.55, tick: "hat", perc: nil, chirp: "bubbles"),
        "magic": World(bpm: 120, lead: "harp", second: "flute", comp: "piano", compStyle: "block", bass: "tuba", bassStyle: "root5",
                       sparkle: "glock", kick: "kick", back: "snare", backGain: 1, tick: "hat", perc: nil, chirp: "sparkle"),
    ]

    // MARK: the song: an original tune in C
    // ch: (beat, chord, bass root); mel: (beat, note, beats) is the tune, which the band
    // plays; voice is what the friend sings: one syllable per beat, because an
    // animal's call is about half a second long and cutting it shorter makes it stutter.

    struct Bar {
        let ch: [(Double, [Double], Double)]
        let mel: [(Double, Double, Double)]
        let voice: [(Double, Double, Double)]
        var answer: String? = nil
    }

    static let C: [Double] = [60, 64, 67], F: [Double] = [60, 65, 69], G: [Double] = [59, 62, 67], Am: [Double] = [57, 60, 64]

    static let verse: [Bar] = [
        Bar(ch: [(0, C, 36)], mel: [(0, 64, 0.5), (0.5, 64, 0.5), (1, 67, 1), (2, 72, 0.5), (2.5, 69, 0.5), (3, 67, 1)],
            voice: [(0, 64, 1), (1, 67, 1), (2, 72, 1), (3, 67, 1)]),
        Bar(ch: [(0, F, 41), (2, G, 43)], mel: [(0, 65, 0.5), (0.5, 65, 0.5), (1, 64, 0.5), (1.5, 62, 0.5), (2, 67, 1)],
            voice: [(0, 65, 1), (1, 62, 1), (2, 67, 1)], answer: "extra"),
        Bar(ch: [(0, C, 36), (2, Am, 45)], mel: [(0, 64, 0.5), (0.5, 64, 0.5), (1, 67, 1), (2, 72, 0.5), (2.5, 74, 0.5), (3, 76, 1)],
            voice: [(0, 64, 1), (1, 67, 1), (2, 72, 1), (3, 76, 1)]),
        Bar(ch: [(0, F, 41), (1, G, 43), (2, C, 36)], mel: [(0, 69, 0.5), (0.5, 72, 0.5), (1, 71, 0.5), (1.5, 74, 0.5), (2, 72, 1)],
            voice: [(0, 69, 1), (1, 71, 1), (2, 72, 1)], answer: "chirp"),
    ]
    static let chorus: [Bar] = [
        Bar(ch: [(0, F, 41), (2, C, 36)], mel: [(0, 72, 1), (1, 72, 0.5), (1.5, 74, 0.5), (2, 76, 1), (3, 72, 1)],
            voice: [(0, 72, 1), (1, 74, 1), (2, 76, 1), (3, 72, 1)]),
        Bar(ch: [(0, G, 43), (2, C, 36)], mel: [(0, 74, 0.5), (0.5, 74, 0.5), (1, 71, 0.5), (1.5, 74, 0.5), (2, 72, 2)],
            voice: [(0, 74, 1), (1, 71, 1), (2, 72, 2)]),
    ]

    /// the middle of the tune, where the synthesised stand-in voices sit
    static let melMid = 69.0
    /// The friend's own notes run from the G of its verse stabs to the E at the top
    /// of the hook. The song is moved (keyLo...keyHi semitones) so the middle of that
    /// range lands on the pitch of the friend's own call.
    static let partMid = 71.5, keyLo = -7.0, keyHi = 4.0

    static func keyFor(_ pitch: Double) -> Double {
        var k = (pitch - partMid).truncatingRemainder(dividingBy: 12)
        k = (k + 12).truncatingRemainder(dividingBy: 12) // 0..12
        if k > keyHi + 0.5 { k -= 12 }
        return max(keyLo, min(keyHi, jsRound(k)))
    }

    /// a low key must not push the bass below what a small speaker can play
    static let bassFloor: [String: Double] = ["bass": 31, "tuba": 31]

    // MARK: the recordings (sounds/index.json, measured by tools/pick-karaoke.js)

    /// instrument notes: id → the MIDI pitch it was recorded at (absent = a drum, never re-pitched)
    static let instIds = ["kick", "snare", "hat", "shaker", "clap", "bongo", "woodblock", "bass", "tuba", "uke", "piano",
                          "marimba", "glock", "flute", "harp", "kalimba", "steelpan", "whistle", "sparkle"]
    static let instPitch: [String: Double] = [
        "bass": 43.07, "tuba": 39.09, "uke": 69.08, "piano": 72.14, "marimba": 72.09, "glock": 105.49, "flute": 74.14,
        "harp": 75.96, "kalimba": 71.16, "steelpan": 72.1,
    ]
    /// each friend's singing voice: the pitch of a call that holds a note (absent = it plays its sound as it is)
    static let singPitch: [String: Double] = [
        "chick": 97.48, "penguin": 65.8, "owl": 66.38, "hamster": 89.63, "kitten": 76.52, "bearcub": 86.95, "panda": 64.72,
        "dino": 79.78, "dragon": 90.98, "koala": 65.04, "raccoon": 103.16, "tiger": 84.57, "lion": 86.45, "calf": 51.71,
        "lamb": 66.07, "fawn": 96.36, "hedgehog": 93.01, "otter": 69.61, "seal": 77.41, "monkey": 83.9, "elephant": 80.55,
        "squirrel": 96.51, "puppy": 78.45, "capybara": 86.91, "redpanda": 98.67, "goat": 65.36,
    ]

    /// (sample key, bundle file) for every karaoke recording loaded at start-up;
    /// each friend's extra sound is loaded when it hatches
    static var startupFiles: [(String, String)] {
        instIds.map { (dir + "inst/" + $0, "karaoke-inst-" + $0) } +
            friends.keys.sorted().map { (dir + "sing/" + $0, "karaoke-sing-" + $0) }
    }

    // MARK: instruments: the recorded note when loaded, else the synth kit

    static let gain: [String: Double] = [
        "kick": 0.95, "snare": 0.5, "hat": 0.28, "shaker": 0.32, "clap": 0.5, "bongo": 0.55, "woodblock": 0.45,
        "bass": 0.85, "tuba": 0.72, "uke": 0.27, "piano": 0.27, "marimba": 0.36, "glock": 0.28, "flute": 0.38,
        "harp": 0.32, "kalimba": 0.36, "steelpan": 0.36, "whistle": 0.35, "sparkle": 0.4,
    ]
    /// the friend's voice is one part in the band, level with the instruments
    static let singGain = 1.3
    /// whichever instrument has the tune sits a little forward
    static let leadGain = 1.35
    /// pitched recordings move by whole octaves to sit near home (a glockenspiel plays where a glockenspiel lives)
    static let home: [String: Double] = ["bass": 40, "tuba": 40, "uke": 64, "piano": 64, "marimba": 64, "harp": 64,
                                         "kalimba": 72, "glock": 84, "flute": 76, "steelpan": 72]

    /// the synthesised stand-in for each instrument
    static func syn(_ id: String, _ k: Kit, _ n: Double, _ t: Double, _ d: Double, _ g: Double, _ o: Ch) {
        switch id {
        case "kick": k.kick(t, 0.5 * g)
        case "snare": k.snare(t, 0.2 * g)
        case "hat": k.hat(t, 0.05 * g)
        case "shaker": k.shaker(t, 0.045 * g)
        case "clap": k.clap(t, 0.13 * g)
        case "bongo": k.bongo(t, true, 0.13 * g)
        case "woodblock": k.woodblock(t, true, 0.08 * g)
        case "bass": k.bass(n, t, d, 0.22 * g)
        case "tuba": k.tuba(n, t, d, 0.19 * g)
        case "uke": k.uke([n], t, 0.05 * g)
        case "piano": k.piano(n, t, d, 0.06 * g, o)
        case "marimba": k.marimba(n, t, 0.08 * g, o)
        case "glock": k.glock(n, t, 1.1, 0.04 * g)
        case "flute": k.flute(n, t, d, 0.06 * g, o)
        case "harp": k.harp([n], t, 0, 0.045 * g)
        case "kalimba": k.xylo(n, t, 0.07 * g)
        case "steelpan": k.steel(n, t, 0.9, 0.08 * g)
        case "whistle": k.slideWhistle(t, n, n + 12, 0.4, 0.06 * g)
        case "sparkle":
            for (i, x) in [0.0, 4, 7, 12, 16].enumerated() { k.glock(n + x, t + Double(i) * 0.055, 0.8, 0.03 * g) }
        default: break
        }
    }

    /// an animal syllable from the synth kit, by name
    static func say(_ kind: String, _ k: Kit, _ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ g: Double = 1) {
        switch kind {
        case "moo": k.moo(t, f, d, c, g)
        case "quack": k.quack(t, f, d, c, g)
        case "baa": k.baa(t, f, d, c, g)
        case "woof": k.woof(t, f, d, c, g)
        case "meow": k.meow(t, f, d, c, g)
        case "oink": k.oink(t, f, d, c, g)
        case "hoot": k.hoot(t, f, d, c, g)
        case "cheep": k.cheep(t, f, d, c, g)
        case "trumpet": k.trumpet(t, f, d, c, g)
        case "roar": k.roar(t, f, d, c, g)
        case "neigh": k.neigh(t, f, d, c, g)
        case "squeak": k.squeak(t, f, d, c, g)
        case "ork": k.ork(t, f, d, c, g)
        case "croak": k.croak(t, f, d, c, g)
        case "ooh": k.ooh(t, f, d, c, g)
        case "buzz": k.buzz(t, f, d, c, g)
        case "bloop": k.bloop(t, f, d, c, g)
        case "sniff": k.sniff(t, f, d, c, g)
        default: k.cheep(t, f, d, c, g)
        }
    }

    // MARK: one friend's part in the band

    /// Decided once, at the start, so a song never switches voice halfway through.
    final class Player {
        let world: World
        let friendId: String
        /// semitones the whole song moves to sit in the friend's key
        let key: Double
        /// "sings", "plays" or "synth"
        let role: String
        let recorded: Bool
        private let use: [String: (base: Double?, off: Double)]
        private let voice: (base: Double, off: Double)?
        private let synKind: String
        private let synOff: Double
        private let hasExtra: Bool

        init(_ s: Synth, friendId: String) {
            func has(_ key: String) -> Bool { s.samples[Karaoke.dir + key] != nil }
            var u: [String: (base: Double?, off: Double)] = [:]
            for id in Karaoke.instIds where has("inst/" + id) {
                let m = Karaoke.instPitch[id]
                var off = 0.0
                if let m, let h = Karaoke.home[id] { off = 12 * jsRound((m - h) / 12) }
                u[id] = (m, off)
            }
            use = u
            let f = Karaoke.friends[friendId] ?? Friend(world: "meadow", synKind: "cheep", synHz: 2400)
            self.friendId = friendId
            world = Karaoke.worlds[f.world] ?? Karaoke.worlds["meadow"]!
            synKind = f.synKind
            // a recorded call with a pitch sings (and sets the key); one without is played as it is
            let rec = has("sing/" + friendId)
            recorded = rec
            if rec, let m = Karaoke.singPitch[friendId] {
                let k = Karaoke.keyFor(m)
                key = k
                voice = (m, 12 * jsRound((m - (Karaoke.partMid + k)) / 12))
                role = "sings"
            } else {
                key = 0
                voice = nil
                role = rec ? "plays" : "synth"
            }
            // synth voice: whole octaves too, so the tune keeps its shape
            synOff = 12 * jsRound((69 + 12 * log2(f.synHz / 440) - Karaoke.melMid) / 12)
            hasExtra = has("extra/" + friendId)
        }

        /// one instrument note; d = how long it may ring (0 = let a drum ring out)
        func inst(_ k: Kit, _ id: String, _ n0: Double, _ t: Double, _ d: Double, _ g: Double = 1, _ out: Ch = .comp) {
            var n = n0 + key
            if let fl = Karaoke.bassFloor[id], n < fl { n += 12 }
            guard let u = use[id] else { Karaoke.syn(id, k, n, t, d, g, out); return }
            let rate = u.base.map { pow(2, (n + u.off - $0) / 12) } ?? 1
            k.s.playSample(Karaoke.dir + "inst/" + id, at: t, bus: k.bus, gain: (Karaoke.gain[id] ?? 0.3) * g * k.g(out),
                           rate: rate, maxDur: d > 0 ? max(d, 0.25) : nil)
        }

        /// One sung syllable: it rings for as long as it naturally lasts, overlapping
        /// the next by a touch (legato), and is only faded (gently, never chopped)
        /// if the call is longer than that.
        func sing(_ k: Kit, _ n: Double, _ t: Double, _ d: Double, _ out: Ch, _ g: Double = 1) {
            let len = d + 0.1
            let sample = Karaoke.dir + "sing/" + friendId
            if let v = voice {
                let rate = pow(2, (n + key + v.off - v.base) / 12)
                k.s.playSample(sample, at: t, bus: k.bus, gain: Karaoke.singGain * g * k.g(out), rate: rate, maxDur: len, fade: 0.12)
            } else if recorded {
                // not a note: its own sound, as it is. It only leans a touch up or down
                // with the tune (two semitones at most), the way a drummer moves between toms
                let lean = max(-2, min(2, (n - Karaoke.partMid) * 0.35))
                k.s.playSample(sample, at: t, bus: k.bus, gain: Karaoke.singGain * g * k.g(out), rate: pow(2, lean / 12),
                               maxDur: len, fade: 0.12)
            } else {
                Karaoke.say(synKind, k, t, midi(n + synOff), synKind == "cheep" ? min(len, 0.14) : len, out, g)
            }
        }

        /// its second sound; if that has not loaded, the world's chirp answers instead
        func extra(_ k: Kit, _ t: Double, _ out: Ch, _ chord: [Double]) {
            if hasExtra {
                k.s.playSample(Karaoke.dir + "extra/" + friendId, at: t, bus: k.bus, gain: 0.85 * k.g(out), maxDur: 1.4)
            } else {
                chirp(k, t, chord)
            }
        }

        /// tones and chirps that suit the world, always on the chord's notes
        func chirp(_ k: Kit, _ t: Double, _ chord: [Double]) {
            let hi = chord.map { $0 + 24 + key }
            let o: Ch = .sparkle
            switch world.chirp {
            case "cheeps":
                k.cheep(t, midi(hi[2]), 0.08, o, 0.8)
                k.cheep(t + 0.12, midi(hi[2] + 5), 0.08, o, 0.8)
                inst(k, "whistle", 72, t + 0.24, 0, 0.8, o)
            case "birds":
                for i in 0..<6 {
                    k.cheep(t + Double(i) * 0.065, midi(hi[i % 2 == 1 ? 2 : 1] + (i > 3 ? 12 : 0)), 0.05, o, 0.7)
                }
            case "parrot":
                k.squeak(t, midi(hi[0]), 0.16, o, 0.9)
                k.squeak(t + 0.2, midi(hi[2]), 0.2, o, 0.9)
                inst(k, "bongo", 0, t + 0.1, 0, 0.6, .drums)
                inst(k, "bongo", 0, t + 0.22, 0, 0.5, .drums)
            case "bubbles":
                for (i, j) in [0, 1, 2, 0].enumerated() {
                    k.bloop(t + Double(i) * 0.09, midi(chord[j] + key + 12 * (i == 3 ? 2 : 1)), 0.1, o, 0.9)
                }
            default: // sparkle
                inst(k, "sparkle", 84, t, 0, 0.8, o)
                for (i, n) in (chord + [chord[0] + 12]).enumerated() { inst(k, "glock", n + 12, t + Double(i) * 0.07, 0.6, 0.6, o) }
            }
        }
    }

    // MARK: putting the song together

    /// A song arranged for one friend: its events (by beat), length in beats, the
    /// ring-out after the last beat, and when the friend sings (beat, seconds) so
    /// the friend on screen can bop along.
    struct Arrangement {
        let score: Score
        let beats: Double
        let tail: Double
        let sung: [(beat: Double, len: Double)]
        let player: Player
    }

    static func arrange(_ s: Synth, friendId: String, spb: Double) -> Arrangement {
        let sc = Score()
        let p = Player(s, friendId: friendId)
        let w = p.world
        var sung: [(beat: Double, len: Double)] = []
        func at(_ beat: Double, _ fn: @escaping (Kit, Double) -> Void) { sc.at(beat, fn) }
        func singAt(_ beat: Double, _ n: Double, _ d: Double, _ out: Ch) {
            sc.at(beat) { k, t in p.sing(k, n, t, d, out) }
            sung.append((beat, d + 0.1))
        }

        func groove(_ b: Double, _ full: Bool) {
            for x in stride(from: 0.0, to: 4, by: 0.5) {
                if x.truncatingRemainder(dividingBy: 2) == 0 { at(b + x) { k, t in p.inst(k, w.kick, 0, t, 0, 1, .drums) } }
                if x == 1 || x == 3 {
                    at(b + x) { k, t in
                        p.inst(k, w.back, 0, t, 0, w.backGain, .drums)
                        if full && w.back != "clap" { p.inst(k, "clap", 0, t, 0, 0.7, .drums) }
                    }
                }
                let tg = x.truncatingRemainder(dividingBy: 1) != 0 ? 0.6 : 1
                at(b + x) { k, t in p.inst(k, w.tick, 0, t, 0, tg, .drums) }
            }
            if let perc = w.perc {
                for x in [1.5, 3.5] { at(b + x) { k, t in p.inst(k, perc, 0, t, 0, 0.6, .drums) } }
            }
        }

        func bass(_ b: Double, _ r: Double, _ beats: Double) {
            let steps: [(Double, Double)]
            switch w.bassStyle {
            case "walk":
                steps = beats >= 4 ? [(0, r), (1, r + 4), (2, r + 7), (3, r + 9)] : beats >= 2 ? [(0, r), (1, r + 7)] : [(0, r)]
            case "oompah":
                steps = beats >= 4 ? [(0, r), (2, r + 7)] : [(0, r)]
            default:
                steps = beats >= 4 ? [(0, r), (2, r + 7), (3.5, r + 7)] : [(0, r)]
            }
            for (x, n) in steps { at(b + x) { k, t in p.inst(k, w.bass, n, t, spb * 0.9, 1, .bass) } }
        }

        func comp(_ b: Double, _ chord: [Double], _ beats: Double) {
            switch w.compStyle {
            case "strum":
                for (x, g) in [(0.0, 1.0), (1, 0.7), (1.5, 0.8), (2.5, 0.7), (3, 0.8)] where x < beats {
                    at(b + x) { k, t in
                        for (i, n) in chord.enumerated() { p.inst(k, w.comp, n, t + Double(i) * 0.015, spb * 1.5, g) }
                    }
                }
            case "arp":
                let notes = [chord[0], chord[1], chord[2], chord[0] + 12, chord[2], chord[1], chord[2], chord[0] + 12]
                for i in 0..<Int(beats * 2) {
                    let n = notes[i % 8], g = i % 2 == 1 ? 0.7 : 1
                    at(b + Double(i) * 0.5) { k, t in p.inst(k, w.comp, n, t, spb, g) }
                }
            case "offbeat":
                for x in stride(from: 0.5, to: beats, by: 1) {
                    at(b + x) { k, t in for n in [chord[1], chord[2]] { p.inst(k, w.comp, n, t, spb * 0.5, 0.9) } }
                }
            default: // block chords on the beat, a lighter one on the "and" before the next
                for x in stride(from: 0.0, to: beats, by: 2) {
                    at(b + x) { k, t in for n in chord { p.inst(k, w.comp, n, t, spb * 1.6, 1) } }
                    if x + 1.5 < beats {
                        at(b + x + 1.5) { k, t in for n in chord { p.inst(k, w.comp, n + 12, t, spb * 0.5, 0.5) } }
                    }
                }
            }
        }

        func melody(_ id: String, _ b: Double, _ mel: [(Double, Double, Double)], _ g: Double, _ up: Double = 12, _ out: Ch = .lead) {
            for (x, n, d) in mel { at(b + x) { k, t in p.inst(k, id, n + up, t, d * spb * 1.05, g, out) } }
        }

        func bars(_ list: [Bar], _ b0: Double, _ isChorus: Bool) {
            for (i, bar) in list.enumerated() {
                let b = b0 + Double(i) * 4
                groove(b, isChorus)
                for (j, change) in bar.ch.enumerated() {
                    let (x, chord, root) = change
                    let beats = (j + 1 < bar.ch.count ? bar.ch[j + 1].0 : 4) - x
                    bass(b + x, root, beats)
                    comp(b + x, chord, beats)
                }
                func chordAt(_ x: Double) -> [Double] { bar.ch.filter { $0.0 <= x }.last?.1 ?? bar.ch[0].1 }
                let harmony = bar.mel.filter { $0.2 >= 1 }.map { ($0.0, Band.harmony($0.1, chordAt($0.0)), $0.2) }
                if !isChorus {
                    // the tune passes around the band: the lead's line, then the second instrument's
                    let (tune, other) = i < 2 ? (w.lead, w.second) : (w.second, w.lead)
                    melody(tune, b, bar.mel, Karaoke.leadGain)
                    melody(other, b, harmony, 0.45, 12, .sparkle)
                    // the friend: off-beat stabs on the chord, and its answers in the gaps
                    singAt(b + 1, chordAt(1)[2], spb * 0.75, .aR)
                    if bar.answer == nil { singAt(b + 3, chordAt(3)[0] + 12, spb * 0.75, .aR) }
                } else {
                    // everyone: the tune on the lead, a counter-melody, sparkle up high, the friend on the hook
                    melody(w.lead, b, bar.mel, Karaoke.leadGain)
                    melody(w.second, b, harmony, 0.6, 12, .sparkle)
                    melody(w.sparkle, b, bar.mel, 0.4, 24, .sparkle)
                    for (x, n, d) in bar.voice { singAt(b + x, n, d * spb, .solo) }
                }
                if bar.answer == "extra" {
                    let ch = chordAt(3)
                    at(b + 3) { k, t in p.extra(k, t, .aR, ch) }
                }
                if bar.answer == "chirp" {
                    let ch = chordAt(3)
                    at(b + 3) { k, t in p.chirp(k, t, ch) }
                    // the band echoes the end of the line, an octave up
                    for (j, note) in bar.mel.suffix(3).enumerated() {
                        let n = note.1
                        at(b + 3 + Double(j) * 0.25) { k, t in p.inst(k, w.lead, n + 24, t, spb * 0.4, 0.7, .sparkle) }
                    }
                }
            }
        }

        // intro: a count-in on the sticks, the band walks up, the friend says hello
        for x in 0..<4 {
            let g = x == 0 ? 1.0 : 0.7
            at(Double(x)) { k, t in p.inst(k, "woodblock", 0, t, 0, g, .drums) }
        }
        at(0) { k, t in for n in C { p.inst(k, w.comp, n, t, spb * 2, 0.7) } }
        singAt(2, 67, spb, .aR)
        for (i, n) in [60.0, 64, 67, 72].enumerated() {
            at(2 + Double(i) * 0.5) { k, t in p.inst(k, w.lead, n + 12, t, spb * 0.5, 0.8, .lead) }
        }
        at(3) { k, t in p.inst(k, w.bass, 43, t, spb * 0.9, 1, .bass) }
        at(3.5) { k, t in p.chirp(k, t, C) }
        var b = 4.0

        // verse: the instruments take turns with the tune; the friend plays along
        bars(verse, b, false)
        b += Double(verse.count) * 4

        // chorus: the whole band, the friend singing the hook with the lead
        at(b) { k, t in k.crash(t, 0.1) }
        bars(chorus, b, true)
        b += Double(chorus.count) * 4
        // a chirp in the chorus's last held note
        at(b - 1) { k, t in p.chirp(k, t, C) }

        // stop! one band hit, then the friend's solo break: its own full call
        at(b) { k, t in
            k.crash(t, 0.12)
            p.inst(k, w.kick, 0, t, 0, 1, .drums)
            p.inst(k, w.bass, 36, t, spb, 1, .bass)
            for n in C { p.inst(k, w.comp, n, t, spb, 1) }
        }
        let call = Band.friendCalls[friendId] ?? "cheep"
        let callLen = Band.lenOf(call, s)
        let soloAt = b + 1
        let padNotes = [60.0, 64, 67].map { $0 + p.key }
        at(soloAt) { k, t in
            Band.playCall(k, call, t, .solo)
            k.strings(padNotes, t, callLen + spb, 0.01)
        }
        // ta-da: the whole band, the friend with them, then one last ad-lib
        let end = ((soloAt + (callLen + 0.15) / spb) * 2).rounded(.up) / 2
        singAt(end, 67, spb, .solo)
        at(end) { k, t in
            p.inst(k, w.lead, 79, t, spb, Karaoke.leadGain, .lead)
            p.inst(k, w.kick, 0, t, 0, 1, .drums)
        }
        singAt(end + 1, 72, spb * 2, .solo)
        at(end + 1) { k, t in
            p.inst(k, w.lead, 84, t, spb * 3, Karaoke.leadGain, .lead)
            p.inst(k, w.second, 76, t, spb * 3, 0.7, .sparkle)
            k.crash(t, 0.13)
            p.inst(k, w.kick, 0, t, 0, 1, .drums)
            p.inst(k, w.bass, 36, t, spb * 3, 1, .bass)
            for (i, n) in [48.0, 55, 60, 64, 67, 72].enumerated() { p.inst(k, w.comp, n, t + Double(i) * 0.03, spb * 3, 0.8) }
            p.chirp(k, t + 0.1, C)
        }
        at(end + 2.5) { k, t in p.extra(k, t, .aR, C) }
        return Arrangement(score: sc, beats: end + 2.5, tail: 2.6, sung: sung, player: p)
    }

    /// Egg karaoke for this friend (or a random one: the settings preview, or a
    /// photo that hatched).
    static func friend(for id: String?) -> String {
        if let id, friends[id] != nil { return id }
        return friends.keys.randomElement() ?? "chick"
    }

    /// Arrange the song and hand it to the synth. Returns its length in seconds
    /// and, for each sung note, how long from now until it starts and how long it lasts.
    static func perform(friend id: String, on s: Synth) -> (len: Double, sung: [(delay: Double, len: Double)]) {
        let fid = friend(for: id)
        let w = worlds[friends[fid]?.world ?? "meadow"] ?? worlds["meadow"]!
        let spb = 60 / w.bpm
        let t0 = s.t + 0.08
        let kit = Kit(s: s, bus: .celeb, mix: true, t0: t0, spb: spb)
        let a = arrange(s, friendId: fid, spb: spb)
        let events = a.score.events
            .map { (t: t0 + $0.beat * spb, fn: $0.fn) }
            .sorted { $0.t < $1.t }
        let len = a.beats * spb + a.tail
        s.startCelebration(Celebration(events: events, kit: kit, end: t0 + len, friendCall: Band.friendCalls[fid] ?? "cheep"))
        let sung = a.sung.map { (delay: t0 + $0.beat * spb - s.t, len: $0.len) }
        return (len, sung)
    }
}

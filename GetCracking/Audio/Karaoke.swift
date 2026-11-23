import Foundation

/// Egg karaoke, the default hatching song. The native twin of the web app's
/// js/karaoke.js.
///
/// A little band plays an original tune, and the friend who just hatched is one
/// of the players. The tune is carried by instruments and passed around: the
/// lead instrument plays the first verse line, a second instrument takes the
/// next, and in the chorus everyone plays, with a counter-melody and sparkle on
/// top. The friend's own recorded sound (Resources/Sounds/kara-sing-<id>.mp3)
/// is one more part in the band, and what it does with it depends on the sound:
///   sings   a call that holds a clear note (a meow, a moo, a hoot) sings in
///           tune. Like real karaoke, the whole song moves to that friend's
///           key, so its voice is only ever nudged a few notes.
///   plays   a sound that is not a note (a quack, a sniff, a turtle's shell
///           knock, a bunny's thump) is never re-pitched: the friend plays it
///           as it is, in time, like a percussion instrument.
/// Which one is decided by the recording (a pitch in `singPitch` = sings).
/// Either way the friend plays off-beat stabs through the verse, with its
/// second sound (kara-extra-<id>.mp3) and the world's chirps answering in the
/// gaps; sings the hook with the lead in the chorus; takes one short solo
/// break (its full call); then joins the "ta-da".
///
/// Each world has its own band:
///   meadow    piano lead, flute, ukulele, upright bass, claps, egg shaker, wood block, glockenspiel, cheeps + slide whistle
///   woodland  flute lead, kalimba, harp, upright bass, wood block, shaker, glockenspiel, birdsong trills
///   jungle    steel pan lead, marimba, tuba, bongos, shaker, wood block, glockenspiel, parrot whistles
///   water     kalimba lead, glockenspiel, piano, upright bass, soft snare, hi-hat, flute, bubble bloops
///   magic     harp lead, flute, piano, tuba, snare, hi-hat, glockenspiel, sparkles
///
/// Every instrument is one recorded note (kara-inst-<id>.mp3), pitched to each
/// note here by its playback rate. Anything that has not loaded is played by
/// the synthesised kit in Band.swift instead, so the song always works.
///
///   intro (count-in, hello) → verse → chorus → stop! the friend's solo → ta-da.

private func midi(_ n: Double) -> Double { 440 * pow(2, (n - 69) / 12) }

/// JavaScript's Math.round (halves go up), so keys match the web exactly
private func jsRound(_ x: Double) -> Double { floor(x + 0.5) }

/// the nearest chord tone a bit below a melody note: a simple harmony line
private func harmonyBelow(_ n: Double, _ chord: [Double]) -> Double {
    var best: Double = n - 12
    for c in chord {
        var o: Double = -24
        while o <= 12 {
            let h: Double = c + o
            if h <= n - 3 && h > best { best = h }
            o += 12
        }
    }
    return best
}

// MARK: - a few more instruments for the synthesised stand-in band

extension Kit {
    func woodblock(_ t: Double, _ hi: Bool = true, _ gn: Double = 0.1) {
        tone(hi ? 1250 : 880, t, 0.07, .drums, gain: gn, partials: [(1, 1), (2.4, 0.3)])
    }

    func xylo(_ n: Double, _ t: Double, _ gn: Double = 0.08) {
        tone(midi(n), t, 0.35, .sparkle, gain: gn, partials: [(1, 1), (3.93, 0.25), (9.4, 0.05)])
    }

    /// the flute, on any channel
    func fluteOn(_ n: Double, _ t: Double, _ d: Double, _ gn: Double, _ c: Ch) {
        let m: Double = midi(n)
        let path: PitchPath = [(0, m)]
        V(t, VSpec(type: .sine, f: path, partials: [(1, 1), (2, 0.14), (3, 0.04)], dur: d, gain: gn, attack: 0.06, sus: 0.9,
                   vib: (5, 14, 0.15), noise: 0.05, noiseF: m * 2), c)
    }

    /// any animal syllable by name, with a level (the friend's synthesised stand-in voice)
    func say(_ kind: String, _ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double) {
        switch kind {
        case "moo": moo(t, f, d, c, gn)
        case "quack": quack(t, f, d, c, gn)
        case "baa": baa(t, f, d, c, gn)
        case "woof": woof(t, f, d, c, gn)
        case "meow": meow(t, f, d, c, gn)
        case "oink": oink(t, f, d, c, gn)
        case "hoot": hoot(t, f, d, c, gn)
        case "cheep": cheep(t, f, d, c, gn)
        case "trumpet": trumpet(t, f, d, c, gn)
        case "roar": roar(t, f, d, c, gn)
        case "neigh": neigh(t, f, d, c, gn)
        case "squeak": squeak(t, f, d, c, gn)
        case "ork": ork(t, f, d, c, gn)
        case "croak": croak(t, f, d, c, gn)
        case "ooh": ooh(t, f, d, c, gn)
        case "ah": ah(t, f, d, c, gn)
        case "crow": crow(t, f, d, c, gn)
        case "buzz": buzz(t, f, d, c, gn)
        case "bloop": bloop(t, f, d, c, gn)
        case "sniff": sniff(t, f, d, c, gn)
        default: break
        }
    }
}

// MARK: - the song and its bands

enum Karaoke {
    /// the song's id in Sound.endSounds and Settings.endSound
    static let id = "karaoke"
    /// sample keys: "karaoke/inst/<id>", "karaoke/sing/<friend>", "karaoke/extra/<friend>"
    static let dir = "karaoke/"

    enum CompStyle { case strum, arp, offbeat, block }
    enum BassStyle { case walk, root5, oompah }
    enum Chirp { case cheeps, birds, parrot, bubbles, sparkle }
    /// what fills the gap at the end of a verse line: the friend's own stab,
    /// its second sound, or the world's chirp
    enum Answer { case stab, extra, chirp }

    /// lead and second carry the tune; comp, bass, sparkle and the drums fill out the band
    struct World {
        let bpm: Double
        let lead: String
        let second: String
        let comp: String
        let compStyle: CompStyle
        let bass: String
        let bassStyle: BassStyle
        let sparkle: String
        let back: String
        let backGain: Double
        let tick: String
        let perc: String?
        let chirp: Chirp
    }

    static let worlds: [String: World] = [
        "meadow": World(bpm: 124, lead: "piano", second: "flute", comp: "uke", compStyle: .strum, bass: "bass", bassStyle: .walk,
                        sparkle: "glock", back: "clap", backGain: 1, tick: "shaker", perc: "woodblock", chirp: .cheeps),
        "woodland": World(bpm: 116, lead: "flute", second: "kalimba", comp: "harp", compStyle: .arp, bass: "bass", bassStyle: .root5,
                          sparkle: "glock", back: "woodblock", backGain: 1, tick: "shaker", perc: nil, chirp: .birds),
        "jungle": World(bpm: 128, lead: "steelpan", second: "marimba", comp: "marimba", compStyle: .offbeat, bass: "tuba", bassStyle: .oompah,
                        sparkle: "glock", back: "bongo", backGain: 1, tick: "shaker", perc: "woodblock", chirp: .parrot),
        "water": World(bpm: 112, lead: "kalimba", second: "glock", comp: "piano", compStyle: .arp, bass: "bass", bassStyle: .root5,
                       sparkle: "flute", back: "snare", backGain: 0.55, tick: "hat", perc: nil, chirp: .bubbles),
        "magic": World(bpm: 120, lead: "harp", second: "flute", comp: "piano", compStyle: .block, bass: "tuba", bassStyle: .root5,
                       sparkle: "glock", back: "snare", backGain: 1, tick: "hat", perc: nil, chirp: .sparkle),
    ]

    /// each friend's world, then its synthesised stand-in voice: (syllable in Kit.say, Hz)
    static let friends: [String: (String, String, Double)] = [
        "chick": ("meadow", "cheep", 2400), "duckling": ("meadow", "quack", 380), "penguin": ("water", "quack", 450),
        "owl": ("woodland", "hoot", 400), "hamster": ("meadow", "squeak", 2000), "bunny": ("meadow", "bloop", 260),
        "fox": ("woodland", "woof", 600), "kitten": ("meadow", "meow", 650), "bearcub": ("woodland", "roar", 160),
        "panda": ("jungle", "baa", 420), "frog": ("water", "croak", 170), "turtle": ("water", "bloop", 500),
        "dino": ("magic", "roar", 140), "dragon": ("magic", "roar", 150), "mouse": ("meadow", "squeak", 2800),
        "piglet": ("meadow", "oink", 210), "koala": ("jungle", "oink", 140), "raccoon": ("woodland", "squeak", 2200),
        "tiger": ("jungle", "roar", 180), "lion": ("jungle", "roar", 170), "calf": ("meadow", "moo", 180),
        "lamb": ("meadow", "baa", 420), "fawn": ("woodland", "meow", 750), "hedgehog": ("woodland", "squeak", 2300),
        "otter": ("water", "squeak", 1800), "seal": ("water", "ork", 300), "axolotl": ("water", "bloop", 800),
        "bat": ("woodland", "squeak", 3000), "mole": ("woodland", "sniff", 2600), "monkey": ("jungle", "ooh", 450),
        "elephant": ("jungle", "trumpet", 520), "squirrel": ("woodland", "squeak", 2500), "puppy": ("meadow", "woof", 300),
        "unicorn": ("magic", "neigh", 800), "capybara": ("jungle", "squeak", 1500), "redpanda": ("woodland", "squeak", 2000),
        "sloth": ("jungle", "squeak", 1700), "ladybug": ("woodland", "buzz", 240), "snail": ("woodland", "bloop", 700),
        "goat": ("meadow", "baa", 440),
    ]

    // ---- the recordings (web: sounds/index.json → karaoke)

    /// every band instrument that has a recorded note
    static let instruments: [String] = [
        "kick", "snare", "hat", "shaker", "clap", "bongo", "woodblock", "bass", "tuba", "uke", "piano", "marimba",
        "glock", "flute", "harp", "kalimba", "steelpan", "whistle", "sparkle",
    ]

    /// the pitch (MIDI note, with cents) of each pitched instrument's recorded note
    static let instPitch: [String: Double] = [
        "bass": 43.07, "tuba": 39.09, "uke": 69.08, "piano": 72.14, "marimba": 72.09, "glock": 105.49,
        "flute": 74.14, "harp": 75.96, "kalimba": 71.16, "steelpan": 72.1,
    ]

    /// Friends whose recorded call holds a clear note: they sing, and the song
    /// moves to their key. Everyone else plays their sound as it is.
    static let singPitch: [String: Double] = [
        "chick": 97.48, "penguin": 65.8, "owl": 66.38, "hamster": 89.63, "kitten": 76.52, "bearcub": 86.95,
        "panda": 64.72, "dino": 79.78, "dragon": 90.98, "koala": 65.04, "raccoon": 103.16, "tiger": 84.57,
        "lion": 86.45, "calf": 51.71, "lamb": 66.07, "fawn": 96.36, "hedgehog": 93.01, "otter": 69.61,
        "seal": 77.41, "monkey": 83.9, "elephant": 80.55, "squirrel": 96.51, "puppy": 78.45, "capybara": 86.91,
        "redpanda": 98.67, "goat": 65.36,
    ]

    /// level of each recorded instrument
    static let gain: [String: Double] = [
        "kick": 0.95, "snare": 0.5, "hat": 0.28, "shaker": 0.32, "clap": 0.5, "bongo": 0.55, "woodblock": 0.45,
        "bass": 0.85, "tuba": 0.72, "uke": 0.27, "piano": 0.27, "marimba": 0.36, "glock": 0.28, "flute": 0.38,
        "harp": 0.32, "kalimba": 0.36, "steelpan": 0.36, "whistle": 0.35, "sparkle": 0.4,
    ]
    /// the friend's voice is one part in the band, level with the instruments
    static let singGain: Double = 1.3
    /// whichever instrument has the tune sits a little forward
    static let leadGain: Double = 1.35
    /// Pitched recordings are moved by whole octaves to sit near their natural
    /// pitch (a glockenspiel plays where a glockenspiel lives), then tuned.
    static let home: [String: Double] = [
        "bass": 40, "tuba": 40, "uke": 64, "piano": 64, "marimba": 64, "harp": 64, "kalimba": 72, "glock": 84,
        "flute": 76, "steelpan": 72,
    ]
    /// a low key must not push the bass below what a small speaker can play
    static let floorNote: [String: Double] = ["bass": 31, "tuba": 31]

    /// the middle of the tune, where the synthesised stand-in voices sit
    static let melMid: Double = 69
    /// The friend's own notes run from the G of its verse stabs to the E at the
    /// top of the hook. The song is moved (keyLo...keyHi semitones) so the
    /// middle of that range lands on the pitch of the friend's own call.
    static let partMid: Double = 71.5
    static let keyLo: Int = -7
    static let keyHi: Int = 4

    static func keyFor(_ pitch: Double) -> Int {
        var k: Double = (pitch - partMid).truncatingRemainder(dividingBy: 12)
        if k < 0 { k += 12 }
        if k > Double(keyHi) + 0.5 { k -= 12 }
        let r: Int = Int(jsRound(k))
        return max(keyLo, min(keyHi, r))
    }

    // ---- the tune

    /// One bar. ch: (beat, chord, bass root); mel: (beat, note, beats) is the
    /// tune; voice is what the friend sings in the chorus: one syllable per
    /// beat, because an animal's call is about half a second long and cutting
    /// it shorter makes it stutter.
    struct Bar {
        let ch: [(Double, [Double], Double)]
        let mel: [(Double, Double, Double)]
        let voice: [(Double, Double, Double)]
        let answer: Answer
    }

    // an original tune in C
    static let cC: [Double] = [60, 64, 67]
    static let cF: [Double] = [60, 65, 69]
    static let cG: [Double] = [59, 62, 67]
    static let cAm: [Double] = [57, 60, 64]

    static let verse: [Bar] = [
        Bar(ch: [(0, cC, 36)],
            mel: [(0, 64, 0.5), (0.5, 64, 0.5), (1, 67, 1), (2, 72, 0.5), (2.5, 69, 0.5), (3, 67, 1)],
            voice: [(0, 64, 1), (1, 67, 1), (2, 72, 1), (3, 67, 1)], answer: .stab),
        Bar(ch: [(0, cF, 41), (2, cG, 43)],
            mel: [(0, 65, 0.5), (0.5, 65, 0.5), (1, 64, 0.5), (1.5, 62, 0.5), (2, 67, 1)],
            voice: [(0, 65, 1), (1, 62, 1), (2, 67, 1)], answer: .extra),
        Bar(ch: [(0, cC, 36), (2, cAm, 45)],
            mel: [(0, 64, 0.5), (0.5, 64, 0.5), (1, 67, 1), (2, 72, 0.5), (2.5, 74, 0.5), (3, 76, 1)],
            voice: [(0, 64, 1), (1, 67, 1), (2, 72, 1), (3, 76, 1)], answer: .stab),
        Bar(ch: [(0, cF, 41), (1, cG, 43), (2, cC, 36)],
            mel: [(0, 69, 0.5), (0.5, 72, 0.5), (1, 71, 0.5), (1.5, 74, 0.5), (2, 72, 1)],
            voice: [(0, 69, 1), (1, 71, 1), (2, 72, 1)], answer: .chirp),
    ]
    static let chorus: [Bar] = [
        Bar(ch: [(0, cF, 41), (2, cC, 36)],
            mel: [(0, 72, 1), (1, 72, 0.5), (1.5, 74, 0.5), (2, 76, 1), (3, 72, 1)],
            voice: [(0, 72, 1), (1, 74, 1), (2, 76, 1), (3, 72, 1)], answer: .stab),
        Bar(ch: [(0, cG, 43), (2, cC, 36)],
            mel: [(0, 74, 0.5), (0.5, 74, 0.5), (1, 71, 0.5), (1.5, 74, 0.5), (2, 72, 2)],
            voice: [(0, 74, 1), (1, 71, 1), (2, 72, 2)], answer: .stab),
    ]

    /// the chord sounding at beat x of a bar
    fileprivate static func chord(_ bar: Bar, at x: Double) -> [Double] {
        var c: [Double] = bar.ch[0].1
        for e in bar.ch where e.0 <= x { c = e.1 }
        return c
    }

    // ---- recordings to load (Sound.swift decodes them)

    static func instKey(_ id: String) -> String { dir + "inst/" + id }
    static func singKey(_ friend: String) -> String { dir + "sing/" + friend }
    static func extraKey(_ friend: String) -> String { dir + "extra/" + friend }

    /// every karaoke recording: (sample key, file name in the bundle without ".mp3").
    /// The band first, then every friend's voice, then their second sounds.
    static var allRecordings: [(key: String, file: String)] {
        var out: [(key: String, file: String)] = []
        for id in instruments { out.append((key: instKey(id), file: "kara-inst-" + id)) }
        let ids: [String] = friends.keys.sorted()
        for id in ids { out.append((key: singKey(id), file: "kara-sing-" + id)) }
        for id in ids { out.append((key: extraKey(id), file: "kara-extra-" + id)) }
        return out
    }

    /// what one friend's song needs: the band and that friend's two sounds
    static func recordings(for friend: String) -> [(key: String, file: String)] {
        var out: [(key: String, file: String)] = []
        for id in instruments { out.append((key: instKey(id), file: "kara-inst-" + id)) }
        out.append((key: singKey(friend), file: "kara-sing-" + friend))
        out.append((key: extraKey(friend), file: "kara-extra-" + friend))
        return out
    }

    /// who sings: the friend that hatched, or any friend (the settings preview, a photo friend)
    static func singer(_ friend: String?) -> String {
        if let f = friend, friends[f] != nil { return f }
        return GC.pick(friends.keys.sorted())
    }

    // MARK: the synthesised stand-in for each instrument

    fileprivate static func synth(_ k: Kit, _ id: String, _ n: Double, _ t: Double, _ d: Double, _ g: Double, _ c: Ch) {
        // d = 0 means "let it ring"; the synthesised notes need a length
        let ring: Double = d > 0 ? d : 0.9
        switch id {
        case "kick": k.kick(t, 0.5 * g)
        case "snare": k.snare(t, 0.2 * g)
        case "hat": k.hat(t, 0.05 * g)
        case "shaker": k.shaker(t, 0.045 * g)
        case "clap": k.clap(t, 0.13 * g)
        case "bongo": k.bongo(t, true, 0.13 * g)
        case "woodblock": k.woodblock(t, true, 0.08 * g)
        case "bass": k.bass(n, t, ring, 0.22 * g)
        case "tuba": k.tuba(n, t, ring, 0.19 * g)
        case "uke": k.uke([n], t, 0.05 * g)
        case "piano": k.piano(n, t, ring, 0.06 * g, c)
        case "marimba": k.marimba(n, t, 0.08 * g, c)
        case "glock": k.glock(n, t, 1.1, 0.04 * g)
        case "flute": k.fluteOn(n, t, ring, 0.06 * g, c)
        case "harp": k.harp([n], t, 0, 0.045 * g)
        case "kalimba": k.xylo(n, t, 0.07 * g)
        case "steelpan": k.steel(n, t, 0.9, 0.08 * g)
        case "whistle": k.slideWhistle(t, n, n + 12, 0.4, 0.06 * g)
        case "sparkle":
            let steps: [Double] = [0, 4, 7, 12, 16]
            for (i, x) in steps.enumerated() { k.glock(n + x, t + Double(i) * 0.055, 0.8, 0.03 * g) }
        default: break
        }
    }

    // MARK: putting the song together

    /// Arrange Egg karaoke for this friend (an id from `friends`; see `singer`)
    /// and hand it to the synth. Returns the song's length in seconds and,
    /// for each note the friend sings, how long from now it starts and how
    /// long it lasts (the web bops the friend on each one).
    static func perform(_ friendId: String, on s: Synth) -> (len: Double, cues: [(delay: Double, dur: Double)]) {
        guard let info = friends[friendId], let world = worlds[info.0] else { return (len: 0, cues: []) }
        let spb: Double = 60 / world.bpm
        let lead: Double = 0.08
        let t0: Double = s.t + lead
        let kit = Kit(s: s, bus: .celeb, mix: true, t0: t0, spb: spb)
        let player = KaraokePlayer(friend: friendId, world: world, synKind: info.1, synHz: info.2, s: s)
        let a = KaraokeArranger(p: player, spb: spb)
        let call: String = Band.friendCalls[friendId] ?? "cheep"
        let callLen: Double = Band.lenOf(call, s)
        let beats: Double = a.arrange(call: call, callLen: callLen)
        let tail: Double = 2.6

        var events: [(t: Double, fn: (Kit, Double) -> Void)] = []
        events.reserveCapacity(a.sc.events.count)
        for e in a.sc.events { events.append((t: t0 + e.beat * spb, fn: e.fn)) }
        events.sort { $0.t < $1.t }
        let len: Double = beats * spb + tail
        s.startCelebration(Celebration(events: events, kit: kit, end: t0 + len, friendCall: call))

        var cues: [(delay: Double, dur: Double)] = []
        for c in a.cues { cues.append((delay: lead + c.beat * spb, dur: c.dur)) }
        return (len: len, cues: cues)
    }
}

// MARK: - the players

/// One recording the song will use.
private struct KaraokeRec {
    let key: String
    /// its pitch (MIDI), or nil for a drum or an effect
    let base: Double?
    /// whole octaves moved, so it sits near its natural pitch
    let off: Double
}

/// Plays every part: a recorded note when it has loaded, else the synth kit.
/// Decided once, when the song starts, so it never switches voice halfway.
/// Its methods run on the audio thread (inside the song's events).
private struct KaraokePlayer {
    let world: Karaoke.World
    /// semitones the whole song is moved, to the friend's key
    let key: Double
    let use: [String: KaraokeRec]
    let singKey: String
    let extraKey: String
    /// the friend's sound is a recording (false = the synthesised stand-in)
    let rec: Bool
    /// set when the friend's recording holds a note: it sings
    let voice: KaraokeRec?
    let synKind: String
    let synOff: Double
    let hasExtra: Bool

    init(friend: String, world: Karaoke.World, synKind: String, synHz: Double, s: Synth) {
        self.world = world
        var use: [String: KaraokeRec] = [:]
        for id in Karaoke.instruments {
            let k: String = Karaoke.instKey(id)
            if s.sampleLength(k) == nil { continue }
            let base: Double? = Karaoke.instPitch[id]
            var off: Double = 0
            if let m = base, let h = Karaoke.home[id] { off = 12 * jsRound((m - h) / 12) }
            use[id] = KaraokeRec(key: k, base: base, off: off)
        }
        self.use = use

        let sk: String = Karaoke.singKey(friend)
        let ek: String = Karaoke.extraKey(friend)
        self.singKey = sk
        self.extraKey = ek
        let recorded: Bool = s.sampleLength(sk) != nil
        self.rec = recorded
        // a recorded call with a pitch sings (and sets the key); one without is played as it is
        if recorded, let m = Karaoke.singPitch[friend] {
            let k: Double = Double(Karaoke.keyFor(m))
            self.key = k
            self.voice = KaraokeRec(key: sk, base: m, off: 12 * jsRound((m - (Karaoke.partMid + k)) / 12))
        } else {
            self.key = 0
            self.voice = nil
        }
        // the synth voice moves by whole octaves too, so the tune keeps its shape
        let synNote: Double = 69 + 12 * log2(synHz / 440)
        self.synKind = synKind
        self.synOff = 12 * jsRound((synNote - Karaoke.melMid) / 12)
        self.hasExtra = s.sampleLength(ek) != nil
    }

    /// one note of an instrument. d = how long it may ring (0 = let a drum ring out)
    func inst(_ k: Kit, _ id: String, _ note: Double, _ t: Double, _ d: Double, _ g: Double, _ c: Ch) {
        var n: Double = note + key
        if let low = Karaoke.floorNote[id], n < low { n += 12 }
        guard let u = use[id] else {
            Karaoke.synth(k, id, n, t, d, g, c)
            return
        }
        var rate: Double = 1
        if let base = u.base { rate = pow(2, (n + u.off - base) / 12) }
        let level: Double = (Karaoke.gain[id] ?? 0.3) * g * k.g(c)
        let ring: Double? = d > 0 ? max(d, 0.25) : nil
        k.s.playSample(u.key, at: t, bus: k.bus, gain: level, rate: rate, maxDur: ring)
    }

    /// One sung syllable: it rings for as long as it naturally lasts,
    /// overlapping the next by a touch (legato), and is only faded (gently,
    /// never chopped) if the call is longer than that.
    func sing(_ k: Kit, _ n: Double, _ t: Double, _ d: Double, _ c: Ch, _ g: Double) {
        let len: Double = d + 0.1
        let level: Double = Karaoke.singGain * g * k.g(c)
        if let v = voice, let base = v.base {
            let rate: Double = pow(2, (n + key + v.off - base) / 12)
            k.s.playSample(singKey, at: t, bus: k.bus, gain: level, rate: rate, maxDur: len, fade: 0.12)
        } else if rec {
            // not a note: its own sound, as it is. It only leans a touch up or down
            // with the tune (two semitones at most), the way a drummer moves between toms
            let lean: Double = max(-2.0, min(2.0, (n - Karaoke.partMid) * 0.35))
            let rate: Double = pow(2, lean / 12)
            k.s.playSample(singKey, at: t, bus: k.bus, gain: level, rate: rate, maxDur: len, fade: 0.12)
        } else {
            let dur: Double = synKind == "cheep" ? min(len, 0.14) : len
            k.say(synKind, t, midi(n + synOff), dur, c, g)
        }
    }

    /// its second sound; if that has not loaded, the world's chirp answers instead
    func extra(_ k: Kit, _ t: Double, _ c: Ch, _ chord: [Double]) {
        if hasExtra {
            k.s.playSample(extraKey, at: t, bus: k.bus, gain: 0.85 * k.g(c), maxDur: 1.4)
            return
        }
        chirp(k, t, chord)
    }

    /// tones and chirps that suit the world, always on the chord's notes
    func chirp(_ k: Kit, _ t: Double, _ chord: [Double]) {
        guard chord.count >= 3 else { return }
        let o: Ch = .sparkle
        var hi: [Double] = []
        for n in chord { hi.append(n + 24 + key) }
        switch world.chirp {
        case .cheeps:
            k.cheep(t, midi(hi[2]), 0.08, o, 0.8)
            k.cheep(t + 0.12, midi(hi[2] + 5), 0.08, o, 0.8)
            inst(k, "whistle", 72, t + 0.24, 0, 0.8, o)
        case .birds:
            for i in 0..<6 {
                let base: Double = i % 2 == 1 ? hi[2] : hi[1]
                let up: Double = i > 3 ? 12 : 0
                k.cheep(t + Double(i) * 0.065, midi(base + up), 0.05, o, 0.7)
            }
        case .parrot:
            k.squeak(t, midi(hi[0]), 0.16, o, 0.9)
            k.squeak(t + 0.2, midi(hi[2]), 0.2, o, 0.9)
            inst(k, "bongo", 0, t + 0.1, 0, 0.6, .drums)
            inst(k, "bongo", 0, t + 0.22, 0, 0.5, .drums)
        case .bubbles:
            let order: [Int] = [0, 1, 2, 0]
            for (i, j) in order.enumerated() {
                let up: Double = i == 3 ? 24 : 12
                k.bloop(t + Double(i) * 0.09, midi(chord[j] + key + up), 0.1, o, 0.9)
            }
        case .sparkle:
            inst(k, "sparkle", 84, t, 0, 0.8, o)
            let notes: [Double] = chord + [chord[0] + 12]
            for (i, n) in notes.enumerated() {
                inst(k, "glock", n + 12, t + Double(i) * 0.07, 0.6, 0.6, o)
            }
        }
    }
}

/// Writes the song out as events on a Score (beats), on the main thread.
private final class KaraokeArranger {
    let sc = Score()
    let p: KaraokePlayer
    let w: Karaoke.World
    let spb: Double
    /// every note the friend sings: its beat and how long it lasts (seconds)
    var cues: [(beat: Double, dur: Double)] = []

    init(p: KaraokePlayer, spb: Double) {
        self.p = p
        self.w = p.world
        self.spb = spb
    }

    // ---- one event each

    func inst(_ beat: Double, _ id: String, _ n: Double, _ d: Double, _ g: Double, _ c: Ch, dt: Double = 0) {
        let p = self.p
        sc.at(beat) { k, t in p.inst(k, id, n, t + dt, d, g, c) }
    }

    func sing(_ beat: Double, _ n: Double, _ d: Double, _ c: Ch) {
        let p = self.p
        sc.at(beat) { k, t in p.sing(k, n, t, d, c, 1) }
        cues.append((beat: beat, dur: d + 0.1))
    }

    func extra(_ beat: Double, _ c: Ch, _ chord: [Double]) {
        let p = self.p
        sc.at(beat) { k, t in p.extra(k, t, c, chord) }
    }

    func chirp(_ beat: Double, _ chord: [Double], dt: Double = 0) {
        let p = self.p
        sc.at(beat) { k, t in p.chirp(k, t + dt, chord) }
    }

    func crash(_ beat: Double, _ gn: Double) {
        sc.at(beat) { k, t in k.crash(t, gn) }
    }

    // ---- the band's parts

    func groove(_ b: Double, _ full: Bool) {
        for i in 0..<8 {
            let x: Double = Double(i) * 0.5
            let onBeat: Bool = i % 2 == 0
            if i % 4 == 0 { inst(b + x, "kick", 0, 0, 1, .drums) }
            if i == 2 || i == 6 {
                inst(b + x, w.back, 0, 0, w.backGain, .drums)
                if full && w.back != "clap" { inst(b + x, "clap", 0, 0, 0.7, .drums) }
            }
            inst(b + x, w.tick, 0, 0, onBeat ? 1 : 0.6, .drums)
        }
        if let perc = w.perc {
            inst(b + 1.5, perc, 0, 0, 0.6, .drums)
            inst(b + 3.5, perc, 0, 0, 0.6, .drums)
        }
    }

    func bass(_ b: Double, _ r: Double, _ beats: Double) {
        var steps: [(Double, Double)] = [(0, r)]
        switch w.bassStyle {
        case .walk:
            if beats >= 4 {
                steps = [(0, r), (1, r + 4), (2, r + 7), (3, r + 9)]
            } else if beats >= 2 {
                steps = [(0, r), (1, r + 7)]
            }
        case .oompah:
            if beats >= 4 { steps = [(0, r), (2, r + 7)] }
        case .root5:
            if beats >= 4 { steps = [(0, r), (2, r + 7), (3.5, r + 7)] }
        }
        for step in steps { inst(b + step.0, w.bass, step.1, spb * 0.9, 1, .bass) }
    }

    func comp(_ b: Double, _ chord: [Double], _ beats: Double) {
        guard chord.count >= 3 else { return }
        switch w.compStyle {
        case .strum:
            let hits: [(Double, Double)] = [(0, 1), (1, 0.7), (1.5, 0.8), (2.5, 0.7), (3, 0.8)]
            for hit in hits {
                if hit.0 >= beats { continue }
                for (i, n) in chord.enumerated() {
                    inst(b + hit.0, w.comp, n, spb * 1.5, hit.1, .comp, dt: Double(i) * 0.015)
                }
            }
        case .arp:
            let notes: [Double] = [chord[0], chord[1], chord[2], chord[0] + 12, chord[2], chord[1], chord[2], chord[0] + 12]
            let count: Int = Int(beats * 2)
            for i in 0..<count {
                let g: Double = i % 2 == 1 ? 0.7 : 1
                inst(b + Double(i) * 0.5, w.comp, notes[i % 8], spb, g, .comp)
            }
        case .offbeat:
            var x: Double = 0.5
            while x < beats {
                inst(b + x, w.comp, chord[1], spb * 0.5, 0.9, .comp)
                inst(b + x, w.comp, chord[2], spb * 0.5, 0.9, .comp)
                x += 1
            }
        case .block:
            // block chords on the beat, a lighter one on the "and" before the next
            var x: Double = 0
            while x < beats {
                for n in chord { inst(b + x, w.comp, n, spb * 1.6, 1, .comp) }
                if x + 1.5 < beats {
                    for n in chord { inst(b + x + 1.5, w.comp, n + 12, spb * 0.5, 0.5, .comp) }
                }
                x += 2
            }
        }
    }

    func melody(_ id: String, _ b: Double, _ mel: [(Double, Double, Double)], _ g: Double, _ up: Double, _ c: Ch) {
        for m in mel { inst(b + m.0, id, m.1 + up, m.2 * spb * 1.05, g, c) }
    }

    func bars(_ list: [Karaoke.Bar], _ b0: Double, _ isChorus: Bool) {
        for (i, bar) in list.enumerated() {
            let b: Double = b0 + Double(i) * 4
            groove(b, isChorus)
            for (j, change) in bar.ch.enumerated() {
                let x: Double = change.0
                let next: Double = j + 1 < bar.ch.count ? bar.ch[j + 1].0 : 4
                let beats: Double = next - x
                bass(b + x, change.2, beats)
                comp(b + x, change.1, beats)
            }
            var harmony: [(Double, Double, Double)] = []
            for m in bar.mel where m.2 >= 1 {
                let h: Double = harmonyBelow(m.1, Karaoke.chord(bar, at: m.0))
                harmony.append((m.0, h, m.2))
            }
            if !isChorus {
                // the tune passes around the band: the lead's line, then the second instrument's
                let tune: String = i < 2 ? w.lead : w.second
                let other: String = i < 2 ? w.second : w.lead
                melody(tune, b, bar.mel, Karaoke.leadGain, 12, .lead)
                melody(other, b, harmony, 0.45, 12, .sparkle)
                // the friend: off-beat stabs on the chord, and its answers in the gaps
                sing(b + 1, Karaoke.chord(bar, at: 1)[2], spb * 0.75, .aR)
                if bar.answer == .stab { sing(b + 3, Karaoke.chord(bar, at: 3)[0] + 12, spb * 0.75, .aR) }
                if bar.answer == .extra { extra(b + 3, .aR, Karaoke.chord(bar, at: 3)) }
                if bar.answer == .chirp {
                    chirp(b + 3, Karaoke.chord(bar, at: 3))
                    // the band echoes the end of the line, an octave up
                    let last: [(Double, Double, Double)] = Array(bar.mel.suffix(3))
                    for (j, m) in last.enumerated() {
                        inst(b + 3 + Double(j) * 0.25, w.lead, m.1 + 24, spb * 0.4, 0.7, .sparkle)
                    }
                }
            } else {
                // everyone: the tune on the lead, a counter-melody, sparkle up high, the friend on the hook
                melody(w.lead, b, bar.mel, Karaoke.leadGain, 12, .lead)
                melody(w.second, b, harmony, 0.6, 12, .sparkle)
                melody(w.sparkle, b, bar.mel, 0.4, 24, .sparkle)
                for v in bar.voice { sing(b + v.0, v.1, v.2 * spb, .solo) }
            }
        }
    }

    /// The whole song; returns its length in beats (before the last chord's tail).
    func arrange(call: String, callLen: Double) -> Double {
        let cC: [Double] = Karaoke.cC

        // intro: a count-in on the sticks, the band walks up, the friend says hello
        for x in 0..<4 { inst(Double(x), "woodblock", 0, 0, x == 0 ? 1 : 0.7, .drums) }
        for n in cC { inst(0, w.comp, n, spb * 2, 0.7, .comp) }
        sing(2, 67, spb, .aR)
        let walk: [Double] = [60, 64, 67, 72]
        for (i, n) in walk.enumerated() { inst(2 + Double(i) * 0.5, w.lead, n + 12, spb * 0.5, 0.8, .lead) }
        inst(3, w.bass, 43, spb * 0.9, 1, .bass)
        chirp(3.5, cC)
        var b: Double = 4

        // verse: the instruments take turns with the tune; the friend plays along
        bars(Karaoke.verse, b, false)
        b += Double(Karaoke.verse.count) * 4

        // chorus: the whole band, the friend singing the hook with the lead
        crash(b, 0.1)
        bars(Karaoke.chorus, b, true)
        b += Double(Karaoke.chorus.count) * 4
        // a chirp in the chorus's last held note
        chirp(b - 1, cC)

        // stop! one band hit, then the friend's solo break: its own full call
        crash(b, 0.12)
        inst(b, "kick", 0, 0, 1, .drums)
        inst(b, w.bass, 36, spb, 1, .bass)
        for n in cC { inst(b, w.comp, n, spb, 1, .comp) }
        let soloAt: Double = b + 1
        let key: Double = p.key
        let pad: [Double] = [60 + key, 64 + key, 67 + key]
        let padLen: Double = callLen + spb
        sc.at(soloAt) { k, t in
            Band.playCall(k, call, t, .solo)
            k.strings(pad, t, padLen, 0.01)
        }

        // ta-da: the whole band, the friend with them, then one last ad-lib
        let end: Double = ((soloAt + (callLen + 0.15) / spb) * 2).rounded(.up) / 2
        sing(end, 67, spb, .solo)
        inst(end, w.lead, 79, spb, Karaoke.leadGain, .lead)
        inst(end, "kick", 0, 0, 1, .drums)

        sing(end + 1, 72, spb * 2, .solo)
        inst(end + 1, w.lead, 84, spb * 3, Karaoke.leadGain, .lead)
        inst(end + 1, w.second, 76, spb * 3, 0.7, .sparkle)
        crash(end + 1, 0.13)
        inst(end + 1, "kick", 0, 0, 1, .drums)
        inst(end + 1, w.bass, 36, spb * 3, 1, .bass)
        let spread: [Double] = [48, 55, 60, 64, 67, 72]
        for (i, n) in spread.enumerated() { inst(end + 1, w.comp, n, spb * 3, 0.8, .comp, dt: Double(i) * 0.03) }
        chirp(end + 1, cC, dt: 0.1)

        extra(end + 2.5, .aR, cC)
        return end + 2.5
    }
}

import Foundation

/// Egg karaoke's song, bands and voices as plain data (the native twin of the
/// tables in the web app's js/karaoke.js and the packs' `karaoke`, `worlds` and
/// `call` entries). Karaoke.swift plays them.
///
/// Plain Foundation on purpose: Tests/KaraokeChecks compiles this file (with
/// KaraokeIndex.swift and Monetization/Packs.swift) on its own to check the
/// key choice, the pitch-bend limits and that every friend has its sounds.
enum KaraokeData {
    /// a friend's band (world), then its synthesised stand-in voice: a Kit
    /// syllable (moo, squeak, hoot …) sung around hz
    struct Friend: Equatable {
        let world: String
        let synth: String
        let hz: Double
    }

    private static func F(_ world: String, _ synth: String, _ hz: Double) -> Friend { Friend(world: world, synth: synth, hz: hz) }

    static let friends: [String: Friend] = [
        // Classic
        "chick": F("meadow", "cheep", 2400), "duckling": F("meadow", "quack", 380), "penguin": F("water", "quack", 450),
        "owl": F("woodland", "hoot", 400), "hamster": F("meadow", "squeak", 2000), "bunny": F("meadow", "bloop", 260),
        "fox": F("woodland", "woof", 600), "kitten": F("meadow", "meow", 650), "bearcub": F("woodland", "roar", 160),
        "panda": F("jungle", "baa", 420), "frog": F("water", "croak", 170), "turtle": F("water", "bloop", 500),
        "dino": F("magic", "roar", 140), "dragon": F("magic", "roar", 150), "mouse": F("meadow", "squeak", 2800),
        "piglet": F("meadow", "oink", 210), "koala": F("jungle", "oink", 140), "raccoon": F("woodland", "squeak", 2200),
        "tiger": F("jungle", "roar", 180), "lion": F("jungle", "roar", 170), "calf": F("meadow", "moo", 180),
        "lamb": F("meadow", "baa", 420), "fawn": F("woodland", "meow", 750), "hedgehog": F("woodland", "squeak", 2300),
        "otter": F("water", "squeak", 1800), "seal": F("water", "ork", 300), "axolotl": F("water", "bloop", 800),
        "bat": F("woodland", "squeak", 3000), "mole": F("woodland", "sniff", 2600), "monkey": F("jungle", "ooh", 450),
        "elephant": F("jungle", "trumpet", 520), "squirrel": F("woodland", "squeak", 2500), "puppy": F("meadow", "woof", 300),
        "unicorn": F("magic", "neigh", 800), "capybara": F("jungle", "squeak", 1500), "redpanda": F("woodland", "squeak", 2000),
        "sloth": F("jungle", "squeak", 1700), "ladybug": F("woodland", "buzz", 240), "snail": F("woodland", "bloop", 700),
        "goat": F("meadow", "baa", 440),
        // Aussie Bush (web js/packs/aussie.js)
        "galah": F("bush", "crow", 1300), "cockatoo": F("bush", "crow", 1000), "kookaburra": F("bush", "ah", 600),
        "emu": F("bush", "hoot", 300), "joey": F("bush", "bloop", 500), "wombat": F("bush", "oink", 150),
        "platypus": F("water", "croak", 260), "echidna": F("bush", "sniff", 2600), "sugarglider": F("bush", "squeak", 2200),
        "frillneck": F("bush", "sniff", 3800), "bilby": F("bush", "squeak", 2400), "molecricket": F("bush", "buzz", 420),
        // Christmas (web js/packs/christmas.js)
        "gingerbread": F("jingle", "squeak", 1800), "treecookie": F("jingle", "cheep", 2400), "shortbread": F("jingle", "hoot", 880),
        "pudding": F("jingle", "bloop", 300), "nutcracker": F("jingle", "ork", 240), "sugarplum": F("jingle", "hoot", 880),
        "mouseking": F("jingle", "squeak", 2600), "snowfairy": F("jingle", "cheep", 3000), "angel": F("jingle", "ah", 520),
        "reindeer": F("jingle", "ork", 200), "robin": F("jingle", "cheep", 3000), "snowman": F("jingle", "hoot", 330),
        "xmasbeetle": F("jingle", "buzz", 220),
    ]

    /// One world's band. lead and second carry the tune; comp, bass, sparkle
    /// and the drums fill it out; chirp is the world's answer in the gaps.
    struct World: Equatable {
        let bpm: Double
        let lead: String
        let second: String
        let comp: String
        /// strum | arp | offbeat | block
        let compStyle: String
        let bass: String
        /// walk | oompah | root5
        let bassStyle: String
        let sparkle: String
        let kick: String
        let back: String
        var backGain: Double = 1
        let tick: String
        var perc: String? = nil
        let chirp: String
    }

    static let worlds: [String: World] = [
        "meadow": World(bpm: 124, lead: "piano", second: "flute", comp: "uke", compStyle: "strum", bass: "bass", bassStyle: "walk",
                        sparkle: "glock", kick: "kick", back: "clap", tick: "shaker", perc: "woodblock", chirp: "cheeps"),
        "woodland": World(bpm: 116, lead: "flute", second: "kalimba", comp: "harp", compStyle: "arp", bass: "bass", bassStyle: "root5",
                          sparkle: "glock", kick: "kick", back: "woodblock", tick: "shaker", chirp: "birds"),
        "jungle": World(bpm: 128, lead: "steelpan", second: "marimba", comp: "marimba", compStyle: "offbeat", bass: "tuba", bassStyle: "oompah",
                        sparkle: "glock", kick: "kick", back: "bongo", tick: "shaker", perc: "woodblock", chirp: "parrot"),
        "water": World(bpm: 112, lead: "kalimba", second: "glock", comp: "piano", compStyle: "arp", bass: "bass", bassStyle: "root5",
                       sparkle: "flute", kick: "kick", back: "snare", backGain: 0.55, tick: "hat", chirp: "bubbles"),
        "magic": World(bpm: 120, lead: "harp", second: "flute", comp: "piano", compStyle: "block", bass: "tuba", bassStyle: "root5",
                       sparkle: "glock", kick: "kick", back: "snare", tick: "hat", chirp: "sparkle"),
        // Aussie Bush: a bush band, the banjo has the tune and the spoons click the backbeat
        "bush": World(bpm: 122, lead: "banjo", second: "flute", comp: "uke", compStyle: "strum", bass: "bass", bassStyle: "walk",
                      sparkle: "glock", kick: "kick", back: "spoons", tick: "shaker", perc: "woodblock", chirp: "kooka"),
        // Christmas: celesta lead, brushes, a clip-clop wood block and sleigh bells on every off-beat
        "jingle": World(bpm: 132, lead: "celesta", second: "flute", comp: "piano", compStyle: "block", bass: "bass", bassStyle: "walk",
                        sparkle: "glock", kick: "kick", back: "snare", backGain: 0.5, tick: "sleighbells", perc: "woodblock", chirp: "jingle"),
    ]

    /// what each world's chirp plays besides animal syllables (Karaoke.chirp)
    static let chirpInstruments: [String: [String]] = [
        "cheeps": ["whistle"], "birds": [], "parrot": ["bongo"], "bubbles": [], "sparkle": ["sparkle", "glock"],
        "kooka": [], "jingle": ["sleighbells", "glock"],
    ]

    /// every instrument a world's band plays (the arrangement also uses the
    /// wood block for the count-in and claps in the chorus)
    static func instruments(of w: World) -> Set<String> {
        var s: Set<String> = [w.lead, w.second, w.comp, w.bass, w.sparkle, w.kick, w.back, w.tick, "woodblock", "clap"]
        if let p = w.perc { s.insert(p) }
        for i in chirpInstruments[w.chirp] ?? [] { s.insert(i) }
        return s
    }

    /// instruments with a synthesised stand-in in Karaoke.syn (played when
    /// the recording has not loaded)
    static let synthStandIns: Set<String> = [
        "kick", "snare", "hat", "shaker", "clap", "bongo", "woodblock", "bass", "tuba", "uke", "piano", "marimba",
        "glock", "flute", "harp", "kalimba", "steelpan", "whistle", "sparkle",
        "banjo", "spoons", // Aussie Bush
        "sleighbells", "celesta", // Christmas
    ]

    // MARK: the song

    /// An original tune in C. ch: (beat, chord, bass root); mel: (beat, note,
    /// beats) is the tune the band plays; voice is what the friend sings, one
    /// syllable per beat (a call is about half a second long).
    struct Bar {
        let ch: [(Double, [Double], Double)]
        let mel: [(Double, Double, Double)]
        let voice: [(Double, Double, Double)]
        var answer: String? = nil

        /// the chord sounding at beat x of the bar
        func chordAt(_ x: Double) -> [Double] { ch.last { $0.0 <= x }?.1 ?? ch[0].1 }
    }

    static let C: [Double] = [60, 64, 67], Fc: [Double] = [60, 65, 69], G: [Double] = [59, 62, 67], Am: [Double] = [57, 60, 64]

    static let verse: [Bar] = [
        Bar(ch: [(0, C, 36)], mel: [(0, 64, 0.5), (0.5, 64, 0.5), (1, 67, 1), (2, 72, 0.5), (2.5, 69, 0.5), (3, 67, 1)],
            voice: [(0, 64, 1), (1, 67, 1), (2, 72, 1), (3, 67, 1)]),
        Bar(ch: [(0, Fc, 41), (2, G, 43)], mel: [(0, 65, 0.5), (0.5, 65, 0.5), (1, 64, 0.5), (1.5, 62, 0.5), (2, 67, 1)],
            voice: [(0, 65, 1), (1, 62, 1), (2, 67, 1)], answer: "extra"),
        Bar(ch: [(0, C, 36), (2, Am, 45)], mel: [(0, 64, 0.5), (0.5, 64, 0.5), (1, 67, 1), (2, 72, 0.5), (2.5, 74, 0.5), (3, 76, 1)],
            voice: [(0, 64, 1), (1, 67, 1), (2, 72, 1), (3, 76, 1)]),
        Bar(ch: [(0, Fc, 41), (1, G, 43), (2, C, 36)], mel: [(0, 69, 0.5), (0.5, 72, 0.5), (1, 71, 0.5), (1.5, 74, 0.5), (2, 72, 1)],
            voice: [(0, 69, 1), (1, 71, 1), (2, 72, 1)], answer: "chirp"),
    ]
    static let chorus: [Bar] = [
        Bar(ch: [(0, Fc, 41), (2, C, 36)], mel: [(0, 72, 1), (1, 72, 0.5), (1.5, 74, 0.5), (2, 76, 1), (3, 72, 1)],
            voice: [(0, 72, 1), (1, 74, 1), (2, 76, 1), (3, 72, 1)]),
        Bar(ch: [(0, G, 43), (2, C, 36)], mel: [(0, 74, 0.5), (0.5, 74, 0.5), (1, 71, 0.5), (1.5, 74, 0.5), (2, 72, 2)],
            voice: [(0, 74, 1), (1, 71, 1), (2, 72, 2)]),
    ]

    /// the intro's hello and the ta-da's two notes
    static let helloNote = 67.0
    static let tadaNotes: [Double] = [67, 72]

    /// Every note the friend sings, in song order: hello, its stabs in the
    /// verse (the chord's top note on beat 2, the root an octave up on beat 4
    /// unless the bar has an answer there), the hook in the chorus, the ta-da.
    /// Karaoke.arrange sings exactly these.
    static func verseStabs(_ bar: Bar) -> [(beat: Double, note: Double)] {
        var s: [(beat: Double, note: Double)] = [(1, bar.chordAt(1)[2])]
        if bar.answer == nil { s.append((3, bar.chordAt(3)[0] + 12)) }
        return s
    }
    static var sungNotes: [Double] {
        var notes: [Double] = [helloNote]
        for bar in verse { for s in verseStabs(bar) { notes.append(s.note) } }
        for bar in chorus { for v in bar.voice { notes.append(v.1) } }
        notes.append(contentsOf: tadaNotes)
        return notes
    }

    // MARK: key and voice

    /// the middle of the tune, where the synthesised stand-in voices sit
    static let melMid = 69.0
    /// The friend's own notes run from the G of its verse stabs to the E at
    /// the top of the hook. The song moves (keyLo…keyHi semitones) so the
    /// middle of that range lands on the pitch of the friend's own call.
    static let partMid = 71.5, keyLo = -7.0, keyHi = 4.0

    /// JavaScript's Math.round (halves round up), so octaves and keys match the web exactly
    static func jsRound(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

    /// the song's key (semitones from C) for a call that sings at this pitch (MIDI)
    static func keyFor(_ pitch: Double) -> Double {
        var k = ((pitch - partMid).truncatingRemainder(dividingBy: 12) + 12).truncatingRemainder(dividingBy: 12) // 0..12
        if k > keyHi + 0.5 { k -= 12 }
        return max(keyLo, min(keyHi, jsRound(k)))
    }

    /// a low key must not push the bass below what a small speaker can play
    static let floorNote: [String: Double] = ["bass": 31, "tuba": 31]

    /// recorded instrument levels (a pack's instrument defaults to 0.35)
    static let gain: [String: Double] = [
        "kick": 0.95, "snare": 0.5, "hat": 0.28, "shaker": 0.32, "clap": 0.5, "bongo": 0.55, "woodblock": 0.45,
        "bass": 0.85, "tuba": 0.72, "uke": 0.27, "piano": 0.27, "marimba": 0.36, "glock": 0.28, "flute": 0.38,
        "harp": 0.32, "kalimba": 0.36, "steelpan": 0.36, "whistle": 0.35, "sparkle": 0.4,
        "banjo": 0.34, "spoons": 0.42, "sleighbells": 0.3, "celesta": 0.3,
    ]
    /// the friend's voice is one part in the band, level with the instruments
    static let singGain = 1.3
    /// whichever instrument has the tune sits a little forward
    static let leadGain = 1.35
    /// where each pitched recording naturally sits (MIDI): it is moved by whole
    /// octaves to sit near here (a glockenspiel plays where a glockenspiel lives)
    static let home: [String: Double] = [
        "bass": 40, "tuba": 40, "uke": 64, "piano": 64, "marimba": 64, "harp": 64, "kalimba": 72, "glock": 84, "flute": 76, "steelpan": 72,
        "banjo": 69, "celesta": 79,
    ]

    /// whole octaves to move a pitched recording (0 for an unpitched one)
    static func octaveShift(_ id: String, measured m: Double?) -> Double {
        guard let m, let h = home[id] else { return 0 }
        return 12 * jsRound((m - h) / 12)
    }

    /// How the friend takes part:
    ///   sings  its recorded call holds a note: the song moves to its key and
    ///          the call is re-pitched to each note (never far)
    ///   plays  its recording is not a note: played as it is, leaning at most
    ///          two semitones with the tune, like a drummer moving between toms
    ///   synth  no recording loaded: the synthesised stand-in voice sings
    enum Role: String { case sings, plays, synth }

    struct Voice: Equatable {
        let role: Role
        /// the song's key, semitones from C
        let key: Double
        /// the recording's measured pitch and the octaves it is moved by
        let base: Double
        let off: Double

        /// semitones the recording is bent to sing note n (n in C, before the key)
        func bend(_ n: Double) -> Double {
            switch role {
            case .sings: return n + key + off - base
            case .plays: return max(-2, min(2, (n - KaraokeData.partMid) * 0.35))
            case .synth: return 0
            }
        }
    }

    /// recorded = the friend's karaoke voice (ksing-<id>) has loaded
    static func voice(for id: String, recorded: Bool) -> Voice {
        guard recorded, let rec = sing[id] else { return Voice(role: .synth, key: 0, base: 0, off: 0) }
        guard let m = rec.m else { return Voice(role: .plays, key: 0, base: 0, off: 0) }
        let key = keyFor(m)
        return Voice(role: .sings, key: key, base: m, off: 12 * jsRound((m - (partMid + key)) / 12))
    }

    /// the synthesised voice moves by whole octaves too, so the tune keeps its shape
    static func synthOctaves(_ hz: Double) -> Double {
        12 * jsRound((69 + 12 * log2(hz / 440) - melMid) / 12)
    }
}

/// Which call each friend makes: its solo in the animal bands and Egg
/// karaoke, and what it says when tapped (web GC.Band.FRIEND_CALL). Every
/// call has a recording (Resources/Sounds/call-<name>.mp3) and a synthesised
/// stand-in (Band.calls).
enum FriendCalls {
    static let classic: [String: String] = [
        "chick": "cheep", "duckling": "peep", "penguin": "honk", "owl": "hoot", "hamster": "squeak", "bunny": "boing", "fox": "yip",
        "kitten": "meow", "bearcub": "rawr", "panda": "lamb", "frog": "ribbit", "turtle": "bloop", "dino": "dino", "dragon": "dragon",
        "mouse": "squeak", "piglet": "oink", "koala": "grunt", "raccoon": "chitter", "tiger": "roar", "lion": "roar", "calf": "calf",
        "lamb": "lamb", "fawn": "mew", "hedgehog": "sniff", "otter": "eep", "seal": "ork", "axolotl": "bloop", "bat": "squeak",
        "mole": "sniff", "monkey": "monkey", "elephant": "trumpet", "squirrel": "chitter", "puppy": "woof", "unicorn": "unicorn",
        "capybara": "wheek", "redpanda": "squeak", "sloth": "sloth", "ladybug": "buzz", "snail": "bloop", "goat": "goat",
    ]
    static let aussie: [String: String] = [
        "galah": "galah", "cockatoo": "cockatoo", "kookaburra": "kooka", "emu": "emu", "joey": "boing", "wombat": "huff",
        "platypus": "platypus", "echidna": "sniff", "sugarglider": "glider", "frillneck": "frill", "bilby": "squeak", "molecricket": "churr",
    ]
    static let christmas: [String: String] = [
        "gingerbread": "gingerhee", "treecookie": "bauble", "shortbread": "starding", "pudding": "wobble", "nutcracker": "clack",
        "sugarplum": "sugarplum", "mouseking": "mouseking", "snowfairy": "icetinkle", "angel": "angelaah", "reindeer": "reindeer",
        "robin": "tweet", "snowman": "snowhoo", "xmasbeetle": "buzz",
    ]
    static let all: [String: String] = classic.merging(aussie) { a, _ in a }.merging(christmas) { a, _ in a }
}

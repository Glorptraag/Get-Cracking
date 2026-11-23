import Foundation

/// Egg karaoke, the default hatching song: the native twin of the web app's
/// js/karaoke.js (the song, bands and voices are data in KaraokeData.swift).
///
/// A little band plays an original tune and the friend who just hatched is one
/// of the players. The tune passes around the band: the lead instrument plays
/// the first verse lines, the second instrument the next, and in the chorus
/// everyone plays, with a counter-melody and sparkle on top. The friend's own
/// recording (ksing-<id>.mp3) is one more part in the band:
///   sings  a call that holds a clear note (a meow, a moo, a hoot) sings in
///          tune; the whole song moves to that friend's key, so its voice is
///          only ever nudged a few notes and still sounds like itself
///   plays  a sound that is not a note (a quack, a sniff, a shell knock) is
///          never re-pitched: the friend plays it in time, like percussion
/// It plays off-beat stabs through the verse, with its second sound
/// (kextra-<id>.mp3) and the world's chirps answering in the gaps, sings the
/// hook with the lead in the chorus, takes one short solo break (its full
/// call) and joins the ta-da.
///
/// Every instrument is one recorded note (kinst-<id>.mp3) pitched to each note
/// of the song, so the band is always in time and in tune. Anything not loaded
/// yet is played by the synthesised kit (Band.swift) instead.
///
///   intro (count-in, hello) → verse → chorus → stop! the solo break → ta-da

private func midi(_ n: Double) -> Double { 440 * pow(2, (n - 69) / 12) }

enum Karaoke {
    /// sample keys: "karaoke/inst/<id>", "karaoke/sing/<id>", "karaoke/extra/<id>"
    static let dir = "karaoke/"

    static func instKey(_ id: String) -> String { dir + "inst/" + id }
    static func singKey(_ id: String) -> String { dir + "sing/" + id }
    static func extraKey(_ id: String) -> String { dir + "extra/" + id }
    /// the bundled file for a sample key (Resources/Sounds is flattened: kinst-banjo.mp3)
    static func file(_ key: String) -> String {
        "k" + key.dropFirst(dir.count).replacingOccurrences(of: "/", with: "-")
    }

    /// (kit, note, time, how long it may ring, gain, channel)
    typealias Syn = (Kit, Double, Double, Double, Double, Ch) -> Void

    /// The synthesised stand-in for each instrument (KaraokeData.synthStandIns).
    static let syn: [String: Syn] = [
        "kick": { k, _, t, _, g, _ in k.kick(t, 0.5 * g) },
        "snare": { k, _, t, _, g, _ in k.snare(t, 0.2 * g) },
        "hat": { k, _, t, _, g, _ in k.hat(t, 0.05 * g) },
        "shaker": { k, _, t, _, g, _ in k.shaker(t, 0.045 * g) },
        "clap": { k, _, t, _, g, _ in k.clap(t, 0.13 * g) },
        "bongo": { k, _, t, _, g, _ in k.bongo(t, true, 0.13 * g) },
        "woodblock": { k, _, t, _, g, _ in k.woodblock(t, true, 0.08 * g) },
        "bass": { k, n, t, d, g, _ in k.bass(n, t, d, 0.22 * g) },
        "tuba": { k, n, t, d, g, _ in k.tuba(n, t, d, 0.19 * g) },
        "uke": { k, n, t, _, g, _ in k.uke([n], t, 0.05 * g) },
        "piano": { k, n, t, d, g, o in k.piano(n, t, d, 0.06 * g, o) },
        "marimba": { k, n, t, _, g, o in k.marimba(n, t, 0.08 * g, o) },
        "glock": { k, n, t, _, g, _ in k.glock(n, t, 1.1, 0.04 * g) },
        "flute": { k, n, t, d, g, o in k.flute(n, t, d, 0.06 * g, o) },
        "harp": { k, n, t, _, g, _ in k.harp([n], t, 0, 0.045 * g) },
        "kalimba": { k, n, t, _, g, _ in k.xylo(n, t, 0.07 * g) },
        "steelpan": { k, n, t, _, g, _ in k.steel(n, t, 0.9, 0.08 * g) },
        "whistle": { k, n, t, _, g, _ in k.slideWhistle(t, n, n + 12, 0.4, 0.06 * g) },
        "sparkle": { k, n, t, _, g, _ in
            for (i, x) in [0.0, 4, 7, 12, 16].enumerated() { k.glock(n + x, t + Double(i) * 0.055, 0.8, 0.03 * g) }
        },
        // Aussie Bush
        "banjo": { k, n, t, _, g, o in k.banjo(n, t, 0.08 * g, o) },
        "spoons": { k, _, t, _, g, _ in k.claves(t, 0.06 * g); k.claves(t + 0.03, 0.04 * g) },
        // Christmas
        "sleighbells": { k, _, t, _, g, _ in k.tamb(t, 0.06 * g); k.tamb(t + 0.025, 0.03 * g) },
        "celesta": { k, n, t, _, g, _ in k.glock(n, t, 0.9, 0.04 * g) },
    ]

    /// The friend to sing: this one, or (a settings preview, a photo) any friend.
    static func pick(_ friend: String?) -> String {
        if let f = friend, KaraokeData.friends[f] != nil { return f }
        return GC.pick(KaraokeData.friends.keys.sorted())
    }

    /// Arrange the song for this friend and hand it to the synth; returns its
    /// length in seconds. The friend's recordings should already be loaded.
    static func perform(_ friendId: String, on s: Synth) -> Double {
        guard let f = KaraokeData.friends[friendId], let w = KaraokeData.worlds[f.world] else { return 0 }
        let spb = 60 / w.bpm
        let t0 = s.t + 0.08
        let kit = Kit(s: s, bus: .celeb, mix: true, t0: t0, spb: spb)
        let call = FriendCalls.all[friendId] ?? "meow"
        let p = KaraokePlayer(s: s, k: kit, friendId: friendId, friend: f, world: w)
        let sc = Score()
        let beats = arrange(sc, p, call: call, spb: spb)
        let events = sc.events
            .map { (t: t0 + $0.beat * spb, fn: $0.fn) }
            .sorted { $0.t < $1.t }
        let len = beats * spb + 2.6
        s.startCelebration(Celebration(events: events, kit: kit, end: t0 + len, friendCall: call))
        return len
    }

    // MARK: arrange

    private static func arrange(_ sc: Score, _ p: KaraokePlayer, call: String, spb: Double) -> Double {
        let w = p.world
        func at(_ beat: Double, _ fn: @escaping (Double) -> Void) { sc.at(beat) { _, t in fn(t) } }
        let lead = KaraokeData.leadGain

        func groove(_ b: Double, _ full: Bool) {
            for i in 0..<8 {
                let x = Double(i) * 0.5
                if i % 4 == 0 { at(b + x) { t in p.inst(w.kick, 0, t, 0, 1, .drums) } }
                if x == 1 || x == 3 {
                    at(b + x) { t in
                        p.inst(w.back, 0, t, 0, w.backGain, .drums)
                        if full && w.back != "clap" { p.inst("clap", 0, t, 0, 0.7, .drums) }
                    }
                }
                let g = i % 2 == 1 ? 0.6 : 1
                at(b + x) { t in p.inst(w.tick, 0, t, 0, g, .drums) }
            }
            if let perc = w.perc {
                for x in [1.5, 3.5] { at(b + x) { t in p.inst(perc, 0, t, 0, 0.6, .drums) } }
            }
        }

        func bass(_ b: Double, _ r: Double, _ beats: Double) {
            let steps: [(Double, Double)]
            switch w.bassStyle {
            case "walk": steps = beats >= 4 ? [(0, r), (1, r + 4), (2, r + 7), (3, r + 9)] : beats >= 2 ? [(0, r), (1, r + 7)] : [(0, r)]
            case "oompah": steps = beats >= 4 ? [(0, r), (2, r + 7)] : [(0, r)]
            default: steps = beats >= 4 ? [(0, r), (2, r + 7), (3.5, r + 7)] : [(0, r)]
            }
            for (x, n) in steps { at(b + x) { t in p.inst(w.bass, n, t, spb * 0.9, 1, .bass) } }
        }

        func comp(_ b: Double, _ chord: [Double], _ beats: Double) {
            switch w.compStyle {
            case "strum":
                for (x, g) in [(0.0, 1.0), (1, 0.7), (1.5, 0.8), (2.5, 0.7), (3, 0.8)] where x < beats {
                    at(b + x) { t in for (i, n) in chord.enumerated() { p.inst(w.comp, n, t + Double(i) * 0.015, spb * 1.5, g) } }
                }
            case "arp":
                let notes = [chord[0], chord[1], chord[2], chord[0] + 12, chord[2], chord[1], chord[2], chord[0] + 12]
                var i = 0
                while Double(i) < beats * 2 {
                    let n = notes[i % 8], g = i % 2 == 1 ? 0.7 : 1
                    at(b + Double(i) * 0.5) { t in p.inst(w.comp, n, t, spb, g) }
                    i += 1
                }
            case "offbeat":
                var x = 0.5
                while x < beats {
                    at(b + x) { t in for n in [chord[1], chord[2]] { p.inst(w.comp, n, t, spb * 0.5, 0.9) } }
                    x += 1
                }
            default: // block chords on the beat, a lighter one on the "and" before the next
                var x = 0.0
                while x < beats {
                    at(b + x) { t in for n in chord { p.inst(w.comp, n, t, spb * 1.6, 1) } }
                    if x + 1.5 < beats { at(b + x + 1.5) { t in for n in chord { p.inst(w.comp, n + 12, t, spb * 0.5, 0.5) } } }
                    x += 2
                }
            }
        }

        func melody(_ id: String, _ b: Double, _ mel: [(Double, Double, Double)], _ g: Double, _ up: Double = 12, _ out: Ch = .lead) {
            for (x, n, d) in mel { at(b + x) { t in p.inst(id, n + up, t, d * spb * 1.05, g, out) } }
        }

        func bars(_ list: [KaraokeData.Bar], _ b0: Double, chorus: Bool) {
            for (i, bar) in list.enumerated() {
                let b = b0 + Double(i) * 4
                groove(b, chorus)
                for (j, change) in bar.ch.enumerated() {
                    let (x, chord, root) = change
                    let beats = (j + 1 < bar.ch.count ? bar.ch[j + 1].0 : 4) - x
                    bass(b + x, root, beats)
                    comp(b + x, chord, beats)
                }
                let harmony = bar.mel.filter { $0.2 >= 1 }.map { ($0.0, below($0.1, bar.chordAt($0.0)), $0.2) }
                if !chorus {
                    // the tune passes around the band: the lead's line, then the second instrument's
                    let (tune, other) = i < 2 ? (w.lead, w.second) : (w.second, w.lead)
                    melody(tune, b, bar.mel, lead)
                    melody(other, b, harmony, 0.45, 12, .sparkle)
                    // the friend: off-beat stabs on the chord, and its answers in the gaps
                    for stab in KaraokeData.verseStabs(bar) {
                        at(b + stab.beat) { t in p.sing(stab.note, t, spb * 0.75, .aR) }
                    }
                } else {
                    // everyone: the tune on the lead, a counter-melody, sparkle up high, the friend on the hook
                    melody(w.lead, b, bar.mel, lead)
                    melody(w.second, b, harmony, 0.6, 12, .sparkle)
                    melody(w.sparkle, b, bar.mel, 0.4, 24, .sparkle)
                    for (x, n, d) in bar.voice { at(b + x) { t in p.sing(n, t, d * spb, .solo) } }
                }
                let c3 = bar.chordAt(3)
                if bar.answer == "extra" { at(b + 3) { t in p.extra(t, .aR, c3) } }
                if bar.answer == "chirp" {
                    at(b + 3) { t in p.chirp(t, c3) }
                    // the band echoes the end of the line, an octave up
                    for (j, m) in bar.mel.suffix(3).enumerated() {
                        at(b + 3 + Double(j) * 0.25) { t in p.inst(w.lead, m.1 + 24, t, spb * 0.4, 0.7, .sparkle) }
                    }
                }
            }
        }

        let C = KaraokeData.C
        // intro: a count-in on the sticks, the band walks up, the friend says hello
        for x in 0..<4 {
            let g = x == 0 ? 1.0 : 0.7
            at(Double(x)) { t in p.inst("woodblock", 0, t, 0, g, .drums) }
        }
        at(0) { t in for n in C { p.inst(w.comp, n, t, spb * 2, 0.7) } }
        at(2) { t in p.sing(KaraokeData.helloNote, t, spb, .aR) }
        for (i, n) in [60.0, 64, 67, 72].enumerated() { at(2 + Double(i) * 0.5) { t in p.inst(w.lead, n + 12, t, spb * 0.5, 0.8, .lead) } }
        at(3) { t in p.inst(w.bass, 43, t, spb * 0.9, 1, .bass) }
        at(3.5) { t in p.chirp(t, C) }
        var b = 4.0

        // verse: the instruments take turns with the tune; the friend plays along
        bars(KaraokeData.verse, b, chorus: false)
        b += Double(KaraokeData.verse.count) * 4

        // chorus: the whole band, the friend singing the hook with the lead
        let k = p.k
        at(b) { t in k.crash(t, 0.1) }
        bars(KaraokeData.chorus, b, chorus: true)
        b += Double(KaraokeData.chorus.count) * 4
        // a chirp in the chorus's last held note
        at(b - 1) { t in p.chirp(t, C) }

        // stop! one band hit, then the friend's solo break: its own full call
        at(b) { t in
            k.crash(t, 0.12)
            p.inst(w.kick, 0, t, 0, 1, .drums)
            p.inst(w.bass, 36, t, spb, 1, .bass)
            for n in C { p.inst(w.comp, n, t, spb, 1) }
        }
        let callLen = Band.lenOf(call, p.s)
        let soloAt = b + 1
        let key = p.voice.key
        at(soloAt) { t in
            Band.playCall(k, call, t, .solo)
            k.strings([60.0, 64, 67].map { $0 + key }, t, callLen + spb, 0.01)
        }
        // ta-da: the whole band, the friend with them, then one last ad-lib
        let end = ((soloAt + (callLen + 0.15) / spb) * 2).rounded(.up) / 2
        let tada = KaraokeData.tadaNotes
        at(end) { t in
            p.sing(tada[0], t, spb, .solo)
            p.inst(w.lead, 79, t, spb, lead, .lead)
            p.inst(w.kick, 0, t, 0, 1, .drums)
        }
        at(end + 1) { t in
            p.sing(tada[1], t, spb * 2, .solo)
            p.inst(w.lead, 84, t, spb * 3, lead, .lead)
            p.inst(w.second, 76, t, spb * 3, 0.7, .sparkle)
            k.crash(t, 0.13)
            p.inst(w.kick, 0, t, 0, 1, .drums)
            p.inst(w.bass, 36, t, spb * 3, 1, .bass)
            for (i, n) in [48.0, 55, 60, 64, 67, 72].enumerated() { p.inst(w.comp, n, t + Double(i) * 0.03, spb * 3, 0.8) }
            p.chirp(t + 0.1, C)
        }
        at(end + 2.5) { t in p.extra(t, .aR, C) }
        return end + 2.5
    }
}

/// The friend and its band for one song: decides once, at the start, which
/// recordings play (so a song never switches voice halfway through), then
/// plays instruments, sung notes, the friend's extra sound and the chirps.
/// Runs on the audio thread, under Sound's lock, like the rest of the synth.
final class KaraokePlayer {
    unowned let s: Synth
    let k: Kit
    let friendId: String
    let friend: KaraokeData.Friend
    let world: KaraokeData.World
    let voice: KaraokeData.Voice
    /// recorded instruments that have loaded: their measured pitch and octave shift
    private let use: [String: (base: Double?, off: Double)]
    private let hasExtra: Bool
    private let synOff: Double

    init(s: Synth, k: Kit, friendId: String, friend: KaraokeData.Friend, world: KaraokeData.World) {
        self.s = s
        self.k = k
        self.friendId = friendId
        self.friend = friend
        self.world = world
        var loaded: [String: (base: Double?, off: Double)] = [:]
        for (id, rec) in KaraokeData.inst where s.samples[Karaoke.instKey(id)] != nil {
            loaded[id] = (rec.m, KaraokeData.octaveShift(id, measured: rec.m))
        }
        use = loaded
        voice = KaraokeData.voice(for: friendId, recorded: s.samples[Karaoke.singKey(friendId)] != nil)
        hasExtra = KaraokeData.extra[friendId] != nil && s.samples[Karaoke.extraKey(friendId)] != nil
        synOff = KaraokeData.synthOctaves(friend.hz)
    }

    var key: Double { voice.key }

    /// One instrument note (n in C; the song's key is added here). d = how long
    /// it may ring (0 = let a drum ring out).
    func inst(_ id: String, _ n0: Double, _ t: Double, _ d: Double, _ g: Double = 1, _ out: Ch = .comp) {
        var n = n0 + key
        if let f = KaraokeData.floorNote[id], n < f { n += 12 }
        guard let u = use[id] else {
            Karaoke.syn[id]?(k, n, t, d, g, out)
            return
        }
        let rate = u.base.map { pow(2, (n + u.off - $0) / 12) } ?? 1
        s.playSample(Karaoke.instKey(id), at: t, bus: k.bus, gain: (KaraokeData.gain[id] ?? 0.35) * g * k.g(out),
                     rate: rate, maxDur: d > 0 ? max(d, 0.25) : nil)
    }

    /// One sung syllable: it rings for as long as it naturally lasts,
    /// overlapping the next by a touch, and is only faded (gently, never
    /// chopped) if the call is longer than that.
    func sing(_ n: Double, _ t: Double, _ d: Double, _ out: Ch, _ g: Double = 1) {
        let len = d + 0.1
        if voice.role == .synth {
            let kind = friend.synth
            k.say(kind, t, midi(n + synOff), kind == "cheep" ? min(len, 0.14) : len, out, g)
        } else {
            s.playSample(Karaoke.singKey(friendId), at: t, bus: k.bus, gain: KaraokeData.singGain * g * k.g(out),
                         rate: pow(2, voice.bend(n) / 12), maxDur: len, fade: 0.12)
        }
        if g >= 1, let bop = s.onSing { bop(t - s.t, len) }
    }

    /// its second sound; if that has not loaded, the world's chirp answers instead
    @discardableResult
    func extra(_ t: Double, _ out: Ch, _ chord: [Double]) -> Double {
        if hasExtra { return s.playSample(Karaoke.extraKey(friendId), at: t, bus: k.bus, gain: 0.85 * k.g(out), maxDur: 1.4) }
        chirp(t, chord)
        return 0.5
    }

    /// tones and chirps that suit the world, always on the chord's notes
    func chirp(_ t: Double, _ chord: [Double]) {
        let hi = chord.map { $0 + 24 + key }
        let o = Ch.sparkle
        switch world.chirp {
        case "cheeps":
            k.cheep(t, midi(hi[2]), 0.08, o, 0.8)
            k.cheep(t + 0.12, midi(hi[2] + 5), 0.08, o, 0.8)
            inst("whistle", 72, t + 0.24, 0, 0.8, o)
        case "birds":
            for i in 0..<6 { k.cheep(t + Double(i) * 0.065, midi(hi[i % 2 == 1 ? 2 : 1] + (i > 3 ? 12 : 0)), 0.05, o, 0.7) }
        case "parrot":
            k.squeak(t, midi(hi[0]), 0.16, o, 0.9)
            k.squeak(t + 0.2, midi(hi[2]), 0.2, o, 0.9)
            inst("bongo", 0, t + 0.1, 0, 0.6, .drums)
            inst("bongo", 0, t + 0.22, 0, 0.5, .drums)
        case "bubbles":
            for (i, j) in [0, 1, 2, 0].enumerated() {
                k.bloop(t + Double(i) * 0.09, midi(chord[j] + key + 12 * (i == 3 ? 2 : 1)), 0.1, o, 0.9)
            }
        case "kooka": // Aussie Bush: a kookaburra laugh on the chord, koo-koo-ka-ka-ka, climbing then tumbling
            let seq = [hi[0], hi[1], hi[2], hi[2], hi[1], hi[2], hi[1], hi[0]]
            for (i, n) in seq.enumerated() {
                if i < 2 { k.ooh(t + Double(i) * 0.07, midi(n - 12), 0.06, o, 0.55) } else { k.ah(t + Double(i) * 0.07, midi(n - 12), 0.06, o, 0.55) }
            }
        case "jingle": // Christmas: a shake of the sleigh bells, then the chord rung on the glockenspiel
            inst("sleighbells", 0, t, 0, 1, .drums)
            inst("sleighbells", 0, t + 0.11, 0, 0.7, .drums)
            for (i, n) in (chord + [chord[0] + 12]).enumerated() { inst("glock", n + 24, t + 0.05 + Double(i) * 0.07, 0.5, 0.55, o) }
        default: // sparkle
            inst("sparkle", 84, t, 0, 0.8, o)
            for (i, n) in (chord + [chord[0] + 12]).enumerated() { inst("glock", n + 12, t + Double(i) * 0.07, 0.6, 0.6, o) }
        }
    }
}

// MARK: - kit additions (web band.js has these; the animal bands did not need them)

extension Kit {
    func xylo(_ n: Double, _ t: Double, _ gn: Double = 0.08) {
        tone(midi(n), t, 0.35, .sparkle, gain: gn, partials: [(1, 1), (3.93, 0.25), (9.4, 0.05)])
    }
    func woodblock(_ t: Double, _ hi: Bool = true, _ gn: Double = 0.1) {
        tone(hi ? 1250 : 880, t, 0.07, .drums, gain: gn, partials: [(1, 1), (2.4, 0.3)])
    }
    func tamb(_ t: Double, _ gn: Double = 0.06) {
        noise(t, 0.13, .drums, freq: 8200, q: 2.2, gain: gn)
        tone(5300, t, 0.1, .drums, gain: gn * 0.18)
        tone(7150, t + 0.004, 0.08, .drums, gain: gn * 0.14)
    }

    /// an animal syllable by name (web k.say[kind]): the karaoke's stand-in voices
    func say(_ kind: String, _ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
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
        default: squeak(t, f, d, c, gn)
        }
    }
}

// MARK: - the packs' calls (web js/packs/aussie.js and christmas.js `calls`)

extension Band {
    /// Synthesised stand-ins for the packs' new calls; the recordings
    /// (call-<name>.mp3) replace them once loaded.
    static let packCalls: [String: Call] = [
        // Aussie Bush
        "galah": Call(len: 0.5) { k, t, o in k.crow(t, 1350, 0.16, o); k.crow(t + 0.24, 1500, 0.2, o) },
        "cockatoo": Call(len: 0.45) { k, t, o in k.crow(t, 1050, 0.42, o) },
        "kooka": Call(len: 1.5) { k, t, o in
            // koo-koo-koo-ka-ka-ka: a laugh that climbs and tumbles
            for (i, hz) in [560.0, 600, 640, 760, 820, 900, 820, 760, 700, 640, 600].enumerated() { k.ah(t + Double(i) * 0.12, hz, 0.1, o, 0.8) }
            k.ooh(t + 1.35, 520, 0.14, o)
        },
        "emu": Call(len: 0.9) { k, t, o in for g in [0.0, 0.3, 0.6] { k.hoot(t + g, 150, 0.24, o, 1.2) } },
        "huff": Call(len: 0.55) { k, t, o in k.ork(t, 170, 0.2, o, 0.8); k.oink(t + 0.28, 140, 0.24, o, 0.8) },
        "platypus": Call(len: 0.45) { k, t, o in k.croak(t, 270, 0.42, o, 0.7) },
        "glider": Call(len: 0.4) { k, t, o in
            for (i, g) in [0.0, 0.13, 0.26].enumerated() { k.woof(t + g, 900 + Double(i) * 40, 0.08, o, 0.6) }
        },
        "frill": Call(len: 0.5) { k, t, o in k.sniff(t, 4200, 0.3, o, 0.6); k.squeak(t + 0.32, 2200, 0.14, o) },
        "churr": Call(len: 0.7) { k, t, o in for i in 0..<12 { k.squeak(t + Double(i) * 0.055, 2500, 0.04, o, 0.8) } },
        // Christmas
        "gingerhee": Call(len: 0.6) { k, t, o in
            for (i, g) in [0.0, 0.13, 0.26].enumerated() { k.squeak(t + g, 1700 + Double(i) * 160, 0.1, o) }
            k.squeak(t + 0.4, 2300, 0.16, o)
        },
        "bauble": Call(len: 0.8) { k, t, _ in
            for g in [0.0, 0.07, 0.15, 0.24] { k.tamb(t + g, 0.05) }
            for (i, n) in [91.0, 96, 100].enumerated() { k.glock(n, t + 0.1 + Double(i) * 0.12, 0.6, 0.04) }
        },
        "starding": Call(len: 1.0) { k, t, o in k.glock(84, t, 1.2, 0.07); k.glock(96, t + 0.02, 0.9, 0.03); k.hoot(t, 1046, 0.5, o, 0.5) },
        "wobble": Call(len: 0.7) { k, t, o in
            for (i, g) in [0.0, 0.16, 0.3, 0.42].enumerated() { k.bloop(t + g, 320 - Double(i) * 30, 0.14, o, 1 - Double(i) * 0.18) }
        },
        "clack": Call(len: 0.6) { k, t, o in
            k.woodblock(t, true, 0.14); k.woodblock(t + 0.16, false, 0.14); k.claves(t + 0.38, 0.12); k.ork(t + 0.4, 220, 0.12, o, 0.4)
        },
        "sugarplum": Call(len: 1.0) { k, t, _ in
            for (i, n) in [79.0, 83, 86, 91, 95, 98].enumerated() { k.glock(n, t + Double(i) * 0.09, 0.8, 0.05) }
        },
        "mouseking": Call(len: 0.55) { k, t, o in k.squeak(t, 2400, 0.12, o); k.squeak(t + 0.18, 2800, 0.3, o) },
        "icetinkle": Call(len: 0.9) { k, t, _ in
            for (i, n) in [96.0, 100, 103, 98, 101, 105].enumerated() { k.glock(n, t + Double(i) * 0.06, 0.5, 0.035) }
        },
        "angelaah": Call(len: 1.1) { k, t, o in
            k.ah(t, 523, 1.0, o, 0.8); k.ah(t, 659, 1.0, o, 0.4)
            for (i, n) in [84.0, 88, 91].enumerated() { k.glock(n, t + 0.7 + Double(i) * 0.07, 0.6, 0.03) }
        },
        "reindeer": Call(len: 0.8) { k, t, o in
            k.sniff(t, 700, 0.18, o)
            for g in [0.22, 0.3, 0.38, 0.5] { k.tamb(t + g, 0.06) }
            k.ork(t + 0.5, 190, 0.2, o, 0.6)
        },
        "snowhoo": Call(len: 0.9) { k, t, o in k.hoot(t, 330, 0.85, o) },
    ]
}

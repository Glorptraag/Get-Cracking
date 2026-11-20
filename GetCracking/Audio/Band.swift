import Foundation

/// The animal bands: three celebration songs that play when the egg hatches,
/// each a full little band plus a chorus of animal voices. The native twin of
/// the web app's js/band.js; every sound is made by the synth in Sound.swift,
/// except the animal calls, which use the recordings in Resources/Sounds when
/// they have loaded.
///
///   Animal band       a marching band: drum major's whistle, trumpets in harmony,
///                     tuba, trombones, French horns, bass drum, snare, cymbals,
///                     glockenspiel, piccolo, timpani, slide whistle, kazoo
///   Jungle jam        calypso: steel drum, marimba, ukulele, bongos, shaker,
///                     claves, bass, pan flute
///   Farmyard hoedown  two-step: fiddle, banjo, harmonica, jug, washboard,
///                     cowbell, hand claps, slide whistle
///
/// Every song has the same shape, so a child learns it: intro → 4 bars where
/// the band plays a line and an animal answers → 2 bars where the animals sing
/// the tune → everyone cheers → the friend who just hatched gets a solo → a big
/// ending. Events are handed to the synth, which runs each one just before it
/// is due (inside the render callback), so the song stops at once.

private func midi(_ n: Double) -> Double { 440 * pow(2, (n - 69) / 12) }
private func P(_ v: Double) -> Path { [(0, v)] }
/// a path written as fractions of a length d (time) and a pitch f
private func rel(_ p: Path, _ f: Double, _ d: Double) -> Path { p.map { ($0.0 * d, $0.1 * f) } }

/// mixer channels inside a song (web: one gain + pan node each; here a level)
enum Ch { case drums, bass, comp, lead, sparkle, aL, aR, solo }

/// A band's scheduled events, run by the synth on the audio thread.
final class Celebration {
    var events: [(t: Double, fn: (Kit, Double) -> Void)]
    var i = 0
    let kit: Kit
    let end: Double
    let friendCall: String

    init(events: [(t: Double, fn: (Kit, Double) -> Void)], kit: Kit, end: Double, friendCall: String) {
        self.events = events
        self.kit = kit
        self.end = end
        self.friendCall = friendCall
    }
}

/// Collects a song's events while it is being arranged.
final class Score {
    var events: [(beat: Double, fn: (Kit, Double) -> Void)] = []
    func at(_ beat: Double, _ fn: @escaping (Kit, Double) -> Void) { events.append((beat: beat, fn: fn)) }
}

// MARK: - the instruments

struct Kit {
    unowned let s: Synth
    let bus: Bus
    /// inside a song the channel levels apply; a lone call (tapping the friend) plays at 1
    let mix: Bool
    let t0: Double
    let spb: Double

    /// beat → time
    func B(_ beat: Double) -> Double { t0 + beat * spb }

    func g(_ c: Ch) -> Double {
        guard mix else { return 1 }
        switch c {
        case .drums: return 0.85
        case .comp, .sparkle: return 0.9
        case .solo: return 1.15
        case .bass, .lead, .aL, .aR: return 1
        }
    }

    func tone(_ f: Double, _ t: Double, _ d: Double, _ c: Ch, gain: Double, attack: Double = 0.005,
              partials: [(Double, Double)] = [(1, 1)], wave: Wave = .sine, slide: Double? = nil) {
        s.tone(f, t, d, gain: gain * g(c), attack: attack, partials: partials, wave: wave, slide: slide, bus: bus)
    }

    func noise(_ t: Double, _ d: Double, _ c: Ch, freq: Double, q: Double, gain: Double,
               attack: Double = 0.003, type: FilterType = .bandpass) {
        s.noiseBurst(t, d, freq: freq, q: q, gain: gain * g(c), attack: attack, type: type, bus: bus)
    }

    func V(_ t: Double, _ v: VSpec, _ c: Ch) { s.voice(v, at: t, gain: g(c), bus: bus) }

    // ---- drums & percussion

    func kick(_ t: Double, _ gn: Double = 0.5) {
        tone(150, t, 0.3, .drums, gain: gn, slide: 0.32)
        tone(80, t, 0.22, .drums, gain: gn * 0.5, wave: .triangle, slide: 0.7)
        noise(t, 0.02, .drums, freq: 3500, q: 0.8, gain: gn * 0.18)
    }
    /// a crisp marching snare: wires + a tight drum head
    func snare(_ t: Double, _ gn: Double = 0.22) {
        noise(t, 0.13, .drums, freq: 3800, q: 0.7, gain: gn * 0.8)
        noise(t, 0.17, .drums, freq: 1400, q: 0.5, gain: gn * 0.6, type: .highpass)
        tone(225, t, 0.07, .drums, gain: gn * 0.6, wave: .triangle, slide: 0.8)
    }
    func flam(_ t: Double, _ gn: Double = 0.22) { snare(t - 0.028, gn * 0.35); snare(t, gn) }
    /// big felt-beater marching bass drum
    func bassDrum(_ t: Double, _ gn: Double = 0.5) {
        tone(72, t, 0.55, .drums, gain: gn, slide: 0.72)
        tone(118, t, 0.2, .drums, gain: gn * 0.45, wave: .triangle, slide: 0.7)
        noise(t, 0.07, .drums, freq: 600, q: 0.7, gain: gn * 0.35, type: .lowpass)
    }
    /// hand cymbals
    func clash(_ t: Double, _ gn: Double = 0.08) {
        noise(t, 0.75, .drums, freq: 3200, q: 0.5, gain: gn, type: .highpass)
        noise(t, 0.4, .drums, freq: 6200, q: 1.2, gain: gn * 0.7)
    }
    /// the drum major's whistle: the pea makes it trill
    func peaWhistle(_ t: Double, _ d: Double, _ gn: Double = 0.1) {
        V(t, VSpec(type: .sine, f: [(0, 2650), (0.04, 2900), (d, 2850)], dur: d, gain: gn, attack: 0.01, release: 0.03,
                   vib: (46, 45, 0), trem: (46, 0.75), noise: 0.08, noiseF: 2900), .sparkle)
    }
    func roll(_ t0: Double, _ t1: Double, _ g0: Double, _ g1: Double) {
        let n = max(2, Int(((t1 - t0) / 0.05).rounded()))
        for i in 0..<n {
            let f = Double(i) / Double(n)
            noise(t0 + (t1 - t0) * f, 0.06, .drums, freq: 1700, q: 0.5, gain: g0 + (g1 - g0) * f, type: .highpass)
        }
    }
    func hat(_ t: Double, _ gn: Double = 0.06, open: Bool = false) {
        noise(t, open ? 0.24 : 0.035, .drums, freq: 7600, q: 0.7, gain: gn, type: .highpass)
    }
    func crash(_ t: Double, _ gn: Double = 0.13) {
        noise(t, 2.0, .drums, freq: 4800, q: 0.4, gain: gn, type: .highpass)
        noise(t, 1.3, .drums, freq: 9500, q: 1.5, gain: gn * 0.6)
    }
    func clap(_ t: Double, _ gn: Double = 0.16) {
        for i in 0..<3 { noise(t + Double(i) * 0.011, 0.025, .drums, freq: 1300, q: 1.1, gain: gn) }
        noise(t + 0.033, 0.14, .drums, freq: 1150, q: 0.9, gain: gn * 0.6)
    }
    func shaker(_ t: Double, _ gn: Double = 0.045) {
        noise(t, 0.075, .drums, freq: 5500, q: 0.7, gain: gn, attack: 0.02, type: .highpass)
    }
    func claves(_ t: Double, _ gn: Double = 0.1) {
        tone(2450, t, 0.06, .drums, gain: gn, partials: [(1, 1), (2.2, 0.15)])
    }
    func bongo(_ t: Double, _ hi: Bool, _ gn: Double = 0.16) {
        tone(hi ? 410 : 290, t, hi ? 0.13 : 0.18, .drums, gain: gn, partials: [(1, 1), (1.52, 0.25)], slide: 0.9)
        noise(t, 0.018, .drums, freq: hi ? 3200 : 2100, q: 1, gain: gn * 0.35)
    }
    func cowbell(_ t: Double, _ gn: Double = 0.07) {
        V(t, VSpec(type: .square, f: P(562), partials: [(1, 1), (1.505, 0.8)], dur: 0.32, gain: gn, pluck: true,
                   filter: (.bandpass, P(820), 2.2)), .drums)
    }
    func washboard(_ t: Double, _ gn: Double = 0.07) {
        noise(t, 0.07, .drums, freq: 3600, q: 2.5, gain: gn, attack: 0.018)
        for i in 0..<3 { tone(4100 + Double(i) * 300, t + Double(i) * 0.012, 0.02, .drums, gain: gn * 0.12) }
    }
    func timp(_ t: Double, _ n: Double, _ gn: Double = 0.25) {
        tone(midi(n), t, 1.4, .bass, gain: gn, partials: [(1, 1), (1.5, 0.35), (2, 0.25), (2.74, 0.08)], slide: 0.985)
    }
    func timpRoll(_ t0: Double, _ t1: Double, _ n: Double, _ g0: Double, _ g1: Double) {
        let c = max(2, Int(((t1 - t0) / 0.065).rounded()))
        for i in 0..<c {
            let f = Double(i) / Double(c)
            tone(midi(n), t0 + (t1 - t0) * f, 0.3, .bass, gain: g0 + (g1 - g0) * f, partials: [(1, 1), (1.5, 0.3), (2, 0.2)])
        }
    }

    // ---- bass

    func tuba(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.2) {
        let m = midi(n)
        V(t, VSpec(f: [(0, m * 0.97), (0.04, m)], dur: d, gain: gn, attack: 0.035, release: 0.09, sus: 0.7,
                   filter: (.lowpass, [(0, 260), (0.05, 950), (max(d, 0.06), 480)], 1.1)), .bass)
    }
    func bass(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.24) {
        tone(midi(n), t, d, .bass, gain: gn, partials: [(1, 1), (2, 0.55), (3, 0.22), (4, 0.08)])
    }
    func jug(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.22) {
        let m = midi(n)
        V(t, VSpec(f: [(0, m * 0.93), (0.07, m)], dur: d, gain: gn, attack: 0.03, release: 0.08, sus: 0.55,
                   formants: [([(0, 260), (0.08, 420), (max(d, 0.09), 300)], 2.5, 1), (P(800), 4, 0.35)]), .bass)
    }

    // ---- chords & keys

    func piano(_ n: Double, _ t: Double, _ d: Double = 0.9, _ gn: Double = 0.07, _ c: Ch = .comp) {
        tone(midi(n), t, d, c, gain: gn, partials: [(1, 1), (2, 0.45), (3, 0.18), (4, 0.1), (5.02, 0.04)])
    }
    func strings(_ notes: [Double], _ t: Double, _ d: Double, _ gn: Double = 0.022) {
        for n in notes {
            V(t, VSpec(f: P(midi(n)), detune: [-9, 0, 8], dur: d, gain: gn, attack: min(0.35, d * 0.3), release: 0.35, sus: 0.9,
                       vib: (5, 7, 0.2), filter: (.lowpass, P(2300), 0.7)), .comp)
        }
    }
    func uke(_ notes: [Double], _ t: Double, _ gn: Double = 0.06) {
        for (i, n) in notes.enumerated() {
            tone(midi(n), t + Double(i) * 0.016, 0.38, .comp, gain: gn, partials: [(1, 1), (2, 0.4), (3, 0.12)], wave: .triangle)
        }
    }
    func banjo(_ n: Double, _ t: Double, _ gn: Double = 0.08, _ c: Ch = .comp) {
        V(t, VSpec(f: P(midi(n)), dur: 0.42, gain: gn, pluck: true, filter: (.lowpass, [(0, 5200), (0.12, 1400), (0.42, 900)], 2.5)), c)
    }
    func strumBanjo(_ notes: [Double], _ t: Double, _ gn: Double) {
        for (i, n) in notes.enumerated() { banjo(n, t + Double(i) * 0.014, gn) }
    }
    func harmonica(_ notes: [Double], _ t: Double, _ d: Double, _ gn: Double = 0.035) {
        for n in notes {
            V(t, VSpec(type: .square, f: P(midi(n)), dur: d, gain: gn, attack: 0.03, release: 0.06, sus: 0.85,
                       trem: (6.5, 0.25), filter: (.lowpass, P(2400), 1.2)), .comp)
        }
    }
    /// French horns: round, mellow sustained chords
    func horns(_ notes: [Double], _ t: Double, _ d: Double, _ gn: Double = 0.022) {
        for n in notes {
            V(t, VSpec(f: P(midi(n)), detune: [-5, 5], dur: d, gain: gn, attack: min(0.09, d * 0.3), release: 0.12, sus: 0.85,
                       vib: (4.8, 6, 0.25), filter: (.lowpass, P(1050), 0.6)), .comp)
        }
    }
    /// trombones: the "pah" in oom-pah
    func bones(_ notes: [Double], _ t: Double, _ d: Double, _ gn: Double = 0.04) {
        for n in notes {
            let m = midi(n)
            V(t, VSpec(f: [(0, m * 0.98), (0.03, m)], detune: [-6, 6], dur: d, gain: gn, attack: 0.02, release: 0.06, sus: 0.6,
                       filter: (.lowpass, [(0, 400), (0.04, 2200), (max(d, 0.05), 900)], 1.2)), .comp)
        }
    }

    // ---- melody

    /// trumpets: a little scoop up into each note
    func brass(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.075, _ c: Ch = .lead) {
        let m = midi(n)
        V(t, VSpec(f: [(0, m * 0.975), (0.035, m)], detune: [-7, 0, 6], dur: d, gain: gn, attack: 0.035, release: 0.09, sus: 0.8,
                   vib: (5.5, 10, 0.18), filter: (.lowpass, [(0, 450), (0.045, 3400), (0.25, 2100)], 1.3)), c)
    }
    func glock(_ n: Double, _ t: Double, _ d: Double = 1.1, _ gn: Double = 0.045) {
        tone(midi(n), t, d, .sparkle, gain: gn, partials: [(1, 1), (2.76, 0.2), (5.4, 0.06)])
    }
    func flute(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.07) {
        let m = midi(n)
        V(t, VSpec(type: .sine, f: P(m), partials: [(1, 1), (2, 0.14), (3, 0.04)], dur: d, gain: gn, attack: 0.06, sus: 0.9,
                   vib: (5, 14, 0.15), noise: 0.05, noiseF: m * 2), .lead)
    }
    func panflute(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.07) {
        let m = midi(n)
        V(t, VSpec(type: .sine, f: [(0, m * 0.985), (0.05, m)], partials: [(1, 1), (2, 0.08)], dur: d, gain: gn, attack: 0.05,
                   release: 0.1, sus: 0.8, vib: (4.5, 12, 0.2), noise: 0.14, noiseF: m * 1.5), .lead)
    }
    func steel(_ n: Double, _ t: Double, _ d: Double = 0.9, _ gn: Double = 0.1) {
        tone(midi(n), t, d, .lead, gain: gn, attack: 0.004, partials: [(1, 1), (2, 0.55), (3.01, 0.18), (4.02, 0.26), (5.05, 0.05)])
    }
    func marimba(_ n: Double, _ t: Double, _ gn: Double = 0.09, _ c: Ch = .comp) {
        tone(midi(n), t, 0.6, c, gain: gn, partials: [(1, 1), (4, 0.15), (9.8, 0.03)])
    }
    func fiddle(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.065) {
        let m = midi(n)
        V(t, VSpec(f: [(0, m * 0.985), (0.05, m)], dur: d, gain: gn, attack: 0.04, sus: 0.85, vib: (6, 18, 0.1),
                   formants: [(P(700), 3, 1), (P(1700), 4, 0.7), (P(3000), 5, 0.4)]), .lead)
    }
    func kazoo(_ n: Double, _ t: Double, _ d: Double, _ gn: Double = 0.05, _ c: Ch = .lead) {
        let m = midi(n)
        V(t, VSpec(f: [(0, m * 0.97), (0.04, m)], dur: d, gain: gn, attack: 0.02, release: 0.06, sus: 0.9, vib: (6, 25, 0.08),
                   formants: [(P(600), 4, 1), (P(1500), 8, 0.9), (P(2800), 8, 0.5)], noise: 0.12, noiseF: 2500), c)
    }
    func slideWhistle(_ t: Double, _ n0: Double, _ n1: Double, _ d: Double, _ gn: Double = 0.08) {
        V(t, VSpec(type: .sine, f: [(0, midi(n0)), (d, midi(n1))], partials: [(1, 1), (2, 0.06)], dur: d, gain: gn, attack: 0.04,
                   release: 0.06, vib: (6.5, 30, 0), noise: 0.05, noiseF: 3000), .sparkle)
    }
    func harp(_ notes: [Double], _ t: Double, _ gap: Double, _ gn: Double = 0.05) {
        for (i, n) in notes.enumerated() {
            tone(midi(n), t + Double(i) * gap, 1.3, .sparkle, gain: gn, partials: [(1, 1), (2, 0.25)], wave: .triangle)
        }
    }

    // ---- animal syllables: (t, f Hz, d s, channel). Paths are fractions of d
    // (time) and f (pitch), so the same moo can be a cow or a calf, short or
    // long, and the animals can sing the tune.

    func moo(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.9), (0.14, 1.06), (0.6, 1.0), (1, 0.78)], f, d), dur: d, gain: 0.25 * gn, attack: d * 0.12,
                   release: d * 0.28, vib: (4, 12, d * 0.2), filter: (.lowpass, rel([(0, 2), (0.26, 8.8), (0.75, 5.6), (1, 2.4)], f, d), 2.5),
                   noise: 0.03, noiseF: 400), c)
    }
    func quack(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 1.1), (0.6, 1), (1, 0.82)], f, d), dur: d, gain: 0.46 * gn, attack: 0.008, release: d * 0.3,
                   formants: [([(0, 900), (d * 0.5, 1300)], 5, 1), (P(2600), 7, 0.6)], noise: 0.08, noiseF: 1500), c)
    }
    func baa(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.9), (0.1, 1.01), (1, 0.9)], f, d), dur: d, gain: 0.39 * gn, attack: 0.03, release: d * 0.2,
                   vib: (7.5, 55, 0), trem: (7.5, 0.55), filter: (.lowpass, [(0, 500), (0.06, 4000)], 0.7),
                   formants: [(P(800), 5, 1), (P(1200), 6, 0.7), (P(2500), 8, 0.3)]), c)
    }
    func woof(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.82), (0.2, 1.14), (1, 0.72)], f, d), dur: d, gain: 0.4 * gn, attack: 0.006, release: d * 0.3,
                   formants: [(P(550), 3, 1), (P(1100), 4, 0.6), (P(2300), 6, 0.2)], noise: 0.25, noiseF: 900), c)
    }
    func meow(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.84), (0.22, 1.13), (0.6, 1.06), (1, 0.77)], f, d), dur: d, gain: 0.19 * gn, attack: 0.04,
                   release: d * 0.2, vib: (5.5, 18, d * 0.15),
                   formants: [(rel([(0, 0.7), (0.3, 1.45), (0.85, 0.9)], 620, d), 5, 1),
                              (rel([(0, 3.7), (0.3, 2.4), (0.85, 1.4)], 620, d), 7, 0.7),
                              (P(3000), 8, 0.15)]), c)
    }
    func oink(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(type: .square, f: rel([(0, 0.9), (0.28, 1.13), (1, 0.8)], f, d), dur: d, gain: 0.45 * gn, attack: 0.01,
                   release: d * 0.3, trem: (38, 0.7), formants: [(P(650), 3, 1), (P(1500), 5, 0.4)], noise: 0.35, noiseF: 700), c)
    }
    func hoot(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(type: .sine, f: rel([(0, 0.97), (0.22, 1.04), (1, 0.92)], f, d), partials: [(1, 1), (2, 0.12)], dur: d,
                   gain: 0.21 * gn, attack: min(0.07, d * 0.2), release: d * 0.4, noise: 0.03, noiseF: 400), c)
    }
    func cheep(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(type: .sine, f: rel([(0, 1.15), (1, 0.92)], f, d), dur: d, gain: 0.17 * gn, attack: 0.006, release: d * 0.3), c)
    }
    func trumpet(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.72), (0.13, 1.14), (0.6, 1.06), (1, 0.9)], f, d), detune: [-15, 15], dur: d, gain: 0.23 * gn,
                   attack: 0.05, release: d * 0.22, vib: (9, 45, 0.08),
                   formants: [(P(800), 3, 1), (P(1600), 4, 0.9), (P(3200), 5, 0.5)], noise: 0.2, noiseF: 1800), c)
    }
    func roar(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.82), (0.23, 1.18), (1, 0.7)], f, d), detune: [-20, 20], dur: d, gain: 0.5 * gn, attack: d * 0.1,
                   release: d * 0.3, trem: (32, 0.45), filter: (.lowpass, rel([(0, 3), (0.23, 14), (1, 4)], f, d), 1),
                   formants: [(P(700), 2, 1), (P(1300), 3, 0.6)], noise: 0.4, noiseF: 600), c)
    }
    func neigh(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.72), (0.12, 1.57), (0.5, 1.14), (1, 0.6)], f, d), dur: d, gain: 0.17 * gn, attack: 0.04,
                   release: d * 0.25, vib: (11, 140, 0.1),
                   formants: [(P(900), 4, 1), (P(1800), 5, 0.6), (P(2800), 6, 0.3)], noise: 0.12, noiseF: 2000), c)
    }
    func squeak(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(type: .sine, f: rel([(0, 0.87), (0.45, 1.16), (1, 1)], f, d), dur: d, gain: 0.125 * gn, attack: 0.008,
                   release: d * 0.3, vib: (30, 40, 0)), c)
    }
    func ork(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 1.1), (1, 0.83)], f, d), dur: d, gain: 0.42 * gn, attack: 0.012, release: d * 0.3,
                   trem: (25, 0.3), formants: [(P(600), 3, 1), (P(1100), 4, 0.6)], noise: 0.25, noiseF: 800), c)
    }
    func croak(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(type: .square, f: rel([(0, 0.95), (1, 1.12)], f, d), dur: d, gain: 0.55 * gn, attack: 0.01, release: 0.03,
                   trem: (30, 1), formants: [(P(450), 3, 1), (P(1300), 5, 0.5)]), c)
    }
    func ooh(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.85), (1, 1.15)], f, d), dur: d, gain: 0.28 * gn, attack: 0.02, release: d * 0.3,
                   formants: [(P(400), 4, 1), (P(850), 6, 0.3)]), c)
    }
    func ah(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.88), (1, 1.12)], f, d), dur: d, gain: 0.28 * gn, attack: 0.02, release: d * 0.3,
                   formants: [(P(900), 4, 1), (P(1400), 5, 0.6)]), c)
    }
    func crow(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.9), (0.2, 1.05), (0.75, 1), (1, 0.75)], f, d), dur: d, gain: 0.16 * gn, attack: 0.02,
                   release: d * 0.25, vib: (7, 40, d * 0.25),
                   formants: [(P(900), 5, 1), (P(1900), 6, 0.6), (P(3200), 8, 0.3)], noise: 0.1, noiseF: 2500), c)
    }
    func buzz(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(f: rel([(0, 0.92), (0.4, 1.08), (0.75, 0.96), (1, 1.04)], f, d), dur: d, gain: 0.18 * gn, attack: 0.08,
                   release: 0.1, vib: (14, 60, 0), filter: (.lowpass, P(1800), 1)), c)
    }
    func bloop(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        V(t, VSpec(type: .sine, f: rel([(0, 0.35), (1, 1)], f, d), dur: d, gain: 0.23 * gn, attack: 0.005, release: d * 0.3), c)
    }
    func sniff(_ t: Double, _ f: Double, _ d: Double, _ c: Ch, _ gn: Double = 1) {
        noise(t, d, c, freq: f, q: 2, gain: 0.5 * gn, attack: d * 0.4)
    }

    /// the singers' syllables, by name (for the animal choir)
    func syllable(_ who: String, _ t: Double, _ f: Double, _ d: Double, _ c: Ch) {
        switch who {
        case "meow": meow(t, f, d, c)
        case "baa": baa(t, f, d, c)
        case "quack": quack(t, f, d, c)
        case "woof": woof(t, f, d, c)
        case "oink": oink(t, f, d, c)
        case "hoot": hoot(t, f, d, c)
        case "trumpet": trumpet(t, f, d, c)
        case "cheep": cheep(t, f, d, c)
        default: break
        }
    }
}

// MARK: - songs

enum Kind { case a, b }

/// one call-and-response bar: the band's line (beat, note, beats), then an animal answers
struct BarA { let chord: [Double]; let root: Double; let fifth: Double; let mel: [(Double, Double, Double)] }
/// one choir bar: chord changes (beat, chord, root) and the notes the animals sing
struct BarB { let chords: [(Double, [Double], Double)]; let notes: [(Double, Double, Double)] }
struct Ending { let chord: [Double]; let root: Double; let top: [Double]; let fan: [(Double, Double, Double)] }

protocol BandSong {
    var bpm: Double { get }
    var introBeats: Double { get }
    /// how long the last chord rings after the final beat
    var tail: Double { get }
    var pool: [String] { get }
    var singers: [String] { get }
    var callBars: [BarA] { get }
    var choirBars: [BarB] { get }
    var end: Ending { get }
    func intro(_ sc: Score)
    func groove(_ sc: Score, _ b: Double, _ kind: Kind, _ i: Int)
    func bass(_ sc: Score, _ b: Double, _ root: Double, _ fifth: Double, _ beats: Double)
    func comp(_ sc: Score, _ b: Double, _ chord: [Double], _ kind: Kind, _ beats: Double)
    func lead(_ k: Kit, _ t: Double, _ n: Double, _ d: Double, _ i: Int, _ chord: [Double])
    /// the soft chord under the friend's solo
    func pad(_ k: Kit, _ notes: [Double], _ t: Double, _ d: Double, _ gn: Double)
    func finish(_ k: Kit, _ t: Double, _ e: Ending)
}

extension BandSong {
    var tail: Double { 2.6 }
    func pad(_ k: Kit, _ notes: [Double], _ t: Double, _ d: Double, _ gn: Double) { k.strings(notes, t, d, gn) }
}

private let C: [Double] = [60, 64, 67], F: [Double] = [60, 65, 69], G: [Double] = [59, 62, 67], Am: [Double] = [57, 60, 64]
private let A7: [Double] = [57, 61, 64, 67], D: [Double] = [62, 66, 69]
private let Fj: [Double] = [60, 65, 69], Bb: [Double] = [62, 65, 70], Cj: [Double] = [60, 64, 67], Dm: [Double] = [62, 65, 69]
private let Gf: [Double] = [59, 62, 67], Cf: [Double] = [60, 64, 67], Df: [Double] = [62, 66, 69], Em: [Double] = [59, 64, 67]

/// the nearest chord tone a bit below a melody note: a simple harmony line
private func below(_ n: Double, _ chord: [Double]) -> Double {
    var best = n - 12
    for c in chord {
        for o in stride(from: -24.0, through: 12.0, by: 12.0) {
            let h = c + o
            if h <= n - 3 && h > best { best = h }
        }
    }
    return best
}

/// nobody in a real band hits exactly the same every time
private func hum(_ g: Double) -> Double { g * (0.88 + Double.random(in: 0..<0.24)) }

/// Animal band: a marching band, finale stepped up a key.
private struct MarchSong: BandSong {
    let bpm = 136.0
    let introBeats = 4.0
    let tail = 4.2
    let pool = ["moo", "quack", "baa", "woof", "meow", "oink", "trumpet", "roar", "hoot", "neigh"]
    let singers = ["meow", "baa", "kazoo", "quack", "hoot", "woof"]
    // a dotted march line, then a gap for the animal; bars 1-2 share a rhythm so it is easy to follow
    let callBars = [
        BarA(chord: C, root: 36, fifth: 43, mel: [(0, 67, 0.75), (0.75, 72, 0.25), (1, 76, 0.5), (1.5, 79, 0.5)]),
        BarA(chord: F, root: 41, fifth: 36, mel: [(0, 69, 0.75), (0.75, 72, 0.25), (1, 77, 0.5), (1.5, 81, 0.5)]),
        BarA(chord: G, root: 43, fifth: 38, mel: [(0, 79, 0.75), (0.75, 77, 0.25), (1, 76, 0.5), (1.5, 74, 0.5)]),
        BarA(chord: C, root: 36, fifth: 43, mel: [(0, 76, 0.75), (0.75, 74, 0.25), (1, 72, 1)]),
    ]
    // the animals sing; the last two beats pivot on A7 so the finale can step up a key
    let choirBars = [
        BarB(chords: [(0, Am, 33), (2, F, 41)], notes: [(0, 69, 1), (1, 72, 1), (2, 77, 1), (3, 76, 1)]),
        BarB(chords: [(0, G, 43), (2, A7, 45)], notes: [(0, 74, 1), (1, 71, 1), (2, 73, 1), (3, 76, 1)]),
    ]
    // finale in D: one step higher than the rest of the song, for a lift
    let end = Ending(chord: D, root: 38, top: [62, 66, 69, 74], fan: [(0, 69, 1.0 / 3), (1.0 / 3, 74, 1.0 / 3), (2.0 / 3, 78, 1.0 / 3), (1, 81, 1)])

    func intro(_ sc: Score) {
        // drum major's whistle ("tweet, tweeeet!"), then a snare roll with a slide whistle into the downbeat
        sc.at(0) { k, t in k.peaWhistle(t, 0.16) }
        sc.at(0.5) { k, t in k.peaWhistle(t, k.B(1.6) - t) }
        sc.at(2) { k, t in
            k.roll(t, k.B(4) - 0.03, 0.03, 0.2)
            k.slideWhistle(t, 64, 88, k.B(3.9) - t, 0.06)
        }
    }

    func groove(_ sc: Score, _ b: Double, _ kind: Kind, _ i: Int) {
        if i == 0 {
            let gn = kind == .a ? 0.12 : 0.08
            sc.at(b) { k, t in k.crash(t, gn) }
        }
        // oom-pah: bass drum on 1 and 3, snare + cymbals on 2 and 4
        for x in [0.0, 2.0] {
            let gn = hum(x > 0 ? 0.4 : 0.5)
            sc.at(b + x) { k, t in k.bassDrum(t, gn) }
        }
        for x in [1.0, 3.0] {
            let g1 = hum(0.2), g2 = hum(0.15), g3 = hum(0.045)
            sc.at(b + x) { k, t in
                if kind == .a { k.flam(t, g1) } else { k.clap(t, g2) }
                k.clash(t, g3)
            }
        }
        if kind == .a {
            for x in [0.5, 1.75, 2.5, 3.25] { // ghost notes keep it marching
                let gn = hum(0.06)
                sc.at(b + x) { k, t in k.snare(t, gn) }
            }
            if i == 3 { // fill into the choir
                for (j, x) in [3.5, 3.625, 3.75, 3.875].enumerated() {
                    let gn = 0.08 + Double(j) * 0.035
                    sc.at(b + x) { k, t in k.snare(t, gn) }
                }
            } else {
                let gn = hum(0.1)
                sc.at(b + 3.5) { k, t in k.snare(t, gn) }
            }
        } else {
            for x in 0..<8 {
                let gn = hum(x % 2 == 1 ? 0.03 : 0.05)
                sc.at(b + Double(x) / 2) { k, t in k.hat(t, gn) }
            }
            if i == 1 { sc.at(b + 2) { k, t in k.roll(t, k.B(b + 4) - 0.03, 0.02, 0.22) } } // roll into the key change
        }
    }

    func bass(_ sc: Score, _ b: Double, _ root: Double, _ fifth: Double, _ beats: Double) {
        sc.at(b) { k, t in k.tuba(root, t, k.B(b + 0.9) - t) }
        if beats > 2 { sc.at(b + 2) { k, t in k.tuba(fifth, t, k.B(b + 2.9) - t) } }
    }

    func comp(_ sc: Score, _ b: Double, _ chord: [Double], _ kind: Kind, _ beats: Double) {
        // trombones on the "pah", horns hold the harmony underneath
        let bonesG = kind == .a ? 0.045 : 0.032
        var x = 1.0
        while x < beats {
            let bx = b + x
            sc.at(bx) { k, t in k.bones(chord, t, k.B(bx + 0.45) - t, bonesG) }
            x += 2
        }
        let hornsG = kind == .a ? 0.012 : 0.02
        let up = Array(chord.map { $0 + 12 }.prefix(3))
        sc.at(b) { k, t in k.horns(up, t, k.B(b + beats) - t - 0.03, hornsG) }
    }

    func lead(_ k: Kit, _ t: Double, _ n: Double, _ d: Double, _ i: Int, _ chord: [Double]) {
        k.brass(n, t, d * 0.9)
        k.brass(below(n, chord), t, d * 0.9, 0.045) // second trumpets play the harmony
        k.glock(n + 12, t, 0.8, 0.03)
        if i >= 2 { k.flute(n + 12, t, d * 0.88, 0.035) } // piccolo joins for the second half
    }

    func pad(_ k: Kit, _ notes: [Double], _ t: Double, _ d: Double, _ gn: Double) { k.horns(notes, t, d, gn * 1.6) }

    func finish(_ k: Kit, _ t: Double, _ e: Ending) {
        let top = e.top
        func hit(_ tt: Double, _ d: Double, _ gn: Double) {
            for n in top { k.brass(n, tt, d, gn) }
            k.bones(top.prefix(3).map { $0 - 12 }, tt, d, gn * 0.6)
            k.tuba(e.root, tt, d, 0.22)
            k.bassDrum(tt, 0.55)
            k.timp(tt, e.root + 12, 0.28)
        }
        // ta-daaa … bum-BUM!
        hit(t, 1.25, 0.065)
        k.horns(top, t, 1.3, 0.02)
        k.crash(t, 0.16)
        k.clash(t, 0.08)
        k.harp(top.map { $0 + 12 } + top.dropFirst().map { $0 + 24 }, t + 0.05, 0.045, 0.045)
        let t2 = t + 1.3 + k.spb * 1.5, t3 = t + 1.3 + k.spb * 2
        k.roll(t + 1.3, t2, 0.03, 0.14)
        k.flam(t2, 0.2)
        hit(t2, 0.18, 0.06)
        hit(t3, 1.4, 0.075)
        k.crash(t3, 0.16)
        k.clash(t3, 0.09)
        k.glock(top[3] + 24, t3, 1.4, 0.05)
    }
}

/// Jungle jam: calypso.
private struct JungleSong: BandSong {
    let bpm = 124.0
    let introBeats = 3.0
    let pool = ["monkey", "trumpet", "roar", "tweet", "ribbit", "hoot", "buzz", "chitter"]
    let singers = ["hoot", "trumpet", "meow", "cheep", "hoot", "trumpet", "meow"]
    let callBars = [
        BarA(chord: Fj, root: 41, fifth: 48, mel: [(0, 72, 0.75), (0.75, 77, 0.75), (1.5, 81, 0.5)]),
        BarA(chord: Bb, root: 46, fifth: 41, mel: [(0, 74, 0.75), (0.75, 77, 0.75), (1.5, 82, 0.5)]),
        BarA(chord: Cj, root: 48, fifth: 43, mel: [(0, 76, 0.5), (0.5, 79, 0.5), (1, 84, 0.5), (1.5, 82, 0.5)]),
        BarA(chord: Fj, root: 41, fifth: 48, mel: [(0, 81, 0.75), (0.75, 79, 0.75), (1.5, 77, 0.5)]),
    ]
    let choirBars = [
        BarB(chords: [(0, Dm, 38), (2, Bb, 46)], notes: [(0, 69, 1), (1, 74, 1), (2, 74, 1), (3, 77, 1)]),
        BarB(chords: [(0, Cj, 48), (2, Fj, 41)], notes: [(0, 79, 1), (1, 76, 1), (2, 77, 2)]),
    ]
    let end = Ending(chord: Fj, root: 41, top: [65, 69, 72, 77], fan: [(0, 72, 1.0 / 3), (1.0 / 3, 77, 1.0 / 3), (2.0 / 3, 81, 1.0 / 3), (1, 84, 1)])

    func intro(_ sc: Score) {
        sc.at(0) { k, t in Band.playCall(k, "monkey", t, .aL) }
        for (b, hi) in [(1.5, true), (2.0, false), (2.25, true), (2.5, false), (2.75, false)] {
            let gn = 0.1 + b * 0.025
            sc.at(b) { k, t in k.bongo(t, hi, gn) }
        }
        for x in 0..<6 {
            let gn = 0.02 + Double(x) * 0.006
            sc.at(1.5 + Double(x) / 4) { k, t in k.shaker(t, gn) }
        }
    }

    func groove(_ sc: Score, _ b: Double, _ kind: Kind, _ i: Int) {
        if i == 0 && kind == .a { sc.at(b) { k, t in k.crash(t, 0.08) } }
        for x in [0.0, 1.5, 2.0, 3.5] { sc.at(b + x) { k, t in k.kick(t, 0.4) } }
        let bongos: [(Double, Bool)] = [(0, false), (0.5, true), (1, true), (1.5, false), (2, false), (2.5, true), (3, true), (3.5, true), (3.75, true)]
        for (x, hi) in bongos {
            let gn = x.truncatingRemainder(dividingBy: 1) != 0 ? 0.09 : 0.13
            sc.at(b + x) { k, t in k.bongo(t, hi, gn) }
        }
        for x in 0..<16 {
            let gn = x % 2 == 1 ? 0.025 : 0.04
            sc.at(b + Double(x) / 4) { k, t in k.shaker(t, gn) }
        }
        for x in [0.0, 0.75, 1.5, 2.5, 3.0] { sc.at(b + x) { k, t in k.claves(t, 0.06) } }
    }

    func bass(_ sc: Score, _ b: Double, _ root: Double, _ fifth: Double, _ beats: Double) {
        sc.at(b) { k, t in k.bass(root, t, 0.5) }
        sc.at(b + 1.5) { k, t in k.bass(root, t, 0.3, 0.18) }
        if beats > 2 {
            sc.at(b + 2) { k, t in k.bass(fifth, t, 0.5) }
            sc.at(b + 3.5) { k, t in k.bass(fifth + 2, t, 0.3, 0.18) }
        }
    }

    func comp(_ sc: Score, _ b: Double, _ chord: [Double], _ kind: Kind, _ beats: Double) {
        if kind == .a {
            let up = chord.map { $0 + 12 }
            var x = 0.5
            while x < beats {
                sc.at(b + x) { k, t in k.uke(up, t, 0.04) }
                x += 1
            }
        } else {
            for x in 0..<Int(beats * 2) {
                let n = chord[x % 3] + (x % 6 < 3 ? 0 : 12)
                sc.at(b + Double(x) / 2) { k, t in k.marimba(n, t, 0.06) }
            }
        }
    }

    func lead(_ k: Kit, _ t: Double, _ n: Double, _ d: Double, _ i: Int, _ chord: [Double]) {
        k.steel(n, t, max(0.6, d), 0.1)
        if d > k.spb * 0.7 { k.steel(n, t + k.spb / 2, 0.5, 0.05) } // steel pans repeat long notes
        k.marimba(n - 12, t, 0.06, .lead)
        if i >= 2 { k.panflute(n + 12, t, d * 0.9, 0.035) }
    }

    func finish(_ k: Kit, _ t: Double, _ e: Ending) {
        for n in e.top { k.steel(n, t, 1.6, 0.07) }
        for n in e.top { k.steel(n + 12, t + 0.18, 1.2, 0.04) }
        k.uke(e.top.map { $0 + 12 }, t, 0.06)
        k.bass(e.root, t, 1.4, 0.26)
        k.kick(t, 0.5)
        k.crash(t, 0.14)
        k.bongo(t, true, 0.16)
        k.bongo(t + 0.09, false, 0.16)
        k.harp([77, 81, 84, 89, 93, 96], t + 0.05, 0.05, 0.045)
        Band.playCall(k, "tweet", t + 0.4, .aR)
    }
}

/// Farmyard hoedown: a two-step, opened by the rooster.
private struct FarmSong: BandSong {
    let bpm = 144.0
    let introBeats = 4.0
    let pool = ["moo", "baa", "oink", "quack", "woof", "neigh", "goat", "cheep", "meow"]
    let singers = ["baa", "quack", "oink", "meow", "woof", "baa", "kazoo"]
    let callBars = [
        BarA(chord: Gf, root: 43, fifth: 38, mel: [(0, 67, 0.5), (0.5, 71, 0.5), (1, 74, 1)]),
        BarA(chord: Cf, root: 48, fifth: 43, mel: [(0, 72, 0.5), (0.5, 76, 0.5), (1, 79, 1)]),
        BarA(chord: Df, root: 50, fifth: 45, mel: [(0, 74, 0.5), (0.5, 78, 0.5), (1, 81, 0.5), (1.5, 78, 0.5)]),
        BarA(chord: Gf, root: 43, fifth: 38, mel: [(0, 79, 0.5), (0.5, 74, 0.5), (1, 71, 1)]),
    ]
    let choirBars = [
        BarB(chords: [(0, Em, 40), (2, Cf, 48)], notes: [(0, 71, 1), (1, 67, 1), (2, 72, 1), (3, 76, 1)]),
        BarB(chords: [(0, Df, 50), (2, Gf, 43)], notes: [(0, 74, 1), (1, 78, 1), (2, 79, 2)]),
    ]
    let end = Ending(chord: Gf, root: 43, top: [67, 71, 74, 79], fan: [(0, 67, 1.0 / 3), (1.0 / 3, 71, 1.0 / 3), (2.0 / 3, 74, 1.0 / 3), (1, 79, 1)])

    func intro(_ sc: Score) {
        sc.at(0) { k, t in Band.playCall(k, "rooster", t, .aL) }
        sc.at(3) { k, t in k.washboard(t, 0.08) }
        sc.at(3.5) { k, t in k.washboard(t, 0.1) }
        sc.at(3) { k, t in k.fiddle(62, t, k.B(3.45) - t, 0.05) }
        sc.at(3.5) { k, t in k.fiddle(64, t, k.B(3.95) - t, 0.05) }
    }

    func groove(_ sc: Score, _ b: Double, _ kind: Kind, _ i: Int) {
        if i == 0 && kind == .a { sc.at(b) { k, t in k.crash(t, 0.08) } }
        for x in [0.0, 2.0] { sc.at(b + x) { k, t in k.kick(t, 0.42) } }
        for x in [1.0, 3.0] { sc.at(b + x) { k, t in k.clap(t, 0.12) } }
        for x in 0..<8 {
            let gn = x % 2 == 1 ? 0.035 : 0.06
            sc.at(b + Double(x) / 2) { k, t in k.washboard(t, gn) }
        }
        sc.at(b) { k, t in k.cowbell(t, 0.05) }
        if kind == .b { sc.at(b + 2) { k, t in k.cowbell(t, 0.04) } }
    }

    func bass(_ sc: Score, _ b: Double, _ root: Double, _ fifth: Double, _ beats: Double) {
        sc.at(b) { k, t in k.jug(root, t, k.B(b + 0.85) - t) }
        if beats > 2 { sc.at(b + 2) { k, t in k.jug(fifth, t, k.B(b + 2.85) - t) } }
    }

    func comp(_ sc: Score, _ b: Double, _ chord: [Double], _ kind: Kind, _ beats: Double) {
        let up = chord.map { $0 + 12 }
        var x = 1.0
        while x < beats {
            sc.at(b + x) { k, t in k.strumBanjo(up, t, 0.055) }
            x += 2
        }
        if kind == .a {
            var j = 0
            while Double(j) < beats {
                let n = chord[j % 3] + 24
                sc.at(b + Double(j) + 0.5) { k, t in k.banjo(n, t, 0.03) }
                j += 1
            }
        } else {
            sc.at(b) { k, t in k.harmonica(up, t, k.B(b + beats) - t - 0.05, 0.022) }
        }
    }

    func lead(_ k: Kit, _ t: Double, _ n: Double, _ d: Double, _ i: Int, _ chord: [Double]) {
        k.fiddle(n, t, d * 0.92)
        if i >= 2 { k.harmonica([n], t, d * 0.9, 0.04) } else { k.banjo(n + 12, t, 0.04, .sparkle) }
    }

    func finish(_ k: Kit, _ t: Double, _ e: Ending) {
        k.fiddle(e.top[3], t, 1.6, 0.07)
        k.fiddle(e.top[1] + 12, t, 1.6, 0.04)
        k.harmonica(e.top, t, 1.5, 0.03)
        k.strumBanjo(e.top.map { $0 + 12 }, t, 0.07)
        k.jug(e.root, t, 1.0, 0.24)
        k.kick(t, 0.5)
        k.crash(t, 0.14)
        k.cowbell(t, 0.07)
        k.cowbell(t + 0.28, 0.06)
        k.slideWhistle(t + 0.05, 74, 98, 0.45, 0.06)
    }
}

// MARK: - calls, and putting a song together

enum Band {
    static let songs: [String: BandSong] = ["band": MarchSong(), "jungle": JungleSong(), "farm": FarmSong()]

    /// What each animal "says" when it answers or takes its solo (the synthesised
    /// version; the recording replaces it once loaded). len = how long it lasts.
    struct Call {
        let len: Double
        let play: (Kit, Double, Ch) -> Void
    }

    static let calls: [String: Call] = [
        "moo": Call(len: 1.15) { k, t, o in k.moo(t, 125, 1.15, o) },
        "calf": Call(len: 0.8) { k, t, o in k.moo(t, 175, 0.8, o) },
        "quack": Call(len: 0.42) { k, t, o in k.quack(t, 300, 0.17, o); k.quack(t + 0.24, 290, 0.18, o) },
        "peep": Call(len: 0.4) { k, t, o in k.quack(t, 420, 0.13, o); k.quack(t + 0.2, 440, 0.14, o) },
        "baa": Call(len: 0.8) { k, t, o in k.baa(t, 330, 0.8, o) },
        // two slightly apart voices = that wobbly goat "meh-eh-eh"
        "goat": Call(len: 0.6) { k, t, o in k.baa(t, 440, 0.55, o, 0.55); k.baa(t, 446, 0.55, o, 0.55) },
        "woof": Call(len: 0.4) { k, t, o in k.woof(t, 280, 0.15, o); k.woof(t + 0.23, 270, 0.16, o) },
        "yip": Call(len: 0.36) { k, t, o in
            k.woof(t, 560, 0.1, o, 0.7); k.woof(t + 0.15, 600, 0.1, o, 0.7); k.woof(t + 0.28, 640, 0.09, o, 0.7)
        },
        "meow": Call(len: 0.72) { k, t, o in k.meow(t, 620, 0.72, o) },
        "mew": Call(len: 0.45) { k, t, o in k.meow(t, 760, 0.45, o) },
        "oink": Call(len: 0.45) { k, t, o in k.oink(t, 190, 0.18, o); k.oink(t + 0.25, 205, 0.18, o) },
        "grunt": Call(len: 0.5) { k, t, o in k.oink(t, 120, 0.22, o); k.ork(t + 0.26, 170, 0.22, o) },
        "hoot": Call(len: 0.95) { k, t, o in k.hoot(t, 380, 0.38, o); k.hoot(t + 0.5, 345, 0.45, o) },
        "cheep": Call(len: 0.4) { k, t, o in
            for i in 0..<3 { k.cheep(t + Double(i) * 0.13, 3100 - Double(i) * 120, 0.08, o) }
        },
        "tweet": Call(len: 0.75) { k, t, o in
            for i in 0..<5 { k.cheep(t + Double(i) * 0.07, 3600 + Double(i % 2) * 400, 0.05, o) }
            k.squeak(t + 0.42, 2600, 0.3, o)
        },
        "trumpet": Call(len: 0.9) { k, t, o in k.trumpet(t, 520, 0.9, o) },
        "roar": Call(len: 0.65) { k, t, o in k.roar(t, 170, 0.65, o) },
        "rawr": Call(len: 0.6) { k, t, o in k.roar(t, 140, 0.6, o) },
        "dino": Call(len: 0.95) { k, t, o in k.roar(t, 115, 0.95, o) },
        "dragon": Call(len: 1.2) { k, t, o in
            k.roar(t, 125, 0.8, o)
            for (i, n) in [84.0, 88, 91, 96].enumerated() { k.glock(n, t + 0.75 + Double(i) * 0.07, 0.6, 0.05) }
        },
        "neigh": Call(len: 1.0) { k, t, o in k.neigh(t, 700, 1.0, o) },
        "unicorn": Call(len: 1.25) { k, t, o in
            k.neigh(t, 820, 0.85, o)
            for (i, n) in [79.0, 84, 88, 91, 96].enumerated() { k.glock(n, t + 0.8 + Double(i) * 0.07, 0.7, 0.05) }
        },
        "squeak": Call(len: 0.32) { k, t, o in k.squeak(t, 3000, 0.12, o); k.squeak(t + 0.17, 3200, 0.12, o) },
        "eep": Call(len: 0.45) { k, t, o in
            for i in 0..<3 { k.squeak(t + Double(i) * 0.15, 1900 + Double(i) * 150, 0.11, o) }
        },
        "chitter": Call(len: 0.5) { k, t, o in
            for i in 0..<7 { k.squeak(t + Double(i) * 0.065, 2500 + Double((i * 7) % 5) * 160, 0.045, o) }
        },
        "ork": Call(len: 0.7) { k, t, o in
            for i in 0..<3 { k.ork(t + Double(i) * 0.25, 300, 0.19, o) }
        },
        "ribbit": Call(len: 0.4) { k, t, o in k.croak(t, 150, 0.13, o); k.croak(t + 0.18, 170, 0.18, o) },
        "monkey": Call(len: 0.85) { k, t, o in
            k.ooh(t, 420, 0.14, o); k.ooh(t + 0.17, 460, 0.14, o)
            k.ah(t + 0.36, 600, 0.15, o); k.ah(t + 0.54, 650, 0.15, o)
            k.squeak(t + 0.72, 1400, 0.12, o)
        },
        "rooster": Call(len: 1.35) { k, t, o in
            k.crow(t, 600, 0.12, o); k.crow(t + 0.15, 730, 0.1, o); k.crow(t + 0.29, 850, 0.15, o)
            k.crow(t + 0.48, 960, 0.85, o)
        },
        "buzz": Call(len: 0.8) { k, t, o in k.buzz(t, 230, 0.8, o) },
        "bloop": Call(len: 0.4) { k, t, o in
            for (i, g) in [0.0, 0.14, 0.26].enumerated() { k.bloop(t + g, 900 * (1 + Double(i) * 0.22), 0.1, o) }
        },
        "boing": Call(len: 0.5) { k, t, o in k.bloop(t, 700, 0.18, o); k.bloop(t + 0.24, 900, 0.2, o) },
        "sniff": Call(len: 0.6) { k, t, o in
            for g in [0.0, 0.11, 0.22, 0.33] { k.sniff(t + g, 2600, 0.07, o) }
            k.squeak(t + 0.45, 2400, 0.12, o)
        },
        "wheek": Call(len: 0.55) { k, t, o in k.squeak(t, 1500, 0.2, o); k.squeak(t + 0.28, 1700, 0.22, o) },
        "sloth": Call(len: 0.9) { k, t, o in k.squeak(t, 1800, 0.9, o, 0.8) },
        "honk": Call(len: 0.6) { k, t, o in
            for i in 0..<3 { k.quack(t + Double(i) * 0.18, 430 + Double(i) * 40, 0.16, o) }
        },
        "lamb": Call(len: 0.6) { k, t, o in k.baa(t, 420, 0.6, o, 0.8) },
    ]

    /// every call that has a recording (Resources/Sounds/call-<name>.mp3)
    static var callNames: [String] { Array(calls.keys) }

    /// which call each friend makes when it takes its solo
    static let friendCalls: [String: String] = [
        "chick": "cheep", "duckling": "peep", "penguin": "honk", "owl": "hoot", "hamster": "squeak", "bunny": "boing", "fox": "yip",
        "kitten": "meow", "bearcub": "rawr", "panda": "lamb", "frog": "ribbit", "turtle": "bloop", "dino": "dino", "dragon": "dragon",
        "mouse": "squeak", "piglet": "oink", "koala": "grunt", "raccoon": "chitter", "tiger": "roar", "lion": "roar", "calf": "calf",
        "lamb": "lamb", "fawn": "mew", "hedgehog": "sniff", "otter": "eep", "seal": "ork", "axolotl": "bloop", "bat": "squeak",
        "mole": "sniff", "monkey": "monkey", "elephant": "trumpet", "squirrel": "chitter", "puppy": "woof", "unicorn": "unicorn",
        "capybara": "wheek", "redpanda": "squeak", "sloth": "sloth", "ladybug": "buzz", "snail": "bloop", "goat": "goat",
    ]

    /// a little magic on top of a recorded call
    private static let after: [String: (Kit, Double) -> Void] = [
        "dragon": { k, t in for (i, n) in [84.0, 88, 91, 96].enumerated() { k.glock(n, t + Double(i) * 0.07, 0.6, 0.05) } },
    ]

    /// An animal's call: the recording when it has loaded, otherwise the synthesised one.
    @discardableResult
    static func playCall(_ k: Kit, _ name: String, _ t: Double, _ c: Ch, _ gain: Double = 1) -> Double {
        let d = k.s.playSample(name, at: t, bus: k.bus, gain: gain * k.g(c))
        if d > 0 {
            after[name]?(k, t + d * 0.8)
            return d
        }
        guard let call = calls[name] else { return 0 }
        call.play(k, t, c)
        return call.len
    }

    static func lenOf(_ name: String, _ s: Synth) -> Double { s.sampleLength(name) ?? calls[name]?.len ?? 0.8 }

    /// tapping the hatched friend: its call on its own
    static func friendCall(_ friendId: String, on s: Synth) -> Double {
        guard let name = friendCalls[friendId] else { return 0 }
        let k = Kit(s: s, bus: .sfx, mix: false, t0: s.t, spb: 0.5)
        return playCall(k, name, s.t + 0.02, .solo)
    }

    /// singers: each animal's comfortable range (Hz); notes are folded into it by octaves
    private static let range: [String: (Double, Double)] = [
        "meow": (440, 820), "baa": (250, 460), "quack": (260, 440), "woof": (220, 400), "oink": (150, 270),
        "hoot": (300, 540), "trumpet": (380, 720), "cheep": (1800, 3600),
    ]

    private static func sing(_ k: Kit, _ who: String, _ t: Double, _ n: Double, _ d: Double, _ c: Ch) {
        if who == "kazoo" { k.kazoo(n, t, d * 0.92, 0.06, c); return }
        guard let r = range[who] else { return }
        var f = midi(n)
        while f < r.0 { f *= 2 }
        while f > r.1 { f /= 2 }
        let len: Double
        if who == "cheep" { len = min(d, 0.12) }
        else if who == "woof" || who == "oink" || who == "quack" { len = min(d * 0.8, 0.3) }
        else { len = d * 0.92 }
        k.syllable(who, t, f, len, c)
    }

    /// Arrange a song and hand it to the synth; returns its length in seconds.
    /// friend = the animal that hatched (any one if nil, e.g. a preview or a photo).
    static func perform(_ id: String, friend: String?, on s: Synth) -> Double {
        guard let song = songs[id] else { return 0 }
        let soloCall = friend.flatMap { friendCalls[$0] } ?? GC.pick(Array(friendCalls.values))
        let spb = 60 / song.bpm
        let t0 = s.t + 0.08
        let kit = Kit(s: s, bus: .celeb, mix: true, t0: t0, spb: spb)
        let sc = Score()
        var others = song.pool.filter { $0 != soloCall }.shuffled()
        if others.isEmpty { others = song.pool }
        let pans: [Ch] = [.aL, .aR, .aL, .aR]

        song.intro(sc)
        var b = song.introBeats

        // the band plays a line, an animal answers
        for (i, bar) in song.callBars.enumerated() {
            song.groove(sc, b, .a, i)
            song.bass(sc, b, bar.root, bar.fifth, 4)
            song.comp(sc, b, bar.chord, .a, 4)
            for (x, n, d) in bar.mel {
                let dd = d * spb
                sc.at(b + x) { k, t in song.lead(k, t, n, dd, i, bar.chord) }
            }
            let who = others[i % others.count]
            let pan = pans[i % pans.count]
            sc.at(b + 2) { k, t in Band.playCall(k, who, t, pan) }
            b += 4
        }

        // the animals sing the tune
        var singer = Int.random(in: 0..<song.singers.count)
        for (i, bar) in song.choirBars.enumerated() {
            song.groove(sc, b, .b, i)
            for (j, change) in bar.chords.enumerated() {
                let (x, chord, root) = change
                let beats = j + 1 < bar.chords.count ? bar.chords[j + 1].0 - x : 4 - x
                song.bass(sc, b + x, root, root + 7, beats)
                song.comp(sc, b + x, chord, .b, beats)
            }
            for (x, n, d) in bar.notes {
                let who = song.singers[singer % song.singers.count]
                singer += 1
                let out: Ch = singer % 2 == 1 ? .aL : .aR
                let dd = d * spb
                sc.at(b + x) { k, t in Band.sing(k, who, t, n, dd, out) }
            }
            b += 4
        }

        // finale: fanfare + everyone cheers, then the friend's solo, then the ending
        let e = song.end
        sc.at(b) { k, t in k.crash(t, 0.12); k.kick(t, 0.5) }
        for (x, n, d) in e.fan {
            let dd = d * spb
            sc.at(b + x) { k, t in song.lead(k, t, n, dd, 3, e.chord) }
        }
        song.bass(sc, b, e.root, e.root + 7, 2)
        let cheer = Array(others.dropFirst(4).prefix(3)) + Array(others.prefix(1))
        for (i, who) in cheer.enumerated() {
            let pan: Ch = i % 2 == 1 ? .aL : .aR
            sc.at(b + 1 + Double(i) * 0.25) { k, t in Band.playCall(k, who, t, pan, 0.8) }
        }
        let soloAt = b + 3
        let callLen = lenOf(soloCall, s)
        let rollNote = e.root + 12
        sc.at(soloAt - 0.5) { k, t in k.timpRoll(t, t + 0.5, rollNote, 0.02, 0.12) }
        sc.at(soloAt) { k, t in
            Band.playCall(k, soloCall, t, .solo)
            song.pad(k, e.top, t, callLen + k.spb, 0.012)
        }
        let endBeat = ((soloAt + (callLen + 0.15) / spb) * 2).rounded(.up) / 2
        sc.at(endBeat) { k, t in song.finish(k, t, e) }

        let events = sc.events
            .map { (t: t0 + $0.beat * spb, fn: $0.fn) }
            .sorted { $0.t < $1.t }
        let len = endBeat * spb + song.tail
        s.startCelebration(Celebration(events: events, kit: kit, end: t0 + len, friendCall: soloCall))
        return len
    }
}

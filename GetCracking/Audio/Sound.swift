import AVFoundation
import UIKit

/// Everything is synthesised live — no audio files, and all melodies are
/// original. Three jobs:
///   1. countdown music — an ambient "something is happening" cue that keeps
///      working when the child looks away from the screen
///   2. small sound effects — crack, pop, boop, knock
///   3. the end tune — a cheerful celebration instead of an alarm
///
/// A single AVAudioSourceNode renders a tiny polyphonic synth (sine /
/// triangle partials with exponential envelopes, filtered noise bursts), a
/// soft echo and a gentle compressor. The music sequencer runs inside the
/// render callback, so notes land exactly on the beat.
final class Sound {
    static let shared = Sound()

    struct Choice: Identifiable { let id: String; let name: String; let icon: String }

    static let music: [Choice] = [
        Choice(id: "musicbox", name: "Music box", icon: "🎶"),
        Choice(id: "marimba", name: "Marimba walk", icon: "🎵"),
        Choice(id: "forest", name: "Forest birds", icon: "🐦"),
        Choice(id: "rain", name: "Soft rain", icon: "🌧️"),
        Choice(id: "ticktock", name: "Gentle tick-tock", icon: "🕰️"),
        Choice(id: "off", name: "Quiet", icon: "🔇"),
    ]
    static let endSounds: [Choice] = [
        Choice(id: "tada", name: "Ta-da parade", icon: "🎉"),
        Choice(id: "chimes", name: "Happy chimes", icon: "🔔"),
        Choice(id: "birds", name: "Birdsong hello", icon: "🐤"),
        Choice(id: "bubbles", name: "Bubble pops", icon: "🫧"),
    ]

    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private let synth: Synth
    private let lock = NSLock()
    private var configured = false
    private let speech = AVSpeechSynthesizer()
    private var previewWork: DispatchWorkItem?
    private var pausedMusic: String?
    private(set) var volume: Double = 0.7

    private init() {
        let sr = AVAudioSession.sharedInstance().sampleRate
        synth = Synth(sampleRate: sr > 0 ? sr : 48_000)
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let self, let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self.ensure()
        }
        nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            self?.configured = false
            self?.ensure()
        }
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.ensure()
        }
    }

    /// Start (or restart) the audio session and engine. Safe to call often.
    @discardableResult
    func ensure() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            // .playback: the ring/silent switch must not mute the hatch tune
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch { /* sound is optional */ }

        if !configured {
            engine.stop()
            if let s = source { engine.detach(s) }
            let sr = session.sampleRate > 0 ? session.sampleRate : 48_000
            lock.lock(); synth.setSampleRate(sr); lock.unlock()
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2) else { return false }
            let synth = self.synth, lock = self.lock
            let node = AVAudioSourceNode(format: format) { _, _, frameCount, abl -> OSStatus in
                let buffers = UnsafeMutableAudioBufferListPointer(abl)
                let n = Int(frameCount)
                guard let first = buffers.first, let left = first.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
                lock.lock()
                synth.render(into: left, frames: n)
                lock.unlock()
                for b in buffers.dropFirst() {
                    if let d = b.mData?.assumingMemoryBound(to: Float.self) { d.update(from: left, count: n) }
                }
                return noErr
            }
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            source = node
            configured = true
        }
        if !engine.isRunning {
            engine.prepare()
            do { try engine.start() } catch { return false }
        }
        return true
    }

    /// let the phone's audio session go when no timer is running
    func releaseMedia() {
        // give the last notes time to ring out, then hand the audio back
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            self.lock.lock(); let busy = self.synth.isBusy; self.lock.unlock()
            guard !busy else { return }
            self.engine.pause()
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    private func with(_ f: (Synth) -> Void) {
        guard ensure() else { return }
        lock.lock()
        f(synth)
        lock.unlock()
    }

    func setVolume(_ v: Double) {
        volume = v
        lock.lock(); synth.masterTarget = v; lock.unlock()
    }

    // MARK: music

    func startMusic(_ id: String) {
        with { $0.startMusic(id) }
    }

    func stopMusic(fade: Double = 0.6) {
        lock.lock(); synth.stopMusic(fade: fade); lock.unlock()
    }

    func pauseMusic() {
        lock.lock(); pausedMusic = synth.music; synth.stopMusic(fade: 0.3); lock.unlock()
    }

    func resumeMusic() {
        if let m = pausedMusic { startMusic(m) }
    }

    func setTension(_ v: Double) {
        lock.lock(); synth.tension = v; lock.unlock()
    }

    func preview(music id: String) {
        previewWork?.cancel()
        if id == "off" { stopMusic(); return }
        startMusic(id)
        let w = DispatchWorkItem { [weak self] in self?.stopMusic() }
        previewWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: w)
    }

    @discardableResult
    func preview(end id: String) -> Double {
        previewWork?.cancel()
        stopMusic(fade: 0.2)
        return endTune(id)
    }

    // MARK: sound effects

    func crack() { with { $0.crack() } }
    func boop() { with { $0.boop() } }
    func knock() { with { $0.knock() } }
    func ready() { with { $0.ready() } }
    func pop() { with { $0.pop() } }
    func cheer() { with { $0.cheer() } }
    func clink(_ p: Double = 0.5) { with { $0.clink(p) } }
    func thud(_ p: Double = 0.5) { with { $0.thud(p) } }
    func whoosh() { with { $0.whoosh() } }

    /// the celebration tune; returns its length in seconds
    @discardableResult
    func endTune(_ id: String) -> Double {
        var len = 0.0
        with { len = $0.endTune(id) }
        return len
    }

    /// "It's a Fox!" in the device voice.
    func say(_ text: String) {
        speech.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        u.pitchMultiplier = 1.25
        u.volume = Float(min(1, volume + 0.2))
        speech.speak(u)
    }
}

// MARK: - the synth (render thread; always used under Sound.lock)

private func midi(_ n: Double) -> Double { 440 * pow(2, (n - 69) / 12) }

/// Original melodies (MIDI note numbers, nil = rest).
private struct Song {
    let bpm: Double
    let steps: Double
    let mel: [Double?]
    let bass: [Double?]
}

private let MUSICBOX = Song(bpm: 76, steps: 2,
    mel: [76, 79, 84, 79, 77, 81, 84, 81, 76, 79, 83, 79, 74, 77, 79, 77,
          72, 76, 79, 76, 74, 77, 81, 77, 79, 76, 74, 72, 71, 74, 79, nil],
    bass: [48, nil, nil, nil, 53, nil, nil, nil, 52, nil, nil, nil, 50, nil, 55, nil,
           48, nil, nil, nil, 50, nil, nil, nil, 55, nil, nil, nil, 43, nil, 55, nil])
private let MARIMBA = Song(bpm: 112, steps: 2,
    mel: [67, 71, 74, 71, 69, 74, 76, 74, 67, 71, 74, 79, 76, 74, 71, 69,
          64, 67, 71, 67, 66, 69, 74, 69, 67, 71, 76, 74, 71, nil, 67, nil],
    bass: [43, nil, 50, nil, 45, nil, 50, nil, 43, nil, 50, nil, 47, nil, 45, nil,
           40, nil, 47, nil, 42, nil, 50, nil, 43, nil, 47, nil, 43, nil, nil, nil])

private enum Bus { case music, sfx }
private enum Wave { case sine, triangle }
private enum FilterType { case lowpass, highpass, bandpass }

/// RBJ biquad.
private struct Biquad {
    var b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    mutating func set(_ type: FilterType, freq: Double, q: Double, sr: Double) {
        let f = min(max(freq, 10), sr * 0.45)
        let w = 2 * Double.pi * f / sr
        let cw = cos(w), alpha = sin(w) / (2 * max(q, 0.0001))
        let a0 = 1 + alpha
        switch type {
        case .lowpass:
            b0 = (1 - cw) / 2; b1 = 1 - cw; b2 = (1 - cw) / 2
        case .highpass:
            b0 = (1 + cw) / 2; b1 = -(1 + cw); b2 = (1 + cw) / 2
        case .bandpass:
            b0 = alpha; b1 = 0; b2 = -alpha
        }
        a1 = -2 * cw
        a2 = 1 - alpha
        b0 /= a0; b1 /= a0; b2 /= a0; a1 /= a0; a2 /= a0
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x; y2 = y1; y1 = y
        return y
    }
}

/// Exponential attack/decay, like Web Audio's exponentialRampToValueAtTime
/// from 0.0001 → peak → 0.0001.
private struct Env {
    var value = 0.0001
    var attackMul: Double
    var decayMul: Double
    var attackLeft: Int
    var decayLeft: Int

    init(peak: Double, attack: Double, dur: Double, sr: Double) {
        let p = max(peak, 0.00011)
        let aN = max(1, Int(attack * sr))
        let dN = max(1, Int(max(dur - attack, 0.001) * sr))
        attackMul = pow(p / 0.0001, 1 / Double(aN))
        decayMul = pow(0.0001 / p, 1 / Double(dN))
        attackLeft = aN
        decayLeft = dN
    }

    var done: Bool { attackLeft <= 0 && decayLeft <= 0 }

    mutating func next() -> Double {
        let v = value
        if attackLeft > 0 { value *= attackMul; attackLeft -= 1 }
        else if decayLeft > 0 { value *= decayMul; decayLeft -= 1 }
        return v
    }
}

private struct ToneVoice {
    var start: Int64
    var env: Env
    var partials: [(ratio: Double, amp: Double)]
    var phases: [Double]
    var freq: Double
    var freqMul: Double      // per-sample multiplier while sliding
    var slideLeft: Int
    var wave: Wave
    var bus: Bus
}

private struct NoiseVoice {
    var start: Int64
    var env: Env
    var filter = Biquad()
    var type: FilterType
    var freq: Double
    var q: Double
    var freqMul = 1.0
    var sweepLeft = 0
    var pos: Int
    var bus: Bus
}

private final class Synth {
    var sr: Double
    private var now: Int64 = 0
    private var tones: [ToneVoice] = []
    private var noises: [NoiseVoice] = []
    private var noise: [Float] = []

    // buses + echo
    private var musicGain = 0.0001, musicTarget = 0.0001, musicTau = 0.5
    var masterTarget = 0.7
    private var master = 0.7
    private var delay: [Double] = []
    private var delayPos = 0
    private var echoLP = Biquad()
    private var lpOut = 0.0
    private var compEnv = 0.0

    // music sequencer
    private(set) var music = "off"
    private var playing = false
    var tension = 0.0
    private var step = 0
    private var nextT = 0.0
    private var ambientAt = 0.0

    // ambient bed (rain / forest)
    private var bed: (kind: String, hp: Biquad, f: Biquad, gain: Double, target: Double, tau: Double, pos: Int, lfo: Double)?

    init(sampleRate: Double) {
        sr = sampleRate
        setSampleRate(sampleRate)
    }

    func setSampleRate(_ s: Double) {
        sr = s
        let len = Int(s * 2)
        noise = (0..<len).map { _ in Float.random(in: -1...1) }
        delay = [Double](repeating: 0, count: Int(s * 0.32))
        delayPos = 0
        echoLP.set(.lowpass, freq: 2600, q: 0.707, sr: s)
        tones.reserveCapacity(128)
        noises.reserveCapacity(64)
    }

    var t: Double { Double(now) / sr }
    var isBusy: Bool { playing || !tones.isEmpty || !noises.isEmpty || bed != nil }

    private func sample(_ time: Double) -> Int64 { Int64((time * sr).rounded()) }

    // MARK: voices

    /// one plucked / struck note
    func tone(_ freq: Double, _ at: Double, _ dur: Double, gain: Double = 0.2, attack: Double = 0.005,
              partials: [(Double, Double)] = [(1, 1)], wave: Wave = .sine, slide: Double? = nil, bus: Bus = .music) {
        guard tones.count < 160 else { return }
        var mul = 1.0, left = 0
        if let s = slide {
            left = max(1, Int(dur * 0.8 * sr))
            mul = pow(s, 1 / Double(left))
        }
        tones.append(ToneVoice(start: sample(at), env: Env(peak: gain, attack: attack, dur: dur, sr: sr),
                               partials: partials.map { (ratio: $0.0, amp: $0.1) }, phases: [Double](repeating: 0, count: partials.count),
                               freq: freq, freqMul: mul, slideLeft: left, wave: wave, bus: bus))
    }

    func noiseBurst(_ at: Double, _ dur: Double, freq: Double = 2000, q: Double = 1, gain: Double = 0.2,
                    attack: Double = 0.003, type: FilterType = .bandpass, bus: Bus = .sfx) {
        guard noises.count < 80 else { return }
        var v = NoiseVoice(start: sample(at), env: Env(peak: gain, attack: attack, dur: dur, sr: sr),
                           type: type, freq: freq, q: q, pos: Int.random(in: 0..<max(1, noise.count)), bus: bus)
        v.filter.set(type, freq: freq, q: q, sr: sr)
        noises.append(v)
    }

    // MARK: music

    func startMusic(_ id: String) {
        stopMusic(fade: 0.6)
        music = id
        if id == "off" { return }
        musicGain = 0.0001
        musicTarget = 0.55
        musicTau = 0.5
        step = 0
        nextT = t + 0.1
        ambientAt = t + 0.5
        playing = true
        if id == "forest" || id == "rain" {
            var hp = Biquad(), f = Biquad()
            if id == "rain" {
                hp.set(.highpass, freq: 400, q: 0.707, sr: sr)
                f.set(.lowpass, freq: 1800, q: 0.707, sr: sr)
            } else {
                f.set(.bandpass, freq: 500, q: 0.6, sr: sr)
            }
            bed = (id, hp, f, 0.0001, id == "rain" ? 0.12 : 0.07, 1.0, 0, 0)
        }
    }

    func stopMusic(fade: Double) {
        playing = false
        if bed != nil {
            bed!.target = 0
            bed!.tau = max(0.01, fade / 3)
        }
    }

    private func schedule(until end: Double) {
        guard playing else { return }
        let id = music
        let song = id == "marimba" ? MARIMBA : MUSICBOX
        let stepDur = id == "ticktock" ? (tension > 0 ? 0.5 : 1) : 60 / song.bpm / song.steps
        // after a stall, skip the missed notes instead of firing them all at once
        if nextT < t - 0.02 {
            let missed = ceil((t - nextT) / stepDur)
            nextT += missed * stepDur
            step += Int(missed)
        }
        if ambientAt < t - 0.02 { ambientAt = t + 0.05 }

        switch id {
        case "musicbox", "marimba":
            while nextT < end {
                let i = step % song.mel.count
                let n = song.mel[i], b = song.bass[i]
                if id == "musicbox" {
                    if let n { tone(midi(n), nextT, 1.4, gain: 0.11, partials: [(1, 1), (2, 0.25), (3.01, 0.08)]) }
                    if let b { tone(midi(b), nextT, 2.2, gain: 0.08, wave: .triangle) }
                    if tension > 0, let n, i % 2 == 0 { tone(midi(n + 12), nextT + stepDur * 0.5, 0.6, gain: 0.05) }
                } else {
                    if let n { tone(midi(n), nextT, 0.45, gain: 0.14, partials: [(1, 1), (4, 0.12), (9.8, 0.03)]) }
                    if let b { tone(midi(b), nextT, 0.6, gain: 0.12, partials: [(1, 1), (3.9, 0.08)]) }
                    if tension > 0 && i % 4 == 2 { tone(midi(91), nextT, 0.25, gain: 0.04) }
                }
                nextT += stepDur
                step += 1
            }
        case "ticktock":
            while nextT < end {
                let hi = step % 2 == 0
                noiseBurst(nextT, 0.05, freq: hi ? 2400 : 1700, q: 8, gain: 0.12, bus: .music)
                tone(hi ? 1180 : 880, nextT, 0.07, gain: 0.05)
                if step % 8 == 0 { tone(midi(84), nextT, 1.6, gain: 0.03, partials: [(1, 1), (2.76, 0.2)]) }
                nextT += tension > 0 ? 0.5 : 1
                step += 1
            }
        case "forest":
            if ambientAt < end {
                let at = ambientAt
                let base = GC.rand(2200, 3600)
                let n = Int(GC.rand(2, 5))
                for k in 0..<n { tone(base * GC.rand(0.9, 1.15), at + Double(k) * 0.11, 0.09, gain: 0.05, slide: GC.rand(1.15, 1.4)) }
                ambientAt = at + GC.rand(1.2, tension > 0 ? 2.5 : 4.5)
            }
        case "rain":
            while ambientAt < end {
                tone(GC.rand(900, 2200), ambientAt, 0.18, gain: 0.035, slide: 0.7)
                ambientAt += GC.rand(0.15, 0.9)
            }
        default:
            break
        }
    }

    // MARK: sound effects

    func crack() {
        let at = t + 0.01
        for i in 0..<3 { noiseBurst(at + Double(i) * 0.045 + Double.random(in: 0..<0.02), 0.06, freq: GC.rand(2500, 4200), q: 2, gain: 0.25) }
        tone(220, at, 0.08, gain: 0.1, slide: 0.6, bus: .sfx)
    }
    func boop() { tone(GC.rand(520, 640), t, 0.18, gain: 0.08, slide: 1.5, bus: .sfx) }
    func knock() {
        let at = t + 0.01
        for dt in [0.0, 0.2] {
            tone(190, at + dt, 0.12, gain: 0.25, slide: 0.7, bus: .sfx)
            noiseBurst(at + dt, 0.05, freq: 900, q: 1.5, gain: 0.12)
        }
    }
    /// gentle "time's up" — a soft rising sparkle, never an alarm
    func ready() {
        let at = t + 0.02
        for (i, n) in [72.0, 76, 79, 84].enumerated() {
            tone(midi(n), at + Double(i) * 0.12, 1.2, gain: 0.1, partials: [(1, 1), (2.76, 0.15)], bus: .sfx)
        }
    }
    func pop() {
        tone(320, t, 0.25, gain: 0.3, slide: 3.2, bus: .sfx)
        noiseBurst(t, 0.25, freq: 1500, q: 0.7, gain: 0.2)
    }
    func cheer() {
        for (i, n) in [79.0, 84].enumerated() { tone(midi(n), t + Double(i) * 0.09, 0.3, gain: 0.1, partials: [(1, 1), (2, 0.2)], bus: .sfx) }
    }
    /// shell piece hitting something hard; p = 0…1 pitch
    func clink(_ p: Double) {
        let f = 1800 + p * 2600
        tone(f, t, 0.12, gain: 0.07, partials: [(1, 1), (2.7, 0.3)], bus: .sfx)
        noiseBurst(t, 0.03, freq: f * 1.5, q: 4, gain: 0.08)
    }
    /// soft landing on the ground; p = 0…1 pitch
    func thud(_ p: Double) {
        tone(90 + p * 120, t, 0.16, gain: 0.22, slide: 0.6, bus: .sfx)
        noiseBurst(t, 0.08, freq: 500, q: 0.8, gain: 0.08)
    }
    func whoosh() {
        noiseBurst(t, 0.45, freq: 400, q: 1.2, gain: 0.18, attack: 0.12)
        if var v = noises.popLast() {
            v.sweepLeft = max(1, Int(0.35 * sr))
            v.freqMul = pow(2400.0 / 400.0, 1 / Double(v.sweepLeft))
            noises.append(v)
        }
    }

    func endTune(_ id: String) -> Double {
        let t0 = t + 0.05
        func bell(_ n: Double, _ at: Double, _ d: Double = 1.6, _ g: Double = 0.14) {
            tone(midi(n), at, d, gain: g, partials: [(1, 1), (2.76, 0.18), (5.4, 0.06)], bus: .sfx)
        }
        func pluck(_ n: Double, _ at: Double, _ d: Double = 0.5, _ g: Double = 0.16) {
            tone(midi(n), at, d, gain: g, partials: [(1, 1), (2, 0.3)], wave: .triangle, bus: .sfx)
        }
        switch id {
        case "chimes":
            for (i, n) in [84.0, 81, 79, 76, 79, 81, 84, 88].enumerated() { bell(n, t0 + Double(i) * 0.16, 1.8, 0.12) }
            for n in [72.0, 76, 79, 84] { bell(n, t0 + 1.5, 2.6, 0.07) }
            return 4
        case "birds":
            for (n, dt) in [(86.0, 0.0), (91, 0.14), (86, 0.28), (93, 0.5), (91, 0.64), (88, 0.78), (86, 1.0), (91, 1.14), (98, 1.4)] {
                tone(midi(n), t0 + dt, 0.12, gain: 0.1, slide: 1.25, bus: .sfx)
            }
            for (i, n) in [72.0, 76, 79].enumerated() { pluck(n, t0 + 1.7 + Double(i) * 0.1, 1.4, 0.12) }
            return 3.4
        case "bubbles":
            for i in 0..<10 { tone(midi(64 + Double(i) * 2.4), t0 + Double(i) * 0.12, 0.16, gain: 0.16, slide: 2.2, bus: .sfx) }
            for n in [76.0, 79, 84] { bell(n, t0 + 1.35, 2, 0.09) }
            return 3.4
        default: // ta-da parade
            for (n, dt, d) in [(67.0, 0.0, 0.2), (72, 0.15, 0.2), (76, 0.3, 0.2), (79, 0.45, 0.45), (76, 0.75, 0.2), (79, 0.9, 0.2), (84, 1.05, 1.2)] {
                pluck(n, t0 + dt, d + 0.3, 0.17)
            }
            for n in [60.0, 64, 67, 72] { tone(midi(n), t0 + 1.05, 1.8, gain: 0.06, wave: .triangle, bus: .sfx) }
            for i in 0..<6 { bell(96 + Double(i % 3) * 3, t0 + 1.1 + Double(i) * 0.09, 0.6, 0.04) }
            noiseBurst(t0 + 1.05, 0.5, freq: 6000, q: 0.5, gain: 0.05)
            return 3
        }
    }

    // MARK: render

    func render(into out: UnsafeMutablePointer<Float>, frames n: Int) {
        let blockEnd = t + Double(n) / sr
        // look a little ahead so a note never starts late
        schedule(until: blockEnd + 0.05)

        var musicBuf = [Double](repeating: 0, count: n)
        var sfxBuf = [Double](repeating: 0, count: n)
        let twoPi = 2 * Double.pi

        // tones
        var i = 0
        while i < tones.count {
            var v = tones[i]
            let offset = Int(v.start - now)
            if offset >= n { i += 1; continue }
            var k = max(0, offset)
            while k < n && !v.env.done {
                let e = v.env.next()
                var s = 0.0
                for p in 0..<v.partials.count {
                    let ph = v.phases[p]
                    let w: Double
                    switch v.wave {
                    case .sine: w = sin(twoPi * ph)
                    case .triangle: w = 4 * abs(ph - 0.5) - 1
                    }
                    s += w * v.partials[p].amp
                    var np = ph + v.freq * v.partials[p].ratio / sr
                    np -= floor(np)
                    v.phases[p] = np
                }
                if v.slideLeft > 0 { v.freq *= v.freqMul; v.slideLeft -= 1 }
                if v.bus == .music { musicBuf[k] += s * e } else { sfxBuf[k] += s * e }
                k += 1
            }
            if v.env.done { tones.swapAt(i, tones.count - 1); tones.removeLast() } else { tones[i] = v; i += 1 }
        }

        // noise bursts
        let nlen = noise.count
        i = 0
        while i < noises.count {
            var v = noises[i]
            let offset = Int(v.start - now)
            if offset >= n { i += 1; continue }
            var k = max(0, offset)
            while k < n && !v.env.done {
                if v.sweepLeft > 0 {
                    v.freq *= v.freqMul
                    v.sweepLeft -= 1
                    if v.sweepLeft % 32 == 0 { v.filter.set(v.type, freq: v.freq, q: v.q, sr: sr) }
                }
                let x = Double(noise[v.pos])
                v.pos += 1
                if v.pos >= nlen { v.pos = 0 }
                let s = v.filter.process(x) * v.env.next()
                if v.bus == .music { musicBuf[k] += s } else { sfxBuf[k] += s }
                k += 1
            }
            if v.env.done { noises.swapAt(i, noises.count - 1); noises.removeLast() } else { noises[i] = v; i += 1 }
        }

        // ambient bed
        if var b = bed {
            let k = 1 - exp(-1 / (b.tau * sr))
            for j in 0..<n {
                if b.kind == "forest", j % 64 == 0 {
                    b.lfo += 64 * 0.08 / sr
                    if b.lfo > 1 { b.lfo -= 1 }
                    b.f.set(.bandpass, freq: 500 + 260 * sin(twoPi * b.lfo), q: 0.6, sr: sr)
                }
                var x = Double(noise[b.pos])
                b.pos += 1
                if b.pos >= nlen { b.pos = 0 }
                if b.kind == "rain" { x = b.hp.process(x) }
                b.gain += (b.target - b.gain) * k
                musicBuf[j] += b.f.process(x) * b.gain
            }
            bed = (b.target == 0 && b.gain < 0.0002) ? nil : b
        }

        // buses → echo → master → gentle compressor
        let mk = 1 - exp(-1 / (musicTau * sr))
        let vk = 1 - exp(-1 / (0.05 * sr))
        let attack = 1 - exp(-1 / (0.003 * sr)), release = 1 - exp(-1 / (0.25 * sr))
        let threshold = 0.126 // ≈ -18 dB
        let dlen = delay.count
        for j in 0..<n {
            musicGain += (musicTarget - musicGain) * mk
            master += (masterTarget - master) * vk
            let m = musicBuf[j] * musicGain
            let s = sfxBuf[j] * 0.9
            let delayed = dlen > 0 ? delay[delayPos] : 0
            lpOut = echoLP.process(delayed)
            if dlen > 0 {
                delay[delayPos] = m + s + lpOut * 0.28
                delayPos += 1
                if delayPos >= dlen { delayPos = 0 }
            }
            var y = (m + s + lpOut * 0.35) * master
            let level = abs(y)
            compEnv += (level - compEnv) * (level > compEnv ? attack : release)
            if compEnv > threshold {
                let over = compEnv / threshold
                y *= pow(over, 1.0 / 3.0 - 1) // ratio 3:1
            }
            y *= 1.4 // make-up gain
            out[j] = Float(tanh(y))
        }
        now += Int64(n)
    }
}

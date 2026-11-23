import AVFoundation
import UIKit

/// The music is synthesised live and all melodies are original. Jobs:
///   1. countdown music — an ambient "something is happening" cue that keeps
///      working when the child looks away from the screen
///   2. small sound effects — crack, pop, boop, knock
///   3. the end tune — a cheerful celebration instead of an alarm. The three
///      animal bands (a full band, animal voices and a solo for the friend who
///      hatched) live in Band.swift; the short jingles are here.
///   4. recorded sounds — real animal calls, the egg crack and pop, and
///      "It's a Fox!" for every friend (Resources/Sounds, generated once with
///      ElevenLabs). Every one has a synthesised stand-in.
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
        Choice(id: "band", name: "Animal band", icon: "🥁"),
        Choice(id: "jungle", name: "Jungle jam", icon: "🪇"),
        Choice(id: "farm", name: "Farmyard hoedown", icon: "🐮"),
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
    private var samplesLoading = false
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
        loadSamples()
        return true
    }

    // MARK: recorded sounds

    /// "It's a Fox!" sits clearly on top while the band ducks under it
    static let voiceGain = 1.25

    /// Decode the animal calls and effects in the background (the voice lines
    /// load one at a time, when a friend hatches).
    private func loadSamples() {
        guard !samplesLoading else { return }
        samplesLoading = true
        let names = Band.callNames + ["crack", "pop"]
        DispatchQueue.global(qos: .utility).async { [weak self] in
            for name in names {
                guard let url = Bundle.main.url(forResource: "call-" + name, withExtension: "mp3"),
                      let pcm = Sound.decode(url) else { continue }
                guard let self else { return }
                self.lock.lock(); self.synth.samples[name] = pcm; self.lock.unlock()
            }
        }
    }

    /// an MP3 from the app bundle → mono float samples
    static func decode(_ url: URL) -> (data: [Float], sr: Double)? {
        guard let file = try? AVAudioFile(forReading: url),
              let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buf)) != nil,
              let ch = buf.floatChannelData, buf.frameLength > 1 else { return nil }
        let data = Array(UnsafeBufferPointer(start: ch[0], count: Int(buf.frameLength)))
        return (data, file.processingFormat.sampleRate)
    }

    /// load one voice line if it isn't already; true when it can play
    private func haveSample(_ key: String, file: String) -> Bool {
        lock.lock(); let have = synth.samples[key] != nil; lock.unlock()
        if have { return true }
        guard let url = Bundle.main.url(forResource: file, withExtension: "mp3"), let pcm = Sound.decode(url) else { return false }
        lock.lock(); synth.samples[key] = pcm; lock.unlock()
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
        with { s in
            s.stopCelebration(fade: 0.3)
            s.startMusic(id)
        }
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
        stopCelebration(fade: 0.2)
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

    func crack() {
        with { s in
            if s.playSample("crack", at: s.t + 0.01, bus: .sfx, gain: 0.9, rate: GC.rand(0.92, 1.1)) == 0 { s.crack() }
        }
    }
    func boop() { with { $0.boop() } }
    func knock() { with { $0.knock() } }
    func ready() { with { $0.ready() } }
    func pop() {
        with { s in
            if s.playSample("pop", at: s.t, bus: .sfx, gain: 1.1) == 0 { s.pop() }
        }
    }
    func cheer() { with { $0.cheer() } }
    func clink(_ p: Double = 0.5) { with { $0.clink(p) } }
    func thud(_ p: Double = 0.5) { with { $0.thud(p) } }
    func whoosh() { with { $0.whoosh() } }

    /// the celebration tune; returns its length in seconds.
    /// friend (optional) = the animal that hatched; it gets a solo in the bands
    @discardableResult
    func endTune(_ id: String, friend: String? = nil) -> Double {
        var len = 0.0
        with { s in
            if Band.songs[id] != nil {
                len = Band.perform(id, friend: friend, on: s)
            } else {
                s.stopCelebration(fade: 0.2)
                len = s.endTune(id)
            }
        }
        return len
    }

    /// stop a band that is playing (New egg, Stop, closing a preview)
    func stopCelebration(fade: Double = 0.3) {
        lock.lock(); synth.stopCelebration(fade: fade); lock.unlock()
    }

    /// tapping the hatched friend: it says hello in its own voice; 0 if it has none
    @discardableResult
    func friendCall(_ friendId: String) -> Double {
        var len = 0.0
        with { len = Band.friendCall(friendId, on: $0) }
        return len
    }

    /// "It's a Fox!" (or "Peekaboo!" for a photo) in the recorded voice,
    /// falling back to the device voice if the recording can't be loaded.
    func sayFriend(animalId: String?, name: String) {
        let id = animalId ?? "peekaboo"
        if haveSample("voice/" + id, file: "voice-" + id) {
            var len = 0.0
            with { s in
                len = s.playSample("voice/" + id, at: s.t + 0.05, bus: .voice, gain: Sound.voiceGain)
                if len > 0 { s.duckCelebration(len + 0.3) }
            }
            if len > 0 { return }
        }
        say(animalId != nil ? "It's \(GC.aName(name))!" : name)
    }

    /// The device voice (only a fallback now).
    func say(_ text: String) {
        lock.lock(); synth.duckCelebration(1.4 + Double(text.count) * 0.06); lock.unlock()
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

/// music: the countdown; sfx: effects and jingles (with echo);
/// celeb: an animal band (its own level, so it can stop or duck); voice: "It's a Fox!"
enum Bus { case music, sfx, celeb, voice }
enum Wave { case sine, triangle }
enum FilterType { case lowpass, highpass, bandpass }

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

// MARK: - band voices (Band.swift builds songs out of these)

enum OscType { case saw, square, sine, triangle }

/// A pitch or filter sweep: (seconds from the note's start, value),
/// exponential between points, like Web Audio's exponentialRampToValueAtTime.
typealias PitchPath = [(Double, Double)]

/// One synthesised voice: oscillators → (filter) → (vowel formants) →
/// (tremolo) → envelope. Brass, horns, fiddle, kazoo and every animal are one
/// of these. Keep arguments in this order when calling the memberwise init.
struct VSpec {
    var type: OscType = .saw
    var f: PitchPath
    var partials: [(Double, Double)] = [(1, 1)]
    /// extra copies, detuned in cents, for a section sound
    var detune: [Double] = [0]
    var dur: Double
    var gain: Double = 0.2
    var attack: Double? = nil
    var release: Double = 0.08
    var sus: Double = 1
    /// percussive exponential decay instead of a held note
    var pluck = false
    var vib: (rate: Double, cents: Double, delay: Double)? = nil
    var trem: (rate: Double, depth: Double)? = nil
    var filter: (type: FilterType, f: PitchPath, q: Double)? = nil
    var formants: [(f: PitchPath, q: Double, amp: Double)] = []
    /// breath or growl mixed in before the filters
    var noise: Double = 0
    var noiseF: Double = 1500
}

/// Steps through a PitchPath one sample at a time.
private struct Glide {
    private let pts: [(Int, Double)]
    private var seg = 0
    private var mul = 1.0
    private var left = 0
    private(set) var value: Double

    init(_ path: PitchPath, sr: Double) {
        let p = path.isEmpty ? [(0.0, 440.0)] : path
        pts = p.map { (Int(($0.0 * sr).rounded()), max($0.1, 0.0001)) }
        value = pts[0].1
        setup()
    }

    private mutating func setup() {
        while seg + 1 < pts.count {
            let n = pts[seg + 1].0 - pts[seg].0
            if n > 0 {
                left = n
                mul = pow(pts[seg + 1].1 / value, 1 / Double(n))
                return
            }
            seg += 1
            value = pts[seg].1
        }
        left = 0
        mul = 1
    }

    mutating func next() -> Double {
        let v = value
        if left > 0 {
            value *= mul
            left -= 1
            if left == 0 {
                seg += 1
                value = pts[seg].1
                setup()
            }
        }
        return v
    }
}

/// polyBLEP: rounds off the saw/square edges so they don't alias into fizz
private func blep(_ t: Double, _ dt: Double) -> Double {
    if t < dt { let x = t / dt; return x + x - x * x - 1 }
    if t > 1 - dt { let x = (t - 1) / dt; return x * x + x + x + 1 }
    return 0
}

private struct SynthVoice {
    var start: Int64
    let len: Int
    var k = 0
    let type: OscType
    var pitch: Glide
    let ratios: [Double]
    let amps: [Double]
    var phases: [Double]
    let vibRate: Double, vibCents: Double, vibStart: Int, vibRamp: Int
    var vibPhase = 0.0
    let tremRate: Double, tremDepth: Double
    var tremPhase = 0.0
    var filter: Biquad?
    let filterType: FilterType
    var filterF: Glide?
    let filterQ: Double
    var formants: [Biquad]
    var formantF: [Glide]
    let formantQ: [Double]
    let formantAmp: [Double]
    let noise: Double
    var noiseFilter = Biquad()
    var noisePos: Int
    let pluck: Bool
    var env: Env
    let peak: Double, aN: Int, relStart: Int, sus: Double
    let bus: Bus
}

private struct SampleVoice {
    var start: Int64
    let data: [Float]
    var pos = 0.0
    let step: Double
    let gain: Double
    let end: Int
    let fadeAt: Int
    let fadeLen: Int
    var k = 0
    let bus: Bus
}

/// A short, soft room for the bands (four damped combs + two all-passes).
private struct Room {
    private var combs: [[Double]] = []
    private var cpos: [Int] = []
    private var damp: [Double] = []
    private var aps: [[Double]] = []
    private var apos: [Int] = []

    mutating func setup(sr: Double) {
        let k = sr / 44_100
        combs = [1116.0, 1188, 1277, 1356].map { [Double](repeating: 0, count: max(1, Int($0 * k))) }
        cpos = [0, 0, 0, 0]
        damp = [0, 0, 0, 0]
        aps = [556.0, 441].map { [Double](repeating: 0, count: max(1, Int($0 * k))) }
        apos = [0, 0]
    }

    mutating func process(_ x: Double) -> Double {
        guard !combs.isEmpty else { return 0 }
        var out = 0.0
        let input = x * 0.1
        for i in 0..<combs.count {
            let y = combs[i][cpos[i]]
            damp[i] = y * 0.7 + damp[i] * 0.3
            combs[i][cpos[i]] = input + damp[i] * 0.8
            cpos[i] += 1
            if cpos[i] >= combs[i].count { cpos[i] = 0 }
            out += y
        }
        for i in 0..<aps.count {
            let b = aps[i][apos[i]]
            let y = b - out
            aps[i][apos[i]] = out + b * 0.5
            apos[i] += 1
            if apos[i] >= aps[i].count { apos[i] = 0 }
            out = y
        }
        return out
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

final class Synth {
    var sr: Double
    private var now: Int64 = 0
    private var tones: [ToneVoice] = []
    private var noises: [NoiseVoice] = []
    private var voices: [SynthVoice] = []
    private var plays: [SampleVoice] = []
    private var noise: [Float] = []

    /// decoded recordings: key → (mono samples, their sample rate)
    var samples: [String: (data: [Float], sr: Double)] = [:]
    /// recordings are levelled to -14 LUFS (tools/pick-sounds.js); this sits them in the mix
    static let sampleGain = 0.62

    // an animal band: its scheduled events, level, room
    private var celeb: Celebration?
    private var celebGain = 1.0
    private var celebStopping = false
    private var celebFadeTau = 0.1
    private var duckUntil = 0.0
    private var room = Room()

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
        room.setup(sr: s)
        tones.reserveCapacity(256)
        noises.reserveCapacity(128)
        voices.reserveCapacity(96)
        plays.reserveCapacity(32)
    }

    var t: Double { Double(now) / sr }
    var isBusy: Bool { playing || celeb != nil || !tones.isEmpty || !noises.isEmpty || !voices.isEmpty || !plays.isEmpty || bed != nil }

    private func sample(_ time: Double) -> Int64 { Int64((time * sr).rounded()) }

    // MARK: voices

    /// one plucked / struck note
    func tone(_ freq: Double, _ at: Double, _ dur: Double, gain: Double = 0.2, attack: Double = 0.005,
              partials: [(Double, Double)] = [(1, 1)], wave: Wave = .sine, slide: Double? = nil, bus: Bus = .music) {
        guard tones.count < 256 else { return }
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
        guard noises.count < 128 else { return }
        var v = NoiseVoice(start: sample(at), env: Env(peak: gain, attack: attack, dur: dur, sr: sr),
                           type: type, freq: freq, q: q, pos: Int.random(in: 0..<max(1, noise.count)), bus: bus)
        v.filter.set(type, freq: freq, q: q, sr: sr)
        noises.append(v)
    }

    /// one band voice (see VSpec); gain multiplies the spec's own gain
    func voice(_ v: VSpec, at: Double, gain: Double = 1, bus: Bus) {
        guard voices.count < 96, v.dur > 0 else { return }
        var ratios: [Double] = [], amps: [Double] = []
        let share = 1 / Double(v.detune.count).squareRoot()
        for (ratio, amp) in v.partials {
            for cents in v.detune {
                ratios.append(ratio * pow(2, cents / 1200))
                amps.append(amp * share)
            }
        }
        let len = max(1, Int(v.dur * sr))
        let peak = v.gain * gain
        let a = min(v.attack ?? 0.02, v.dur * 0.4)
        let r = min(v.release, v.dur * 0.5)
        var filter: Biquad? = nil
        var filterF: Glide? = nil
        if let f = v.filter {
            filterF = Glide(f.f, sr: sr)
            var b = Biquad()
            b.set(f.type, freq: filterF?.value ?? 1000, q: f.q, sr: sr)
            filter = b
        }
        var formants: [Biquad] = [], formantF: [Glide] = [], formantQ: [Double] = [], formantAmp: [Double] = []
        for fm in v.formants {
            let g = Glide(fm.f, sr: sr)
            var b = Biquad()
            b.set(.bandpass, freq: g.value, q: fm.q, sr: sr)
            formants.append(b)
            formantF.append(g)
            formantQ.append(fm.q)
            formantAmp.append(fm.amp * fm.q.squareRoot()) // narrow bands lose level; give it back
        }
        var nf = Biquad()
        nf.set(.bandpass, freq: v.noiseF, q: 0.8, sr: sr)
        voices.append(SynthVoice(
            start: sample(at), len: len, type: v.type, pitch: Glide(v.f, sr: sr),
            ratios: ratios, amps: amps, phases: [Double](repeating: 0, count: ratios.count),
            vibRate: v.vib?.rate ?? 0, vibCents: v.vib?.cents ?? 0,
            vibStart: Int((v.vib?.delay ?? 0) * sr), vibRamp: max(1, Int(0.12 * sr)),
            tremRate: v.trem?.rate ?? 0, tremDepth: v.trem?.depth ?? 0,
            filter: filter, filterType: v.filter?.type ?? .lowpass, filterF: filterF, filterQ: v.filter?.q ?? 1,
            formants: formants, formantF: formantF, formantQ: formantQ, formantAmp: formantAmp,
            noise: v.noise, noiseFilter: nf, noisePos: Int.random(in: 0..<max(1, noise.count)),
            pluck: v.pluck, env: Env(peak: peak, attack: v.attack ?? 0.004, dur: v.dur, sr: sr),
            peak: peak, aN: max(1, Int(a * sr)), relStart: max(1, Int((v.dur - r) * sr)), sus: v.sus,
            bus: bus))
    }

    /// Play a recording if it has loaded. Returns its length, or 0 so the
    /// caller can fall back to the synthesised version.
    @discardableResult
    func playSample(_ key: String, at: Double, bus: Bus, gain: Double = 1, rate: Double = 1, maxDur: Double? = nil) -> Double {
        guard let smp = samples[key], smp.data.count > 1, plays.count < 32 else { return 0 }
        var dur = Double(smp.data.count - 1) / smp.sr / rate
        var fadeAt = Int.max
        if let m = maxDur, m < dur {
            dur = m
            fadeAt = max(0, Int((m - 0.06) * sr))
        }
        plays.append(SampleVoice(start: sample(at), data: smp.data, step: smp.sr / sr * rate,
                                 gain: gain * Synth.sampleGain, end: Int(dur * sr), fadeAt: fadeAt,
                                 fadeLen: max(1, Int(0.06 * sr)), bus: bus))
        return dur
    }

    /// length of a loaded recording, in seconds
    func sampleLength(_ key: String) -> Double? {
        guard let smp = samples[key], smp.sr > 0 else { return nil }
        return Double(smp.data.count) / smp.sr
    }

    // MARK: animal bands

    /// a new song replaces whatever band was playing
    func startCelebration(_ c: Celebration) {
        purgeCelebration()
        celebGain = 1
        celebStopping = false
        duckUntil = 0
        celeb = c
    }

    func stopCelebration(fade: Double) {
        guard celeb != nil || hasCelebVoices else { return }
        celeb = nil
        celebStopping = true
        celebFadeTau = max(0.01, fade / 3)
    }

    /// dip the band while "It's a Fox!" is said
    func duckCelebration(_ secs: Double) { duckUntil = t + secs }

    private var hasCelebVoices: Bool {
        tones.contains { $0.bus == .celeb } || noises.contains { $0.bus == .celeb } ||
            voices.contains { $0.bus == .celeb } || plays.contains { $0.bus == .celeb }
    }

    private func purgeCelebration() {
        tones.removeAll { $0.bus == .celeb }
        noises.removeAll { $0.bus == .celeb }
        voices.removeAll { $0.bus == .celeb }
        plays.removeAll { $0.bus == .celeb }
    }

    /// run every song event due before `end` (a little ahead, so notes start on time)
    private func runCelebration(until end: Double) {
        guard let c = celeb else { return }
        while c.i < c.events.count && c.events[c.i].t < end {
            let e = c.events[c.i]
            c.i += 1
            if e.t >= t - 0.05 { e.fn(c.kit, e.t) } // skip anything a stall made us miss
        }
        if c.i >= c.events.count && t > c.end { celeb = nil }
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
        runCelebration(until: blockEnd + 0.05)

        var musicBuf = [Double](repeating: 0, count: n)
        var sfxBuf = [Double](repeating: 0, count: n)
        var celebBuf = [Double](repeating: 0, count: n)
        var voiceBuf = [Double](repeating: 0, count: n)
        let twoPi = 2 * Double.pi
        func add(_ bus: Bus, _ k: Int, _ x: Double) {
            switch bus {
            case .music: musicBuf[k] += x
            case .sfx: sfxBuf[k] += x
            case .celeb: celebBuf[k] += x
            case .voice: voiceBuf[k] += x
            }
        }

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
                add(v.bus, k, s * e)
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
                add(v.bus, k, s)
                k += 1
            }
            if v.env.done { noises.swapAt(i, noises.count - 1); noises.removeLast() } else { noises[i] = v; i += 1 }
        }

        // band voices
        i = 0
        while i < voices.count {
            var v = voices[i]
            let offset = Int(v.start - now)
            if offset >= n { i += 1; continue }
            var k = max(0, offset)
            while k < n && v.k < v.len {
                // envelope
                let e: Double
                if v.pluck {
                    e = v.env.next()
                } else if v.k < v.aN {
                    e = v.peak * Double(v.k) / Double(v.aN)
                } else if v.k < v.relStart {
                    let span = Double(max(1, v.relStart - v.aN))
                    e = v.peak + (v.peak * v.sus - v.peak) * Double(v.k - v.aN) / span
                } else {
                    let span = Double(max(1, v.len - v.relStart))
                    e = v.peak * v.sus * max(0, 1 - Double(v.k - v.relStart) / span)
                }
                // pitch + vibrato
                var f = v.pitch.next()
                if v.vibCents > 0 && v.k >= v.vibStart {
                    let depth = min(1, Double(v.k - v.vibStart) / Double(v.vibRamp)) * v.vibCents
                    v.vibPhase += v.vibRate / sr
                    if v.vibPhase >= 1 { v.vibPhase -= 1 }
                    f *= exp2(depth * sin(twoPi * v.vibPhase) / 1200)
                }
                // oscillators
                var x = 0.0
                for j in 0..<v.ratios.count {
                    let ph = v.phases[j]
                    let dt = min(0.49, f * v.ratios[j] / sr)
                    let w: Double
                    switch v.type {
                    case .saw: w = 2 * ph - 1 - blep(ph, dt)
                    case .square:
                        var p2 = ph + 0.5
                        if p2 >= 1 { p2 -= 1 }
                        w = (ph < 0.5 ? 1 : -1) + blep(ph, dt) - blep(p2, dt)
                    case .sine: w = sin(twoPi * ph)
                    case .triangle: w = 4 * abs(ph - 0.5) - 1
                    }
                    x += w * v.amps[j]
                    var np = ph + dt
                    if np >= 1 { np -= 1 }
                    v.phases[j] = np
                }
                if v.noise > 0 {
                    x += v.noiseFilter.process(Double(noise[v.noisePos])) * v.noise
                    v.noisePos += 1
                    if v.noisePos >= nlen { v.noisePos = 0 }
                }
                // filter, then the vowel formants (coefficients follow their sweeps every 32 samples)
                let retune = v.k % 32 == 0
                if v.filter != nil, var ff = v.filterF {
                    let fv = ff.next()
                    v.filterF = ff
                    if retune { v.filter!.set(v.filterType, freq: fv, q: v.filterQ, sr: sr) }
                    x = v.filter!.process(x)
                }
                if !v.formants.isEmpty {
                    var sum = 0.0
                    for j in 0..<v.formants.count {
                        let fv = v.formantF[j].next()
                        if retune { v.formants[j].set(.bandpass, freq: fv, q: v.formantQ[j], sr: sr) }
                        sum += v.formants[j].process(x) * v.formantAmp[j]
                    }
                    x = sum
                }
                if v.tremDepth > 0 {
                    v.tremPhase += v.tremRate / sr
                    if v.tremPhase >= 1 { v.tremPhase -= 1 }
                    x *= 1 - v.tremDepth / 2 + v.tremDepth / 2 * sin(twoPi * v.tremPhase)
                }
                add(v.bus, k, x * e)
                v.k += 1
                k += 1
            }
            if v.k >= v.len { voices.swapAt(i, voices.count - 1); voices.removeLast() } else { voices[i] = v; i += 1 }
        }

        // recordings
        i = 0
        while i < plays.count {
            var v = plays[i]
            let offset = Int(v.start - now)
            if offset >= n { i += 1; continue }
            var k = max(0, offset)
            let last = v.data.count - 1
            while k < n && v.k < v.end {
                let p = Int(v.pos)
                if p >= last { v.k = v.end; break }
                let frac = v.pos - Double(p)
                let x = Double(v.data[p]) * (1 - frac) + Double(v.data[p + 1]) * frac
                var g = v.gain
                if v.k >= v.fadeAt { g *= max(0, 1 - Double(v.k - v.fadeAt) / Double(v.fadeLen)) }
                add(v.bus, k, x * g)
                v.pos += v.step
                v.k += 1
                k += 1
            }
            if v.k >= v.end { plays.swapAt(i, plays.count - 1); plays.removeLast() } else { plays[i] = v; i += 1 }
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

        // the band's level: 1, dipped under the voice line, or fading out when stopped
        let celebTarget = celebStopping ? 0 : (t < duckUntil ? 0.3 : 1)
        let celebTau = celebStopping ? celebFadeTau : (celebTarget < celebGain ? 0.08 : 0.3)
        let ck = 1 - exp(-1 / (celebTau * sr))

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
            celebGain += (celebTarget - celebGain) * ck
            let c = celebBuf[j] * celebGain
            let wet = room.process(c) * 0.22
            var y = (m + s + lpOut * 0.35 + c + wet + voiceBuf[j]) * master
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
        // a stopped band has faded out: clear it away and reset its level
        if celebStopping && celebGain < 0.0005 {
            purgeCelebration()
            celebStopping = false
            celebGain = 1
        }
    }
}

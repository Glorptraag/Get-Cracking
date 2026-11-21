import AVFoundation

/// The crack and pop recordings from Get Cracking, plus each friend's
/// recorded "It's Mary!" line (ElevenLabs, see tools/gen-voice.js).
/// Falls back to the device voice if a line is missing.
@MainActor
final class SoundBox {
    static let shared = SoundBox()

    var soundsOn = true
    var speakNames = true

    private var players: [String: AVAudioPlayer] = [:]
    private let speech = AVSpeechSynthesizer()

    private init() {
        // .ambient: respects the silent switch and never stops other audio
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func crack() { play("crack", volume: 0.8) }
    func pop() { play("pop", volume: 0.9) }

    /// Say the friend's line: the recording if there is one, else the device voice.
    func sayName(of friend: Friend) {
        guard soundsOn, speakNames else { return }
        let file = String(format: "day-%02d", friend.day)
        if play(file, volume: 1) { return }
        speech.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: friend.spoken)
        u.rate = 0.44
        u.pitchMultiplier = 1.2
        u.voice = AVSpeechSynthesisVoice(language: "en-AU")
        speech.speak(u)
    }

    @discardableResult
    private func play(_ name: String, volume: Float) -> Bool {
        guard soundsOn else { return false }
        if let p = players[name] {
            p.currentTime = 0
            p.volume = volume
            p.play()
            return true
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
              let p = try? AVAudioPlayer(contentsOf: url) else { return false }
        players[name] = p
        p.volume = volume
        p.prepareToPlay()
        p.play()
        return true
    }
}

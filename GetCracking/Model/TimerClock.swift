import Foundation

/// The countdown's arithmetic, kept free of UI so the gate checks
/// (Tests/GateChecks) can run it, backgrounding included, without a simulator.
///
/// Time is wall-clock seconds, never a count of ticks, so a run that was
/// away (locked phone, another app) shows the right time and crack step the
/// moment it comes back. A paused run keeps its remaining time frozen.
struct TimerClock: Equatable {
    /// when the crack steps happen, as a fraction of the run (web STEP_AT)
    static let stepAt: [Double] = [0.1, 0.22, 0.34, 0.46, 0.58, 0.7, 0.8, 0.9]

    /// the crack step (0 … 8) for a fraction of the run
    static func step(for fraction: Double) -> Int {
        var n = 0
        for (i, at) in stepAt.enumerated() where fraction >= at { n = i + 1 }
        return n
    }

    private(set) var total: Double
    private(set) var endAt: Double
    private(set) var pausedRemaining: Double?

    init(total: Double, now: Double) {
        self.total = total
        endAt = now + total
    }

    var isPaused: Bool { pausedRemaining != nil }

    func remaining(at now: Double) -> Double { pausedRemaining ?? max(0, endAt - now) }

    /// how much of the run has gone, 0 … 1
    func elapsed(at now: Double) -> Double { min(1, max(0, 1 - remaining(at: now) / total)) }

    func step(at now: Double) -> Int { TimerClock.step(for: elapsed(at: now)) }

    func isUp(at now: Double) -> Bool { !isPaused && remaining(at: now) <= 0 }

    mutating func pause(at now: Double) {
        guard !isPaused else { return }
        pausedRemaining = max(0, endAt - now)
    }

    mutating func resume(at now: Double) {
        guard let rem = pausedRemaining else { return }
        endAt = now + rem
        pausedRemaining = nil
    }

    /// −/+ time: never below 5 s left; the ring's length grows if needed
    mutating func adjust(_ seconds: Double, at now: Double) {
        let rem = remaining(at: now)
        let next = max(5, rem + seconds)
        total = max(next, total + (next - rem))
        if isPaused { pausedRemaining = next } else { endAt = now + next }
    }

    /// "Hatch now": time is up from this moment
    mutating func finish(at now: Double) {
        pausedRemaining = nil
        endAt = now
    }
}

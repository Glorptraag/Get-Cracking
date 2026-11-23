import Foundation

/// The rules of the setup screen's egg-timer dial (web js/app.js `buildDial`,
/// `wireDial`, `stepTime`, from 2f810aa), kept free of UI so the gate checks
/// (Tests/GateChecks) can run them without a simulator.
///
/// One full turn of the ring is 60 minutes. Twisting or tapping the ring sets
/// whole minutes; − / + step 15 s below 3 minutes and 1 minute above.
/// The dial is drawn in a 340×340 box centred on (0, 0), y pointing down.
enum TimeDial {
    static let minSecs = 15
    static let maxSecs = 3600
    /// the ring's radius in the dial's box
    static let radius = 136.0

    static func clamp(_ secs: Int) -> Int { min(maxSecs, max(minSecs, secs)) }

    /// − (dir < 0) or + (dir > 0) from `t` seconds: 15 s steps below 3 minutes
    /// and 1 minute from there up, snapped to that grid first (0:10 + → 0:15,
    /// 4:30 − → 4:00), then clamped to 15 s … 60 min.
    static func step(_ t: Int, _ dir: Int) -> Int {
        let fine = dir > 0 ? t < 180 : t <= 180
        let unit = fine ? 15 : 60
        let down = t >= 0 ? t / unit : -((-t + unit - 1) / unit)      // floor(t / unit)
        let up = t >= 0 ? (t + unit - 1) / unit : -(-t / unit)        // ceil(t / unit)
        return clamp(dir > 0 ? down * unit + unit : up * unit - unit)
    }

    /// how far round the ring `secs` is, 0 … 1
    static func fraction(_ secs: Int) -> Double { min(1, max(0, Double(secs) / Double(maxSecs))) }

    /// the knob's angle in radians, clockwise from 12 o'clock
    static func angle(_ secs: Int) -> Double { fraction(secs) * 2 * .pi }

    /// the knob's centre in the dial's box
    static func knob(_ secs: Int) -> (x: Double, y: Double) {
        let a = angle(secs)
        return (sin(a) * radius, -cos(a) * radius)
    }

    /// A touch at (x, y) from the dial's centre, in the dial's box: how far out
    /// it is, and the whole minute (0 … 60) of the ring under it.
    static func touch(_ x: Double, _ y: Double) -> (dist: Double, minutes: Int) {
        var a = atan2(x, -y)
        if a < 0 { a += 2 * .pi }
        return (hypot(x, y), Int((a / (2 * .pi) * 60).rounded()))
    }

    /// Only the ring itself turns the dial; the egg in the middle stays tappable.
    static func onRing(_ dist: Double) -> Bool { dist >= radius - 26 && dist <= radius + 40 }

    /// The minutes a touch on the ring sets, from the time it shows now.
    /// 0 and 60 share the top of the ring, so it stays on whichever side the
    /// time came from; and a drag (not the first touch) never wraps past the top.
    static func ringMinutes(_ touched: Int, currentSecs: Int, first: Bool) -> Int {
        var m = touched
        let cur = Double(currentSecs) / 60
        if m == 0 { m = cur > 30 ? 60 : 1 }
        if !first {
            if cur >= 45 && m <= 15 { m = 60 }
            if cur <= 15 && m >= 45 { m = 1 }
        }
        return m
    }

    /// What VoiceOver reads for the dial: "5 minutes", "2 minutes 45 seconds", "15 seconds".
    static func spoken(_ secs: Int) -> String {
        let m = secs / 60, s = secs % 60
        var parts: [String] = []
        if m > 0 { parts.append("\(m) minute\(m == 1 ? "" : "s")") }
        if s > 0 { parts.append("\(s) seconds") }
        return parts.joined(separator: " ")
    }
}

import SwiftUI
import QuartzCore

/// Shared constants and helpers (the native counterpart of the web app's util.js).
enum GC {
    /// The chunky dark outline used everywhere.
    static let outHex = "#3b2224"
    static let out = Color(hex: outHex)

    static var now: Double { CACurrentMediaTime() }

    static func rand(_ a: Double, _ b: Double) -> Double { a + Double.random(in: 0..<1) * (b - a) }
    static func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double { max(a, min(b, v)) }
    static func pick<T>(_ arr: [T]) -> T { arr[Int.random(in: 0..<arr.count)] }

    @MainActor static var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    /// Lighten (amt > 0) or darken (amt < 0) a #rrggbb colour.
    static func shade(_ hex: String, _ amt: Double) -> String {
        let (r, g, b) = HexColor.bytes(hex)
        func f(_ c: Int) -> Int {
            let d = Double(c)
            return Int((amt < 0 ? d * (1 + amt) : d + (255 - d) * amt).rounded())
        }
        return String(format: "#%02x%02x%02x", f(r), f(g), f(b))
    }

    /// m:ss, rounding up so the clock reads 0:00 only when time is really up.
    static func fmtTime(_ seconds: Double) -> String {
        let s = max(0, Int(ceil(seconds - 0.0005)))
        return "\(s / 60):" + String(format: "%02d", s % 60)
    }
}

enum HexColor {
    static func bytes(_ hex: String) -> (Int, Int, Int) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        let n = Int(s, radix: 16) ?? 0
        return ((n >> 16) & 255, (n >> 8) & 255, n & 255)
    }
}

extension Color {
    init(hex: String, opacity: Double = 1) {
        let (r, g, b) = HexColor.bytes(hex)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: opacity)
    }
}

/// Deterministic PRNG (xorshift32, bit-for-bit the same as the web version)
/// so scenes draw the same every time.
struct Seeded {
    private var s: UInt32
    init(_ seed: Int) {
        s = UInt32(truncatingIfNeeded: seed)
        if s == 0 { s = 1 }
    }
    mutating func next() -> Double {
        let a = s ^ (s << 13)
        var b = Int32(bitPattern: a)
        b = b ^ (b >> 17)
        var c = UInt32(bitPattern: b)
        c = c ^ (c << 5)
        s = c
        return Double(s % 100000) / 100000
    }
}

/// Shuffle-bag: every item comes up once before any repeats. Persisted.
final class ShuffleBag {
    private let key: String
    private let items: [String]
    private var bag: [String]

    init(key: String, items: [String]) {
        self.key = key
        self.items = items
        bag = (UserDefaults.standard.stringArray(forKey: key) ?? []).filter { items.contains($0) }
    }

    func next() -> String {
        if bag.isEmpty { bag = items.shuffled() }
        let v = bag.removeLast()
        UserDefaults.standard.set(bag, forKey: key)
        return v
    }
}

/// CSS-style timing functions.
struct Ease {
    let x1: Double, y1: Double, x2: Double, y2: Double
    let isLinear: Bool

    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2
        isLinear = false
    }
    private init(linear: Bool) {
        x1 = 0; y1 = 0; x2 = 1; y2 = 1
        isLinear = true
    }

    static let linear = Ease(linear: true)
    static let ease = Ease(0.25, 0.1, 0.25, 1)
    static let easeIn = Ease(0.42, 0, 1, 1)
    static let easeOut = Ease(0, 0, 0.58, 1)
    static let easeInOut = Ease(0.42, 0, 0.58, 1)

    func callAsFunction(_ t: Double) -> Double {
        if isLinear || t <= 0 || t >= 1 { return t }
        // solve x(s) = t for s, then return y(s)
        var s = t
        for _ in 0..<8 {
            let x = bez(s, x1, x2) - t
            if abs(x) < 1e-5 { return bez(s, y1, y2) }
            let d = dbez(s, x1, x2)
            if abs(d) < 1e-6 { break }
            s -= x / d
        }
        var lo = 0.0, hi = 1.0
        s = t
        for _ in 0..<30 {
            let x = bez(s, x1, x2)
            if abs(x - t) < 1e-5 { break }
            if x < t { lo = s } else { hi = s }
            s = (lo + hi) / 2
        }
        return bez(s, y1, y2)
    }

    private func bez(_ s: Double, _ a: Double, _ b: Double) -> Double {
        let u = 1 - s
        return 3 * u * u * s * a + 3 * u * s * s * b + s * s * s
    }
    private func dbez(_ s: Double, _ a: Double, _ b: Double) -> Double {
        let u = 1 - s
        return 3 * u * u * a + 6 * u * s * (b - a) + 3 * s * s * (1 - b)
    }
}

typealias Pt = (Double, Double)

import SwiftUI

/// One transform function, as in a CSS transform list.
enum TOp {
    case translate(Double, Double)
    case scale(Double, Double)
    case rotate(Double)            // degrees
    case skewX(Double)             // degrees

    static func s(_ k: Double) -> TOp { .scale(k, k) }

    var identity: TOp {
        switch self {
        case .translate: return .translate(0, 0)
        case .scale: return .scale(1, 1)
        case .rotate: return .rotate(0)
        case .skewX: return .skewX(0)
        }
    }

    func apply(to m: CGAffineTransform) -> CGAffineTransform {
        switch self {
        case let .translate(x, y): return m.translatedBy(x: x, y: y)
        case let .scale(x, y): return m.scaledBy(x: x, y: y)
        case let .rotate(d): return m.rotated(by: d * .pi / 180)
        case let .skewX(d): return CGAffineTransform(a: 1, b: 0, c: tan(d * .pi / 180), d: 1, tx: 0, ty: 0).concatenating(m)
        }
    }

    static func lerp(_ a: TOp, _ b: TOp, _ t: Double) -> TOp? {
        func l(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        switch (a, b) {
        case let (.translate(ax, ay), .translate(bx, by)): return .translate(l(ax, bx), l(ay, by))
        case let (.scale(ax, ay), .scale(bx, by)): return .scale(l(ax, bx), l(ay, by))
        case let (.rotate(x), .rotate(y)): return .rotate(l(x, y))
        case let (.skewX(x), .skewX(y)): return .skewX(l(x, y))
        default: return nil
        }
    }
}

enum Transform {
    static func matrix(_ ops: [TOp]) -> CGAffineTransform {
        ops.reduce(CGAffineTransform.identity) { $1.apply(to: $0) }
    }

    /// CSS-style list interpolation: matching functions interpolate pairwise,
    /// the shorter list is padded with identity functions.
    static func lerp(_ a: [TOp], _ b: [TOp], _ t: Double) -> CGAffineTransform {
        var out: [TOp] = []
        let n = max(a.count, b.count)
        for i in 0..<n {
            let x = i < a.count ? a[i] : b[i].identity
            let y = i < b.count ? b[i] : a[i].identity
            guard let v = TOp.lerp(x, y, t) else {
                // mismatched functions: fall back to blending matrices
                let ma = matrix(a), mb = matrix(b)
                return CGAffineTransform(a: ma.a + (mb.a - ma.a) * t, b: ma.b + (mb.b - ma.b) * t,
                                         c: ma.c + (mb.c - ma.c) * t, d: ma.d + (mb.d - ma.d) * t,
                                         tx: ma.tx + (mb.tx - ma.tx) * t, ty: ma.ty + (mb.ty - ma.ty) * t)
            }
            out.append(v)
        }
        return matrix(out)
    }

    static func translate(_ x: Double, _ y: Double) -> CGAffineTransform { CGAffineTransform(translationX: x, y: y) }
    static func rotate(_ deg: Double, about x: Double, _ y: Double) -> CGAffineTransform {
        CGAffineTransform(translationX: x, y: y).rotated(by: deg * .pi / 180).translatedBy(x: -x, y: -y)
    }
    static func about(_ ox: Double, _ oy: Double, _ m: CGAffineTransform) -> CGAffineTransform {
        CGAffineTransform(translationX: -ox, y: -oy).concatenating(m).concatenating(CGAffineTransform(translationX: ox, y: oy))
    }
}

/// What an animation contributes this frame. nil = "not animated, use the base value".
struct AnimPose {
    var transform: CGAffineTransform? = nil
    var opacity: Double? = nil
    var trimFrom: Double? = nil
    var trimTo: Double? = nil
}

/// One keyframe for a one-shot (Web Animations style) animation.
struct KF {
    var offset: Double? = nil
    var ops: [TOp]? = nil
    var opacity: Double? = nil
    var trimFrom: Double? = nil
    var trimTo: Double? = nil
    /// timing of the segment that starts at this keyframe (default linear)
    var easing: Ease? = nil

    init(_ ops: [TOp]? = nil, offset: Double? = nil, opacity: Double? = nil,
         trimFrom: Double? = nil, trimTo: Double? = nil, easing: Ease? = nil) {
        self.ops = ops; self.offset = offset; self.opacity = opacity
        self.trimFrom = trimFrom; self.trimTo = trimTo; self.easing = easing
    }
}

/// A one-shot animation on a node: keyframes or a closure of elapsed time.
/// Like Web Animations: it replaces the node's base values while it runs,
/// and with `fill` it keeps its final values afterwards.
final class Anim {
    let start: Double
    let duration: Double
    let fill: Bool
    let sample: (Double) -> AnimPose   // input: elapsed seconds (0...duration)

    init(start: Double, duration: Double, fill: Bool, sample: @escaping (Double) -> AnimPose) {
        self.start = start; self.duration = max(0.0001, duration); self.fill = fill; self.sample = sample
    }

    var end: Double { start + duration }

    func pose(at now: Double) -> AnimPose? {
        if now < start { return nil }
        if now >= end { return fill ? sample(duration) : nil }
        return sample(now - start)
    }

    /// Keyframes → sampler (offsets are spread evenly when not given, like WAAPI).
    static func keyframes(_ kfs: [KF], duration: Double, easing: Ease, base: VNode) -> (Double) -> AnimPose {
        var frames = kfs
        let n = frames.count
        if n > 0 {
            if frames[0].offset == nil { frames[0].offset = 0 }
            if frames[n - 1].offset == nil { frames[n - 1].offset = 1 }
            var i = 0
            while i < n {
                if frames[i].offset == nil {
                    var j = i
                    while j < n, frames[j].offset == nil { j += 1 }
                    let a = frames[i - 1].offset ?? 0, b = frames[j].offset ?? 1
                    for k in i..<j { frames[k].offset = a + (b - a) * Double(k - i + 1) / Double(j - i + 1) }
                    i = j
                } else { i += 1 }
            }
        }
        let baseOps: [TOp] = []
        let baseOpacity = base.opacity
        let baseTrimFrom = base.trimFrom, baseTrimTo = base.trimTo

        func track<V>(_ get: (KF) -> V?) -> [(Double, V, Ease)] {
            frames.compactMap { f in get(f).map { (f.offset ?? 0, $0, f.easing ?? .linear) } }
        }
        let tOps = track { $0.ops }
        let tOp = track { $0.opacity }
        let tTF = track { $0.trimFrom }
        let tTT = track { $0.trimTo }

        func seg<V, R>(_ keys: [(Double, V, Ease)], _ base: V, _ u: Double, _ mix: (V, V, Double) -> R) -> R? {
            guard !keys.isEmpty else { return nil }
            var ks = keys
            if ks[0].0 > 0 { ks.insert((0, base, .linear), at: 0) }
            if ks[ks.count - 1].0 < 1 { ks.append((1, base, .linear)) }
            if u <= ks[0].0 { return mix(ks[0].1, ks[0].1, 0) }
            for i in 0..<(ks.count - 1) {
                let (o0, v0, e) = ks[i]
                let (o1, v1, _) = ks[i + 1]
                if u <= o1 {
                    let local = o1 > o0 ? (u - o0) / (o1 - o0) : 1
                    return mix(v0, v1, e(local))
                }
            }
            let last = ks[ks.count - 1].1
            return mix(last, last, 0)
        }
        func num(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

        return { elapsed in
            let u = easing(min(1, max(0, elapsed / duration)))
            var p = AnimPose()
            p.transform = seg(tOps, baseOps, u) { a, b, t in Transform.lerp(a, b, t) }
            p.opacity = seg(tOp, baseOpacity, u, num)
            p.trimFrom = seg(tTF, Double(baseTrimFrom), u, num)
            p.trimTo = seg(tTT, Double(baseTrimTo), u, num)
            return p
        }
    }
}

/// A looping idle animation (the native counterpart of the CSS @keyframes loops).
struct Loop {
    enum Origin {
        case zero                       // transform-box: view-box; origin 0 0
        case box(Double, Double)        // transform-box: fill-box; origin x% y%
    }
    struct Frame {
        var at: Double
        var ops: [TOp]? = nil
        var opacity: Double? = nil
        var dash: Double? = nil
    }

    var duration: Double
    var delay: Double = 0
    var alternate = false
    var ease: Ease = .easeInOut
    var origin: Origin = .zero
    var frames: [Frame]

    struct Result {
        var transform: CGAffineTransform? = nil
        var opacity: Double = 1
        var dash: Double? = nil
    }

    func evaluate(time: Double, bounds: CGRect) -> Result {
        let elapsed = time - delay
        let iter = max(0, elapsed) / duration
        var u = iter - floor(iter)
        if alternate, Int(floor(iter)) % 2 == 1 { u = 1 - u }

        var r = Result()
        let ops: [TOp]? = value(u, { $0.ops }, base: []) { a, b, t in
            // keep the list form; compose to a matrix below
            Loop.mix(a, b, t)
        }
        if let ops {
            let m = Transform.matrix(ops)
            switch origin {
            case .zero: r.transform = m
            case let .box(fx, fy):
                let ox = Double(bounds.minX) + Double(bounds.width) * fx
                let oy = Double(bounds.minY) + Double(bounds.height) * fy
                r.transform = Transform.about(ox, oy, m)
            }
        }
        if let o: Double = value(u, { $0.opacity }, base: 1, { a, b, t in a + (b - a) * t }) { r.opacity = o }
        r.dash = value(u, { $0.dash }, base: 0, { a, b, t in a + (b - a) * t })
        return r
    }

    private static func mix(_ a: [TOp], _ b: [TOp], _ t: Double) -> [TOp] {
        var out: [TOp] = []
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : b[i].identity
            let y = i < b.count ? b[i] : a[i].identity
            out.append(TOp.lerp(x, y, t) ?? (t < 0.5 ? x : y))
        }
        return out
    }

    private func value<V>(_ u: Double, _ get: (Frame) -> V?, base: V, _ mix: (V, V, Double) -> V) -> V? {
        var keys: [(Double, V)] = frames.compactMap { f in get(f).map { (f.at, $0) } }
        guard !keys.isEmpty else { return nil }
        keys.sort { $0.0 < $1.0 }
        if keys[0].0 > 0 { keys.insert((0, base), at: 0) }
        if keys[keys.count - 1].0 < 1 { keys.append((1, base)) }
        for i in 0..<(keys.count - 1) {
            let (o0, v0) = keys[i], (o1, v1) = keys[i + 1]
            if u <= o1 {
                let local = o1 > o0 ? (u - o0) / (o1 - o0) : 1
                return mix(v0, v1, ease(local))
            }
        }
        return keys[keys.count - 1].1
    }
}

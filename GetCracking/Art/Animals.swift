import SwiftUI

/// The 40 hatchable friends.
///
/// Every animal is a chunky "one-blob" chibi (head + body in one bean shape)
/// assembled from parts:
///   back layer  : tails, wings, manes, quills, shells, ears
///   body        : fill, clipped belly + markings, then a crisp outline pass
///   front layer : arms, feet, floppy ears, face (eyes, cheeks, muzzle, mouth)
///
/// Coordinates: feet sit on y = 0, the animal grows upward (negative y),
/// centred on x = 0. Roughly 200 wide × 200 tall.
struct AnimalDef: Identifiable {
    let id: String
    let name: String
    let body: String
    var shape = "round"
    var belly: String?
    var ears = "none", eyes = "dot", mouth = "w", arms = "paw", feet = "paw", nose = "small", muzzle = "none"
    var back: [String] = [], front: [String] = [], marks: [String] = []
    var earColor: String?, earInner: String?
    var accent: String?, tailColor: String?, tailTip: String?, tailStripe: String?, wingColor: String?
    var maneColor: String?, quillColor: String?, fleeceColor: String?, shellColor: String?, shellSpot: String?
    var gillColor: String?, spikeColor: String?, hornColor: String?, antennaColor: String?
    var markColor: String?, faceColor: String?, muzzleColor: String?, noseColor: String?
    var armColor: String?, feetColor: String?, tuftColor: String?, cheekColor: String?
    var spotPts: [(Double, Double, Double)]?
    var eyesOnBumps = false, whiskers = false, cheeks = true
    var snoutW: Double?, faceY: Double?, eyeX: Double?

    init(_ id: String, _ name: String, _ body: String, _ cfg: (inout AnimalDef) -> Void = { _ in }) {
        self.id = id
        self.name = name
        self.body = body
        cfg(&self)
    }
}

enum Animals {
    private static let O = GC.outHex
    /// the standard outline (6) and the finer one (4.5)
    private static func S(_ fill: String) -> St { St.o(6).filled(fill) }
    private static func S4(_ fill: String) -> St { St.o(4.5).filled(fill) }
    private static func sh(_ c: String, _ a: Double) -> String { GC.shade(c, a) }

    private static let SHAPES: [String: (w: Double, h: Double)] = [
        "round": (64, 128), "tall": (56, 140), "wide": (72, 118), "small": (58, 118),
    ]

    private static func bodyPath(_ w: Double, _ h: Double) -> String {
        "M\(-w),\(-h * 0.45) C\(-w),\(-h * 1.15) \(w),\(-h * 1.15) \(w),\(-h * 0.45) " +
            "C\(w),\(-h * 0.05) \(w * 0.75),0 0,0 C\(-w * 0.75),0 \(-w),\(-h * 0.05) \(-w),\(-h * 0.45) Z"
    }

    /// A thick stroked "tube" with an outline: the path drawn twice.
    static func tube(_ d: String, _ color: String, _ width: Double) -> [VNode] {
        [nPath(d, St.line(O, width + 9)), nPath(d, St.line(color, width))]
    }

    private static func roundedTri(_ a: Pt, _ b: Pt, _ c: Pt, _ fill: String, _ inner: String? = nil) -> [VNode] {
        var out = [nPath("M\(a.0),\(a.1) L\(b.0),\(b.1) L\(c.0),\(c.1) Z", S(fill))]
        if let inner {
            let cx = (a.0 + b.0 + c.0) / 3, cy = (a.1 + b.1 + c.1) / 3
            let k = 0.5
            func p(_ q: Pt) -> Pt { (cx + (q.0 - cx) * k, cy + (q.1 - cy) * k + 3) }
            let ia = p(a), ib = p(b), ic = p(c)
            out.append(nPath("M\(ia.0),\(ia.1) L\(ib.0),\(ib.1) L\(ic.0),\(ic.1) Z",
                             St(fill: inner, stroke: inner, width: 5, join: .round)))
        }
        return out
    }

    // MARK: ears

    private static func ears(_ d: AnimalDef, _ w: Double, _ h: Double) -> [VNode] {
        let c = d.earColor ?? d.body
        let ic = d.earInner ?? sh(c, 0.4)
        switch d.ears {
        case "round":
            return both { s in [nCircle(s * w * 0.62, -h * 0.86, 19, S(c)), nCircle(s * w * 0.62, -h * 0.86, 9, .f(ic))] }
        case "pointy":
            return both { s in roundedTri((s * w * 0.16, -h * 0.9), (s * w * 0.72, -h * 1.22), (s * w * 0.9, -h * 0.62), c, ic) }
        case "tall":
            return both { s in roundedTri((s * w * 0.12, -h * 0.9), (s * w * 0.62, -h * 1.32), (s * w * 0.9, -h * 0.7), c, ic) }
        case "bat":
            return both { s in roundedTri((s * w * 0.12, -h * 0.88), (s * w * 0.98, -h * 1.32), (s * w * 0.95, -h * 0.56), c, ic) }
        case "tufts":
            return both { s in roundedTri((s * w * 0.32, -h * 0.93), (s * w * 0.82, -h * 1.12), (s * w * 0.86, -h * 0.72), c) }
        case "long":
            return both { s in
                [nGroup([nEllipse(s * 22, -h - 26, 15, 40, S(c)), nEllipse(s * 22, -h - 22, 6.5, 27, .f(ic))],
                        rotAbout(s * 10, s * 22, -h - 26))]
            }
        case "tiny":
            return both { s in [nCircle(s * w * 0.5, -h * 0.93, 10, S(c))] }
        case "bigRound":
            return both { s in [nCircle(s * w * 0.72, -h * 0.9, 30, S(c)), nCircle(s * w * 0.72, -h * 0.9, 18, .f(ic))] }
        case "fluffy":
            return both { s in [nCircle(s * w * 0.84, -h * 0.82, 28, S(c)), nCircle(s * w * 0.88, -h * 0.8, 15, .f(ic))] }
        case "side":
            return both { s in [nCircle(s * (w + 3), -h * 0.58, 17, S(c)), nCircle(s * (w + 5), -h * 0.58, 8.5, .f(ic))] }
        case "elephant":
            return both { s in [nEllipse(s * (w + 10), -h * 0.6, 34, 42, S(c)), nEllipse(s * (w + 14), -h * 0.6, 21, 29, .f(ic))] }
        default:
            return []
        }
    }

    /// floppy ears are drawn in front of the body
    private static func earsFront(_ d: AnimalDef, _ w: Double, _ h: Double) -> [VNode] {
        let c = d.earColor ?? sh(d.body, -0.2)
        if d.ears == "floppy" {
            return both { s in [nEllipse(s * (w - 2), -h * 0.7, 16, 30, S(c)).moved(rotAbout(s * 16, s * (w - 2), -h * 0.7))] }
        }
        if d.ears == "goat" {
            return both { s in [nEllipse(s * (w + 6), -h * 0.72, 26, 12, S(c)).moved(rotAbout(s * 22, s * (w + 6), -h * 0.72))] }
        }
        return []
    }

    // MARK: behind-the-body extras

    private static func arm(_ s: Double, _ kids: [VNode]) -> VNode {
        nGroup(kids).looping(s < 0 ? Loops.waveL : Loops.wave, idle: true)
    }

    private static func back(_ d: AnimalDef, _ w: Double, _ h: Double) -> [VNode] {
        var out: [VNode] = []
        let a = d.accent ?? sh(d.body, -0.25)
        for x in d.back {
            switch x {
            case "tailFluffy":
                let p = "M\(w * 0.55),\(-h * 0.22) C\(w + 58),\(-h * 0.16) \(w + 62),\(-h * 0.86) \(w + 26),\(-h * 1.02) " +
                    "C\(w + 20),\(-h * 0.76) \(w + 8),\(-h * 0.52) \(w * 0.7),\(-h * 0.46) Z"
                let tail = nGroup([
                    nPath(p, .f(d.tailColor ?? d.body)),
                    nGroup([nCircle(w + 30, -h * 0.98, 26, .f(d.tailTip ?? "#fdf3e4"))], clip: SVGPath.parse(p)),
                    nPath(p, St.o(6)),
                ])
                out.append(tail.looping(Loops.wag, idle: true))
            case "tailStriped":
                let p = "M\(w * 0.55),\(-h * 0.2) C\(w + 52),\(-h * 0.18) \(w + 56),\(-h * 0.84) \(w + 24),\(-h * 0.98) " +
                    "C\(w + 18),\(-h * 0.74) \(w + 8),\(-h * 0.5) \(w * 0.7),\(-h * 0.44) Z"
                var stripes: [VNode] = []
                for i in 0..<4 {
                    stripes.append(nRect(w - 20, -h * (0.42 + Double(i) * 0.17), 120, 12, .f(d.tailStripe ?? a))
                        .moved(rotAbout(-28, w + 20, -h * 0.5)))
                }
                let tail = nGroup([nPath(p, .f(d.tailColor ?? d.body)), nGroup(stripes, clip: SVGPath.parse(p)), nPath(p, St.o(6))])
                out.append(tail.looping(Loops.wag, idle: true))
            case "tailSquirrel":
                let p = "M\(w * 0.45),\(-h * 0.14) C\(w + 78),\(-h * 0.08) \(w + 74),\(-h * 1.2) \(w + 16),\(-h * 1.18) " +
                    "C\(w - 12),\(-h * 1.16) \(w - 6),\(-h * 0.9) \(w + 16),\(-h * 0.9) " +
                    "C\(w + 34),\(-h * 0.88) \(w + 22),\(-h * 0.5) \(w * 0.62),\(-h * 0.42) Z"
                let tc = d.tailColor ?? d.body
                let tail = nGroup([
                    nPath(p, S(tc)),
                    nPath("M\(w + 10),\(-h * 0.35) C\(w + 40),\(-h * 0.45) \(w + 44),\(-h * 0.85) \(w + 22),\(-h * 1.05)", St.line(sh(tc, 0.25), 5)),
                ])
                out.append(tail.looping(Loops.wag, idle: true))
            case "tailThin":
                out.append(nGroup(tube("M\(w * 0.6),-12 C\(w + 30),-6 \(w + 40),-40 \(w + 22),\(-h * 0.42) C\(w + 10),\(-h * 0.55) \(w + 32),\(-h * 0.62) \(w + 36),\(-h * 0.52)",
                                       d.tailColor ?? "#f4a7b0", 6)).looping(Loops.wag, idle: true))
            case "tailCurl":
                out.append(nGroup(tube("M\(w - 6),\(-h * 0.3) C\(w + 12),\(-h * 0.26) \(w + 22),\(-h * 0.44) \(w + 10),\(-h * 0.5) C\(w),\(-h * 0.54) \(w + 2),\(-h * 0.38) \(w + 16),\(-h * 0.36)",
                                       d.body, 7)).looping(Loops.wag, idle: true))
            case "tailDino":
                let p = "M\(w * 0.5),-6 C\(w + 30),-4 \(w + 50),-20 \(w + 56),\(-h * 0.34) C\(w + 40),\(-h * 0.28) \(w + 20),\(-h * 0.36) \(w * 0.6),\(-h * 0.4) Z"
                out.append(nGroup([nPath(p, S(d.body))]).looping(Loops.wag, idle: true))
            case "batWings":
                out += both { s in [arm(s, [nPath("M\(s * w * 0.6),\(-h * 0.72) Q\(s * (w + 44)),\(-h * 1.02) \(s * (w + 52)),\(-h * 0.52) " +
                    "Q\(s * (w + 36)),\(-h * 0.5) \(s * (w + 28)),\(-h * 0.36) Q\(s * (w + 16)),\(-h * 0.42) \(s * w * 0.8),\(-h * 0.24) Z", S(d.wingColor ?? a))])] }
            case "dragonWings":
                out += both { s in [arm(s, [nPath("M\(s * w * 0.55),\(-h * 0.7) Q\(s * (w + 30)),\(-h * 1.05) \(s * (w + 40)),\(-h * 0.78) " +
                    "Q\(s * (w + 26)),\(-h * 0.66) \(s * (w + 26)),\(-h * 0.5) Q\(s * (w + 10)),\(-h * 0.5) \(s * w * 0.8),\(-h * 0.36) Z", S(d.wingColor ?? a))])] }
            case "mane":
                let cy = -h * 0.6, R = w + 6, mc = d.maneColor ?? a
                for i in 0..<14 {
                    let t = Double(i) / 14 * .pi * 2
                    out.append(nCircle(cos(t) * R, cy + sin(t) * R * 0.92, 20, S(mc)))
                }
                out.append(nEllipse(0, cy, R, R * 0.92, .f(mc)))
            case "quills":
                let cy = -h * 0.52, n = 20
                var pts: [Pt] = []
                for i in 0..<(n * 2) {
                    let t = Double(i) / Double(n * 2) * .pi * 2 - .pi / 2
                    let r = i % 2 == 0 ? 1.32 : 1.08
                    pts.append((cos(t) * w * r, cy + sin(t) * h * 0.56 * r))
                }
                out.append(nPolygon(pts, S(d.quillColor ?? a)))
            case "fleece":
                let cy = -h * 0.5, fc = d.fleeceColor ?? "#fdfaf3"
                for i in 0..<16 {
                    let t = Double(i) / 16 * .pi * 2
                    out.append(nCircle(cos(t) * (w + 4), cy + sin(t) * (h * 0.52), 19, S(fc)))
                }
                out.append(nEllipse(0, cy, w + 4, h * 0.52, .f(fc)))
            case "turtleShell":
                let p = "M\(-w - 20),\(-h * 0.2) C\(-w - 24),\(-h * 1.0) \(w + 24),\(-h * 1.0) \(w + 20),\(-h * 0.2) Q0,\(-h * 0.08) \(-w - 20),\(-h * 0.2) Z"
                let spot = d.shellSpot ?? a
                out.append(nPath(p, .f(d.shellColor ?? a)))
                out.append(nGroup([
                    nCircle(-w - 6, -h * 0.5, 16, .f(spot)), nCircle(w + 6, -h * 0.5, 16, .f(spot)),
                    nCircle(-w + 8, -h * 0.82, 14, .f(spot)), nCircle(w - 8, -h * 0.82, 14, .f(spot)),
                ], clip: SVGPath.parse(p)))
                out.append(nPath(p, St.o(6)))
            case "snailShell":
                let cx = w * 0.45, cy = -h * 0.72, r = h * 0.5
                out.append(nCircle(cx, cy, r, S(d.shellColor ?? a)))
                out.append(nPath("M\(cx),\(cy) m-4,2 a6,6 0 1 1 10,-6 a14,14 0 1 1 -20,14 a24,24 0 1 1 36,-26 a34,34 0 1 1 -48,40",
                                 St.line(d.shellSpot ?? O, 6)))
            case "gills":
                let gc = d.gillColor ?? a
                out += both { s in
                    (0..<3).flatMap { k -> [VNode] in
                        let kk = Double(k)
                        return tube("M\(s * w * 0.7),\(-h * (0.78 - kk * 0.12)) Q\(s * (w + 14)),\(-h * (0.86 - kk * 0.12)) \(s * (w + 26)),\(-h * (0.94 - kk * 0.15))", gc, 9)
                    }
                }
            case "spikes":
                for (i, x) in [-26.0, 0, 26].enumerated() {
                    let lift = abs(x) * 0.15
                    out += roundedTri((x - 13, -h * 0.9 + lift), (x, -h * 1.12 - (i == 1 ? 8 : 0) + lift), (x + 13, -h * 0.9 + lift), d.spikeColor ?? a)
                }
            case "horns":
                out += both { s in tube("M\(s * w * 0.3),\(-h * 0.88) Q\(s * w * 0.42),\(-h * 1.08) \(s * w * 0.62),\(-h * 1.1)", d.hornColor ?? a, 9) }
            case "nubs":
                out += both { s in tube("M\(s * w * 0.36),\(-h * 0.9) L\(s * w * 0.44),\(-h * 1.05)", d.hornColor ?? a, 10) }
            case "antennae":
                out += both { s in [
                    nPath("M\(s * w * 0.18),\(-h * 0.92) Q\(s * w * 0.2),\(-h * 1.16) \(s * w * 0.46),\(-h * 1.24)", St.line(O, 5)),
                    nCircle(s * w * 0.46, -h * 1.24, 7, S4(d.antennaColor ?? O)),
                ] }
            case "eyeStalks":
                out += both { s in [
                    nPath("M\(s * w * 0.16),\(-h * 0.9) L\(s * w * 0.36),\(-h * 1.18)", St.line(O, 15)),
                    nPath("M\(s * w * 0.16),\(-h * 0.9) L\(s * w * 0.36),\(-h * 1.18)", St.line(d.body, 7)),
                    nCircle(s * w * 0.36, -h * 1.2, 11, S4(d.body)),
                ] }
            case "frogBumps":
                out += both { s in [nCircle(s * w * 0.46, -h * 0.92, 21, S(d.body))] }
            default:
                break
            }
        }
        return out
    }

    // MARK: markings (clipped inside the body)

    private static func markings(_ d: AnimalDef, _ w: Double, _ h: Double, _ fy: Double, _ ex: Double) -> [VNode] {
        var out: [VNode] = []
        let m = d.markColor ?? sh(d.body, -0.3)
        let fc = d.faceColor ?? "#fdf3e4"
        let solid = St(fill: m, stroke: m, width: 3, join: .round)
        for x in d.marks {
            switch x {
            case "stripes":
                for s in [-1.0, 1] {
                    for k in 0..<3 {
                        let y = -h * (0.3 + Double(k) * 0.17)
                        out.append(nPath("M\(s * (w + 6)),\(y - 7) L\(s * (w - 22)),\(y) L\(s * (w + 6)),\(y + 7) Z", solid))
                    }
                }
                for x in [-14.0, 0, 14] {
                    out.append(nPath("M\(x - 6),\(-h) L\(x),\(-h * (x != 0 ? 0.88 : 0.84)) L\(x + 6),\(-h) Z", solid))
                }
            case "spots":
                let pts = d.spotPts ?? [(-0.55, 0.82, 9), (0.6, 0.78, 7), (-0.7, 0.4, 8), (0.66, 0.36, 10), (0.2, 0.95, 6), (-0.25, 0.22, 6)]
                for (px, py, r) in pts { out.append(nCircle(px * w, -py * h, r, .f(m))) }
            case "patches":
                out.append(nEllipse(-w * 0.72, -h * 0.8, 28, 22, .f(m)).moved(rotAbout(-20, -w * 0.72, -h * 0.8)))
                out.append(nEllipse(w * 0.82, -h * 0.32, 24, 30, .f(m)))
                out.append(nEllipse(-w * 0.3, -h * 0.08, 18, 12, .f(m)))
            case "mask":
                out.append(nPath("M\(-w - 4),\(fy - 12) Q0,\(fy - 2) \(w + 4),\(fy - 12) L\(w + 4),\(fy + 9) Q\(w * 0.3),\(fy + 12) 0,\(fy + 4) Q\(-w * 0.3),\(fy + 12) \(-w - 4),\(fy + 9) Z", .f(m)))
            case "eyePatches":
                out += both { s in [nEllipse(s * w * ex, fy + 2, 15, 18, .f(m)).moved(rotAbout(s * -28, s * w * ex, fy + 2))] }
            case "eyePatch":
                out.append(nEllipse(w * ex + 2, fy - 1, 17, 16, .f(m)))
            case "faceMask":
                out += both { s in [nCircle(s * w * 0.3, fy + 4, w * 0.42, .f(fc))] }
            case "faceHeart":
                out += both { s in [nCircle(s * w * 0.3, fy, w * 0.38, .f(fc))] }
                out.append(nEllipse(0, fy + 20, w * 0.52, 22, .f(fc)))
            case "lowerFace":
                out.append(nPath("M\(-w - 4),\(fy + 4) Q\(-w * 0.35),\(fy + 2) 0,\(fy + 22) Q\(w * 0.35),\(fy + 2) \(w + 4),\(fy + 4) L\(w + 4),4 L\(-w - 4),4 Z", .f(fc)))
            case "faceOval":
                out.append(nEllipse(0, fy + 6, w * 0.74, h * 0.27, .f(fc)))
            case "muzzlePatch":
                out.append(nEllipse(0, fy + 16, w * 0.56, 22, .f(fc)))
            case "redPanda":
                out.append(nEllipse(0, fy + 18, w * 0.5, 17, .f(fc)))
                out += both { s in [
                    nCircle(s * w * 0.4, fy - 17, 6, .f(fc)),
                    nEllipse(s * w * 0.72, fy + 14, 13, 16, .f(fc)),
                    nPath("M\(s * w * ex),\(fy + 6) Q\(s * w * 0.42),\(fy + 24) \(s * w * 0.3),\(fy + 36)", St.line(m, 8)),
                ] }
            case "slothEyes":
                out += both { s in [nEllipse(s * w * ex, fy + 4, 16, 9, .f(m)).moved(rotAbout(s * 22, s * w * ex, fy + 4))] }
            case "cap":
                out.append(nEllipse(0, -h * 1.08, w * 0.85, h * 0.26, .f(m)))
            case "fawnSpots":
                for (px, py) in [(-0.75, 0.62), (-0.6, 0.42), (-0.82, 0.3), (0.75, 0.6), (0.62, 0.4), (0.84, 0.28), (0.0, 0.98)] {
                    out.append(nCircle(px * w, -py * h, 5.5, .f(m)))
                }
            case "owlBelly":
                for (x, y) in [(-14.0, 0.34), (14, 0.34), (0, 0.22), (-22, 0.16), (22, 0.16)] {
                    out.append(nPath("M\(x - 6),\(-y * h) Q\(x),\(-y * h + 7) \(x + 6),\(-y * h)", St.line(m, 4)))
                }
            case "plastron":
                out.append(nPath("M-30,\(-h * 0.3) L30,\(-h * 0.3) M-34,\(-h * 0.16) L34,\(-h * 0.16) M0,\(-h * 0.48) L0,0", St.line(m, 4)))
            default:
                break
            }
        }
        return out
    }

    // MARK: face

    private static func eyes(_ d: AnimalDef, _ w: Double, _ h: Double, _ fy: Double, _ ex: Double) -> [VNode] {
        if d.eyes == "none" { return [] }
        let ey = d.eyesOnBumps ? -h * 0.93 : fy
        let exx = d.eyesOnBumps ? 0.46 : ex
        if d.eyes == "stalk" {
            return both { s in [
                nEllipse(s * w * 0.36, -h * 1.2, 5.5, 6.5, .f(O)),
                nCircle(s * w * 0.36 - 1.8, -h * 1.2 - 2.4, 2, .f("#fff")),
            ] }
        }
        return both { s in
            let x = s * w * exx
            switch d.eyes {
            case "big":
                return [nCircle(x, ey, 10, .f(O)), nCircle(x - 3, ey - 4, 3.6, .f("#fff")), nCircle(x + 3, ey + 3, 1.6, .f("#fff"))]
            case "ringed":
                return [nCircle(x, ey, 9, .f("#fdfaf3")), nEllipse(x, ey, 5.5, 6.5, .f(O)), nCircle(x - 2, ey - 2.5, 2, .f("#fff"))]
            case "happy":
                return [nPath("M\(x - 7),\(ey + 2) Q\(x),\(ey - 8) \(x + 7),\(ey + 2)", St.line(O, 5))]
            case "tiny":
                return [nEllipse(x, ey, 3.6, 4.2, .f(O))]
            default:
                return [nEllipse(x, ey, 6.5, 8, .f(O)), nCircle(x - 2, ey - 3, 2.5, .f("#fff"))]
            }
        }
    }

    private static func muzzle(_ d: AnimalDef, _ w: Double, _ h: Double, _ fy: Double) -> [VNode] {
        let mc = d.muzzleColor ?? sh(d.body, 0.5)
        switch d.muzzle {
        case "snout":
            return [nEllipse(0, fy + 16, w * 0.34, 16, .f(mc))]
        case "pig":
            let rx = d.snoutW ?? 17
            return [nEllipse(0, fy + 16, rx, 12, S4(mc)), nEllipse(-rx * 0.34, fy + 16, 3, 4.5, .f(O)), nEllipse(rx * 0.34, fy + 16, 3, 4.5, .f(O))]
        case "beak":
            return [nPath("M-9,\(fy + 7) L9,\(fy + 7) L0,\(fy + 19) Z", S4(mc))]
        case "bill":
            return [nEllipse(0, fy + 14, 17, 9, S4(mc)), nPath("M-11,\(fy + 14) Q0,\(fy + 18) 11,\(fy + 14)", St.line(O, 3))]
        case "trunk":
            return tube("M0,\(fy + 6) C0,\(fy + 28) -2,\(fy + 38) -16,\(fy + 42)", d.body, 17)
        case "capy":
            return [nRect(-27, fy + 2, 54, 32, rx: 16, .f(mc)), nEllipse(-9, fy + 11, 3, 4.5, .f(O)), nEllipse(9, fy + 11, 3, 4.5, .f(O))]
        default:
            return []
        }
    }

    private static func nose(_ d: AnimalDef, _ fy: Double) -> [VNode] {
        let nc = d.noseColor ?? O
        let ny = fy + (d.muzzle == "snout" ? 9 : 8)
        switch d.nose {
        case "none":
            return []
        case "big":
            return [nEllipse(0, fy + 11, 13, 10, nc == O ? .f(nc) : S4(nc)), nEllipse(-4, fy + 7, 4, 2.5, St.f("#ffffff").op(0.7))]
        default:
            return [nPath("M-6.5,\(ny - 2) Q0,\(ny - 5) 6.5,\(ny - 2) Q0,\(ny + 7) -6.5,\(ny - 2) Z", St(fill: nc, stroke: nc, width: 3, join: .round))]
        }
    }

    private static func mouth(_ d: AnimalDef, _ fy: Double) -> [VNode] {
        let my = fy + (d.muzzle == "snout" ? 17 : d.nose == "big" ? 25 : d.muzzle == "capy" ? 24 : 16)
        switch d.mouth {
        case "none":
            return []
        case "u":
            return [nPath("M-6,\(my) Q0,\(my + 7) 6,\(my)", St.line(O, 4))]
        case "wide":
            return [nPath("M-16,\(my - 2) Q0,\(my + 10) 16,\(my - 2)", St.line(O, 4))]
        case "open":
            return [nPath("M-7,\(my) Q0,\(my + 13) 7,\(my) Z", S4("#c4505a"))]
        case "fang":
            return [nPath("M-7,\(my) Q-3.5,\(my + 5) 0,\(my) Q3.5,\(my + 5) 7,\(my)", St.line(O, 4)),
                    nPath("M2,\(my + 2) L4.5,\(my + 8) L6.5,\(my + 1) Z", St.o(2).filled("#ffffff"))]
        default: // "w"
            return [nPath("M-7.5,\(my) Q-3.75,\(my + 5.5) 0,\(my) Q3.75,\(my + 5.5) 7.5,\(my)", St.line(O, 4))]
        }
    }

    private static func whiskers(_ d: AnimalDef, _ w: Double, _ fy: Double) -> [VNode] {
        guard d.whiskers else { return [] }
        return both { s in [nPath("M\(s * w * 0.46),\(fy + 13) L\(s * w * 0.86),\(fy + 8) M\(s * w * 0.46),\(fy + 19) L\(s * w * 0.86),\(fy + 21)", St.line(O, 3))] }
    }

    private static func arms(_ d: AnimalDef, _ w: Double, _ h: Double) -> [VNode] {
        let c = d.armColor ?? sh(d.body, -0.06)
        switch d.arms {
        case "none":
            return []
        case "wing":
            return both { s in [arm(s, [nPath("M\(s * (w - 12)),\(-h * 0.6) Q\(s * (w + 18)),\(-h * 0.46) \(s * (w - 2)),\(-h * 0.16) Q\(s * (w - 18)),\(-h * 0.34) \(s * (w - 12)),\(-h * 0.6) Z", S(c))])] }
        case "flipper":
            return both { s in [arm(s, [nEllipse(s * (w - 2), -h * 0.34, 10, 22, S(c)).moved(rotAbout(s * -30, s * (w - 2), -h * 0.34))])] }
        default:
            return both { s in [arm(s, [nEllipse(s * (w - 9), -h * 0.3, 11, 14, S(c)).moved(rotAbout(s * -25, s * (w - 9), -h * 0.3))])] }
        }
    }

    private static func feet(_ d: AnimalDef, _ w: Double) -> [VNode] {
        let c = d.feetColor ?? sh(d.body, -0.12)
        switch d.feet {
        case "none":
            return []
        case "bird":
            return both { s in
                let x = s * w * 0.32
                let p = "M\(x - 10),2 L\(x),-10 L\(x + 10),2 M\(x),-10 L\(x),3"
                return [nPath(p, St.line(O, 10)), nPath(p, St.line(d.feetColor ?? "#f7a531", 4))]
            }
        default:
            return both { s in [nEllipse(s * w * 0.42, -4, 17, 9.5, S(c))] }
        }
    }

    private static func front(_ d: AnimalDef, _ w: Double, _ h: Double) -> [VNode] {
        var out: [VNode] = []
        for x in d.front {
            switch x {
            case "tuft":
                let t = -h * 0.95, c = d.tuftColor ?? sh(d.body, -0.08)
                out.append(nPath("M0,\(t) C-3,\(t - 22) 10,\(t - 30) 14,\(t - 24) C6,\(t - 22) 4,\(t - 10) 0,\(t) Z", S4(c)))
                out.append(nPath("M0,\(t) C-6,\(t - 14) -18,\(t - 18) -20,\(t - 10) C-12,\(t - 12) -6,\(t - 6) 0,\(t) Z", S4(c)))
            case "horn":
                let t = -h * 0.94
                out.append(nPath("M-11,\(t + 4) L0,\(t - 46) L11,\(t + 4) Z", S(d.hornColor ?? "#ffd86b")))
                out.append(nPath("M-7,\(t - 8) L6,\(t - 14) M-4,\(t - 22) L4,\(t - 27)", St.line(O, 3.5)))
            case "pastelMane":
                let cols = ["#f7a8c8", "#c5a8f0", "#9fd8e8", "#ffe08a"]
                for (i, c) in cols.enumerated() {
                    let di = Double(i)
                    out.append(nCircle(-w * 0.55 + di * 13, -h * 0.9 - Double(i % 2) * 6, 15 - di, S4(c)))
                }
            case "fleeceTuft":
                for x in [-16.0, 0, 16] {
                    out.append(nCircle(x, -h * 0.97 - (x != 0 ? 0 : 6), 14, S4(d.fleeceColor ?? "#fdfaf3")))
                }
            case "curl":
                let t = -h * 0.95
                out += tube("M0,\(t + 4) C-2,\(t - 14) 14,\(t - 22) 16,\(t - 10) C17,\(t - 2) 7,\(t - 2) 9,\(t - 10)", d.tuftColor ?? sh(d.body, -0.08), 6)
            case "leaf":
                out.append(nPath("M0,\(-h * 0.97) L0,\(-h * 1.12)", St.line(O, 5)))
                out.append(nPath("M0,\(-h * 1.1) C-6,\(-h * 1.3) -26,\(-h * 1.28) -28,\(-h * 1.2) C-20,\(-h * 1.12) -6,\(-h * 1.1) 0,\(-h * 1.1) Z", S4("#a9d36b")))
                out.append(nPath("M0,\(-h * 1.1) C6,\(-h * 1.28) 24,\(-h * 1.26) 26,\(-h * 1.18) C18,\(-h * 1.1) 6,\(-h * 1.1) 0,\(-h * 1.1) Z", S4("#a9d36b")))
            case "claws":
                out += both { s in [nPath("M\(s * (w - 14)),\(-h * 0.2) l\(s * -3),8 M\(s * (w - 8)),\(-h * 0.2) l0,9 M\(s * (w - 2)),\(-h * 0.22) l\(s * 3),8", St.line(O, 3))] }
            default:
                break
            }
        }
        return out
    }

    /// Draw one animal. The returned node is tagged "critter".
    static func render(_ d: AnimalDef) -> VNode {
        let dims = SHAPES[d.shape] ?? SHAPES["round"]!
        let w = dims.w, h = dims.h
        let fy = -h * (d.faceY ?? 0.56)
        let ex = d.eyeX ?? 0.36
        let bp = bodyPath(w, h)
        let bodyClip = SVGPath.parse(bp)

        var cheeks: [VNode] = []
        if d.cheeks {
            let cc = d.cheekColor ?? "#f48f97"
            cheeks = both { s in [nEllipse(s * w * 0.62, fy + 15, 9, 5.5, St.f(cc).op(0.7))] }
        }
        var inside: [VNode] = []
        if let b = d.belly { inside.append(nEllipse(0, -h * 0.24, w * 0.62, h * 0.27, .f(b))) }
        inside += markings(d, w, h, fy, ex)
        inside.append(nPath(bp, St.line("#ffffff", 10).so(0.25)).moved(tr(-6, -6)))

        let face = nGroup(cheeks + muzzle(d, w, h, fy) + whiskers(d, w, fy) + nose(d, fy) + mouth(d, fy) +
                          [nGroup(eyes(d, w, h, fy, ex)).looping(Loops.blink(4.2))])

        let squash = nGroup(
            [nGroup(back(d, w, h)),
             nGroup(ears(d, w, h)).looping(Loops.ears, idle: true),
             nPath(bp, .f(d.body)),
             nGroup(inside, clip: bodyClip),
             nPath(bp, St.o(6)),
             nGroup(earsFront(d, w, h))]
                + front(d, w, h) + arms(d, w, h) + [face] + feet(d, w)
        ).looping(Loops.critterHop, idle: true)

        let shadow = nEllipse(0, 2, w + 6, 10, St.f(O).op(0.18)).looping(Loops.shadowPulse, idle: true)
        return nGroup([shadow, squash]).tagged("critter")
    }

    /// A framed photo "friend" that hatches like an animal.
    static func renderPhoto(_ image: UIImage) -> VNode {
        let pink = "#f6b3bf"
        let earsG = nGroup(both { s in [nCircle(s * 44, -128, 18, S("#f3c98b")), nCircle(s * 44, -128, 8, .f(pink))] })
            .looping(Loops.ears, idle: true)
        let photo = VNode(.image(image, CGRect(x: -62, y: -132, width: 124, height: 124)))
        photo.clip = Path(ellipseIn: CGRect(x: -62, y: -132, width: 124, height: 124))
        let armsG = both { s in [arm(s, [nEllipse(s * 62, -30, 12, 15, S("#f3c98b")).moved(rotAbout(s * -25, s * 62, -30))])] }
        let feetG = both { s in [nEllipse(s * 26, -4, 17, 9.5, S("#e9b673"))] }
        let squash = nGroup([
            earsG,
            nCircle(0, -70, 64, .f("#fdf3e4")),
            photo,
            nCircle(0, -70, 62, St.line("#f3c98b", 9)),
            nCircle(0, -70, 67, St.o(6)),
        ] + armsG + feetG).looping(Loops.critterHop, idle: true)
        let shadow = nEllipse(0, 2, 66, 10, St.f(O).op(0.18)).looping(Loops.shadowPulse, idle: true)
        return nGroup([shadow, squash]).tagged("critter")
    }

    // MARK: the 40 friends

    static let CREAM = "#fdf3e4", WHITE = "#fdfaf3", PINK = "#f6b3bf", BEAK = "#f7a531"

    static let list: [AnimalDef] = [
        AnimalDef("chick", "Chick", "#ffd84d") { $0.belly = "#ffe98c"; $0.front = ["tuft"]; $0.arms = "wing"; $0.feet = "bird"; $0.muzzle = "beak"; $0.muzzleColor = BEAK; $0.nose = "none"; $0.mouth = "none"; $0.armColor = "#ffcb2e" },
        AnimalDef("duckling", "Duckling", "#f9e27a") { $0.shape = "wide"; $0.belly = "#fff4c2"; $0.front = ["curl"]; $0.tuftColor = "#f0c94a"; $0.arms = "wing"; $0.feet = "bird"; $0.feetColor = "#f08a3c"; $0.muzzle = "bill"; $0.muzzleColor = "#f08a3c"; $0.nose = "none"; $0.mouth = "none"; $0.armColor = "#f0cf5a"; $0.eyes = "happy"; $0.cheekColor = "#f7a07a" },
        AnimalDef("penguin", "Penguin", "#3d4e6e") { $0.shape = "tall"; $0.belly = WHITE; $0.marks = ["faceMask"]; $0.faceColor = WHITE; $0.arms = "flipper"; $0.feet = "bird"; $0.muzzle = "beak"; $0.muzzleColor = BEAK; $0.nose = "none"; $0.mouth = "none" },
        AnimalDef("owl", "Owl", "#a8754f") { $0.belly = "#e8c9a0"; $0.ears = "tufts"; $0.marks = ["faceMask", "owlBelly"]; $0.faceColor = "#f3e2c2"; $0.markColor = "#b98a62"; $0.eyes = "big"; $0.arms = "wing"; $0.feet = "bird"; $0.muzzle = "beak"; $0.muzzleColor = BEAK; $0.nose = "none"; $0.mouth = "none" },
        AnimalDef("hamster", "Hamster", "#eaa865") { $0.shape = "wide"; $0.ears = "round"; $0.earInner = PINK; $0.marks = ["lowerFace"]; $0.faceColor = CREAM; $0.mouth = "w" },
        AnimalDef("bunny", "Bunny", "#f3ece3") { $0.ears = "long"; $0.earInner = PINK; $0.muzzle = "snout"; $0.muzzleColor = WHITE; $0.noseColor = "#f18ea0"; $0.belly = WHITE },
        AnimalDef("fox", "Fox", "#ef8b3a") { $0.ears = "pointy"; $0.earInner = "#4a3030"; $0.marks = ["lowerFace"]; $0.faceColor = CREAM; $0.back = ["tailFluffy"]; $0.tailColor = "#ef8b3a"; $0.feetColor = "#5a3a30"; $0.armColor = "#5a3a30" },
        AnimalDef("kitten", "Kitten", "#b1aaa6") { $0.ears = "pointy"; $0.earInner = PINK; $0.marks = ["stripes"]; $0.markColor = "#858079"; $0.whiskers = true; $0.noseColor = "#f18ea0"; $0.back = ["tailThin"]; $0.tailColor = "#b1aaa6" },
        AnimalDef("bearcub", "Bear Cub", "#9a6845") { $0.ears = "round"; $0.earInner = "#d4a27c"; $0.muzzle = "snout"; $0.muzzleColor = "#ddb48c"; $0.belly = "#c89a72" },
        AnimalDef("panda", "Panda", WHITE) { $0.ears = "round"; $0.earColor = "#2e2a2b"; $0.earInner = "#2e2a2b"; $0.marks = ["eyePatches"]; $0.markColor = "#2e2a2b"; $0.eyes = "ringed"; $0.armColor = "#2e2a2b"; $0.feetColor = "#2e2a2b" },
        AnimalDef("frog", "Frog", "#7cc26a") { $0.shape = "wide"; $0.belly = "#c9e6a0"; $0.back = ["frogBumps"]; $0.eyesOnBumps = true; $0.mouth = "wide"; $0.nose = "none"; $0.feetColor = "#68ad58" },
        AnimalDef("turtle", "Turtle", "#a5d47f") { $0.belly = "#f2e3a5"; $0.marks = ["plastron"]; $0.markColor = "#d8c57f"; $0.back = ["turtleShell"]; $0.shellColor = "#4f8f56"; $0.shellSpot = "#3c7444"; $0.mouth = "u"; $0.nose = "none" },
        AnimalDef("dino", "Dino", "#76c3a6") { $0.belly = "#d8f0c8"; $0.back = ["spikes", "tailDino"]; $0.spikeColor = "#f2a65a"; $0.marks = ["spots"]; $0.markColor = "#5aa98b"; $0.spotPts = [(-0.7, 0.75, 9), (0.72, 0.7, 8), (-0.75, 0.48, 6), (0.78, 0.45, 7)]; $0.mouth = "open"; $0.nose = "none" },
        AnimalDef("dragon", "Dragon", "#a98ad8") { $0.belly = "#f6e3b4"; $0.back = ["dragonWings", "horns"]; $0.wingColor = "#f29fc0"; $0.hornColor = "#f6e3b4"; $0.mouth = "open"; $0.nose = "none"; $0.cheekColor = "#f29fc0" },
        AnimalDef("mouse", "Mouse", "#b6aeb0") { $0.shape = "small"; $0.ears = "bigRound"; $0.earInner = PINK; $0.whiskers = true; $0.noseColor = "#f18ea0"; $0.back = ["tailThin"]; $0.belly = "#d9d3d4" },
        AnimalDef("piglet", "Piglet", "#f7b6c2") { $0.shape = "wide"; $0.ears = "pointy"; $0.earInner = "#ef8fa4"; $0.muzzle = "pig"; $0.muzzleColor = "#f394aa"; $0.nose = "none"; $0.back = ["tailCurl"]; $0.cheekColor = "#ef7f97" },
        AnimalDef("koala", "Koala", "#a5aab3") { $0.ears = "fluffy"; $0.earInner = "#eef0f3"; $0.nose = "big"; $0.belly = "#e3e6ea" },
        AnimalDef("raccoon", "Raccoon", "#9c9a9b") { $0.ears = "pointy"; $0.earInner = "#4a4446"; $0.marks = ["mask"]; $0.markColor = "#4a4446"; $0.eyes = "ringed"; $0.muzzle = "snout"; $0.muzzleColor = "#f1ebe6"; $0.back = ["tailStriped"]; $0.tailStripe = "#4a4446"; $0.belly = "#cfcccd" },
        AnimalDef("tiger", "Tiger Cub", "#f39a3d") { $0.ears = "round"; $0.earInner = "#fbe3c6"; $0.marks = ["stripes"]; $0.markColor = "#4a2b22"; $0.muzzle = "snout"; $0.muzzleColor = CREAM; $0.belly = CREAM },
        AnimalDef("lion", "Lion Cub", "#f3b64e") { $0.ears = "round"; $0.earInner = "#fbe1b0"; $0.back = ["mane"]; $0.maneColor = "#c9682f"; $0.muzzle = "snout"; $0.muzzleColor = "#fbe5b8" },
        AnimalDef("calf", "Calf", WHITE) { $0.ears = "goat"; $0.earColor = "#f1e4e4"; $0.marks = ["patches"]; $0.markColor = "#3d3536"; $0.back = ["nubs"]; $0.hornColor = "#f3e2b8"; $0.muzzle = "pig"; $0.muzzleColor = "#f6b5bd"; $0.snoutW = 24; $0.nose = "none" },
        AnimalDef("lamb", "Lamb", "#f5dcc8") { $0.back = ["fleece"]; $0.fleeceColor = WHITE; $0.front = ["fleeceTuft"]; $0.ears = "floppy"; $0.earColor = "#efcab0"; $0.mouth = "u"; $0.noseColor = "#c98a7a" },
        AnimalDef("fawn", "Fawn", "#c98a55") { $0.ears = "tall"; $0.earInner = "#f3d2b5"; $0.marks = ["fawnSpots"]; $0.markColor = "#fbefdc"; $0.muzzle = "snout"; $0.muzzleColor = "#f3dcc2"; $0.belly = "#efd2ae" },
        AnimalDef("hedgehog", "Hedgehog", "#f2d5b0") { $0.shape = "small"; $0.back = ["quills"]; $0.quillColor = "#8a5d3f"; $0.ears = "tiny"; $0.nose = "big" },
        AnimalDef("otter", "Otter", "#8e6648") { $0.shape = "tall"; $0.ears = "tiny"; $0.marks = ["muzzlePatch"]; $0.faceColor = "#e8d2b2"; $0.whiskers = true; $0.belly = "#c79c76"; $0.back = ["tailDino"] },
        AnimalDef("seal", "Seal Pup", "#e1e8f0") { $0.shape = "wide"; $0.marks = ["spots"]; $0.markColor = "#cad3de"; $0.whiskers = true; $0.arms = "flipper"; $0.feet = "none"; $0.nose = "big"; $0.eyes = "big" },
        AnimalDef("axolotl", "Axolotl", "#f8b5c8") { $0.belly = "#fde0e8"; $0.back = ["gills"]; $0.gillColor = "#e96f96"; $0.mouth = "wide"; $0.nose = "none"; $0.cheekColor = "#ee7d9f" },
        AnimalDef("bat", "Bat", "#6a5679") { $0.belly = "#9a86aa"; $0.ears = "bat"; $0.earInner = "#d4a8d0"; $0.back = ["batWings"]; $0.wingColor = "#4d3c5c"; $0.arms = "none"; $0.mouth = "fang"; $0.noseColor = "#2a1f30" },
        AnimalDef("mole", "Mole", "#5e5459") { $0.ears = "none"; $0.eyes = "happy"; $0.nose = "big"; $0.noseColor = "#f49ab2"; $0.arms = "paw"; $0.armColor = "#f49ab2"; $0.front = ["claws"]; $0.feetColor = "#f49ab2"; $0.cheeks = false },
        AnimalDef("monkey", "Monkey", "#9a6a48") { $0.ears = "side"; $0.earInner = "#ecc9a2"; $0.marks = ["faceHeart"]; $0.faceColor = "#ecc9a2"; $0.back = ["tailThin"]; $0.tailColor = "#9a6a48"; $0.mouth = "open" },
        AnimalDef("elephant", "Elephant", "#a9b8cf") { $0.shape = "wide"; $0.ears = "elephant"; $0.earInner = "#f2b8c6"; $0.muzzle = "trunk"; $0.nose = "none"; $0.mouth = "none" },
        AnimalDef("squirrel", "Squirrel", "#c8743d") { $0.ears = "pointy"; $0.earInner = "#f6dfc0"; $0.belly = "#f6dfc0"; $0.back = ["tailSquirrel"]; $0.tailColor = "#d4824a" },
        AnimalDef("puppy", "Puppy", "#e6b880") { $0.ears = "floppy"; $0.earColor = "#9a6a48"; $0.marks = ["eyePatch"]; $0.markColor = "#b4835a"; $0.muzzle = "snout"; $0.muzzleColor = "#fbefdc"; $0.nose = "big"; $0.mouth = "open"; $0.back = ["tailCurl"] },
        AnimalDef("unicorn", "Unicorn", "#fbf4ff") { $0.ears = "pointy"; $0.earInner = PINK; $0.front = ["pastelMane", "horn"]; $0.hornColor = "#ffd86b"; $0.nose = "none"; $0.mouth = "u"; $0.cheekColor = "#f7a8c8" },
        AnimalDef("capybara", "Capybara", "#b07d52") { $0.shape = "wide"; $0.ears = "tiny"; $0.muzzle = "capy"; $0.muzzleColor = "#946541"; $0.nose = "none"; $0.eyes = "tiny"; $0.mouth = "u" },
        AnimalDef("redpanda", "Red Panda", "#d4643a") { $0.ears = "pointy"; $0.earInner = CREAM; $0.marks = ["redPanda"]; $0.faceColor = CREAM; $0.markColor = "#a5452a"; $0.belly = "#5b3326"; $0.armColor = "#5b3326"; $0.feetColor = "#5b3326"; $0.back = ["tailStriped"]; $0.tailStripe = "#f2d7b0" },
        AnimalDef("sloth", "Sloth", "#c4a684") { $0.marks = ["faceOval", "slothEyes"]; $0.faceColor = "#efe1c8"; $0.markColor = "#6b4c36"; $0.eyes = "ringed"; $0.front = ["claws"]; $0.mouth = "u" },
        AnimalDef("ladybug", "Ladybug", "#e8443a") { $0.shape = "wide"; $0.marks = ["cap", "spots"]; $0.markColor = "#2b2426"; $0.spotPts = [(-0.6, 0.28, 10), (0.6, 0.28, 10), (-0.78, 0.55, 7), (0.78, 0.55, 7), (0, 0.14, 8)]; $0.back = ["antennae"]; $0.nose = "none"; $0.mouth = "u"; $0.armColor = "#2b2426"; $0.feetColor = "#2b2426"; $0.faceY = 0.5 },
        AnimalDef("snail", "Snail", "#f2d39a") { $0.shape = "small"; $0.back = ["snailShell", "eyeStalks"]; $0.shellColor = "#d98a5b"; $0.shellSpot = "#a85c3b"; $0.eyes = "stalk"; $0.nose = "none"; $0.mouth = "u"; $0.arms = "none"; $0.feet = "none" },
        AnimalDef("goat", "Baby Goat", "#f3efe8") { $0.ears = "goat"; $0.earColor = "#e3d7c7"; $0.back = ["horns"]; $0.hornColor = "#cdbda4"; $0.muzzle = "snout"; $0.muzzleColor = "#f6dcd6"; $0.noseColor = "#c98a7a"; $0.front = ["leaf"] },
    ]

    static let byId: [String: AnimalDef] = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
}

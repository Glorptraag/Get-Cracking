import SwiftUI

/// The egg's drawing and its crack landmarks (web js/egg.js). It lives apart
/// from the live `Egg` (Egg.swift) so the art checks can draw every step.
///
/// The egg is the progress bar. It cracks in 8 stepped "landmarks" so a
/// child who can't read numbers can still see time passing:
///
///   step 1    hairline crack near the top
///   step 2-5  the main zig-zag crack runs across the shell
///   step 6-8  more cracks branch off, and every crack gets wider and
///             deeper at each step; by step 8 the egg is hopping
///
/// Coordinates: base of the egg at (0,0), the egg grows up to y = -170.

enum EggPattern: String, CaseIterable { case spots, band, stripes }

struct EggPalette {
    let shell: String
    let spot: String
}

enum EggArt {
    static let pathD = "M0,-170 C40,-170 64,-96 64,-58 C64,-20 36,0 0,0 C-36,0 -64,-20 -64,-58 C-64,-96 -40,-170 0,-170 Z"
    static var path: Path { SVGPath.parse(pathD) }
    static let zig: [Pt] = [(-68, -74), (-50, -88), (-36, -72), (-20, -92), (-4, -74), (12, -94), (28, -74), (44, -90), (68, -76)]
    static let branches: [(step: Int, pts: [Pt])] = [
        (1, [(-30, -140), (-22, -128), (-27, -117), (-17, -108)]),
        (3, [(14, -150), (20, -138), (12, -128), (18, -118)]),
        (5, [(34, -62), (40, -50), (31, -40)]),
        (6, [(12, -94), (22, -106), (16, -116), (28, -128), (38, -122)]),
        (6, [(-36, -72), (-30, -58), (-38, -48)]),
        (7, [(-4, -74), (-12, -60), (-3, -50), (-10, -36)]),
        (7, [(-20, -92), (-26, -104), (-17, -108)]),
        (8, [(-44, -66), (-50, -52), (-42, -42), (-47, -30)]),
        (8, [(44, -90), (50, -104), (42, -114), (46, -126)]),
        (8, [(-6, -152), (-12, -160)]),
    ]
    /// fraction of the timer at which each crack step happens
    static let stepAt: [Double] = [0.1, 0.22, 0.34, 0.46, 0.58, 0.7, 0.8, 0.9]
    /// how much of the main zig-zag shows at each step (0…1)
    static let mainLenByStep: [Double] = [0, 0, 0.22, 0.46, 0.72, 1, 1, 1, 1]
    /// crack line width at each step: the cracks deepen as time passes
    static let crackWByStep: [Double] = [3, 3, 3.6, 4.2, 4.8, 5.4, 6.2, 7, 8]
    /// the main crack's width at step n
    static func crackW(_ n: Int) -> Double { crackWByStep[n] }
    /// a branch's width at step n: 0.78 of the main crack, to 2 decimals (as the web)
    static func branchW(_ n: Int) -> Double { (crackWByStep[n] * 0.78 * 100).rounded() / 100 }

    static let palettes: [EggPalette] = [
        EggPalette(shell: "#fbf1dc", spot: "#a9cf8b"),
        EggPalette(shell: "#dff1e4", spot: "#7cbf9e"),
        EggPalette(shell: "#dcecf6", spot: "#86b6dc"),
        EggPalette(shell: "#fde3d3", spot: "#f19c82"),
        EggPalette(shell: "#ece2f6", spot: "#b49ad9"),
        EggPalette(shell: "#fff1c2", spot: "#f3b54a"),
    ]

    static func stepFor(_ fraction: Double) -> Int {
        var n = 0
        for (i, at) in stepAt.enumerated() where fraction >= at { n = i + 1 }
        return n
    }

    static func patternNodes(_ kind: EggPattern, _ spot: String) -> [VNode] {
        switch kind {
        case .band:
            return [
                nPath("M-70,-112 L-52,-124 L-36,-110 L-20,-124 L-4,-110 L12,-124 L28,-110 L44,-124 L60,-110 L72,-118 L72,-100 L-70,-96 Z", .f(spot)),
                nCircle(-30, -40, 7, .f(spot)), nCircle(20, -30, 9, .f(spot)), nCircle(-6, -150, 6, .f(spot)),
            ]
        case .stripes:
            var out: [VNode] = []
            for (i, y) in [-140.0, -104, -46].enumerated() {
                out.append(nPath("M-70,\(y) Q0,\(y + 14) 70,\(y)", St(stroke: spot, width: i == 1 ? 12 : 9)))
            }
            out.append(nCircle(-24, -122, 5, .f(spot)))
            out.append(nCircle(26, -70, 6, .f(spot)))
            return out
        case .spots:
            let pts: [(Double, Double, Double)] = [(-30, -132, 10), (24, -146, 7), (32, -108, 12), (-40, -86, 8), (-8, -104, 6), (10, -60, 11), (-30, -36, 9), (40, -40, 7), (-48, -58, 5)]
            return pts.map { nCircle($0.0, $0.1, $0.2, .f(spot)) }
        }
    }

    /// The painted shell (fill, pattern, highlight, inner shade, outline).
    static func body(_ pal: EggPalette, _ pattern: EggPattern) -> VNode {
        nGroup([
            nPath(pathD, .f(pal.shell)),
            nGroup(patternNodes(pattern, pal.spot) + [
                nPath("M-40,-60 C-44,-110 -26,-150 -6,-160", St.line("#ffffff", 9).so(0.7)),
                nPath(pathD, St(stroke: GC.outHex, width: 16, strokeOpacity: 0.12)).moved(tr(7, 4)),
            ], clip: path),
            nPath(pathD, St.o(6)),
        ])
    }

    /// The first `len` (0…1) of a polyline, measured along its length, like
    /// SVG's pathLength="1" with a dash `len` long.
    static func partial(_ pts: [Pt], _ len: Double) -> [Pt] {
        guard pts.count > 1, len < 1 else { return pts }
        guard len > 0 else { return [] }
        var segs: [Double] = []
        for i in 1..<pts.count { segs.append(hypot(pts[i].0 - pts[i - 1].0, pts[i].1 - pts[i - 1].1)) }
        var left = segs.reduce(0, +) * len
        var out: [Pt] = [pts[0]]
        for (i, s) in segs.enumerated() {
            let a = pts[i], b = pts[i + 1]
            if left >= s { out.append(b); left -= s; continue }
            let u = s > 0 ? left / s : 0
            out.append((a.0 + (b.0 - a.0) * u, a.1 + (b.1 - a.1) * u))
            break
        }
        return out
    }

    /// The cracks exactly as they look at step `n`, as still nodes (for the
    /// shell pieces of a hatch and the art checks), clipped to the egg.
    static func cracks(step n: Int) -> VNode {
        var kids: [VNode] = []
        let main = partial(zig, mainLenByStep[n])
        if main.count > 1 { kids.append(nPolyline(main, St.line(GC.outHex, crackW(n)))) }
        for b in branches where n >= b.step { kids.append(nPolyline(b.pts, St.line(GC.outHex, branchW(n)))) }
        return nGroup(kids, clip: path)
    }
}

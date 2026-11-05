import SwiftUI

/// 10 illustrated worlds.
///
/// Each world is an isometric diorama block (like a little terrarium cut out
/// of the ground): a grassy top face where the egg sits, and two cut-away
/// side faces showing burrows, roots and sleepy critters.
///
/// Stage coordinates: viewBox 0 0 600 720.
///   top face diamond  L(60,370) T(300,250) R(540,370) B(300,490)
///   side depth        115
///   egg base / ring   centre (300,392)

/// A small reference-type wrapper so scene builders can share one RNG.
final class RNG {
    private var s: Seeded
    init(_ seed: Int) { s = Seeded(seed) }
    func callAsFunction() -> Double { s.next() }
}

struct SceneDef: Identifiable {
    let id: String
    let name: String
    let bg: String
    let ring: String
    var particles: String?
    let top: String, left: String, right: String, lip: String
    var rightLip: String? = nil
    var dark = false
    var tank = false
    var sky: () -> [VNode] = { [] }
    var ground: () -> [VNode] = { [] }
    var leftSide: (RNG, String) -> [VNode] = { _, _ in [] }
    var rightSide: (RNG, String) -> [VNode] = { _, _ in [] }
    var sideCritters: () -> [VNode] = { [] }
    var back: () -> [VNode] = { [] }
    var front: () -> [VNode] = { [] }
}

/// Handles for layering a built scene.
struct BuiltScene {
    let scene: SceneDef
    let root: VNode
    let ringLayer: VNode
    let eggLayer: VNode
    let fxLayer: VNode
}

enum Scenes {
    static let D = 115.0 // block depth
    static let egg = (x: 300.0, y: 392.0)
    static let ring = (cx: 300.0, cy: 392.0, rx: 150.0, ry: 74.0)
    static let fullViewBox = CGRect(x: 0, y: 0, width: 600, height: 720)
    static let tallViewBox = CGRect(x: 45, y: 110, width: 510, height: 580)

    private static let O = GC.outHex
    private static func so(_ fill: String, _ w: Double = 4.5) -> St { St.o(w).filled(fill) }
    private static func sh(_ c: String, _ a: Double) -> String { GC.shade(c, a) }

    // face-local → screen
    static func topPt(_ u: Double, _ v: Double) -> Pt { (60 + u + v, 370 - 0.5 * u + 0.5 * v) }
    static func leftPt(_ u: Double, _ v: Double) -> Pt { (60 + u, 370 + 0.5 * u + v) }
    static func rightPt(_ u: Double, _ v: Double) -> Pt { (300 + u, 490 - 0.5 * u + v) }
    static let TOP_M = CGAffineTransform(a: 1, b: -0.5, c: 1, d: 0.5, tx: 60, ty: 370)
    static let LEFT_M = CGAffineTransform(a: 1, b: 0.5, c: 0, d: 1, tx: 60, ty: 370)
    static let RIGHT_M = CGAffineTransform(a: 1, b: -0.5, c: 0, d: 1, tx: 300, ty: 490)

    // MARK: side-face parts (face-local coords, 240 × 115)

    static func lip(_ color: String, drips: Bool, _ rng: RNG) -> VNode {
        var d = "M0,-1 L240,-1 L240,12 "
        var x = 240.0
        while x > 0 {
            let deep = drips && rng() < 0.25 ? 16 + rng() * 10 : 6 + rng() * 5
            d += "Q\(x - 8),\(12 + deep) \(x - 16),12 "
            x -= 16
        }
        d += "Z"
        return nPath(d, so(color, 4))
    }

    static func pebbles(_ rng: RNG, _ c: String, _ n: Int = 10, _ vMin: Double = 24) -> [VNode] {
        var out: [VNode] = []
        for _ in 0..<n {
            let u = 10 + rng() * 220, v = vMin + rng() * (D - vMin - 10)
            let rx = 3 + rng() * 4, ry = 2 + rng() * 3
            out.append(nEllipse(u, v, rx, ry, so(c, 2.5)))
        }
        return out
    }

    static func roots(_ rng: RNG, _ c: String = "#6b4430", _ n: Int = 4) -> [VNode] {
        var out: [VNode] = []
        for _ in 0..<n {
            let u = 20 + rng() * 200, len = 30 + rng() * 40
            let qx = u + (rng() - 0.5) * 30
            let ex = u + (rng() - 0.5) * 20
            let d = "M\(u),14 Q\(qx),\(14 + len * 0.5) \(ex),\(14 + len)"
            out.append(nPath(d, St.line(O, 9)))
            out.append(nPath(d, St.line(c, 4.5)))
        }
        return out
    }

    static func burrow(_ u: Double, _ v: Double, _ rx: Double, _ ry: Double, _ c: String) -> [VNode] {
        [
            nEllipse(u, v, rx, ry, so(sh(c, 0.28))),
            nPath("M\(u - rx + 6),\(v + 4) Q\(u),\(v + ry + 2) \(u + rx - 6),\(v + 4) L\(u + rx - 8),\(v + ry * 0.55) Q\(u),\(v + ry + 4) \(u - rx + 8),\(v + ry * 0.55) Z", .f(sh(c, 0.12))),
            nPath("M\(u - rx * 0.7),\(v - ry * 0.5) Q\(u),\(v - ry * 0.95) \(u + rx * 0.7),\(v - ry * 0.5)", St.line(sh(c, -0.12), 3).dashed([2, 6])),
        ]
    }

    static func strata(_ colors: [String]) -> [VNode] {
        var out: [VNode] = []
        var y = 14.0
        let h = (D - 14) / Double(colors.count)
        for c in colors {
            out.append(nPath("M0,\(y) Q60,\(y - 5) 120,\(y + 3) T240,\(y) L240,\(y + h + 2) L0,\(y + h + 2) Z", .f(c)))
            y += h
        }
        return out
    }

    static func waterSide(_ c: String) -> [VNode] {
        [
            nRect(0, 0, 240, D, .f(c)),
            nPath("M0,26 Q30,20 60,26 T120,26 T180,26 T240,26", St(stroke: "#ffffff", width: 3, strokeOpacity: 0.35)),
            nPath("M0,60 Q30,54 60,60 T120,60 T180,60 T240,60", St(stroke: "#ffffff", width: 3, strokeOpacity: 0.2)),
            nPath("M0,\(D - 16) Q40,\(D - 24) 80,\(D - 16) T160,\(D - 16) T240,\(D - 16) L240,\(D) L0,\(D) Z", .f("#e9cf96")),
        ]
    }

    static func myco(_ rng: RNG, _ c: String = "#e7d7a8") -> [VNode] {
        var out: [VNode] = []
        for _ in 0..<4 {
            let u = 20 + rng() * 200
            out.append(nPath("M\(u),14 Q\(u + 20),40 \(u - 10),60 T\(u + 10),100", St(stroke: c, width: 2.5, strokeOpacity: 0.55, cap: .round).dashed([1, 5]))
                .looping(Loops.glowPulse()))
        }
        return out
    }

    static func icicles() -> [VNode] {
        [20.0, 60, 110, 170, 210].map { u in
            nPath("M\(u - 5),12 L\(u),\(30 + Double(Int(u) % 3) * 6) L\(u + 5),12 Z", so("#e6f3fb", 2.5))
        }
    }

    static func tunnels() -> [VNode] {
        [nPath("M40,30 Q70,50 60,70 T110,96 T180,80", St.line("#d8b08a", 10))] +
            [(62.0, 64.0), (110, 95), (160, 84)].map { nEllipse($0.0, $0.1, 3, 2, .f(O)) }
    }

    static func worm() -> [VNode] {
        let d = "M170,40 q8,-8 16,0 t16,0"
        return [nPath(d, St.line(O, 10)), nPath(d, St.line("#f4a7b0", 5))]
    }

    static func acorns(_ u: Double, _ v: Double) -> [VNode] {
        var out: [VNode] = []
        for (dx, dy) in [(-14.0, 6.0), (0, 8), (14, 6), (-6, 0), (8, 0)] {
            out.append(nEllipse(u + dx, v + dy, 5, 6, so("#b5703a", 2.5)))
            out.append(nPath("M\(u + dx - 6),\(v + dy - 3) L\(u + dx + 6),\(v + dy - 3)", St(stroke: "#7d5034", width: 4)))
        }
        return out
    }

    static func fossil() -> [VNode] {
        [nGroup([nPath("M0,0 a6,6 0 1 1 8,-4 a12,12 0 1 1 -18,10 a18,18 0 1 1 26,-16", St.line("#f3dcb4", 3))], tr(120, 70))]
    }

    // MARK: the worlds

    typealias P = Props

    static let list: [SceneDef] = {
        var out: [SceneDef] = []

        var forest = SceneDef(id: "forest", name: "Mossy Forest", bg: "#5e6f55", ring: "#f2b544", particles: "fireflies",
                              top: "#86b04f", left: "#b07c52", right: "#8a5e3c", lip: "#6f9a3c")
        forest.ground = {
            [nPath("M10,40 Q60,10 120,30 Q180,10 230,44 L230,90 Q170,70 120,90 Q60,72 10,96 Z", .f("#76a046")),
             nPath("M20,170 Q80,150 140,176 Q200,160 230,190 L230,230 L20,230 Z", .f("#76a046")),
             nEllipse(200, 200, 22, 14, .f("#9cc25e")), nEllipse(40, 60, 18, 12, .f("#9cc25e"))]
        }
        forest.leftSide = { r, c in roots(r, "#7d5034", 5) + burrow(70, 70, 34, 24, c) + pebbles(r, "#8f6545", 10) }
        forest.rightSide = { r, c in roots(r, "#6b4430", 4) + burrow(170, 62, 36, 26, c) + pebbles(r, "#71492f", 10) }
        forest.sideCritters = {
            let a = leftPt(70, 88), b = rightPt(170, 82)
            return [P.burrowCritter(a, "#3d3536"), P.burrowCritter((b.0 + 6, b.1), "#3d3536", "#f7a8a0"), P.burrowCritter(rightPt(150, 84), "#4a3f40")]
        }
        forest.back = {
            [P.trunk(150, 336, 28), P.trunk(452, 338, 26), P.pine(220, 300, 1.05), P.pine(380, 300, 0.95, "#4f8f48", "#6fb35e"), P.trunk(300, 268, 30, "#7d5034"),
             P.fern(110, 372, 1), P.mushroom(130, 352, 0.7), P.rock(470, 362, 0.9, "#a3a89f"), P.bird(470, 338), P.bird(482, 340, "#bfe3f0"),
             P.candle(186, 346, 0.9), P.candle(416, 346, 0.9), P.tuft(250, 302, 1.1), P.tuft(352, 300, 1)]
        }
        forest.front = {
            [P.fern(96, 398, 0.9, "#5fae66"), P.mushroom(505, 396, 0.8, "#f2a65a"), P.tuft(160, 430, 0.9), P.tuft(440, 430, 0.9),
             P.candle(210, 442, 0.85), P.candle(390, 442, 0.85)]
        }
        out.append(forest)

        var pond = SceneDef(id: "pond", name: "Lily Pond", bg: "#9fcdc4", ring: "#f7a8c8", particles: "dragonflies",
                            top: "#8cc363", left: "#a8774f", right: "#5fb3c8", lip: "#78ad4f", rightLip: "#4f9fb4")
        pond.ground = {
            [nPath("M60,20 Q140,0 220,30 L232,232 L40,232 Q10,160 30,100 Q30,40 60,20 Z", so("#6cc0d4", 4)),
             nPath("M80,40 Q130,30 190,50", St.line("#ffffff", 4).so(0.5)),
             nEllipse(160, 170, 16, 16, St(stroke: "#ffffff", width: 2.5, strokeOpacity: 0.6)).looping(Loops.ripple),
             nCircle(98, 142, 78, so("#94c96a", 4))]
        }
        pond.leftSide = { r, c in roots(r, "#7d5034", 3) + burrow(80, 66, 32, 22, c) + pebbles(r, "#8f6545", 9) }
        pond.rightSide = { _, _ in waterSide("#5fb3c8") }
        pond.sideCritters = { [P.fish(rightPt(70, 55), "#f3b54a", 1), P.fish(rightPt(160, 80), "#f39a9a", -1), P.burrowCritter(leftPt(80, 82), "#7a5a48")] }
        pond.back = {
            [P.reeds(130, 350), P.reeds(470, 358, 0.9), P.roundTree(200, 312, 0.9, "#7cbf5a"), P.lilypad(390, 300, 1, flower: true), P.lilypad(440, 322, 0.8),
             P.rock(360, 290, 0.8, "#a3a89f"), P.tuft(250, 300), P.bird(360, 272, "#ffe066")]
        }
        pond.front = { [P.lilypad(470, 420, 0.9, flower: true), P.lilypad(420, 452, 0.7), P.flower(100, 396, 0.9, "#fdfaf3"), P.tuft(150, 424)] }
        out.append(pond)

        var mush = SceneDef(id: "mushroom", name: "Mushroom Hollow", bg: "#5b4a6b", ring: "#9fd8e8", particles: "spores",
                            top: "#7d9a5a", left: "#7a5866", right: "#5f4351", lip: "#67864a")
        mush.ground = {
            [nEllipse(60, 60, 40, 26, .f("#8fae66")), nEllipse(190, 190, 34, 22, .f("#8fae66")),
             nCircle(140, 40, 6, .f("#c5a8f0")), nCircle(40, 200, 5, .f("#c5a8f0"))]
        }
        mush.leftSide = { r, c in myco(r) + burrow(90, 64, 32, 22, c) + pebbles(r, "#694a57", 8) }
        mush.rightSide = { r, c in myco(r) + burrow(150, 70, 30, 20, c) + pebbles(r, "#523946", 8) }
        mush.sideCritters = { [P.burrowCritter(leftPt(90, 80), "#2e2533", "#9fd8e8"), P.burrowCritter(rightPt(150, 84), "#2e2533", "#f7a8c8")] }
        mush.back = {
            [P.mushroom(170, 340, 2.6, "#e8604f"), P.mushroom(430, 344, 2.3, "#c5a8f0", "#fdf3e4", glow: true), P.mushroom(300, 286, 2.0, "#f2a65a"),
             P.mushroom(230, 306, 1, "#9fd8e8", "#fdf3e4", glow: true), P.mushroom(380, 304, 1.1, "#f7a8c8"), P.fern(110, 372, 0.9, "#5f8a52"), P.crystal(490, 368, 0.9, "#c5a8f0")]
        }
        mush.front = {
            [P.mushroom(100, 400, 1, "#9fd8e8", "#fdf3e4", glow: true), P.mushroom(500, 398, 0.9, "#e8604f"), P.mushroom(190, 448, 0.6, "#f7a8c8"),
             P.mushroom(410, 448, 0.6, "#c5a8f0", "#ffffff", glow: true)]
        }
        out.append(mush)

        var snow = SceneDef(id: "snow", name: "Snowy Pines", bg: "#c7d9e6", ring: "#e8604f", particles: "snow",
                            top: "#f4f8fb", left: "#9b7a68", right: "#7d5f50", lip: "#e6eef4")
        snow.ground = {
            [nPath("M30,120 Q80,100 130,120 T230,110", St.line("#d8e4ee", 12))] +
                [(40.0, 40.0), (60, 50), (80, 42), (100, 52)].map { nEllipse($0.0, $0.1, 4, 5, .f("#c9d8e4")) } +
                [nEllipse(190, 200, 30, 18, so("#bfe0ee", 3))]
        }
        snow.leftSide = { r, c in [nRect(0, 12, 240, 10, St.f("#dfeaf2").op(0.5))] + roots(r, "#6b4c3e", 3) + burrow(80, 70, 34, 22, c) + pebbles(r, "#86685a", 9) }
        snow.rightSide = { r, c in [nRect(0, 12, 240, 10, St.f("#dfeaf2").op(0.4))] + burrow(160, 66, 34, 24, c) + pebbles(r, "#6b5044", 9) + icicles() }
        snow.sideCritters = { [P.burrowCritter(leftPt(80, 86), "#fdfaf3", "#3b2224"), P.burrowCritter(rightPt(160, 84), "#8a5a3b")] }
        snow.back = {
            [P.pine(170, 330, 1.1, "#4f8f6a", "#6aaa84", snow: true), P.pine(300, 278, 1.25, "#4f8f6a", "#6aaa84", snow: true), P.pine(430, 330, 1.0, "#4f8f6a", "#6aaa84", snow: true),
             P.pine(230, 300, 0.7, "#4f8f6a", "#6aaa84", snow: true), P.snowman(470, 368, 1), P.rock(110, 364, 0.8, "#b9c4cc")]
        }
        snow.front = { [P.pine(100, 402, 0.55, "#4f8f6a", "#6aaa84", snow: true), P.rock(500, 400, 0.6, "#b9c4cc"), P.bird(510, 384, "#e8604f")] }
        out.append(snow)

        var meadow = SceneDef(id: "meadow", name: "Sunny Meadow", bg: "#f1e2bd", ring: "#e8604f", particles: "petals",
                              top: "#9fcf66", left: "#b5835a", right: "#946644", lip: "#86b84f")
        meadow.sky = { [nGroup([nCircle(500, 90, 36, so("#ffd86b"))]).looping(Loops.sun(5)), P.cloud(110, 110, 1), P.cloud(420, 170, 0.8)] }
        meadow.ground = { [nPath("M0,150 Q60,130 120,140 T240,120", St(stroke: "#b4dc7a", width: 20)), nEllipse(50, 50, 24, 16, .f("#b4dc7a"))] }
        meadow.leftSide = { r, _ in tunnels() + roots(r, "#7d5034", 3) + pebbles(r, "#9a6c48", 10) + worm() }
        meadow.rightSide = { r, c in burrow(150, 66, 34, 24, c) + roots(r, "#6b4430", 3) + pebbles(r, "#7d5638", 10) }
        meadow.sideCritters = { [P.burrowCritter(rightPt(150, 84), "#9a6845")] }
        meadow.back = {
            [P.roundTree(170, 330, 1.05, "#7cbf5a"), P.roundTree(430, 330, 0.95, "#93cc62"), P.bush(300, 282, 1.1, "#7cbf5a"),
             P.flower(230, 306, 1, "#f7a8c8"), P.flower(370, 306, 1, "#9fd8e8"), P.flower(120, 368, 1, "#ffd86b", "#f39a6b"), P.flower(480, 366, 1, "#c5a8f0"), P.tuft(260, 296),
             P.butterfly(220, 230, "#f7a8c8"), P.butterfly(420, 250, "#9fd8e8")]
        }
        meadow.front = {
            [P.flower(96, 398, 1.1, "#f39a6b"), P.flower(504, 398, 1.1, "#f7a8c8"), P.flower(170, 436, 0.8, "#fdfaf3"), P.flower(430, 436, 0.8, "#ffd86b", "#f39a6b"),
             P.tuft(140, 414), P.tuft(460, 414)]
        }
        out.append(meadow)

        var autumn = SceneDef(id: "autumn", name: "Autumn Woods", bg: "#ecc79b", ring: "#7d9a5a", particles: "leaves",
                              top: "#c9a54a", left: "#a8774f", right: "#865c3c", lip: "#b38d3a")
        autumn.sky = { [P.cloud(470, 120, 0.9, "#fbefdc")] }
        autumn.ground = {
            let cols = ["#e8604f", "#f29a3c", "#f2c14a"]
            return [(40.0, 60.0), (70, 180), (180, 40), (200, 200), (120, 20), (20, 130)].enumerated().map { i, p in
                nEllipse(p.0, p.1, 10, 6, .f(cols[i % 3])).moved(rotAbout(Double(i) * 40, p.0, p.1))
            }
        }
        autumn.leftSide = { r, c in roots(r, "#7d5034", 4) + burrow(84, 66, 38, 26, c) + acorns(84, 80) + pebbles(r, "#8f6545", 8) }
        autumn.rightSide = { r, c in roots(r, "#6b4430", 4) + burrow(160, 62, 30, 22, c) + pebbles(r, "#71492f", 9) }
        autumn.sideCritters = { [P.burrowCritter(rightPt(160, 78), "#c8743d")] }
        autumn.back = {
            [P.roundTree(170, 330, 1.1, "#e8723c"), P.roundTree(430, 332, 1.0, "#f2b33c"), P.roundTree(300, 280, 1.2, "#d9553f"),
             P.pumpkin(120, 368, 1), P.pumpkin(140, 380, 0.7), P.bush(480, 368, 0.8, "#c9873a"), P.mushroom(230, 312, 0.8, "#8a5a3b")]
        }
        autumn.front = { [P.pumpkin(500, 402, 0.9), P.tuft(100, 400, 1, "#b38d3a"), P.mushroom(170, 440, 0.6, "#e8604f"), P.tuft(440, 432, 0.9, "#b38d3a")] }
        out.append(autumn)

        var desert = SceneDef(id: "desert", name: "Desert Oasis", bg: "#f6d8ae", ring: "#4f9fb4", particles: "motes",
                              top: "#ecc78c", left: "#d79a62", right: "#bf7f4c", lip: "#e0b475")
        desert.sky = { [nGroup([nCircle(110, 100, 42, so("#ffc94a"))]).looping(Loops.sun(5)), P.cloud(470, 140, 0.7, "#fff6e6")] }
        desert.ground = {
            [nEllipse(190, 60, 38, 26, so("#6cc0d4", 3.5)),
             nPath("M10,180 Q60,160 110,180 T230,170", St(stroke: "#e0b475", width: 8)),
             nPath("M20,90 Q60,80 100,92", St(stroke: "#e0b475", width: 6))]
        }
        desert.leftSide = { _, _ in strata(["#d79a62", "#e2ad74", "#c98852", "#dba06a"]) + fossil() }
        desert.rightSide = { _, _ in strata(["#bf7f4c", "#c98d5a", "#b07040", "#c1814e"]) }
        desert.back = {
            [P.cactus(170, 332, 1.2), P.palm(380, 290, 1.1), P.cactus(450, 338, 0.9, "#8ac466"), P.rock(250, 302, 0.9, "#d9a072"), P.rock(120, 368, 0.7, "#c98852"), P.reeds(420, 296, 0.6)]
        }
        desert.front = { [P.cactus(500, 404, 0.6), P.rock(110, 400, 0.6, "#d9a072"), P.flower(170, 436, 0.7, "#f39a6b")] }
        out.append(desert)

        var beach = SceneDef(id: "beach", name: "Tide Pool Beach", bg: "#bfe3ea", ring: "#f39a6b", particles: "bubbles",
                             top: "#f3dca6", left: "#e5c58a", right: "#5fb3c8", lip: "#e9cf96", rightLip: "#4f9fb4")
        beach.sky = { [P.cloud(120, 120, 0.9), P.cloud(480, 90, 0.7), P.gull(420, 160), P.gull(460, 140)] }
        beach.ground = {
            [nPath("M150,0 L240,0 L240,240 L200,240 Q150,200 170,150 Q190,100 150,60 Q130,30 150,0 Z", so("#6cc0d4", 4)),
             nPath("M160,30 Q180,60 168,90 Q156,120 182,150", St.line("#ffffff", 5).dashed([20, 14])).looping(Loops.waveDash),
             nEllipse(60, 200, 26, 16, so("#8fd0dc", 3))]
        }
        beach.leftSide = { r, _ in
            strata(["#e5c58a", "#dcb877", "#e8cb92"]) + pebbles(r, "#f7c4b0", 6) +
                [nGroup([nPath("M-10,0 Q0,-14 10,0 Z", so("#f7c4b0", 3))], tr(150, 70))]
        }
        beach.rightSide = { _, _ in waterSide("#5fb3c8") }
        beach.sideCritters = { [P.fish(rightPt(80, 60), "#ffd86b", 1), P.fish(rightPt(170, 82), "#f7a8c8", -1), P.crab(leftPt(90, 100))] }
        beach.back = {
            [P.palm(170, 330, 1.15), P.shell(250, 304, 1, "#f7c4b0"), P.starfish(380, 292, 1), P.rock(440, 320, 0.8, "#a3a89f"), P.crab(130, 372), P.shell(220, 330, 0.7, "#fdfaf3")]
        }
        beach.front = { [P.starfish(110, 398, 0.9, "#f7a8c8"), P.shell(490, 398, 0.9), P.shell(180, 444, 0.7, "#c5a8f0"), P.starfish(420, 446, 0.6, "#ffd86b")] }
        out.append(beach)

        var night = SceneDef(id: "night", name: "Moonlit Garden", bg: "#2a3354", ring: "#ffd86b", particles: "fireflies",
                             top: "#4a7a62", left: "#5a4450", right: "#45343e", lip: "#3f6a54")
        night.dark = true
        night.sky = {
            [nCircle(480, 100, 60, St.f("#fff6c9").op(0.18)).looping(Loops.sun(4)),
             nCircle(480, 100, 34, so("#fff3c4")),
             nCircle(470, 92, 6, .f("#efe0a8")), nCircle(490, 110, 4, .f("#efe0a8"))] + P.stars()
        }
        night.ground = { [nPath("M20,120 Q120,90 220,120", St(stroke: "#5c8d72", width: 22)), nEllipse(60, 50, 20, 12, .f("#5c8d72"))] }
        night.leftSide = { r, c in myco(r, "#9fd8e8") + burrow(80, 66, 32, 22, c) + pebbles(r, "#6b5260", 8) }
        night.rightSide = { r, c in burrow(160, 66, 32, 22, c) + pebbles(r, "#574350", 8) }
        night.sideCritters = {
            [P.crystal(leftPt(150, 96), 0.8, "#9fd8e8"), P.burrowCritter(leftPt(80, 82), "#2e2533", "#ffd86b"),
             P.crystal(rightPt(70, 100), 0.7, "#c5a8f0"), P.burrowCritter(rightPt(160, 82), "#2e2533", "#9fd8e8")]
        }
        night.back = {
            [P.roundTree(170, 330, 1.05, "#3f7a5a"), P.roundTree(430, 330, 0.95, "#4a8a66"), P.lantern(300, 284, 1.1),
             P.flower(230, 306, 1, "#c5a8f0", "#fff6c9"), P.flower(370, 306, 1, "#9fd8e8", "#fff6c9"), P.crystal(120, 370, 0.9, "#9fd8e8"),
             P.mushroom(480, 366, 0.8, "#c5a8f0", "#ffffff", glow: true)]
        }
        night.front = {
            [P.flower(100, 398, 1, "#f7a8c8", "#fff6c9"), P.lantern(500, 404, 0.8), P.mushroom(180, 444, 0.6, "#9fd8e8", "#ffffff", glow: true),
             P.flower(420, 440, 0.8, "#c5a8f0", "#fff6c9")]
        }
        out.append(night)

        var reef = SceneDef(id: "reef", name: "Coral Reef Tank", bg: "#d4cdc0", ring: "#f39a9a", particles: "bubbles",
                            top: "#efd9a8", left: "#c9a06a", right: "#a8804f", lip: "#e2c690")
        reef.tank = true
        reef.ground = {
            [nEllipse(60, 70, 26, 16, .f("#e2c690")), nEllipse(190, 190, 30, 18, .f("#e2c690"))] +
                [(30.0, 150.0), (90, 30), (210, 90), (150, 220)].map { nCircle($0.0, $0.1, 5, .f("#d1b27c")) }
        }
        reef.leftSide = { r, _ in strata(["#c9a06a", "#b98f5c"]) + pebbles(r, "#9aa0b0", 14, 14) + pebbles(r, "#f7c4b0", 6, 14) }
        reef.rightSide = { r, _ in strata(["#a8804f", "#9a7445"]) + pebbles(r, "#7f8698", 14, 14) }
        reef.back = {
            [P.seaweed(150, 340, 110), P.seaweed(166, 344, 80, "#8ad08a"), P.coral(240, 304, 1.4, "#f39a9a"), P.coral(370, 300, 1.2, "#c5a8f0"),
             P.seaweed(450, 344, 100, "#5fae7a"), P.rock(300, 280, 1, "#9aa0b0"), P.coral(120, 372, 1, "#ffd86b"), P.starfish(470, 366, 0.9),
             P.fish(210, 200, "#f3b54a", 1), P.fish(400, 170, "#9fd8e8", -1), P.fish(320, 130, "#f7a8c8", 1)]
        }
        reef.front = { [P.coral(500, 404, 0.9, "#f39a6b"), P.shell(100, 398, 0.9), P.seaweed(180, 448, 40), P.seaweed(420, 448, 46, "#8ad08a")] }
        out.append(reef)

        return out
    }()

    static func scene(_ id: String) -> SceneDef { list.first { $0.id == id } ?? list[0] }

    // MARK: particles

    static func particles(_ type: String?, _ n: Int) -> VNode? {
        guard let type else { return nil }
        let r = RNG(type.count * 31)
        var out: [VNode] = []
        let leafCols = ["#e8604f", "#f29a3c", "#f2c14a"], petalCols = ["#f7a8c8", "#fdfaf3", "#ffd86b"]
        for i in 0..<n {
            let x = r() * 600, y = r() * 420, dur = 6 + r() * 8
            let delay = -r() * dur
            let dx = ((r() - 0.5) * 80).rounded()
            switch type {
            case "fireflies":
                out.append(nGroup([nCircle(0, 0, 4, .f("#fff2a0")).looping(Loops.firefly(dur, dx: dx, delay: delay))], tr(x, 120 + y * 0.8)))
            case "spores":
                let rad = 2 + r() * 2.5
                let col = r() < 0.5 ? "#9fd8e8" : "#e7d7a8"
                out.append(nGroup([nCircle(0, 0, rad, .f(col)).looping(Loops.rise(dur, dx: dx, delay: delay))], tr(x, 250 + y * 0.6)))
            case "bubbles":
                let rad = 3 + r() * 5
                out.append(nGroup([nCircle(0, 0, rad, St(fill: "#ffffff", fillOpacity: 0.25, stroke: "#ffffff", width: 2)).looping(Loops.rise(dur, dx: dx, delay: delay))], tr(x, 330 + y * 0.5)))
            case "snow":
                let rad = 2.5 + r() * 3
                out.append(nGroup([nCircle(0, 0, rad, .f("#ffffff")).looping(Loops.fall(dur, dx: dx, delay: delay))], tr(x, -20)))
            case "leaves":
                out.append(nGroup([nPath("M0,-7 C5,-4 5,4 0,7 C-5,4 -5,-4 0,-7 Z", St(fill: leafCols[i % 3], stroke: O, width: 2)).looping(Loops.fall(dur, dx: dx, delay: delay))], tr(x, -20)))
            case "petals":
                out.append(nGroup([nEllipse(0, 0, 4, 6, .f(petalCols[i % 3])).looping(Loops.fall(dur, dx: dx, delay: delay))], tr(x, -20)))
            case "motes":
                out.append(nGroup([nCircle(0, 0, 2.5, .f("#fff6e0")).looping(Loops.firefly(dur, dx: dx, delay: delay))], tr(x, 100 + y)))
            case "dragonflies":
                if i < 3 {
                    let fx = 150 + r() * 300, fy = 180 + r() * 100, d = 9 + r() * 4
                    let wings = nGroup([
                        nEllipse(-7, -2, 8, 3.5, so("#cfeef5", 2)), nEllipse(7, -2, 8, 3.5, so("#cfeef5", 2)),
                        nRect(-2, -6, 4, 16, rx: 2, .f("#4f9fb4")),
                    ]).looping(Loops.flap)
                    out.append(nGroup([wings]).looping(Loops.flutter(fx, fy, d)))
                } else {
                    out.append(nGroup([nCircle(0, 0, 2.5, .f("#ffffff")).looping(Loops.firefly(dur, dx: dx, delay: delay))], tr(x, 150 + y * 0.7)))
                }
            default:
                break
            }
        }
        return nGroup(out)
    }

    // MARK: build

    /// glass water volume above the seabed
    private static func tankGlass() -> (back: [VNode], front: [VNode]) {
        let H = 230.0 // water height above top face
        func up(_ p: Pt) -> Pt { (p.0, p.1 - H) }
        let L: Pt = (60, 370), T: Pt = (300, 250), R: Pt = (540, 370), B: Pt = (300, 490)
        let back = [
            nPolygon([L, T, R, up(R), up(T), up(L)], St(fill: "#7fd1cf", fillOpacity: 0.28)),
            nPolygon([up(L), up(T), up(R), up(B)], St(fill: "#a8e6e0", fillOpacity: 0.35)).looping(Loops.glowPulse(4)),
            nPath("M\(up(T).0),\(up(T).1) L\(T.0),\(T.1)", St(stroke: "#9ef0cf", width: 3).op(0.8)),
        ]
        let glass = St(stroke: "#9ef0cf", width: 4, join: .round)
        let front = [
            nGroup([
                nPolygon([up(L), up(T), up(R), up(B)], glass),
                nPath("M\(L.0),\(L.1) L\(up(L).0),\(up(L).1) M\(R.0),\(R.1) L\(up(R).0),\(up(R).1)", glass),
            ], opacity: 0.95),
            nPath("M\(L.0 + 30),\(L.1 - 30) L\(L.0 + 30),\(L.1 - 170)", St.line("#ffffff", 8).so(0.35)),
            nPath("M\(R.0 - 40),\(R.1 - 40) L\(R.0 - 40),\(R.1 - 150)", St.line("#ffffff", 6).so(0.25)),
        ]
        return (back, front)
    }

    /// Build a world. The egg goes into `eggLayer`, the ground ring into `ringLayer`.
    @MainActor
    static func build(_ id: String, particles withParticles: Bool = true) -> BuiltScene {
        let sc = scene(id)
        let first = sc.id.unicodeScalars.first.map { Int($0.value) } ?? 0
        let rng = RNG(sc.id.count * 977 + first)
        let L: Pt = (60, 370), T: Pt = (300, 250), R: Pt = (540, 370), B: Pt = (300, 490)
        func dn(_ p: Pt) -> Pt { (p.0, p.1 + D) }
        let tank = sc.tank ? tankGlass() : nil

        let lipL = lip(sc.lip, drips: true, rng)
        let lipR = lip(sc.rightLip ?? sc.lip, drips: sc.rightLip == nil, rng)

        func face(_ kids: [VNode], _ m: CGAffineTransform) -> VNode {
            let g = nGroup(kids, m)
            g.bake(.identity) // keep outlines unskewed (non-scaling stroke)
            return g
        }

        let root = VNode()
        root.add(nRect(-400, -400, 1400, 1520, .f(sc.bg)))
        root.add(nGroup(sc.sky()))
        root.add(nEllipse(300, 612, 250, 40, St.f(O).op(0.14)))
        if let tank { root.add(tank.back) }
        // left face
        root.add(nPolygon([L, B, dn(B), dn(L)], .f(sc.left)))
        root.add(face(sc.leftSide(rng, sc.left) + [lipL], LEFT_M))
        root.add(nPolygon([L, B, dn(B), dn(L)], St.o(5)))
        // right face
        root.add(nPolygon([B, R, dn(R), dn(B)], .f(sc.right)))
        root.add(face(sc.rightSide(rng, sc.right) + [lipR], RIGHT_M))
        root.add(nPolygon([B, R, dn(R), dn(B)], St.o(5)))
        root.add(nPolygon([B, R, dn(R), dn(B)], St.f(O).op(0.08)))
        let critters = nGroup(sc.sideCritters())
        // every second burrow-dweller blinks on its own rhythm
        for (i, c) in critters.children.enumerated() where c.tag == "burrow" && (i + 1) % 2 == 0 {
            if c.children.count > 1 { c.children[1].loop = Loops.blink(5.1, delay: -1.7) }
        }
        root.add(critters)
        // top face
        root.add(nPolygon([L, T, R, B], .f(sc.top)))
        root.add(face(sc.ground(), TOP_M))
        root.add(nPolygon([L, T, R, B], St.o(5)))
        root.add(nGroup(sc.back()))
        let ringLayer = VNode(), eggLayer = VNode(), fxLayer = VNode()
        root.add(ringLayer)
        root.add(eggLayer)
        root.add(nGroup(sc.front()))
        if let tank { root.add(tank.front) }
        let reduce = GC.reduceMotion
        if withParticles && !reduce, let p = particles(sc.particles, sc.particles == "fireflies" ? 18 : 16) { root.add(p) }
        root.add(fxLayer)
        if reduce { root.walk { $0.loop = nil } }
        return BuiltScene(scene: sc, root: root, ringLayer: ringLayer, eggLayer: eggLayer, fxLayer: fxLayer)
    }
}

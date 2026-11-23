import SwiftUI

/// Aussie Bush pack worlds: a red-dirt outback with the mole cricket's
/// tunnel, and a gum-tree billabong with the platypus's burrow. Ported from
/// the web's js/packs/aussie.js (props, scenes, particles).
enum AussieWorlds {
    private typealias P = Props
    private static let O = GC.outHex
    private static func so(_ fill: String, _ w: Double = 4.5) -> St { St.o(w).filled(fill) }
    private static func sh(_ c: String, _ a: Double) -> String { GC.shade(c, a) }

    // MARK: props

    /// a gum tree: pale smooth trunk that forks, drooping grey-green leaf clumps
    static func gum(_ x: Double, _ y: Double, _ s: Double = 1, _ trunk: String = "#efe6d6", _ leafC: String = "#93b48a") -> VNode {
        let t = "M\(x - 9 * s),\(y) Q\(x - 7 * s),\(y - 40 * s) \(x - 4 * s),\(y - 62 * s) L\(x - 24 * s),\(y - 96 * s) L\(x - 15 * s),\(y - 100 * s) L\(x),\(y - 74 * s) " +
            "L\(x + 16 * s),\(y - 104 * s) L\(x + 25 * s),\(y - 98 * s) L\(x + 6 * s),\(y - 62 * s) Q\(x + 8 * s),\(y - 40 * s) \(x + 10 * s),\(y) Z"
        func clump(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ c: String) -> VNode { nEllipse(cx, cy, rx, ry, so(c)) }
        func hang(_ cx: Double, _ cy: Double) -> VNode { nPath("M\(cx),\(cy) q-2,\(9 * s) 1,\(15 * s)", rcap(O, 3)) }
        return nGroup([
            nPath(t, so(trunk)),
            nPath("M\(x - 2 * s),\(y - 14 * s) q\(3 * s),\(-8 * s) 0,\(-18 * s) M\(x + 4 * s),\(y - 38 * s) q\(-3 * s),\(-6 * s) 0,\(-14 * s)", rcap(sh(trunk, -0.25), 3)),
            clump(x - 30 * s, y - 104 * s, 30 * s, 17 * s, leafC), clump(x + 30 * s, y - 108 * s, 30 * s, 17 * s, leafC),
            clump(x, y - 124 * s, 34 * s, 19 * s, sh(leafC, 0.1)),
            hang(x - 44 * s, y - 92 * s), hang(x - 20 * s, y - 90 * s), hang(x + 22 * s, y - 94 * s), hang(x + 46 * s, y - 96 * s),
            nEllipse(x - 8 * s, y - 130 * s, 12 * s, 5 * s, .f(sh(leafC, 0.3))),
        ]).looping(Loops.sway(GC.rand(6, 9)))
    }

    /// a termite mound: a lumpy red-earth spire
    static func mound(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#c96f43") -> VNode {
        let p = "M\(x - 26 * s),\(y) Q\(x - 28 * s),\(y - 22 * s) \(x - 18 * s),\(y - 30 * s) Q\(x - 22 * s),\(y - 48 * s) \(x - 12 * s),\(y - 58 * s) " +
            "Q\(x - 10 * s),\(y - 78 * s) \(x - 2 * s),\(y - 84 * s) Q\(x + 6 * s),\(y - 82 * s) \(x + 7 * s),\(y - 66 * s) Q\(x + 16 * s),\(y - 62 * s) \(x + 14 * s),\(y - 44 * s) " +
            "Q\(x + 26 * s),\(y - 34 * s) \(x + 22 * s),\(y - 16 * s) Q\(x + 28 * s),\(y - 8 * s) \(x + 27 * s),\(y) Q\(x),\(y + 5 * s) \(x - 26 * s),\(y) Z"
        return nGroup([
            nPath(p, so(c)),
            nPath("M\(x - 6 * s),\(y - 70 * s) Q\(x - 8 * s),\(y - 50 * s) \(x - 4 * s),\(y - 30 * s) M\(x + 10 * s),\(y - 30 * s) Q\(x + 12 * s),\(y - 20 * s) \(x + 8 * s),\(y - 8 * s)", rcap(sh(c, 0.3), 3.5)),
            nPath("M\(x - 18 * s),\(y - 12 * s) q4,-3 8,0 M\(x + 2 * s),\(y - 48 * s) q4,-3 8,0", rcap(sh(c, -0.25), 3)),
        ])
    }

    /// spinifex: a round hummock of spiky golden grass
    static func spinifex(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#c9c065") -> VNode {
        var pts: [Pt] = [(x - 26 * s, y)]
        let n = 11
        for i in 0...n {
            let a = Double.pi + Double(i) / Double(n) * .pi
            let r = (i % 2 == 1 ? 22.0 : 30.0) * s
            pts.append((x + cos(a) * r, y + sin(a) * r * 0.8))
        }
        pts.append((x + 26 * s, y))
        return nGroup([
            nPolygon(pts, so(c, 3.5)),
            nPath("M\(x),\(y - 2) L\(x),\(y - 18 * s) M\(x - 8 * s),\(y - 2) L\(x - 12 * s),\(y - 14 * s) M\(x + 8 * s),\(y - 2) L\(x + 12 * s),\(y - 14 * s)", rcap(sh(c, -0.25), 2.5)),
        ]).looping(Loops.sway(5))
    }

    /// Sturt's desert pea: red flowers with a dark glossy centre
    static func pea(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        func fl(_ a: Double) -> [VNode] {
            let r = a * .pi / 180, fx = x + cos(r) * 13 * s, fy2 = y - 22 * s + sin(r) * 9 * s
            return [
                nPath("M\(fx),\(fy2 - 8 * s) Q\(fx + 9 * s),\(fy2) \(fx),\(fy2 + 8 * s) Q\(fx - 9 * s),\(fy2) \(fx),\(fy2 - 8 * s) Z", so("#e8463c", 3)),
                nCircle(fx, fy2 - 1 * s, 3.2 * s, .f("#2e2426")),
            ]
        }
        let stem = "M\(x),\(y) L\(x),\(y - 20 * s)"
        return nGroup([nPath(stem, rcap(O, 7)), nPath(stem, rcap("#8fae7a", 3))] + fl(200) + fl(-20) + fl(-90) + fl(90))
            .looping(Loops.bob(GC.rand(3, 4.5)))
    }

    /// a wattle bush: soft green with golden pompoms
    static func wattle(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        var r = Seeded(Int((x * 7 + y).rounded()))
        let bush = P.bush(x, y, s, "#8fae5f")
        for _ in 0..<11 {
            let cx = x + (r.next() - 0.5) * 48 * s
            let cy = y - 8 * s - r.next() * 30 * s
            bush.add(nCircle(cx, cy, 4 * s, so("#ffd23f", 2)))
        }
        return bush
    }

    /// a little opal glinting in the dirt
    static func opal(_ u: Double, _ v: Double) -> VNode {
        nGroup([
            nEllipse(u, v, 7, 5, so("#9fd8e8", 2.5)),
            nEllipse(u - 2, v - 1, 3, 2, .f("#f7a8c8")),
            nEllipse(u + 3, v + 1, 2, 1.5, .f("#c5e88a")),
        ]).looping(Loops.glowPulse())
    }

    /// sleeping in its burrow (upright in screen space): a mole cricket with its helmet and shovels
    static func miniCricket(_ p: Pt) -> VNode {
        let x = p.0, y = p.1
        let body = "M\(x - 15),\(y) Q\(x - 17),\(y - 24) \(x),\(y - 26) Q\(x + 17),\(y - 24) \(x + 15),\(y) Z"
        return nGroup([
            nEllipse(x - 16, y - 7, 7, 6, so("#8c5d3c", 3)), nEllipse(x + 16, y - 7, 7, 6, so("#8c5d3c", 3)),
            nPath(body, so("#b9875c", 3.5)),
            nPath("M\(x - 13),\(y - 15) Q\(x),\(y - 18) \(x + 13),\(y - 15) Q\(x + 12),\(y - 25) \(x),\(y - 26) Q\(x - 12),\(y - 25) \(x - 13),\(y - 15) Z", .f("#8c5d3c")),
            nPath(body, St.o(3.5)),
            nPath("M\(x - 5),\(y - 26) q-3,-7 -8,-8 M\(x + 5),\(y - 26) q3,-7 8,-8", rcap(O, 2.5)),
            nGroup([nPath("M\(x - 8),\(y - 10) q3,3 6,0 M\(x + 2),\(y - 10) q3,3 6,0", rcap(O, 2.2))]).looping(Loops.blink(3.8)),
        ])
    }

    /// sleeping in its bank burrow: a platypus, bill and all
    static func miniPlatypus(_ p: Pt) -> VNode {
        let x = p.0, y = p.1
        return nGroup([
            nPath("M\(x - 16),\(y) Q\(x - 18),\(y - 20) \(x),\(y - 22) Q\(x + 18),\(y - 20) \(x + 16),\(y) Z", so("#94694a", 3.5)),
            nEllipse(x, y - 6, 11, 5, so("#6d7383", 3)),
            nGroup([nPath("M\(x - 8),\(y - 13) q3,3 6,0 M\(x + 2),\(y - 13) q3,3 6,0", rcap(O, 2.2))]).looping(Loops.blink(3.8)),
        ])
    }

    // MARK: the two worlds

    static let scenes: [SceneDef] = {
        typealias S = Scenes
        var outback = SceneDef(id: "outback", name: "Red Dirt Outback", bg: "#f7d6ad", ring: "#5fb3c8", particles: "reddust",
                               top: "#dc7f50", left: "#c0663d", right: "#a3532f", lip: "#cf7347")
        outback.sky = { [nGroup([nCircle(490, 96, 40, so("#ffc94a"))]).looping(Loops.sun(5)), P.cloud(130, 130, 0.8, "#fff3e2"), P.gull(380, 150), P.gull(410, 136)] }
        outback.ground = {
            [nEllipse(70, 60, 30, 18, .f("#e39364")), nEllipse(180, 200, 34, 20, .f("#e39364")),
             nPath("M20,150 Q70,130 120,150 T230,140", rcap("#cf7347", 9)),
             // the mole cricket's front door, with a little heap of dug-out dirt
             nEllipse(200, 60, 16, 12, so("#e39364", 3)), nEllipse(196, 62, 8, 6, .f("#5a2f22"))] +
                [(40.0, 200.0), (120, 30), (220, 120), (90, 110)].map { u, v in nCircle(u, v, 4, .f("#b85f38")) }
        }
        outback.leftSide = { r, _ in
            S.strata(["#c0663d", "#cb7448", "#b55c36", "#c46a40"]) +
                // the mole cricket's tunnel, winding down to its chamber
                [nPath("M200,12 Q190,34 160,40 T110,58 T70,76", rcap("#e8a27a", 13))] +
                S.burrow(66, 80, 30, 20, "#c0663d") + S.pebbles(r, "#9a4a2a", 8, 30) + [opal(150, 92), opal(30, 40)]
        }
        outback.rightSide = { r, c in S.strata(["#a3532f", "#ae5d36", "#9a4c2b"]) + S.burrow(150, 66, 36, 24, c) + S.pebbles(r, "#7f3e22", 9) + [opal(60, 96)] }
        outback.sideCritters = {
            let b = S.rightPt(150, 84)
            return [miniCricket(S.leftPt(66, 96)), P.burrowCritter((b.0 + 4, b.1), "#7d6a5c", "#fdfaf3")]
        }
        outback.back = {
            [mound(150, 342, 1.1), gum(420, 330, 1.05), mound(250, 296, 0.75, "#d07a4c"),
             spinifex(340, 292, 1.1), spinifex(108, 374, 1.15), P.rock(480, 368, 0.7, "#b86a48"), pea(214, 318, 1.1), spinifex(468, 338, 0.95)]
        }
        outback.front = { [spinifex(100, 406, 1.25), pea(500, 404, 1.2), P.rock(170, 444, 0.55, "#b86a48"), spinifex(440, 446, 0.75)] }

        var billabong = SceneDef(id: "billabong", name: "Gum Tree Billabong", bg: "#d6e8d8", ring: "#f2b544", particles: "gumleaves",
                                 top: "#9cc46a", left: "#a8774f", right: "#5fb3c8", lip: "#86b055", rightLip: "#4f9fb4")
        billabong.sky = { [P.cloud(120, 120, 0.9), P.cloud(470, 160, 0.7), nGroup([nCircle(500, 80, 30, so("#ffd86b"))]).looping(Loops.sun(5))] }
        billabong.ground = {
            [nPath("M100,0 L240,0 L240,240 L120,240 Q70,190 110,140 Q150,90 100,40 Q90,18 100,0 Z", so("#6cc0d4", 4)),
             nPath("M150,30 Q180,40 200,70", rcap("#ffffff", 4).so(0.5)),
             nEllipse(190, 170, 14, 14, St(stroke: "#ffffff", width: 2.5, strokeOpacity: 0.6)).looping(Loops.ripple),
             nEllipse(40, 190, 22, 14, .f("#b4d67e")), nEllipse(50, 40, 18, 12, .f("#b4d67e"))]
        }
        billabong.leftSide = { r, c in
            S.roots(r, "#7d5034", 4) + S.burrow(90, 66, 34, 22, c) +
                [nPath("M124,60 Q170,40 230,26", rcap(sh(c, 0.18), 12))] + S.pebbles(r, "#8f6545", 9)
        }
        billabong.rightSide = { _, _ in S.waterSide("#5fb3c8") }
        billabong.sideCritters = {
            [miniPlatypus(S.leftPt(90, 82)), P.fish(S.rightPt(70, 55), "#f3b54a", 1), P.fish(S.rightPt(170, 80), "#9fd8e8", -1)]
        }
        billabong.back = {
            [gum(170, 336, 1.15, "#efe6d6", "#8fb08a"), gum(330, 282, 0.9, "#e6d3c4", "#9cbc8c"), wattle(470, 352, 0.85),
             P.reeds(430, 296, 0.8), P.lilypad(400, 330, 0.8, flower: true), P.rock(110, 372, 0.7, "#a3a89f"), P.bird(158, 214, "#c9a27a"), P.tuft(250, 304)]
        }
        billabong.front = { [wattle(100, 404, 0.7), P.reeds(500, 412, 0.8), P.lilypad(430, 446, 0.7, flower: true), P.tuft(170, 434)] }

        return [outback, billabong]
    }()

    // MARK: particles

    static let particles: [String: Scenes.Particle] = [
        /// falling gum leaves: long and narrow, grey-green and a dry one or two
        "gumleaves": { i, x, _, t, _ in
            nGroup([nPath("M0,-10 C4,-5 4,5 0,10 C-4,5 -4,-5 0,-10 Z", St(fill: ["#8fb08a", "#a9c08f", "#d9b25a"][i % 3], stroke: O, width: 2))
                .looping(t.fall)], tr(x, -20))
        },
        /// red dust drifting in the sun
        "reddust": { i, x, y, t, r in
            nGroup([nCircle(0, 0, 2 + r() * 2, .f(["#f6b98a", "#fde3c8", "#e98e5e"][i % 3])).looping(i % 3 != 0 ? t.firefly : t.rise)], tr(x, 110 + y))
        },
    ]
}

import SwiftUI

/// Christmas pack world: Christmas Village. Snowy roofs, warm windows, fairy
/// lights, the church under the star, gifts, a mouse hole with a tiny
/// stocking and a cellar full of presents. Ported from the web's
/// js/packs/christmas.js (props, scene, particles).
enum ChristmasWorld {
    private typealias P = Props
    private typealias X = ChristmasArt
    private static let O = GC.outHex
    private static func so(_ fill: String, _ w: Double = 4.5) -> St { St.o(w).filled(fill) }
    private static func sh(_ c: String, _ a: Double) -> String { GC.shade(c, a) }

    private static let LIGHTS = ["#ff6b6b", "#ffd86b", "#7fd8ff", "#9fe07a"]

    // MARK: props

    /// a string of fairy lights from a to b, sagging by sag
    static func lights(_ a: Pt, _ b: Pt, _ sag: Double, _ n: Int, _ rot: Int = 0) -> [VNode] {
        let c: Pt = ((a.0 + b.0) / 2, (a.1 + b.1) / 2 + sag)
        let pts = Array(X.along(a, c, b, n + 1).dropFirst().dropLast())
        return [nPath("M\(a.0),\(a.1) Q\(c.0),\(c.1) \(b.0),\(b.1)", plain(O, 2))] + pts.enumerated().map { i, p in
            nEllipse(p.0, p.1 + 4, 3.6, 4.6, St(fill: LIGHTS[(i + rot) % 4], stroke: O, width: 2))
                .looping(Loops.twinkle(1.6 + Double((i * 7 + rot) % 5) * 0.35, delay: -Double(i) * 0.37))
        }
    }

    /// a little house: snowy roof, warm window, wreath on the door, fairy lights
    static func house(_ x: Double, _ y: Double, _ s: Double, _ wall: String, _ roof: String, _ chimney: Bool, _ flip: Bool) -> [VNode] {
        let W = 66 * s, H = 46 * s, pk = 36 * s, L = x - W / 2, R = x + W / 2, top = y - H
        var o: [VNode] = []
        if chimney {
            let cx = flip ? x - W * 0.28 : x + W * 0.22
            o.append(nRect(cx, top - pk * 0.95, 12 * s, pk * 0.8, so("#9a5a48", 4)))
            o.append(nRect(cx - 3 * s, top - pk * 1.02, 18 * s, 8 * s, rx: 4 * s, so("#fbfdff", 3.5)))
        }
        o.append(nRect(L, top, W, H, so(wall)))
        // door with a wreath, and a warm window
        let dx = flip ? x + W * 0.2 : x - W * 0.2, wx = flip ? x - W * 0.2 : x + W * 0.18, wy = y - H * 0.55
        o += [
            nPath("M\(dx - 8 * s),\(y) L\(dx - 8 * s),\(y - 18 * s) Q\(dx),\(y - 27 * s) \(dx + 8 * s),\(y - 18 * s) L\(dx + 8 * s),\(y) Z", so("#7a3f45", 3.5)),
            nCircle(dx, y - 15 * s, 4.5 * s, plain(O, 5 * s)),
            nCircle(dx, y - 15 * s, 4.5 * s, plain(X.HOLLY, 2.6 * s)),
            nCircle(wx, wy, 17 * s, St.f("#ffd86b").op(0.28)).looping(Loops.glowPulse()),
            nRect(wx - 9 * s, wy - 9 * s, 18 * s, 18 * s, rx: 2 * s, so("#ffd86b", 3.5)),
            nPath("M\(wx),\(wy - 9 * s) L\(wx),\(wy + 9 * s) M\(wx - 9 * s),\(wy) L\(wx + 9 * s),\(wy)", plain(O, 2.5)),
            nRect(wx - 12 * s, wy + 8 * s, 24 * s, 5 * s, rx: 2.5 * s, so("#fbfdff", 3)),
        ]
        // roof, snow on top, icicles and lights along the eaves
        let snow = "M\(L - 7 * s),\(top - 1) L\(x),\(top - pk - 2) L\(R + 7 * s),\(top - 1)"
        o += [
            nPath("M\(L - 8 * s),\(top + 3) L\(x),\(top - pk) L\(R + 8 * s),\(top + 3) Z", so(roof)),
            nPath(snow, St.line(O, 13 * s + 4)),
            nPath(snow, St.line("#fbfdff", 13 * s - 3)),
        ]
        var ix = L + 4
        while ix < R - 4 {
            let drop = (6 + (ix * 7).truncatingRemainder(dividingBy: 5)) * s
            o.append(nPath("M\(ix),\(top + 2) L\(ix + 3.5 * s),\(top + 2 + drop) L\(ix + 7 * s),\(top + 2) Z", so("#e6f3fb", 2)))
            ix += 11 * s
        }
        o += lights((L - 2, top + 8), (R + 2, top + 8), 7 * s, 6, Int(x.rounded()))
        return o
    }

    /// the church under the star
    static func church(_ x: Double, _ y: Double, _ s: Double) -> [VNode] {
        let roofSnow = "M\(x - 18 * s),\(y - 116 * s) L\(x),\(y - 148 * s) L\(x + 18 * s),\(y - 116 * s)"
        return [
            nPath("M\(x - 30 * s),\(y - 50 * s) L\(x - 30 * s),\(y - 94 * s) L\(x),\(y - 150 * s) L\(x + 30 * s),\(y - 94 * s) L\(x + 30 * s),\(y - 50 * s) Z", so("#4a5a7a")),
            nPath(roofSnow, St.line(O, 9 * s + 4)),
            nPath(roofSnow, St.line("#fbfdff", 9 * s - 3)),
            nRect(x - 22 * s, y - 98 * s, 44 * s, 60 * s, so("#e3d6c0")),
            nCircle(x, y - 78 * s, 16 * s, St.f("#ffd86b").op(0.3)).looping(Loops.glowPulse()),
            nCircle(x, y - 78 * s, 9 * s, so("#ffd86b", 3.5)),
            nPath("M\(x),\(y - 87 * s) L\(x),\(y - 69 * s) M\(x - 9 * s),\(y - 78 * s) L\(x + 9 * s),\(y - 78 * s)", plain(O, 2.5)),
            nRect(x - 24 * s, y - 101 * s, 48 * s, 7 * s, rx: 3.5 * s, so("#fbfdff", 3.5)),
        ]
    }

    /// a decorated Christmas tree with baubles and a star
    static func xmasTree(_ x: Double, _ y: Double, _ s: Double) -> VNode {
        func t(_ yy: Double, _ ww: Double, _ hh: Double, _ col: String) -> VNode {
            nPath("M\(x - ww),\(yy) L\(x),\(yy - hh) L\(x + ww),\(yy) Q\(x),\(yy + 7 * s) \(x - ww),\(yy) Z", so(col))
        }
        let balls: [(Double, Double, String)] = [(-22, -30, X.BERRY), (18, -34, X.GOLD), (-12, -62, "#7fd8ff"), (14, -66, X.BERRY), (0, -92, X.GOLD), (-26, -8, X.GOLD), (24, -10, "#7fd8ff")]
        return nGroup([
            nRect(x - 6 * s, y - 14 * s, 12 * s, 16 * s, rx: 3, so("#8a5a3b")),
            t(y - 10 * s, 40 * s, 46 * s, "#3f8a5a"), t(y - 42 * s, 32 * s, 42 * s, "#4f9a62"), t(y - 72 * s, 23 * s, 38 * s, "#5aa86c"),
        ] + balls.map { dx, dy, c in nCircle(x + dx * s, y + dy * s, 4.6 * s, so(c, 2.5)) } + [
            nPolygon(X.starPts(x, y - 112 * s, 12 * s, 5.5 * s), so(X.GOLD, 3.5)),
        ]).looping(Loops.sway(7))
    }

    /// a gift box
    static func gift(_ x: Double, _ y: Double, _ s: Double, _ box: String, _ ribbon: String) -> [VNode] {
        let W = 30 * s, H = 24 * s
        return [
            nRect(x - W / 2, y - H, W, H, rx: 2, so(box, 4)),
            nRect(x - 3.5 * s, y - H, 7 * s, H, .f(ribbon)),
            nRect(x - W / 2 - 3 * s, y - H - 7 * s, W + 6 * s, 9 * s, rx: 2, so(box, 4)),
            nRect(x - 3.5 * s, y - H - 7 * s, 7 * s, 9 * s, .f(ribbon)),
            nRect(x - W / 2, y - H, W, H, rx: 2, St.o(4)),
            nEllipse(x - 6 * s, y - H - 10 * s, 7 * s, 4.5 * s, so(ribbon, 3)).moved(rotAbout(-25, x - 6 * s, y - H - 10 * s)),
            nEllipse(x + 6 * s, y - H - 10 * s, 7 * s, 4.5 * s, so(ribbon, 3)).moved(rotAbout(25, x + 6 * s, y - H - 10 * s)),
            nCircle(x, y - H - 9 * s, 3.5 * s, so(ribbon, 2.5)),
        ]
    }
    static func gift(_ p: Pt, _ s: Double, _ box: String, _ ribbon: String) -> [VNode] { gift(p.0, p.1, s, box, ribbon) }

    /// a street lamp with a warm glow
    static func lamp(_ x: Double, _ y: Double, _ s: Double) -> [VNode] {
        [
            nRect(x - 3 * s, y - 58 * s, 6 * s, 58 * s, so("#3f4a6a", 3.5)),
            nCircle(x, y - 66 * s, 18 * s, St.f("#ffe28a").op(0.3)).looping(Loops.flicker),
            nRect(x - 8 * s, y - 74 * s, 16 * s, 16 * s, rx: 4 * s, so("#ffe28a", 3.5)),
            nPath("M\(x - 11 * s),\(y - 75 * s) L\(x + 11 * s),\(y - 75 * s) L\(x),\(y - 84 * s) Z", so("#3f4a6a", 3.5)),
            nPath("M\(x - 10 * s),\(y - 77 * s) Q\(x),\(y - 88 * s) \(x + 10 * s),\(y - 77 * s)", rcap("#fbfdff", 5 * s)),
        ]
    }

    /// the star over the church
    static func bigStar(_ x: Double, _ y: Double) -> [VNode] {
        [
            nCircle(x, y, 58, St.f("#fff1b0").op(0.2)).looping(Loops.glowPulse()),
            nPath("M\(x),\(y - 40) Q\(x + 5),\(y - 5) \(x + 40),\(y) Q\(x + 5),\(y + 5) \(x),\(y + 40) Q\(x - 5),\(y + 5) \(x - 40),\(y) Q\(x - 5),\(y - 5) \(x),\(y - 40) Z", so("#ffe27a", 3.5)),
            nPath("M\(x - 14),\(y - 14) Q\(x),\(y) \(x + 14),\(y - 14) Q\(x),\(y) \(x + 14),\(y + 14) Q\(x),\(y) \(x - 14),\(y + 14) Q\(x),\(y) \(x - 14),\(y - 14) Z", so("#fff6cf", 2.5)),
        ]
    }

    /// a tiny mouse peeking out of its hole (upright, screen space)
    static func peekMouse(_ p: Pt) -> VNode {
        let x = p.0, y = p.1
        return nGroup([
            nCircle(x - 9, y - 22, 7, so("#b6aeb0", 3)), nCircle(x + 9, y - 22, 7, so("#b6aeb0", 3)),
            nCircle(x - 9, y - 22, 3.2, .f("#f6b3bf")), nCircle(x + 9, y - 22, 3.2, .f("#f6b3bf")),
            nPath("M\(x - 13),\(y) Q\(x - 15),\(y - 22) \(x),\(y - 22) Q\(x + 15),\(y - 22) \(x + 13),\(y) Z", so("#b6aeb0", 3.5)),
            nGroup([nEllipse(x - 5, y - 12, 2.4, 3, .f(O)), nEllipse(x + 5, y - 12, 2.4, 3, .f(O))]).looping(Loops.blink(3.8)),
            nCircle(x, y - 7, 2.2, .f("#f18ea0")),
        ])
    }

    /// a tiny stocking hung on a nail (upright)
    static func stocking(_ p: Pt) -> VNode {
        let x = p.0, y = p.1
        return nGroup([
            nPath("M\(x),\(y - 3) L\(x),\(y + 3)", rcap(O, 3)),
            nPath("M\(x - 6),\(y + 3) L\(x + 6),\(y + 3) L\(x + 6),\(y + 17) Q\(x + 14),\(y + 18) \(x + 13),\(y + 25) Q\(x + 10),\(y + 29) \(x),\(y + 26) Q\(x - 6),\(y + 24) \(x - 6),\(y + 17) Z", so("#d6423f", 3)),
            nRect(x - 8, y + 1, 16, 6, rx: 3, so("#fbfdff", 2.5)),
        ])
    }

    /// an arched mouse hole in the side (face-local, like the burrows)
    static func mouseHole(_ u: Double, _ v: Double, _ rw: Double, _ rh: Double, _ c: String) -> [VNode] {
        [
            nPath("M\(u - rw),\(v + rh) L\(u - rw),\(v) A\(rw),\(rw) 0 0 1 \(u + rw),\(v) L\(u + rw),\(v + rh) Z", so(sh(c, -0.45), 4.5)),
            nPath("M\(u - rw + 4),\(v + rh - 4) L\(u + rw - 4),\(v + rh - 4)", plain(sh(c, -0.25), 5)),
        ]
    }

    /// a cellar dug into the side (face-local)
    static func cellar(_ u: Double, _ v: Double, _ rx: Double, _ ry: Double, _ c: String) -> [VNode] {
        [
            nEllipse(u, v, rx, ry, so(sh(c, -0.4), 4.5)),
            nPath("M\(u - rx + 8),\(v + ry * 0.55) L\(u + rx - 8),\(v + ry * 0.55)", rcap("#8a5a3b", 5)),
        ]
    }

    // MARK: the world

    static let scenes: [SceneDef] = {
        typealias S = Scenes
        var v = SceneDef(id: "xmasvillage", name: "Christmas Village", bg: "#34406c", ring: "#ffd86b", particles: "snowflakes",
                         top: "#f4f8fb", left: "#9b7a68", right: "#7d5f50", lip: "#e6eef4")
        v.dark = true
        v.sky = { P.stars() + bigStar(300, 58) }
        v.ground = {
            [nPath("M120,240 Q118,170 140,120 T120,0", rcap("#dbe5ee", 26))] +
                [(132.0, 200.0), (124, 172), (136, 146), (128, 118)].enumerated().map { i, p in nEllipse(p.0 + Double(i % 2) * 8, p.1, 3.5, 5, .f("#c9d8e4")) } +
                [nEllipse(44, 190, 26, 16, .f("#e3ecf4")), nEllipse(200, 44, 22, 14, .f("#e3ecf4"))]
        }
        v.leftSide = { r, c in
            [nRect(0, 12, 240, 10, St.f("#dfeaf2").op(0.5))] + S.roots(r, "#6b4c3e", 2) +
                mouseHole(76, 70, 22, 30, c) + S.pebbles(r, "#86685a", 8) + lights((4, 26), (236, 26), 12, 9, 1)
        }
        v.rightSide = { r, c in
            [nRect(0, 12, 240, 10, St.f("#dfeaf2").op(0.4))] + cellar(150, 68, 52, 30, c) + S.pebbles(r, "#6b5044", 7) +
                S.icicles() + lights((4, 30), (236, 30), 12, 9, 2)
        }
        v.sideCritters = {
            [peekMouse(S.leftPt(76, 100)), stocking(S.leftPt(116, 64))] +
                gift(S.rightPt(126, 92), 0.62, X.BERRY, X.GOLD) + gift(S.rightPt(156, 90), 0.55, "#4f9a62", "#fbfdff") +
                gift(S.rightPt(176, 86), 0.45, "#7fb6d8", X.BERRY) + [P.candle(S.rightPt(102, 94).0, S.rightPt(102, 94).1, 0.6)]
        }
        v.back = {
            [P.pine(226, 290, 0.75, "#4f8f6a", "#6aaa84", snow: true), P.pine(380, 292, 0.7, "#4f8f6a", "#6aaa84", snow: true)] +
                church(300, 284, 1.32) +
                house(164, 338, 1.32, "#c4674a", "#5a4660", true, false) + house(438, 340, 1.25, "#6f8fa6", "#4a3a4a", true, true) +
                gift(246, 318, 0.8, "#f2a0b8", "#fbfdff") + lamp(360, 322, 0.85)
        }
        v.front = {
            [xmasTree(100, 404, 0.62)] + gift(502, 404, 0.9, X.BERRY, X.GOLD) + gift(480, 412, 0.65, "#4f9a62", "#fbfdff") +
                gift(204, 436, 0.6, "#7fb6d8", X.BERRY) + [P.snowman(424, 438, 0.85)]
        }
        return [v]
    }()

    // MARK: particles

    static let particles: [String: Scenes.Particle] = [
        /// falling snow, every third one a little six-armed flake
        "snowflakes": { i, x, _, t, r in
            if i % 3 != 0 {
                return nGroup([nCircle(0, 0, 2.5 + r() * 3, .f("#ffffff")).looping(t.fall)], tr(x, -20))
            }
            return nGroup([nGroup(X.flake(0, 0, 6, "#ffffff", 2, outline: "#c7d9e6", outlineWidth: 4)).looping(t.fall)], tr(x, -20))
        },
    ]
}

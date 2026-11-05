import SwiftUI

/// Scenery props for the worlds (trees, flowers, critters…). Each returns a
/// node in stage coordinates (viewBox 0 0 600 720).
enum Props {
    static let O = GC.outHex
    static func so(_ fill: String, _ w: Double = 4.5) -> St { St.o(w).filled(fill) }
    static func sh(_ c: String, _ a: Double) -> String { GC.shade(c, a) }

    static func pine(_ x: Double, _ y: Double, _ s: Double, _ c: String = "#5a9a4e", _ c2: String = "#7cc06a", snow: Bool = false) -> VNode {
        func t(_ yy: Double, _ ww: Double, _ hh: Double, _ col: String) -> [VNode] {
            var out = [nPath("M\(x - ww),\(yy) L\(x),\(yy - hh) L\(x + ww),\(yy) Q\(x),\(yy + 8 * s) \(x - ww),\(yy) Z", so(col))]
            if snow {
                out.append(nPath("M\(x - ww * 0.42),\(yy - hh * 0.58) L\(x),\(yy - hh) L\(x + ww * 0.42),\(yy - hh * 0.58) Q\(x + ww * 0.15),\(yy - hh * 0.5) \(x),\(yy - hh * 0.62) Q\(x - ww * 0.15),\(yy - hh * 0.5) \(x - ww * 0.42),\(yy - hh * 0.58) Z", so("#fbfdff", 3.5)))
            }
            return out
        }
        var kids = [nRect(x - 7 * s, y - 26 * s, 14 * s, 28 * s, rx: 3, so("#8a5a3b"))]
        kids += t(y - 22 * s, 44 * s, 52 * s, c)
        kids += t(y - 58 * s, 36 * s, 48 * s, c2)
        kids += t(y - 92 * s, 27 * s, 44 * s, sh(c2, 0.12))
        return nGroup(kids).looping(Loops.sway(GC.rand(5, 8)))
    }

    static func roundTree(_ x: Double, _ y: Double, _ s: Double, _ c: String = "#7cbf5a", _ trunk: String = "#8a5a3b") -> VNode {
        let r = 30 * s
        return nGroup([
            nPath("M\(x - 7 * s),\(y) L\(x - 5 * s),\(y - 60 * s) L\(x + 5 * s),\(y - 60 * s) L\(x + 7 * s),\(y) Z", so(trunk)),
            nCircle(x - r * 0.75, y - 70 * s, r * 0.8, so(c)),
            nCircle(x + r * 0.75, y - 72 * s, r * 0.82, so(c)),
            nCircle(x, y - 92 * s, r, so(c)),
            nCircle(x - r * 0.3, y - 100 * s, r * 0.35, .f(sh(c, 0.25))),
            nPath("M\(x - r * 1.2),\(y - 66 * s) Q\(x),\(y - 50 * s) \(x + r * 1.25),\(y - 68 * s)", .f(c)),
        ]).looping(Loops.sway(GC.rand(5, 8)))
    }

    /// a tall trunk that runs out of the top of the picture
    static func trunk(_ x: Double, _ y: Double, _ w: Double = 26, _ c: String = "#8a5a3b") -> VNode {
        nGroup([
            nPath("M\(x - w / 2 - 6),\(y) Q\(x - w / 2),\(y - 40) \(x - w / 2),\(y - 120) L\(x - w / 2 + 4),-20 L\(x + w / 2 - 4),-20 L\(x + w / 2),\(y - 120) Q\(x + w / 2),\(y - 40) \(x + w / 2 + 6),\(y) Z", so(c)),
            nPath("M\(x - 3),\(y - 30) L\(x - 2),\(y - 160) M\(x + 6),\(y - 90) L\(x + 7),\(y - 230)", St.line(sh(c, -0.25), 3)),
        ])
    }

    static func mushroom(_ x: Double, _ y: Double, _ s: Double, _ cap: String = "#e8604f", _ spot: String = "#fdf3e4", glow: Bool = false) -> VNode {
        let g = nGroup([
            nPath("M\(x - 7 * s),\(y) Q\(x - 6 * s),\(y - 16 * s) \(x - 5 * s),\(y - 22 * s) L\(x + 5 * s),\(y - 22 * s) Q\(x + 6 * s),\(y - 16 * s) \(x + 7 * s),\(y) Z", so("#fbf1dc", 4)),
            nPath("M\(x - 22 * s),\(y - 20 * s) Q\(x - 20 * s),\(y - 46 * s) \(x),\(y - 46 * s) Q\(x + 20 * s),\(y - 46 * s) \(x + 22 * s),\(y - 20 * s) Q\(x),\(y - 14 * s) \(x - 22 * s),\(y - 20 * s) Z", so(cap, 4)),
            nCircle(x - 8 * s, y - 32 * s, 4 * s, .f(spot)),
            nCircle(x + 8 * s, y - 36 * s, 3 * s, .f(spot)),
            nCircle(x + 12 * s, y - 25 * s, 2.5 * s, .f(spot)),
        ])
        return glow ? g.looping(Loops.glowPulse()) : g
    }

    static func flower(_ x: Double, _ y: Double, _ s: Double, _ petal: String = "#f7a8c8", _ center: String = "#ffd86b") -> VNode {
        let r = 6 * s
        let stem = "M\(x),\(y) Q\(x - 3 * s),\(y - 12 * s) \(x),\(y - 22 * s)"
        var kids = [nPath(stem, St.line(O, 7 * min(s, 1.2))), nPath(stem, St.line("#6aa84f", 3))]
        for i in 0..<5 {
            let a = Double(i) / 5 * Double.pi * 2 - Double.pi / 2
            kids.append(nCircle(x + cos(a) * r, y - 22 * s + sin(a) * r, r * 0.8, so(petal, 3)))
        }
        kids.append(nCircle(x, y - 22 * s, r * 0.6, so(center, 3)))
        return nGroup(kids).looping(Loops.bob(GC.rand(2.5, 4)))
    }

    static func tuft(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#5f9a3e") -> VNode {
        nPath("M\(x - 10 * s),\(y) Q\(x - 12 * s),\(y - 12 * s) \(x - 16 * s),\(y - 18 * s) Q\(x - 4 * s),\(y - 12 * s) \(x - 2 * s),\(y - 4 * s) Q\(x),\(y - 18 * s) \(x + 4 * s),\(y - 24 * s) Q\(x + 6 * s),\(y - 12 * s) \(x + 4 * s),\(y - 3 * s) Q\(x + 10 * s),\(y - 14 * s) \(x + 16 * s),\(y - 16 * s) Q\(x + 12 * s),\(y - 6 * s) \(x + 10 * s),\(y) Z", so(c, 3.5))
    }

    static func fern(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#4f9a5a") -> VNode {
        var kids: [VNode] = []
        for side in [-1.0, 1.0] {
            for i in 0..<3 {
                let yy = y - 8 * s - Double(i) * 9 * s
                kids.append(nEllipse(x + side * 10 * s, yy, 10 * s, 5 * s, so(c, 3)).moved(rotAbout(side * -25, x + side * 10 * s, yy)))
            }
        }
        kids.append(nPath("M\(x),\(y) L\(x),\(y - 34 * s)", St.line(O, 3)))
        return nGroup(kids).looping(Loops.sway(4))
    }

    static func rock(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#9aa09a") -> VNode {
        nGroup([
            nPath("M\(x - 22 * s),\(y) Q\(x - 24 * s),\(y - 18 * s) \(x - 8 * s),\(y - 22 * s) Q\(x + 6 * s),\(y - 30 * s) \(x + 18 * s),\(y - 16 * s) Q\(x + 26 * s),\(y - 6 * s) \(x + 20 * s),\(y) Q\(x),\(y + 5 * s) \(x - 22 * s),\(y) Z", so(c)),
            nPath("M\(x - 10 * s),\(y - 16 * s) Q\(x - 2 * s),\(y - 22 * s) \(x + 6 * s),\(y - 20 * s)", St.line(sh(c, 0.35), 3)),
        ])
    }

    static func bush(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#6fae57") -> VNode {
        nGroup([
            nCircle(x - 14 * s, y - 12 * s, 14 * s, so(c)),
            nCircle(x + 14 * s, y - 12 * s, 14 * s, so(c)),
            nCircle(x, y - 22 * s, 16 * s, so(c)),
            nPath("M\(x - 26 * s),\(y - 6 * s) L\(x + 26 * s),\(y - 6 * s) L\(x + 22 * s),\(y) L\(x - 22 * s),\(y) Z", .f(c)),
            nPath("M\(x - 28 * s),\(y - 4 * s) Q\(x),\(y + 4 * s) \(x + 28 * s),\(y - 4 * s)", St.line(O, 4.5)),
        ]).looping(Loops.sway(6))
    }

    static func candle(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        nGroup([
            nPath("M\(x - 12 * s),\(y) Q\(x),\(y + 6 * s) \(x + 12 * s),\(y) Q\(x + 12 * s),\(y - 10 * s) \(x),\(y - 10 * s) Q\(x - 12 * s),\(y - 10 * s) \(x - 12 * s),\(y) Z", so("#a9aaa0", 3.5)),
            nRect(x - 4 * s, y - 26 * s, 8 * s, 18 * s, rx: 2, so("#fbf1dc", 3)),
            nCircle(x, y - 33 * s, 13 * s, St.f("#ffe28a").op(0.35)).looping(Loops.flicker),
            nPath("M\(x),\(y - 40 * s) Q\(x + 5 * s),\(y - 32 * s) \(x),\(y - 28 * s) Q\(x - 5 * s),\(y - 32 * s) \(x),\(y - 40 * s) Z", so("#ffc94a", 2.5)).looping(Loops.flicker),
        ])
    }

    static func cactus(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#79b35b") -> VNode {
        nGroup([
            nPath("M\(x - 10 * s),\(y) L\(x - 10 * s),\(y - 58 * s) Q\(x),\(y - 72 * s) \(x + 10 * s),\(y - 58 * s) L\(x + 10 * s),\(y) Z", so(c)),
            nPath("M\(x - 10 * s),\(y - 26 * s) L\(x - 22 * s),\(y - 26 * s) Q\(x - 28 * s),\(y - 28 * s) \(x - 28 * s),\(y - 36 * s) L\(x - 28 * s),\(y - 46 * s) Q\(x - 22 * s),\(y - 54 * s) \(x - 17 * s),\(y - 46 * s) L\(x - 17 * s),\(y - 36 * s) L\(x - 10 * s),\(y - 36 * s)", so(c)),
            nPath("M\(x + 10 * s),\(y - 34 * s) L\(x + 20 * s),\(y - 34 * s) L\(x + 20 * s),\(y - 48 * s) Q\(x + 25 * s),\(y - 55 * s) \(x + 30 * s),\(y - 48 * s) L\(x + 30 * s),\(y - 30 * s) Q\(x + 28 * s),\(y - 24 * s) \(x + 20 * s),\(y - 24 * s) L\(x + 10 * s),\(y - 24 * s)", so(c)),
            nPath("M\(x),\(y - 8 * s) L\(x),\(y - 54 * s)", St.line(sh(c, -0.2), 3)),
            nCircle(x, y - 66 * s, 5 * s, so("#f7a8c8", 3)),
        ])
    }

    static func palm(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        var kids = [nPath("M\(x - 7 * s),\(y) Q\(x - 4 * s),\(y - 50 * s) \(x + 2 * s),\(y - 92 * s) L\(x + 10 * s),\(y - 92 * s) Q\(x + 6 * s),\(y - 50 * s) \(x + 7 * s),\(y) Z", so("#b8875a"))]
        for a in [-150.0, -115, -65, -30, -95] {
            let r = a * Double.pi / 180
            let ex = x + cos(r) * 46 * s + 6 * s, ey = y - 90 * s + sin(r) * 30 * s + 10 * s
            kids.append(nPath("M\(x + 6 * s),\(y - 92 * s) Q\((x + ex) / 2),\(ey - 26 * s) \(ex),\(ey + 6 * s) Q\((x + ex) / 2 + 4),\(ey - 10 * s) \(x + 6 * s),\(y - 88 * s) Z", so("#6fb35a", 4)))
        }
        kids.append(nCircle(x + 2 * s, y - 86 * s, 5 * s, so("#8a5a3b", 3)))
        kids.append(nCircle(x + 11 * s, y - 84 * s, 5 * s, so("#8a5a3b", 3)))
        return nGroup(kids).looping(Loops.sway(6))
    }

    static func reeds(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        var kids: [VNode] = []
        for (i, dx) in [-8.0, 0, 9].enumerated() {
            let top = y - (44 + Double(i) * 6) * s
            let d = "M\(x + dx),\(y) Q\(x + dx - 2),\(y - 30 * s) \(x + dx + 2),\(top)"
            kids.append(nPath(d, St.line(O, 7)))
            kids.append(nPath(d, St.line("#7aa84f", 3)))
            if i != 1 { kids.append(nRect(x + dx - 3, top, 9, 16 * s, rx: 4.5, so("#8a5a3b", 3))) }
        }
        return nGroup(kids)
    }

    static func lilypad(_ x: Double, _ y: Double, _ s: Double = 1, flower: Bool = false) -> VNode {
        var kids = [nPath("M\(x),\(y) L\(x + 22 * s),\(y - 4 * s) A\(24 * s),\(12 * s) 0 1 1 \(x + 18 * s),\(y + 6 * s) Z", so("#7cc26a", 3.5))]
        if flower {
            kids.append(nGroup([nPath("M-8,0 L-4,-12 L0,-4 L4,-14 L8,-4 L12,-10 L12,2 Q2,6 -8,0 Z", so("#f7b6c8", 3))], tr(x - 4, y - 4)))
        }
        return nGroup(kids)
    }

    static func shell(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#f7c4b0") -> VNode {
        nGroup([
            nPath("M\(x - 12 * s),\(y) Q\(x - 14 * s),\(y - 18 * s) \(x),\(y - 20 * s) Q\(x + 14 * s),\(y - 18 * s) \(x + 12 * s),\(y) Q\(x),\(y + 4 * s) \(x - 12 * s),\(y) Z", so(c, 3.5)),
            nPath("M\(x),\(y + 1) L\(x),\(y - 18 * s) M\(x - 6 * s),\(y) L\(x - 4 * s),\(y - 16 * s) M\(x + 6 * s),\(y) L\(x + 4 * s),\(y - 16 * s)", St.line(O, 2.5)),
        ])
    }

    static func starfish(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#f39a6b") -> VNode {
        var pts: [Pt] = []
        for i in 0..<10 {
            let a = Double(i) / 10 * Double.pi * 2 - Double.pi / 2, r = (i % 2 == 1 ? 6.0 : 15.0) * s
            pts.append((x + cos(a) * r, y + sin(a) * r * 0.6))
        }
        return nPolygon(pts, so(c, 3.5))
    }

    static func crystal(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#9fd8e8") -> VNode {
        nGroup([
            nPath("M\(x - 8 * s),\(y) L\(x - 10 * s),\(y - 22 * s) L\(x),\(y - 36 * s) L\(x + 10 * s),\(y - 22 * s) L\(x + 8 * s),\(y) Z", so(c, 3.5)),
            nPath("M\(x + 6 * s),\(y) L\(x + 14 * s),\(y - 14 * s) L\(x + 20 * s),\(y - 6 * s) L\(x + 16 * s),\(y) Z", so(sh(c, -0.15), 3)),
            nPath("M\(x - 4 * s),\(y - 6 * s) L\(x - 5 * s),\(y - 22 * s)", St.line("#ffffff", 3).op(0.8)),
        ]).looping(Loops.glowPulse())
    }
    static func crystal(_ p: Pt, _ s: Double, _ c: String) -> VNode { crystal(p.0, p.1, s, c) }

    static func seaweed(_ x: Double, _ y: Double, _ h: Double = 70, _ c: String = "#6fbf7a") -> VNode {
        let d = "M\(x),\(y) C\(x - 14),\(y - h * 0.3) \(x + 14),\(y - h * 0.6) \(x),\(y - h)"
        return nGroup([nPath(d, St.line(O, 14)), nPath(d, St.line(c, 6))]).looping(Loops.seaSway(GC.rand(3, 5)))
    }

    static func coral(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#f39a9a") -> VNode {
        let d = "M\(x),\(y) L\(x),\(y - 30 * s) M\(x),\(y - 16 * s) L\(x - 14 * s),\(y - 30 * s) L\(x - 14 * s),\(y - 40 * s) M\(x),\(y - 20 * s) L\(x + 12 * s),\(y - 34 * s) L\(x + 12 * s),\(y - 44 * s)"
        return nGroup([nPath(d, St.line(O, 13 * s)), nPath(d, St.line(c, 6 * s))])
    }

    static func pumpkin(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        let stalk = "M\(x),\(y - 25 * s) Q\(x + 2 * s),\(y - 34 * s) \(x + 8 * s),\(y - 34 * s)"
        return nGroup([
            nEllipse(x, y - 12 * s, 20 * s, 14 * s, so("#f29a3c")),
            nPath("M\(x),\(y - 25 * s) Q\(x - 8 * s),\(y - 12 * s) \(x),\(y + 1) M\(x),\(y - 25 * s) Q\(x + 8 * s),\(y - 12 * s) \(x),\(y + 1)", St(stroke: O, width: 3)),
            nPath(stalk, St.line(O, 7)),
            nPath(stalk, St.line("#6a8a3e", 3)),
        ])
    }

    static func lantern(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        nGroup([
            nPath("M\(x),\(y) L\(x),\(y - 40 * s)", St(stroke: O, width: 4)),
            nCircle(x, y - 50 * s, 18 * s, St.f("#ffe28a").op(0.35)).looping(Loops.flicker),
            nRect(x - 8 * s, y - 60 * s, 16 * s, 20 * s, rx: 5 * s, so("#ffd86b", 3.5)),
            nPath("M\(x - 10 * s),\(y - 60 * s) L\(x + 10 * s),\(y - 60 * s)", St.line(O, 5)),
        ])
    }

    static func snowman(_ x: Double, _ y: Double, _ s: Double = 1) -> VNode {
        nGroup([
            nCircle(x, y - 14 * s, 15 * s, so("#fbfdff")),
            nCircle(x, y - 38 * s, 11 * s, so("#fbfdff")),
            nCircle(x - 4 * s, y - 40 * s, 1.8, .f(O)),
            nCircle(x + 4 * s, y - 40 * s, 1.8, .f(O)),
            nPath("M\(x),\(y - 36 * s) L\(x + 9 * s),\(y - 34 * s) L\(x),\(y - 33 * s) Z", so("#f29a3c", 2)),
            nPath("M\(x - 12 * s),\(y - 30 * s) Q\(x),\(y - 24 * s) \(x + 12 * s),\(y - 30 * s)", St.line("#e8604f", 5)),
        ])
    }

    static func bird(_ x: Double, _ y: Double, _ c: String = "#9fd8e8") -> VNode {
        nGroup([
            nEllipse(x, y - 8, 9, 8, so(c, 3.5)),
            nCircle(x + 3, y - 10, 1.6, .f(O)),
            nPath("M\(x + 8),\(y - 9) L\(x + 13),\(y - 7) L\(x + 8),\(y - 5) Z", so("#f7a531", 2)),
        ]).looping(Loops.bob(1.6))
    }

    static func crab(_ x: Double, _ y: Double) -> VNode {
        nGroup([
            nEllipse(x, y - 8, 14, 9, so("#ef6b55", 3.5)),
            nCircle(x - 16, y - 16, 5, so("#ef6b55", 3)),
            nCircle(x + 16, y - 16, 5, so("#ef6b55", 3)),
            nCircle(x - 4, y - 11, 1.8, .f(O)),
            nCircle(x + 4, y - 11, 1.8, .f(O)),
        ]).looping(Loops.scuttle)
    }
    static func crab(_ p: Pt) -> VNode { crab(p.0, p.1) }

    static func butterfly(_ x: Double, _ y: Double, _ c: String = "#f7a8c8") -> VNode {
        func wing(_ k: Double) -> VNode {
            nGroup([
                nPath("M0,-1 C-5,-17 -21,-19 -20,-7 C-19,1 -8,2 0,-1 Z", so(c, 2.5)),
                nPath("M0,1 C-4,12 -15,14 -14,6 C-13,1 -6,0 0,1 Z", so(sh(c, -0.12), 2.5)),
                nCircle(-12, -8, 2.6, .f("#fdfaf3")),
            ], CGAffineTransform(scaleX: k, y: 1))
        }
        return nGroup([
            nGroup([wing(1), wing(-1)]).looping(Loops.flap),
            nRect(-2, -9, 4, 17, rx: 2, .f(O)),
            nPath("M-1,-9 Q-4,-16 -7,-17 M1,-9 Q4,-16 7,-17", St.line(O, 1.8)),
        ]).looping(Loops.flutter(x, y))
    }

    static func cloud(_ x: Double, _ y: Double, _ s: Double = 1, _ c: String = "#fdfaf3") -> VNode {
        nGroup([
            nPath("M\(x - 40 * s),\(y) Q\(x - 44 * s),\(y - 20 * s) \(x - 20 * s),\(y - 20 * s) Q\(x - 14 * s),\(y - 40 * s) \(x + 8 * s),\(y - 34 * s) Q\(x + 28 * s),\(y - 40 * s) \(x + 32 * s),\(y - 20 * s) Q\(x + 50 * s),\(y - 18 * s) \(x + 44 * s),\(y) Z", so(c, 4)),
        ]).looping(Loops.drift(GC.rand(50, 80)))
    }

    /// a sleepy critter living in a side burrow (drawn upright in screen space)
    static func burrowCritter(_ p: Pt, _ c: String = "#3d3536", _ eye: String = "#fdfaf3") -> VNode {
        let x = p.0, y = p.1
        return nGroup([
            nPath("M\(x - 14),\(y) Q\(x - 16),\(y - 22) \(x),\(y - 24) Q\(x + 16),\(y - 22) \(x + 14),\(y) Z", so(c, 3.5)),
            nGroup([nEllipse(x - 5, y - 13, 2.6, 3.2, .f(eye)), nEllipse(x + 5, y - 13, 2.6, 3.2, .f(eye))]).looping(Loops.blink(3.8)),
        ]).tagged("burrow")
    }

    static func fish(_ p: Pt, _ c: String = "#f3b54a", _ dir: Double = 1) -> VNode {
        let body = nGroup([
            nPath("M-12,0 Q0,-10 12,0 Q0,10 -12,0 Z M-12,0 L-20,-7 L-20,7 Z", so(c, 3)),
            nCircle(6, -2, 1.6, .f(O)),
        ], CGAffineTransform(translationX: p.0, y: p.1).scaledBy(x: dir, y: 1))
        return nGroup([body]).looping(Loops.swim(dir * 40, GC.rand(5, 8)))
    }
    static func fish(_ x: Double, _ y: Double, _ c: String, _ dir: Double) -> VNode { fish((x, y), c, dir) }

    static func gull(_ x: Double, _ y: Double) -> VNode {
        nGroup([nPath("M\(x - 12),\(y) Q\(x - 6),\(y - 8) \(x),\(y) Q\(x + 6),\(y - 8) \(x + 12),\(y)", St.line(O, 3.5))]).looping(Loops.glide)
    }

    static func stars() -> [VNode] {
        var r = Seeded(7)
        var out: [VNode] = []
        for _ in 0..<26 {
            let x = r.next() * 600, y = r.next() * 230
            let td = 2 + r.next() * 3
            let delay = -(r.next() * 4)
            let rad = 1.5 + r.next() * 2
            out.append(nCircle(x, y, rad, .f("#fff6c9")).looping(Loops.twinkle(td, delay: delay)))
        }
        return out
    }
}

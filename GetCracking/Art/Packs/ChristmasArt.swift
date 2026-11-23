import SwiftUI

/// Christmas pack: 13 festive friends in the house style, borrowing designs
/// and colours from Advent Eggs:
///   Christmas baking  Gingerbread Pal, Christmas Tree Cookie, Shortbread Star, Christmas Pudding
///   The Nutcracker    Nutcracker, Sugar Plum Fairy, Mouse King, Snowflake Fairy
///   Christmas Eve     Angel, Reindeer, Robin, Snowman, Christmas Beetle (an Aussie Christmas)
/// The cookies keep the bean and dress it up: the tree's branches and the
/// star's points sit behind the bean, so every friend still bounces, blinks
/// and waves like the Classic 40. Ported from the web's js/packs/christmas.js;
/// the world is in ChristmasWorld.swift.
enum ChristmasArt {
    private typealias A = Animals
    private static let O = GC.outHex
    private static func sh(_ c: String, _ a: Double) -> String { GC.shade(c, a) }

    static let GOLD = "#f0b63c", HOLLY = "#3f8a5a", BERRY = "#d63b4f", WHITE = "#fdfaf3", ICING = "#fffdf8"

    // MARK: helpers (shared with the world)

    /// a star polygon's points: n points, outer R, inner r, centred on (cx, cy), first point straight up
    static func starPts(_ cx: Double, _ cy: Double, _ R: Double, _ r: Double, _ n: Int = 5) -> [Pt] {
        (0..<(n * 2)).map { i in
            let a = -Double.pi / 2 + Double(i) * .pi / Double(n), rr = i % 2 == 1 ? r : R
            return (cx + cos(a) * rr, cy + sin(a) * rr)
        }
    }

    /// a four-point twinkle
    static func twinkle(_ x: Double, _ y: Double, _ r: Double, _ c: String, _ sw: Double = 3) -> VNode {
        nPath("M\(x),\(y - r) Q\(x),\(y) \(x + r),\(y) Q\(x),\(y) \(x),\(y + r) Q\(x),\(y) \(x - r),\(y) Q\(x),\(y) \(x),\(y - r) Z",
              St(fill: c, stroke: O, width: sw, join: .round))
    }

    /// a holly leaf, centred on (x, y), pointing along angle a (degrees), L long
    static func hollyLeaf(_ x: Double, _ y: Double, _ a: Double, _ L: Double, _ c: String = ChristmasArt.HOLLY) -> VNode {
        func q(_ u: Double, _ v: Double) -> String { "\(u * L),\(v * L)" }
        let d = "M\(q(-1, 0)) Q\(q(-0.72, -0.16)) \(q(-0.52, -0.42)) Q\(q(-0.3, -0.24)) \(q(0, -0.46)) Q\(q(0.3, -0.24)) \(q(0.52, -0.42)) Q\(q(0.72, -0.16)) \(q(1, 0)) " +
            "Q\(q(0.72, 0.16)) \(q(0.52, 0.42)) Q\(q(0.3, 0.24)) \(q(0, 0.46)) Q\(q(-0.3, 0.24)) \(q(-0.52, 0.42)) Q\(q(-0.72, 0.16)) \(q(-1, 0)) Z"
        return nGroup([
            nPath(d, St(fill: c, stroke: O, width: 3.5, join: .round)),
            nPath("M\(q(-0.7, 0)) L\(q(0.7, 0))", rcap(sh(c, 0.35), 2.5)),
        ], svgMove(x, y, rot: a))
    }

    /// a sprig: two holly leaves and three berries, centred on (x, y)
    static func holly(_ x: Double, _ y: Double, _ s: Double = 1, _ tilt: Double = 0) -> VNode {
        nGroup([hollyLeaf(-12, 2, -20, 15), hollyLeaf(12, 2, 20, 15)] +
            [(0.0, -4.0), (-6.5, 3), (6.5, 3)].map { u, v in nCircle(u, v, 5.5, St(fill: BERRY, stroke: O, width: 3)) } +
            [nCircle(-1.5, -5.5, 1.6, St.f("#ffffff").op(0.8))],
            svgMove(x, y, rot: tilt, scale: s))
    }

    /// a wavy piped-icing line through points (alternating bumps of size amp)
    static func piped(_ pts: [Pt], _ amp: Double, _ c: String = ChristmasArt.ICING, _ wdt: Double = 4) -> VNode {
        var d = "M\(pts[0].0),\(pts[0].1)"
        for i in 1..<pts.count {
            let (x0, y0) = pts[i - 1], (x1, y1) = pts[i]
            let mx = (x0 + x1) / 2, my = (y0 + y1) / 2
            let len = hypot(x1 - x0, y1 - y0) == 0 ? 1 : hypot(x1 - x0, y1 - y0)
            let nx = -(y1 - y0) / len, ny = (x1 - x0) / len, s = i % 2 == 1 ? amp : -amp
            d += " Q\(mx + nx * s),\(my + ny * s) \(x1),\(y1)"
        }
        return nPath(d, St.line(c, wdt))
    }

    /// points along a quadratic curve a → b with control c
    static func along(_ a: Pt, _ c: Pt, _ b: Pt, _ n: Int) -> [Pt] {
        (0...n).map { i in
            let t = Double(i) / Double(n), u = 1 - t
            return (u * u * a.0 + 2 * u * t * c.0 + t * t * b.0, u * u * a.1 + 2 * u * t * c.1 + t * t * b.1)
        }
    }

    /// points along the bean body's outline (Animals.bodyPath), shrunk by sc about its middle
    static func beanPts(_ w: Double, _ h: Double, _ sc: Double, _ n: Int) -> [Pt] {
        let segs: [[Pt]] = [[(-w, -h * 0.45), (-w, -h * 1.15), (w, -h * 1.15), (w, -h * 0.45)],
                            [(w, -h * 0.45), (w, -h * 0.05), (w * 0.75, 0), (0, 0)],
                            [(0, 0), (-w * 0.75, 0), (-w, -h * 0.05), (-w, -h * 0.45)]]
        var out: [Pt] = []
        let cy = -h * 0.5
        for (j, g) in segs.enumerated() {
            let m = Int((Double(n) / (j > 0 ? 4 : 2)).rounded())
            for i in (j > 0 ? 1 : 0)...m {
                let t = Double(i) / Double(m), u = 1 - t
                let b0 = u * u * u, b1 = 3 * u * u * t, b2 = 3 * u * t * t, b3 = t * t * t
                let x = b0 * g[0].0 + b1 * g[1].0 + b2 * g[2].0 + b3 * g[3].0
                let y = b0 * g[0].1 + b1 * g[1].1 + b2 * g[2].1 + b3 * g[3].1
                out.append((x * sc, cy + (y - cy) * sc))
            }
        }
        return out
    }

    /// where the friend's face sits (same as Animals.render)
    static func faceY(_ d: AnimalDef, _ h: Double) -> Double { -h * (d.faceY ?? 0.56) }

    /// A person's head: hair framing a skin-coloured face, with a fringe.
    /// d.skin, d.hair, d.hairTo (how far down the sides the hair falls, fraction of h)
    static func personHead(_ d: AnimalDef, _ k: PartKit) -> [VNode] {
        let w = k.w, h = k.h, fy = faceY(d, h)
        let cy = fy + 5, rx = w * 0.64, ry = h * 0.255
        let hair = d.hair ?? "#4a2f45"
        // fringe: the top of the face, scalloped along its lower edge
        let yE = cy - ry * 0.3, xE = rx * (1 - 0.09).squareRoot(), yS = cy - ry * 0.62, n = 5
        var fringe = "M\(-xE),\(yE) A\(rx),\(ry) 0 0 1 \(xE),\(yE)"
        for i in 1...n {
            let x = xE - (2 * xE * Double(i)) / Double(n), y = i == n ? yE : yS + (i % 2 == 1 ? 0 : 3)
            fringe += " Q\(x + xE / Double(n)),\(yS + 13) \(x),\(y)"
        }
        return [
            nRect(-w - 10, -h * 1.3, 2 * w + 20, h * 1.3 - h * (d.hairTo ?? 0.46), .f(hair)),
            nEllipse(0, cy, rx, ry, .f(d.skin ?? "#f6d2b4")),
            nPath(fringe + " Z", .f(hair)),
        ]
    }

    /// a six-armed snowflake (outlined tubes)
    static func flake(_ x: Double, _ y: Double, _ r: Double, _ c: String = "#ffffff", _ wdt: Double = 3.5,
                      outline: String = GC.outHex, outlineWidth: Double? = nil) -> [VNode] {
        var d = ""
        for i in 0..<3 {
            let a = Double(i) * .pi / 3 + .pi / 2, dx = cos(a) * r, dy = sin(a) * r
            d += "M\(x - dx),\(y - dy) L\(x + dx),\(y + dy) "
            for s in [-1.0, 1] {
                let bx = x + s * dx * 0.55, by = y + s * dy * 0.55, b = r * 0.3
                for t in [-1.0, 1] {
                    let aa = a + t * 0.6 + (s < 0 ? .pi : 0)
                    d += "M\(bx),\(by) L\(bx + cos(aa) * b),\(by + sin(aa) * b) "
                }
            }
        }
        return [nPath(d, rcap(outline, outlineWidth ?? wdt + 3.5)), nPath(d, rcap(c, wdt))]
    }

    /// a jingle bell
    static func bell(_ x: Double, _ y: Double, _ r: Double) -> [VNode] {
        [
            nCircle(x, y, r, St(fill: GOLD, stroke: O, width: 3)),
            nPath("M\(x - r * 0.5),\(y + r * 0.25) L\(x + r * 0.5),\(y + r * 0.25)", rcap(O, 2.2)),
            nCircle(x - r * 0.35, y - r * 0.35, r * 0.25, St.f("#ffffff").op(0.8)),
        ]
    }

    /// a plain arm (the Classic paw), for parts that hold something in one hand
    private static func paw(_ d: AnimalDef, _ k: PartKit, _ s: Double) -> VNode {
        let c = d.armColor ?? sh(d.body, -0.06)
        return nEllipse(s * (k.w - 9), -k.h * 0.3, 11, 14, A.S(c)).moved(rotAbout(s * -25, s * (k.w - 9), -k.h * 0.3))
    }

    private static func points(_ list: [(Double, Double)], _ w: Double, _ yb: Double) -> [Pt] { list.map { (w * $0.0, yb + $0.1) } }

    // MARK: parts

    static let parts: AnimalParts = {
        var p = AnimalParts()

        // back
        /// Christmas Tree Cookie: three tiers of branches behind the bean
        p.back["treeTiers"] = { d, k in
            let w = k.w, c = sh(d.body, -0.07)
            var out: [VNode] = []
            for (by, hw, ay) in [(-10.0, w + 30, -86.0), (-56, w + 22, -132), (-100, w + 8, -176)] {
                out.append(nPath("M\(-hw),\(by) L0,\(ay) L\(hw),\(by) Q0,\(by + 8) \(-hw),\(by) Z", A.S(c)))
                // icing dots and sprinkles on the tips that show
                out += both { s in [
                    nCircle(s * (hw - 12), by - 4, 3.4, .f(ICING)),
                    nCircle(s * (hw - 26), by - 13, 3, St(fill: s < 0 ? BERRY : GOLD, stroke: O, width: 2)),
                ] }
            }
            return out
        }
        /// Shortbread Star: five rounded points behind the bean, with piped icing
        p.back["starPoints"] = { d, _ in
            let pts = starPts(0, -78, 96, 50), icing = starPts(0, -78, 80, 43)
            return [
                nPolygon(pts, St(fill: O, stroke: O, width: 22, join: .round)),
                nPolygon(pts, St(fill: d.body, stroke: d.body, width: 10, join: .round)),
                nPolygon(icing, St(stroke: ICING, width: 4.5, cap: .round, join: .round).dashed([0.5, 9])),
            ]
        }
        /// Christmas Pudding sits on a plate
        p.back["plate"] = { _, k in
            [nEllipse(0, -3, k.w + 22, 14, A.S("#eef3f8")), nEllipse(0, -4, k.w + 8, 8, plain("#c9d6e2", 3))]
        }
        /// fairy wings: a big pair and a small pair
        p.back["fairyWings"] = { d, k in
            let w = k.w, h = k.h, c = d.wingColor ?? "#f6c6e6", hi = sh(c, 0.45)
            return both { s in
                let ux = s * (w + 11), uy = -h * 0.76, lx = s * (w + 5), ly = -h * 0.38
                return [
                    nEllipse(ux, uy, 22, 35, A.S(c)).moved(rotAbout(s * 32, ux, uy)),
                    nEllipse(ux + s * 3, uy - 6, 9, 18, .f(hi)).moved(rotAbout(s * 32, ux, uy)),
                    nEllipse(lx, ly, 17, 24, A.S(c)).moved(rotAbout(s * -34, lx, ly)),
                ]
            }
        }
        /// Snowflake Fairy: icy, pointed crystal wings
        p.back["iceWings"] = { d, k in
            let w = k.w, h = k.h, c = d.wingColor ?? "#e6f4ff"
            return both { s in
                let x0 = s * (w - 14), y0 = -h * 0.62
                let pd = "M\(x0),\(y0) L\(s * (w + 10)),\(-h * 1.06) L\(s * (w + 32)),\(-h * 0.88) L\(s * (w + 21)),\(-h * 0.6) " +
                    "L\(s * (w + 30)),\(-h * 0.36) L\(s * (w + 10)),\(-h * 0.24) Z"
                return [
                    nPath(pd, A.S(c)),
                    nPath("M\(s * (w + 2)),\(-h * 0.64) L\(s * (w + 18)),\(-h * 0.88) M\(s * (w + 2)),\(-h * 0.54) L\(s * (w + 22)),\(-h * 0.38)", rcap("#ffffff", 4)),
                ]
            }
        }
        /// Angel: soft feathered wings
        p.back["featherWings"] = { d, k in
            let w = k.w, h = k.h, c = d.wingColor ?? "#fffaf0"
            return both { s in
                func X(_ v: Double) -> Double { s * v }
                let pd = "M\(X(w - 16)),\(-h * 0.74) Q\(X(w + 24)),\(-h * 1.16) \(X(w + 40)),\(-h * 0.92) " +
                    "Q\(X(w + 42)),\(-h * 0.8) \(X(w + 32)),\(-h * 0.74) Q\(X(w + 40)),\(-h * 0.62) \(X(w + 28)),\(-h * 0.55) " +
                    "Q\(X(w + 33)),\(-h * 0.42) \(X(w + 18)),\(-h * 0.38) Q\(X(w + 16)),\(-h * 0.26) \(X(w - 6)),\(-h * 0.3) Z"
                return [
                    nPath(pd, A.S(c)),
                    nPath("M\(X(w + 6)),\(-h * 0.76) Q\(X(w + 18)),\(-h * 0.8) \(X(w + 28)),\(-h * 0.75) M\(X(w + 4)),\(-h * 0.56) Q\(X(w + 14)),\(-h * 0.58) \(X(w + 22)),\(-h * 0.54)",
                          rcap(sh(c, -0.18), 3)),
                ]
            }
        }
        /// a ballerina's bun on top of the head
        p.back["bun"] = { d, k in [nCircle(0, -k.h * 1.0, 15, A.S(d.hair ?? "#4a2f45"))] }
        /// Mouse King's royal cape
        p.back["cape"] = { d, k in
            let w = k.w, h = k.h
            return [nPath("M\(-w * 0.8),\(-h * 0.62) L\(w * 0.8),\(-h * 0.62) Q\(w * 1.25),\(-h * 0.3) \(w * 1.3),-4 Q0,10 \(-w * 1.3),-4 Q\(-w * 1.25),\(-h * 0.3) \(-w * 0.8),\(-h * 0.62) Z",
                          A.S(d.capeColor ?? "#8c2f45"))]
        }
        /// Reindeer antlers
        p.back["antlers"] = { d, k in
            let w = k.w, h = k.h, c = d.antlerColor ?? "#e6cfa3"
            return both { s in
                let main = "M\(s * w * 0.26),\(-h * 0.88) C\(s * w * 0.3),\(-h * 1.16) \(s * w * 0.62),\(-h * 1.26) \(s * w * 0.96),\(-h * 1.36)"
                return A.tube(main, c, 9) +
                    A.tube("M\(s * w * 0.4),\(-h * 1.12) Q\(s * w * 0.3),\(-h * 1.3) \(s * w * 0.2),\(-h * 1.4)", c, 8) +
                    A.tube("M\(s * w * 0.7),\(-h * 1.28) Q\(s * w * 0.72),\(-h * 1.42) \(s * w * 0.62),\(-h * 1.52)", c, 8) +
                    // the two pieces join cleanly: repaint the core over the outlines where they meet
                    [nPath(main, rcap(c, 9))]
            }
        }
        /// Robin: a little tail tipped up behind
        p.back["robinTail"] = { d, k in
            let w = k.w, h = k.h
            return [nGroup([nPath("M\(w * 0.6),\(-h * 0.18) Q\(w + 4),\(-h * 0.44) \(w + 14),\(-h * 0.56) Q\(w + 26),\(-h * 0.62) \(w + 30),\(-h * 0.5) Q\(w + 36),\(-h * 0.42) \(w + 28),\(-h * 0.36) Q\(w + 14),\(-h * 0.2) \(w * 0.75),\(-h * 0.06) Z",
                                  A.S(sh(d.body, -0.12)))]).looping(Loops.wag, idle: true)]
        }
        /// Christmas Beetle: short antennae with little fan-shaped clubs
        p.back["fanAntennae"] = { d, k in
            let w = k.w, h = k.h, c = d.antennaColor ?? O
            return both { s in
                let x = s * w * 0.86, y = -h * 1.2
                return [nPath("M\(s * w * 0.4),\(-h * 0.9) Q\(s * w * 0.5),\(-h * 1.14) \(x),\(y)", rcap(O, 5))] +
                    [-40.0, 0, 40].map { a in nEllipse(x + s * 2, y - 7, 4.5, 9, A.S4(c)).moved(rotAbout(s * 30 + a, x, y)) }
            }
        }

        // marks (clipped inside the body)
        /// Gingerbread Pal: a piped icing hairline
        p.marks["gingerIcing"] = { _, k in [piped(beanPts(k.w, k.h, 0.86, 44), 2.6, ICING, 3.6)] }
        /// Christmas Tree Cookie: icing garlands and sprinkles
        p.marks["treeIcing"] = { _, k in
            let w = k.w, h = k.h
            let g1 = piped(along((-w * 1.05, -h * 0.3), (0, -h * 0.06), (w * 1.05, -h * 0.3), 10), 2.6)
            let g2 = piped(along((-w * 0.8, -h * 0.84), (0, -h * 0.68), (w * 0.8, -h * 0.84), 8), 2.6)
            let spr: [(Double, Double, String)] = [(-0.62, 0.17, BERRY), (0.58, 0.15, GOLD), (-0.18, 0.08, "#6fb3c9"), (0.24, 0.24, "#f2a0b8"), (-0.84, 0.5, GOLD), (0.84, 0.56, BERRY),
                                                   (-0.3, 0.95, "#f2a0b8"), (0.34, 0.97, "#6fb3c9"), (0.02, 1.02, GOLD)]
            return [g1, g2] + spr.enumerated().map { i, e in
                nEllipse(e.0 * w, -e.1 * h, 2.4, 5, .f(e.2)).moved(rotAbout(Double((i * 47) % 180 - 90), e.0 * w, -e.1 * h))
            }
        }
        /// Shortbread Star: sugar sparkles baked on
        p.marks["sugar"] = { _, k in
            [(-0.62, 0.3), (0.6, 0.32), (-0.2, 0.14), (0.26, 0.2), (-0.72, 0.7), (0.74, 0.74), (-0.3, 0.96), (0.32, 0.94), (0, 0.32), (-0.5, 0.88), (0.52, 0.86)]
                .map { x, y in nCircle(x * k.w, -y * k.h, 2.3, St.f(ICING).op(0.9)) }
        }
        /// Christmas Pudding: custard poured over the top, and currants
        p.marks["custard"] = { _, k in
            let w = k.w, h = k.h
            let top = -h * 0.8
            let drips: [(Double, Double)] = [(-w - 6, 0), (-w * 0.72, 14), (-w * 0.42, 4), (-w * 0.12, 12), (w * 0.2, 2), (w * 0.5, 15), (w * 0.8, 3), (w + 6, 8)]
            var pd = "M\(-w - 8),\(-h * 1.3) L\(-w - 8),\(top)"
            for i in 1..<drips.count {
                let x0 = drips[i - 1].0, (x1, dp) = drips[i]
                pd += " Q\((x0 + x1) / 2),\(top + dp * 1.6) \(x1),\(top + (i % 2 == 1 ? 2 : -2))"
            }
            pd += " L\(w + 8),\(-h * 1.3) Z"
            let currants: [(Double, Double)] = [(-0.76, 0.3), (0.72, 0.28), (-0.34, 0.13), (0.38, 0.12), (0, 0.26), (-0.86, 0.56), (0.88, 0.6), (-0.56, 0.1), (0.6, 0.48)]
            return currants.enumerated().map { i, c in
                nEllipse(c.0 * w, -c.1 * h, 4.5, 3.4, .f("#3a1f18")).moved(rotAbout(Double(i * 37), c.0 * w, -c.1 * h))
            } + [
                nPath(pd, .f("#fdf3d0")),
                nPath("M\(-w * 0.55),\(-h * 0.94) Q\(-w * 0.3),\(-h * 1.04) 0,\(-h * 1.02)", rcap("#ffffff", 5)),
            ]
        }
        /// Nutcracker: white hair, painted face, chin-strap beard, belt, white trousers
        p.marks["nutcracker"] = { d, k in
            let w = k.w, h = k.h, fy = faceY(d, h)
            let hair = "#f5f0e6"
            return [nRect(-w - 10, -h * 1.3, 2 * w + 20, h * 0.68, .f(hair))] +
                both { s in [nCircle(s * (w - 2), -h * 0.66, 17, .f(hair))] } + [
                    nEllipse(0, fy + 2, w * 0.68, 29, .f(d.skin ?? "#f6d2b4")),
                    nPath("M\(-w * 0.74),\(fy - 8) Q\(-w * 0.8),\(fy + 36) 0,\(fy + 40) Q\(w * 0.8),\(fy + 36) \(w * 0.74),\(fy - 8) " +
                        "L\(w * 0.56),\(fy - 2) Q\(w * 0.5),\(fy + 26) 0,\(fy + 28) Q\(-w * 0.5),\(fy + 26) \(-w * 0.56),\(fy - 2) Z", .f(hair)),
                    nRect(-w - 10, -h * 0.21, 2 * w + 20, h * 0.21 + 4, .f(hair)),
                    nRect(-w - 10, -h * 0.29, 2 * w + 20, 12, .f("#2d2a3a")),
                    nRect(-8, -h * 0.29 - 2, 16, 16, rx: 3, St(fill: GOLD, stroke: O, width: 3)),
                ]
        }
        /// hair and a face, for the people
        p.marks["person"] = personHead
        /// a tutu at the waist
        p.marks["tutu"] = { d, k in
            let w = k.w, h = k.h, y0 = -h * 0.32, y1 = -h * 0.15, n = 7, c = d.tutu ?? "#e6c8f2"
            var pd = "M\(-w - 6),\(y0) L\(w + 6),\(y0) L\(w + 6),\(y1)"
            for i in 1...n {
                let x = w + 6 - ((2 * w + 12) * Double(i)) / Double(n)
                pd += " Q\(x + (w + 6) / Double(n)),\(y1 + 12) \(x),\(y1)"
            }
            var out = [nPath(pd + " Z", .f(c)), nPath("M\(-w - 6),\(y0) L\(w + 6),\(y0)", plain(sh(c, -0.2), 3))]
            for (i, x) in [-0.6, -0.2, 0.2, 0.6].enumerated() {
                if d.tutuFlakes {
                    out += flake(x * w, (y0 + y1) / 2 + 1, 5.5, "#ffffff", 2.2)
                } else {
                    out.append(nCircle(x * w, (y0 + y1) / 2 + Double(i % 2) * 3, 2.6, St.f("#ffffff").op(0.85)))
                }
            }
            return out
        }
        /// Angel: a gold hem on the robe
        p.marks["hem"] = { _, k in
            let w = k.w, h = k.h
            return [
                nPath("M\(-w - 6),\(-h * 0.13) Q0,\(-h * 0.06) \(w + 6),\(-h * 0.13) L\(w + 6),4 L\(-w - 6),4 Z", .f(GOLD)),
                nPath("M\(-w - 6),\(-h * 0.09) Q0,\(-h * 0.02) \(w + 6),\(-h * 0.09)", rcap("#fff3c0", 2.5).dashed([0.5, 7])),
            ]
        }
        /// Robin: the orange-red breast and face, edged in soft grey
        p.marks["robin"] = { d, k in
            let w = k.w, h = k.h
            return [
                nEllipse(0, -h * 0.47, w * 0.74, h * 0.37, plain("#b9c2cc", 8)),
                nEllipse(0, -h * 0.47, w * 0.74, h * 0.37, .f(d.breast ?? "#ec6a3c")),
                nEllipse(0, -h * 0.04, w * 0.6, h * 0.17, .f("#f6efe6")),
            ]
        }
        /// Snowman: a soft blue shadow on the snowball
        p.marks["snowShade"] = { d, k in
            let w = k.w, h = k.h
            return [nEllipse(w * 0.2, -h * 0.44, w * 1.05, h * 0.52, .f("#dde9f3")), nEllipse(-w * 0.06, -h * 0.52, w * 1.02, h * 0.5, .f(d.body))]
        }
        /// Christmas Beetle: a shiny green-gold head plate, wing-case seam and ribs
        p.marks["beetle"] = { d, k in
            let w = k.w, h = k.h, m = sh(d.body, -0.18)
            return [
                nEllipse(0, -h * 1.06, w * 0.86, h * 0.25, .f(d.capColor ?? "#7f9a3a")),
                nEllipse(-w * 0.32, -h * 0.92, 14, 5, St.f("#ffffff").op(0.45)).moved(rotAbout(-18, -w * 0.32, -h * 0.92)),
            ] + both { s in [
                nPath("M\(s * w * 0.86),\(-h * 0.76) Q\(s * w * 1.0),\(-h * 0.4) \(s * w * 0.74),\(-h * 0.08)", rcap(m, 3.5)),
                nPath("M\(s * w * 0.72),\(-h * 0.84) Q\(s * w * 0.82),\(-h * 0.7) \(s * w * 0.84),\(-h * 0.56)", rcap("#ffffff", 5).so(0.5)),
            ] }
        }

        // mouth
        /// a white piped icing smile
        p.mouth["icingSmile"] = { d, k in
            let my = faceY(d, k.h) + 15
            let pd = "M-10,\(my) Q0,\(my + 10) 10,\(my)"
            return [nPath(pd, rcap(O, 9)), nPath(pd, rcap(ICING, 4))]
        }
        /// the Nutcracker's big toothy grin
        p.mouth["nutGrin"] = { d, k in
            let my = faceY(d, k.h) + 15
            let pd = "M-12,\(my - 3) L12,\(my - 3) Q12,\(my + 10) 0,\(my + 10) Q-12,\(my + 10) -12,\(my - 3) Z"
            return [
                nPath(pd, .f("#8c2f3a")),
                nRect(-11, my - 3, 22, 5.5, .f("#ffffff")),
                nPath("M-4,\(my - 3) L-4,\(my + 2.5) M4,\(my - 3) L4,\(my + 2.5)", plain(O, 2)),
                nPath(pd, St.o(4.5)),
            ]
        }
        /// Snowman: a smile of little coals
        p.mouth["coal"] = { d, k in
            let my = faceY(d, k.h) + 19
            return [-12.0, -6, 0, 6, 12].map { x in nCircle(x, my + 5 * (1 - (x / 12) * (x / 12)), 2.8, .f(O)) }
        }

        // nose
        /// Snowman's carrot
        p.nose["carrot"] = { d, k in
            let y = faceY(d, k.h) + 8
            return [
                nPath("M-3,\(y - 4) Q2,\(y - 6) 4,\(y - 3) L27,\(y + 5) L3,\(y + 5) Q-4,\(y + 3) -3,\(y - 4) Z", A.S4("#f29a3c")),
                nPath("M9,\(y - 1) L10,\(y + 3) M16,\(y + 1) L16.5,\(y + 4)", rcap(O, 2)),
            ]
        }

        // arms
        /// Gingerbread Pal: stubby cookie arms out to the sides, iced at the ends
        p.arms["gingerArms"] = { d, k in
            let w = k.w, h = k.h
            return both { s in
                [A.arm(s, [nGroup([
                    nEllipse(0, 0, 13, 20, A.S(d.body)),
                    piped([(-8, 8), (-4, 8), (0, 8), (4, 8), (8, 8)], 3, ICING, 3.2),
                ], svgMove(s * (w + 1), -h * 0.3, rot: s * -48))])]
            }
        }
        /// holds a wand in the right hand; the left one waves
        p.arms["wand"] = { d, k in
            let w = k.w, h = k.h
            let tip: Pt = (w + 24, -h * 0.86)
            let top = d.wandTop == "flake" ? flake(tip.0, tip.1, 15, "#ffffff", 4.5) : [nPolygon(starPts(tip.0, tip.1, 16, 7.5), A.S4(GOLD))]
            return [A.arm(-1, [paw(d, k, -1)]),
                    nGroup(A.tube("M\(w - 4),\(-h * 0.36) L\(tip.0),\(tip.1)", "#f6e7c2", 4) + top + [paw(d, k, 1)])]
        }
        /// both hands together in front, holding something
        p.arms["hold"] = { d, k in
            both { s in [nEllipse(s * 20, -k.h * 0.29, 8, 9, A.S4(d.skin ?? "#e5b48c"))] }
        }
        /// Mouse King holds a sceptre
        p.arms["sceptre"] = { d, k in
            let w = k.w, h = k.h
            let top: Pt = (w + 14, -h * 0.82)
            return [A.arm(-1, [paw(d, k, -1)]),
                    nGroup(A.tube("M\(w - 8),\(-h * 0.2) L\(top.0),\(top.1)", GOLD, 5) + [
                        nCircle(top.0, top.1, 9, A.S4(BERRY)),
                        nCircle(top.0 - 3, top.1 - 3, 2.5, St.f("#ffffff").op(0.8)),
                        paw(d, k, 1),
                    ])]
        }
        /// Snowman's twig arms
        p.arms["twigs"] = { _, k in
            let w = k.w, h = k.h, c = "#8a5a3b"
            return both { s in
                [A.arm(s, A.tube("M\(s * (w - 8)),\(-h * 0.48) L\(s * (w + 24)),\(-h * 0.8)", c, 5) +
                    A.tube("M\(s * (w + 12)),\(-h * 0.68) L\(s * (w + 28)),\(-h * 0.66)", c, 4) +
                    A.tube("M\(s * (w + 24)),\(-h * 0.8) L\(s * (w + 25)),\(-h * 0.91) M\(s * (w + 24)),\(-h * 0.8) L\(s * (w + 33)),\(-h * 0.86)", c, 3.5))]
            }
        }

        // feet
        /// Gingerbread Pal: cookie feet with icing zigzags
        p.feet["gingerFeet"] = { d, k in
            both { s in
                [nGroup([
                    nEllipse(0, 0, 17, 11, A.S(d.body)),
                    piped([(-9, -1), (-4.5, -1), (0, -1), (4.5, -1), (9, -1)], 3, ICING, 3.2),
                ], tr(s * k.w * 0.42, -6))]
            }
        }

        // front
        /// a gold star held in front (the 'hold' arms are drawn over it)
        p.front["heldStar"] = { _, k in
            let y = -k.h * 0.3
            return [nPolygon(starPts(0, y - 2, 18, 8.5), A.S4(GOLD)), nCircle(-4, y - 6, 2.4, St.f("#ffffff").op(0.8))]
        }
        /// Christmas Beetle: a middle pair of legs
        p.front["midLegs"] = { d, k in
            let w = k.w, h = k.h
            return both { s in A.tube("M\(s * (w - 6)),\(-h * 0.5) L\(s * (w + 12)),\(-h * 0.46) L\(s * (w + 16)),\(-h * 0.36)", d.armColor ?? O, 5) }
        }
        /// Gingerbread Pal: gumdrop buttons
        p.front["gumdrops"] = { _, k in
            let h = k.h
            return [(BERRY, 0.27), (HOLLY, 0.14)].flatMap { e -> [VNode] in
                let (c, y) = e
                return [
                    nPath("M-7.5,\(-h * y + 5) Q-8,\(-h * y - 8) 0,\(-h * y - 8) Q8,\(-h * y - 8) 7.5,\(-h * y + 5) Q0,\(-h * y + 7) -7.5,\(-h * y + 5) Z", A.S4(c)),
                    nCircle(-2.5, -h * y - 3, 1.4, St.f("#ffffff").op(0.8)),
                    nCircle(2.5, -h * y + 1, 1.2, St.f("#ffffff").op(0.8)),
                ]
            }
        }
        /// Reindeer: a red harness with jingle bells
        p.front["bellCollar"] = { _, k in
            let w = k.w, h = k.h
            let a: Pt = (-w * 0.84, -h * 0.34), c: Pt = (0, -h * 0.12), b: Pt = (w * 0.84, -h * 0.34)
            let pts = along(a, c, b, 8)
            return A.tube("M\(a.0),\(a.1) Q\(c.0),\(c.1) \(b.0),\(b.1)", "#d6423f", 8) +
                [2, 4, 6].flatMap { i in bell(pts[i].0, pts[i].1 + 7, 7.5) }
        }
        /// Snowman: a red knitted scarf with a dangling end
        p.front["scarf"] = { _, k in
            let w = k.w, h = k.h, c = "#e8604f", st = "#fdfaf3"
            let pd = "M\(-w * 0.95),\(-h * 0.4) Q0,\(-h * 0.22) \(w * 0.95),\(-h * 0.4) L\(w * 0.98),\(-h * 0.29) Q0,\(-h * 0.1) \(-w * 0.98),\(-h * 0.29) Z"
            let tail = "M\(w * 0.36),\(-h * 0.26) L\(w * 0.62),\(-h * 0.25) L\(w * 0.66),\(-h * 0.04) L\(w * 0.4),\(-h * 0.03) Z"
            var out = [nPath(tail, A.S(c)), nPath("M\(w * 0.4),\(-h * 0.11) L\(w * 0.65),\(-h * 0.12)", plain(st, 5))]
            out += [0.42, 0.5, 0.58].map { x in nPath("M\(w * x + 2),\(-h * 0.03) L\(w * x + 3),\(h * 0.02)", rcap(O, 3.5)) }
            out.append(nPath(pd, A.S(c)))
            out += [-0.5, 0, 0.5].map { x in
                let yt = -h * 0.4 + (1 - x * x) * h * 0.09, yb = -h * 0.29 + (1 - x * x) * h * 0.095
                return nPath("M\(x * w - 4),\(yt + 3) L\(x * w - 4),\(yb - 3) M\(x * w + 4),\(yt + 3) L\(x * w + 4),\(yb - 3)", rcap(st, 3.5))
            }
            return out
        }
        /// Snowman: coal buttons
        p.front["coalButtons"] = { _, k in
            [0.2, 0.07].flatMap { y in [nCircle(0, -k.h * y, 5.5, .f(O)), nCircle(-1.6, -k.h * y - 1.6, 1.5, St.f("#ffffff").op(0.5))] }
        }
        /// Mouse King: an ermine collar
        p.front["ermine"] = { _, k in
            let w = k.w, h = k.h
            let pd = "M\(-w * 0.9),\(-h * 0.46) Q0,\(-h * 0.3) \(w * 0.9),\(-h * 0.46) Q\(w * 0.94),\(-h * 0.34) \(w * 0.82),\(-h * 0.3) Q0,\(-h * 0.12) \(-w * 0.82),\(-h * 0.3) Q\(-w * 0.94),\(-h * 0.34) \(-w * 0.9),\(-h * 0.46) Z"
            return [nPath(pd, A.S(WHITE))] + [(-0.6, 0.36), (-0.22, 0.26), (0.2, 0.26), (0.58, 0.36)].map { x, y in
                nPath("M\(x * w),\(-h * y - 4) L\(x * w - 3),\(-h * y + 3) L\(x * w + 3),\(-h * y + 3) Z", St(fill: "#2e2a2b", stroke: "#2e2a2b", width: 2, join: .round))
            }
        }

        // over (drawn last, on top of everything)
        /// a gold star on top of the tree
        p.over["treeStar"] = { _, _ in [nPolygon(starPts(0, -178, 20, 9), A.S4(GOLD)), nCircle(-4, -182, 2.4, St.f("#ffffff").op(0.8))] }
        /// a sprig of holly on the head
        p.over["hollyTop"] = { _, k in [holly(0, -k.h * 0.97, 1)] }
        p.over["hollySide"] = { _, k in [holly(k.w * 0.42, -k.h * 0.9, 0.9, 24)] }
        /// the Nutcracker's tall shako hat with a plume
        p.over["shako"] = { _, k in
            let yb = -k.h * 0.8, top = yb - 54, navy = "#2d2a3a"
            return [
                nEllipse(0, top - 12, 9, 14, A.S4("#ffffff")),
                nCircle(0, top - 3, 5, St(fill: BERRY, stroke: O, width: 2.5)),
                nPath("M-27,\(yb) L-31,\(top + 2) Q0,\(top - 6) 31,\(top + 2) L27,\(yb) Z", A.S(navy)),
                nPath("M-28,\(yb - 14) L28,\(yb - 14) L28,\(yb - 6) L-28,\(yb - 6) Z", .f(GOLD)),
                nPolygon(starPts(0, top + 22, 11, 5), St(fill: GOLD, stroke: O, width: 3, join: .round)),
                nEllipse(0, yb, 36, 8, A.S(navy)),
            ]
        }
        /// a little tiara
        p.over["tiara"] = { d, k in
            let yb = -k.h * 0.87
            let pts = points([(-0.36, 0), (-0.26, -12), (-0.12, -6), (0, -22), (0.12, -6), (0.26, -12), (0.36, 0)], k.w, yb)
            return [nPolygon(pts, A.S4(d.tiara ?? GOLD)), nCircle(0, yb - 8, 4, St(fill: d.gem ?? "#f28ab8", stroke: O, width: 2.5))]
        }
        /// Snowflake Fairy: a crown of icicles with a snowflake
        p.over["iceCrown"] = { _, k in
            let yb = -k.h * 0.87
            let pts = points([(-0.42, 0), (-0.36, -14), (-0.24, -4), (-0.14, -20), (-0.05, -6), (0.05, -6), (0.14, -20), (0.24, -4), (0.36, -14), (0.42, 0)], k.w, yb)
            return [nPolygon(pts, A.S4("#dff1ff"))] + flake(0, yb - 14, 10, "#ffffff", 3.4)
        }
        /// a golden halo
        p.over["halo"] = { _, k in
            let cy = -k.h * 1.1
            return [nEllipse(0, cy, 30, 8.5, plain(O, 12)), nEllipse(0, cy, 30, 8.5, plain(GOLD, 5))]
        }
        /// a crown
        p.over["crown"] = { _, k in
            let w = k.w, yb = -k.h * 0.86
            let pts = points([(-0.48, 0), (-0.52, -32), (-0.25, -14), (0, -38), (0.25, -14), (0.52, -32), (0.48, 0)], w, yb)
            var out = [nPolygon(pts, A.S(GOLD)), nRect(-w * 0.5, yb - 6, w, 7, .f("#d9952a"))]
            out += [(0.0, -12.0, BERRY, 5.0), (-0.3, -8, "#4f7fc0", 3.6), (0.3, -8, HOLLY, 3.6)].map { x, y, c, r in
                nCircle(x * w, yb + y, r, St(fill: c, stroke: O, width: 2.5))
            }
            out += [-0.52, 0, 0.52].enumerated().map { i, x in nCircle(x * w, yb + (i == 1 ? -38 : -32), 4, St(fill: GOLD, stroke: O, width: 2.5)) }
            return out
        }
        /// twinkles around the friend
        p.over["sparkles"] = { d, k in
            let w = k.w, h = k.h, c = d.sparkleColor ?? "#ffe27a"
            return [(-w - 26, -h * 0.98, 10.0), (-w - 34, -h * 0.4, 8), (w + 34, -h * 0.4, 8), (w * 0.62, -h * 1.18, 9)].map { x, y, r in twinkle(x, y, r, c) }
        }
        /// a black top hat with a holly band
        p.over["topHat"] = { _, k in
            let yb = -k.h * 0.93, navy = "#2d2a3a"
            return [nGroup([
                nPath("M-24,\(yb) L-24,\(yb - 40) Q0,\(yb - 45) 24,\(yb - 40) L24,\(yb) Z", A.S(navy)),
                nRect(-24, yb - 13, 48, 9, .f("#e8604f")),
                nEllipse(0, yb, 38, 8, A.S(navy)),
                holly(14, yb - 10, 0.55, 10),
            ], rotAbout(-8, 0, yb))]
        }
        /// a little red Christmas hat, tipped to one side
        p.over["xmasHat"] = { _, k in
            let yb = -k.h * 0.95
            return [nGroup([
                nPath("M-24,\(yb) Q-14,\(yb - 34) 6,\(yb - 46) Q26,\(yb - 52) 34,\(yb - 34) Q20,\(yb - 34) 20,\(yb) Z", A.S("#d6423f")),
                nCircle(36, yb - 32, 8, A.S(WHITE)),
                nRect(-28, yb - 7, 54, 14, rx: 7, A.S(WHITE)),
            ], svgMove(16, yb + 2, rot: 22, scale: 0.78).translatedBy(x: 0, y: -yb))]
        }
        /// a snowflake hair clip
        p.over["flakeClip"] = { _, k in flake(-k.w * 0.5, -k.h * 0.82, 9, "#ffffff", 3.4) }
        return p
    }()

    // MARK: the 13 friends (web order)

    private static let SKIN_LIGHT = "#f6d2b4", SKIN_WARM = "#e5b48c", SKIN_TAN = "#c68a5e"

    static let friends: [AnimalDef] = [
        // Christmas baking
        AnimalDef("gingerbread", "Gingerbread Pal", "#c98447") {
            $0.marks = ["gingerIcing"]; $0.front = ["gumdrops"]; $0.arms = "gingerArms"; $0.feet = "gingerFeet"; $0.nose = "none"; $0.mouth = "icingSmile"; $0.cheekColor = "#e8604f"
        },
        AnimalDef("treecookie", "Christmas Tree Cookie", "#5aa665") {
            $0.back = ["treeTiers"]; $0.marks = ["treeIcing"]; $0.over = ["treeStar"]; $0.armColor = "#4f955a"; $0.feetColor = "#9a6a3e"; $0.nose = "none"; $0.mouth = "u"
        },
        AnimalDef("shortbread", "Shortbread Star", "#eec070") {
            $0.back = ["starPoints"]; $0.marks = ["sugar"]; $0.arms = "none"; $0.feet = "none"; $0.nose = "none"; $0.mouth = "u"; $0.cheekColor = "#f39a6b"
        },
        AnimalDef("pudding", "Christmas Pudding", "#8e5236") {
            $0.shape = "wide"; $0.back = ["plate"]; $0.marks = ["custard"]; $0.over = ["hollyTop"]; $0.feet = "none"; $0.nose = "none"; $0.mouth = "w"; $0.armColor = "#7a4430"; $0.cheekColor = "#f3828f"
        },
        // The Nutcracker
        AnimalDef("nutcracker", "Nutcracker", "#c23b3f") {
            $0.shape = "tall"; $0.skin = SKIN_LIGHT; $0.marks = ["nutcracker"]; $0.over = ["shako"]; $0.mouth = "nutGrin"; $0.noseColor = "#d98a7a"
            $0.armColor = "#b0343a"; $0.feetColor = "#2d2a3a"; $0.cheekColor = "#f08a8a"
        },
        AnimalDef("sugarplum", "Sugar Plum Fairy", "#b98ad6") {
            $0.skin = SKIN_TAN; $0.hair = "#4a2f45"; $0.marks = ["person", "tutu"]; $0.tutu = "#e6c8f2"; $0.back = ["fairyWings", "bun"]; $0.wingColor = "#f6c6e6"
            $0.arms = "wand"; $0.armColor = SKIN_TAN; $0.feetColor = "#f29ac0"; $0.over = ["tiara", "sparkles"]; $0.tiara = GOLD; $0.gem = "#f28ab8"; $0.noseColor = "#8a5440"
        },
        AnimalDef("mouseking", "Mouse King", "#a3a0aa") {
            $0.belly = "#d8d4dc"; $0.ears = "bigRound"; $0.earInner = "#f2b6c4"; $0.back = ["cape", "tailThin"]; $0.capeColor = "#8c2f45"; $0.tailColor = "#e8a3b4"
            $0.whiskers = true; $0.noseColor = "#e58aa0"; $0.front = ["ermine"]; $0.arms = "sceptre"; $0.over = ["crown"]
        },
        AnimalDef("snowfairy", "Snowflake Fairy", "#a9d6f0") {
            $0.skin = SKIN_LIGHT; $0.hair = "#f2f5fb"; $0.hairTo = 0.4; $0.marks = ["person", "tutu"]; $0.tutu = "#e6f4ff"; $0.tutuFlakes = true; $0.back = ["iceWings"]; $0.wingColor = "#e6f4ff"
            $0.arms = "wand"; $0.wandTop = "flake"; $0.armColor = SKIN_LIGHT; $0.feetColor = "#dff1ff"; $0.over = ["iceCrown", "sparkles"]; $0.sparkleColor = "#ffffff"; $0.noseColor = "#e0a090"
        },
        // Christmas Eve
        AnimalDef("angel", "Angel", "#fdfaf2") {
            $0.skin = SKIN_WARM; $0.hair = "#f2c75c"; $0.hairTo = 0.36; $0.marks = ["person", "hem"]; $0.back = ["featherWings"]; $0.wingColor = "#fffaf0"
            $0.arms = "hold"; $0.armColor = "#f3ede0"; $0.feetColor = "#efe4cc"; $0.front = ["heldStar"]; $0.over = ["halo", "sparkles"]; $0.noseColor = "#b8785a"
        },
        AnimalDef("reindeer", "Reindeer", "#a8774f") {
            $0.belly = "#efdcc0"; $0.ears = "goat"; $0.earColor = "#8f6240"; $0.back = ["antlers"]; $0.antlerColor = "#e6cfa3"; $0.muzzle = "snout"; $0.muzzleColor = "#efdcc0"
            $0.nose = "big"; $0.noseColor = "#4a3030"; $0.front = ["bellCollar"]; $0.feetColor = "#5a3a2a"
        },
        AnimalDef("robin", "Robin", "#8a6a4f") {
            $0.breast = "#ec6a3c"; $0.marks = ["robin"]; $0.back = ["robinTail"]; $0.eyes = "big"; $0.muzzle = "beak"; $0.muzzleColor = "#6a5446"; $0.nose = "none"; $0.mouth = "none"
            $0.arms = "wing"; $0.armColor = "#7a5c44"; $0.feet = "bird"; $0.feetColor = "#d49a7a"; $0.over = ["hollySide"]
        },
        AnimalDef("snowman", "Snowman", "#fbfdff") {
            $0.marks = ["snowShade"]; $0.nose = "carrot"; $0.mouth = "coal"; $0.arms = "twigs"; $0.feet = "none"; $0.front = ["coalButtons", "scarf"]; $0.over = ["topHat"]
        },
        AnimalDef("xmasbeetle", "Christmas Beetle", "#d9a43e") {
            $0.shape = "wide"; $0.capColor = "#7f9a3a"; $0.marks = ["beetle"]; $0.back = ["fanAntennae"]; $0.front = ["midLegs"]; $0.antennaColor = "#8a6a2a"
            $0.nose = "none"; $0.mouth = "u"; $0.armColor = "#6a4a2a"; $0.feetColor = "#6a4a2a"; $0.faceY = 0.52; $0.over = ["xmasHat"]
        },
    ]
}

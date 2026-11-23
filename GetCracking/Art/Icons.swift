import SwiftUI

/// Drawn icons: the native twin of the web app's js/icons.js.
///
/// Every icon in the app is drawn here in the same visual language as the eggs
/// and friends: chunky dark outline, flat warm fills, a 48×48 box. No emoji
/// anywhere, so the app looks the same on every device. Each icon is path data
/// for the app's own vector scene graph (VNode), like the rest of the art.
///
///   IconView(name: "lock", size: 28)   a drawn icon as a SwiftUI view
///   Icons.has(name)                    is this a known icon?
///   Icons.fromEmoji(e)                 icon name for an emoji saved by older builds
///   Icons.image(name, size:)           a still image of it, for icons inside running text
enum Icons {
    // MARK: paint (the web's S, L(), SHINE)

    private static let O = GC.outHex
    private enum C {
        static let cream = "#fdf3e4", teal = "#62b5c5", tealDk = "#4b9bab", gold = "#e0a43c", yellow = "#ffd86b"
        static let leaf = "#a9d36b", leafDk = "#7fb04a", berry = "#c9483f", clay = "#d98a64", wood = "#b98652"
        static let bark = "#9a5a3c", pink = "#f7a8c8", sky = "#9fd8e8", stone = "#cbbfae", grey = "#8d8784"
        static let lilac = "#c5a8f0", orange = "#f39a6b"
    }
    /// filled, with the 3.5 dark outline
    private static func S(_ fill: String) -> St { St(fill: fill, stroke: O, width: 3.5, cap: .round, join: .round) }
    /// an outline-only line
    private static func L(_ w: Double = 3.5) -> St { St(stroke: O, width: w, cap: .round, join: .round) }
    /// a white highlight
    private static let shine = St(stroke: "#ffffff", width: 3, strokeOpacity: 0.65, cap: .round)
    /// a thin-outlined fill (stroke-width w, round joins)
    private static func thin(_ fill: String, _ w: Double) -> St { St(fill: fill, stroke: O, width: w, join: .round) }

    private static func p(_ d: String, _ st: St) -> VNode { nPath(d, st) }

    // MARK: shape helpers (the web's gear, star, arcArrow)

    private static func f(_ v: Double) -> Double { (v * 10).rounded() / 10 }
    private static func pt(_ cx: Double, _ cy: Double, _ r: Double, _ deg: Double) -> Pt {
        (f(cx + cos(deg * .pi / 180) * r), f(cy + sin(deg * .pi / 180) * r))
    }

    /// a toothed wheel: n teeth between radius r0 (root) and r1 (tip)
    private static func gear(_ cx: Double, _ cy: Double, _ r0: Double, _ r1: Double, _ n: Int, _ st: St) -> VNode {
        let step = 360 / Double(n)
        var d: [Pt] = []
        for i in 0..<n {
            let a = Double(i) * step
            d += [pt(cx, cy, r0, a - step * 0.5), pt(cx, cy, r0, a - step * 0.28), pt(cx, cy, r1, a - step * 0.18),
                  pt(cx, cy, r1, a + step * 0.18), pt(cx, cy, r0, a + step * 0.28)]
        }
        return nPolygon(d, st)
    }

    /// a pointed star or burst
    private static func star(_ cx: Double, _ cy: Double, _ r0: Double, _ r1: Double, _ n: Int, _ st: St, rot: Double = -90) -> VNode {
        var d: [Pt] = []
        for i in 0..<(n * 2) { d.append(pt(cx, cy, i % 2 == 1 ? r0 : r1, rot + Double(i) * 180 / Double(n))) }
        return nPolygon(d, st)
    }

    /// a fat curved arrow along a circle, drawn as an outlined ribbon with a head
    private static func arcArrow(_ cx: Double, _ cy: Double, _ r: Double, _ a0: Double, _ a1: Double, _ fill: String) -> [VNode] {
        let (x0, y0) = pt(cx, cy, r, a0), (x1, y1) = pt(cx, cy, r, a1)
        let large = abs(a1 - a0) > 180 ? 1 : 0, sweep = a1 > a0 ? 1 : 0
        let arc = "M\(x0) \(y0) A\(r) \(r) 0 \(large) \(sweep) \(x1) \(y1)"
        let dir: Double = sweep == 1 ? 90 : -90 // tangent direction at the end
        let tip = pt(x1, y1, 7, a1 + dir), b1 = pt(x1, y1, 7.5, a1), b2 = pt(x1, y1, -7.5, a1)
        return [
            p(arc, St(stroke: O, width: 10, cap: .round)),
            p(arc, St(stroke: fill, width: 3.6, cap: .round)),
            nPolygon([b1, tip, b2], S(fill)),
        ]
    }

    private static let egg = "M24 4 C33 4 38 19 38 28 C38 37 32 44 24 44 C16 44 10 37 10 28 C10 19 15 4 24 4 Z"
    private static func chickFace(_ cx: Double, _ cy: Double) -> [VNode] {
        [
            nCircle(cx - 4, cy - 1, 1.9, .f(O)), nCircle(cx + 4, cy - 1, 1.9, .f(O)),
            nPolygon([(cx - 2.6, cy + 2.5), (cx + 2.6, cy + 2.5), (cx, cy + 5.6)], thin(C.orange, 2.2)),
        ]
    }

    // MARK: the icons

    private static let builders: [String: () -> [VNode]] = [
        /* ---------- setup + navigation */
        "tree": {
            [p("M20.5 29 V42 H27.5 V29", S(C.bark)),
             p("M24 5 C33 5 39 11 39 19 C39 27 33 32 24 32 C15 32 9 27 9 19 C9 11 15 5 24 5 Z", S(C.leaf)),
             p("M15 19 C15 14 18 11 22 10", shine), p("M6 42 H42", L())]
        },
        "notes": {
            [p("M17 35 V14 L36 9 V31", L()), p("M17 13.5 L36 8.5 V15 L17 20 Z", .f(O)),
             nEllipse(12, 36, 6.3, 5, S(C.teal)).moved(rotAbout(-20, 12, 36)),
             nEllipse(31, 32, 6.3, 5, S(C.teal)).moved(rotAbout(-20, 31, 32))]
        },
        "note": {
            [p("M27 34 V7 C30 12 37 13 37 21", L()),
             nEllipse(21, 35, 7.4, 5.8, S(C.gold)).moved(rotAbout(-20, 21, 35))]
        },
        "book": {
            [p("M3 14 V41 C10 39 18 39 24 43 C30 39 38 39 45 41 V14", S(C.berry)),
             p("M24 13 C19 9 12 8 6 10 V37 C12 35 19 36 24 40 Z", S(C.cream)),
             p("M24 13 C29 9 36 8 42 10 V37 C36 35 29 36 24 40 Z", S(C.cream)),
             p("M10 17 C13 16 17 16 20 18 M10 23 C13 22 17 22 20 24 M28 18 C31 16 35 16 38 17 M28 24 C31 22 35 22 38 23",
               St(stroke: O, width: 2.4, strokeOpacity: 0.35, cap: .round))]
        },
        "gear": { [gear(24, 24, 14.5, 20.5, 8, S(C.stone)), nCircle(24, 24, 6.5, S(C.cream))] },

        /* ---------- timer screen */
        "tap": {
            [nRect(17, 2.5, 10, 27, rx: 5, S("#fbd3a8")),
             p("M14 23 H35 C38 23 40 25 40 28 V33 C40 40 35 45 28 45 H25 C17 45 11 40 11 32 V26 C11 24 12 23 14 23 Z", S("#fbd3a8")),
             p("M17 24 V32 M27 24 V30 M33.5 24 V30", St(stroke: O, width: 3, cap: .round)),
             p("M20 8 V14", shine)]
        },
        "lock": {
            [p("M15 22 V16 C15 10.5 19 7 24 7 C29 7 33 10.5 33 16 V22", St(stroke: O, width: 9, cap: .round)),
             p("M15 22 V16 C15 10.5 19 7 24 7 C29 7 33 10.5 33 16 V22", St(stroke: C.stone, width: 3, cap: .round)),
             nRect(9, 21, 30, 22, rx: 6, S(C.gold)),
             p("M24 28 V35", St(stroke: O, width: 5, cap: .round)), nCircle(24, 28.5, 3.6, .f(O))]
        },
        "egg": {
            [p(egg, S("#fbf1dc")),
             nCircle(20, 17, 3.2, .f("#a9cf8b")), nCircle(29, 24, 4.2, .f("#a9cf8b")),
             nCircle(19, 32, 3.6, .f("#a9cf8b")), nCircle(29, 37, 2.6, .f("#a9cf8b")),
             p("M15 30 C14 22 16 14 20 9", shine)]
        },
        "pause": { [nRect(11, 9, 9, 30, rx: 3.5, S(C.teal)), nRect(28, 9, 9, 30, rx: 3.5, S(C.teal))] },
        "play": { [p("M15 9.5 C15 7.5 17 6.5 18.7 7.5 L39 21.5 C40.6 22.6 40.6 25.4 39 26.5 L18.7 40.5 C17 41.5 15 40.5 15 38.5 Z", S(C.leaf))] },
        "stop": { [nRect(10, 10, 28, 28, rx: 6, S(C.berry))] },
        "hatch": {
            [p("M24 8 C22.5 5 25 3.5 27 5", L(3)), nCircle(24, 20, 11.5, S(C.yellow))] + chickFace(24, 19) +
                [p("M9 29 L14 24 L19 30 L24 25 L29 30 L34 24 L39 29 C39 39 33 45 24 45 C15 45 9 39 9 29 Z", S("#fbf1dc"))]
        },
        "again": { arcArrow(24, 24, 14, 200, 340, C.leafDk) + arcArrow(24, 24, 14, 20, 160, C.teal) },
        "reset": { arcArrow(24, 25, 13.5, -40, 230, C.teal) },
        "close": { [p("M14 14 L34 34 M34 14 L14 34", St(stroke: O, width: 6, cap: .round))] },
        "minus": { [p("M11 24 H37", St(stroke: O, width: 6, cap: .round))] },
        "plus": { [p("M24 11 V37 M11 24 H37", St(stroke: O, width: 6, cap: .round))] },

        /* ---------- settings choices */
        "dice": {
            [nGroup([nRect(8, 8, 32, 32, rx: 8, S(C.cream))] +
                [(16.0, 16.0), (32, 16), (24, 24), (16, 32), (32, 32)].map { nCircle($0.0, $0.1, 3.2, .f(C.berry)) },
                rotAbout(-10, 24, 24))]
        },
        "bird": {
            [nPolygon([(13, 27), (4, 21), (6, 33)], S(C.tealDk)), nCircle(22, 26, 13, S(C.teal)),
             p("M14 26 C17 33 25 33 28 27", St(stroke: O, width: 3, cap: .round)),
             nCircle(27, 21, 2.1, .f(O)), nPolygon([(34, 20), (42, 23), (34, 26.5)], S(C.gold)),
             p("M19 39 V44 M25 39 V44", L(3))]
        },
        "chick": {
            [p("M24 10 C22.5 6.5 25 5 27 6.5", L(3)), nCircle(24, 27, 15, S(C.yellow))] + chickFace(24, 24) +
                [p("M10.5 30 C13 35 17 35 18 32", St(stroke: O, width: 3, cap: .round)),
                 p("M37.5 30 C35 35 31 35 30 32", St(stroke: O, width: 3, cap: .round)),
                 nCircle(16, 29, 2.4, .f(C.pink)), nCircle(32, 29, 2.4, .f(C.pink))]
        },
        "rain": {
            [p("M13 30 C6.5 30 5.5 21 12 19.5 C12 11.5 22 8.5 26 14.5 C30 10.5 38.5 13 37.5 20 C43.5 21 42.5 30 36 30 Z", S(C.cream))] +
                [(15.0, 35.0), (24, 38), (33, 35)].map { x, y in
                    p("M\(x) \(y) C\(x + 2.6) \(y + 3.4) \(x + 3) \(y + 6.4) \(x) \(y + 6.8) C\(x - 3) \(y + 6.4) \(x - 2.6) \(y + 3.4) \(x) \(y) Z",
                      thin(C.sky, 2.6))
                }
        },
        "clock": {
            [p("M15 41 L12.5 45 M33 41 L35.5 45", L()), nCircle(24, 25, 17, S(C.gold)),
             nCircle(24, 25, 12, S(C.cream)), p("M24 25 V17.5 M24 25 L29 28", L()),
             nCircle(24, 25, 2, .f(O)), nCircle(24, 5.5, 3, S(C.gold))]
        },
        "quiet": {
            [p("M7 19 H15 L25 10.5 V37.5 L15 29 H7 Z", S(C.stone)),
             p("M31 19 L41 29 M41 19 L31 29", St(stroke: O, width: 4.5, cap: .round))]
        },
        "tada": {
            [nPolygon([(6, 43), (15, 17), (32, 34)], S(C.gold)),
             p("M10.5 31 L20 38.5 M13 24 L26 34.5", St(stroke: C.berry, width: 3.4, cap: .round)),
             nPolygon([(6, 43), (15, 17), (32, 34)], L()),
             star(32, 11, 2.4, 6, 4, thin(C.yellow, 2.4)),
             nCircle(41, 22, 3, St(fill: C.pink, stroke: O, width: 2.4)), nCircle(22, 7, 2.6, St(fill: C.sky, stroke: O, width: 2.4)),
             p("M37 33 C40 31 41 35 44 33", St(stroke: O, width: 2.6, cap: .round))]
        },
        "drum": {
            [p("M5 9 L19 19 M43 9 L29 19", St(stroke: O, width: 3.5, cap: .round)),
             nCircle(5, 9, 3, S(C.cream)), nCircle(43, 9, 3, S(C.cream)),
             p("M8 22 V37 C8 41 15 44 24 44 C33 44 40 41 40 37 V22 Z", S(C.berry)),
             p("M8 25 L16 38 L24 25 L32 38 L40 25", St(stroke: C.yellow, width: 3, join: .round)),
             p("M8 36 C8 40 15 43 24 43 C33 43 40 40 40 36", L()),
             nEllipse(24, 22, 16, 5.5, S(C.cream))]
        },
        // Egg karaoke: a microphone whose head is a cracked egg, and a note
        "mic": {
            [p("M19 28 L21 42 C21.3 45 26.7 45 27 42 L29 28 Z", S(C.berry)),
             p("M22 4 C30 4 34 12 34 19 C34 25 29 30 22 30 C15 30 10 25 10 19 C10 12 14 4 22 4 Z", S(C.cream)),
             p("M11 18 L15 14.5 L18.5 18.5 L22 14.5 L25.5 18.5 L29 14.5 L33 18", L(2.6)),
             p("M15 9 C16 7.5 17.5 6.5 19 6", shine),
             p("M42 7 V20", L(3)), p("M42 7 L46 9", L(3)), nEllipse(39.5, 20.5, 3.4, 2.6, .f(O))]
        },
        "maracas": {
            [p("M17 25 L9 44 M31 25 L39 44", St(stroke: O, width: 7, cap: .round)),
             p("M17 25 L9 44 M31 25 L39 44", St(stroke: C.wood, width: 3, cap: .round)),
             nEllipse(19, 15, 9, 11, S(C.orange)).moved(rotAbout(22, 19, 15)),
             nEllipse(30, 15, 9, 11, S(C.leaf)).moved(rotAbout(-22, 30, 15)),
             p("M25 11 L35 15 M24 17 L33 21", St(stroke: C.yellow, width: 2.8, cap: .round)),
             p("M3 9 C4.5 7 6 7 7 9 M41 4 C42.5 2 44 2 45 4", St(stroke: O, width: 2.6, cap: .round))]
        },
        "barn": {
            [p("M5 43 V21 L14 9 H34 L43 21 V43 Z", S(C.berry)),
             p("M3 22 L14 8 H34 L45 22", L()),
             p("M15 43 V28 H33 V43 Z", S(C.cream)), p("M15 28 L33 43 M33 28 L15 43", St(stroke: O, width: 3, cap: .round)),
             nRect(20, 13, 8, 8, rx: 1.5, S(C.yellow))]
        },
        "bell": {
            [nCircle(24, 39, 4, S(C.gold)), nCircle(24, 6.5, 2.8, S(C.gold)),
             p("M24 8.5 C15 8.5 12.5 16 12.5 23 V30 L8 36 H40 L35.5 30 V23 C35.5 16 33 8.5 24 8.5 Z", S(C.yellow)),
             p("M17.5 28 V22 C17.5 18 19 15.5 21 14.5", shine)]
        },
        "bubbles": {
            [(19.0, 27.0, 13.0), (36, 14, 7.5), (37, 36, 5)].flatMap { x, y, r in
                [nCircle(x, y, r, S(C.sky).fo(0.85)),
                 p("M\(f(x - r * 0.55)) \(f(y - r * 0.05)) A\(f(r * 0.58)) \(f(r * 0.58)) 0 0 1 \(f(x - r * 0.05)) \(f(y - r * 0.55))", shine)]
            }
        },
        "roll": {
            [p("M3 20 H11 M1 28 H9 M4 36 H11", St(stroke: O, width: 3.4, cap: .round)),
             nGroup([p("M27 6 C35 6 40 20 40 27 C40 36 34 42 27 42 C20 42 14 36 14 27 C14 20 19 6 27 6 Z", S("#fbf1dc")),
                     p("M14.5 27 L19 23 L23 28 L27 23.5 L31 28 L35 23 L39.5 27", L(3))], rotAbout(32, 27, 26))]
        },
        "boom": { [star(24, 24, 11, 21, 9, S(C.orange)), star(24, 24, 6, 11.5, 7, S(C.yellow), rot: -70)] },
        "bricks": {
            [nRect(5, 9, 17, 10, rx: 2, S(C.clay)), nRect(22, 9, 17, 10, rx: 2, S(C.clay)),
             nRect(13, 19, 17, 10, rx: 2, S(C.clay)), nRect(30, 19, 13, 10, rx: 2, S(C.clay)),
             nRect(5, 19, 8, 10, rx: 2, S(C.clay)),
             nRect(5, 29, 17, 10, rx: 2, S(C.clay)), nRect(22, 29, 17, 10, rx: 2, S(C.clay)),
             p("M40 36 L45 41 L40 44 Z M36 42 L39 46 L34 46 Z", thin(C.clay, 2.6))]
        },
        "paw": {
            [p("M24 24 C31 24 37 31 37 36 C37 41 33 43 29 42 C26.5 41.5 25.5 40.5 24 40.5 C22.5 40.5 21.5 41.5 19 42 C15 43 11 41 11 36 C11 31 17 24 24 24 Z", S(C.wood))] +
                [(11.0, 20.0, -20.0), (19, 12, -6), (29, 12, 6), (37, 20, 20)].map { x, y, r in
                    nEllipse(x, y, 4.6, 6, S(C.wood)).moved(rotAbout(r, x, y))
                }
        },
        "camera": {
            [p("M17 13 L19.5 8 H28.5 L31 13", S(C.stone)), nRect(5, 13, 38, 27, rx: 6, S(C.teal)),
             nCircle(24, 26.5, 9, S(C.cream)), nCircle(24, 26.5, 4, .f(O)), nCircle(22.4, 24.8, 1.4, .f("#ffffff")),
             nRect(34, 17, 5, 3.4, rx: 1.4, St(fill: C.yellow, stroke: O, width: 2.2))]
        },
        "gift": {
            [p("M24 14 C20 6 12 6 13 11 C14 15 20 14 24 14 C28 14 34 15 35 11 C36 6 28 6 24 14 Z", S(C.gold)),
             nRect(9, 21, 30, 22, rx: 3, S(C.berry)), nRect(6, 14, 36, 8, rx: 3, S(C.berry)),
             p("M24 14 V43", St(stroke: O, width: 9.5)), p("M24 15.6 V41.3", St(stroke: C.gold, width: 3))]
        },
        "broom": {
            [p("M38 5 L25 25", St(stroke: O, width: 7.5, cap: .round)), p("M38 5 L25 25", St(stroke: C.wood, width: 2.6, cap: .round)),
             p("M20 21 L31 28 L24 44 C18 44 9 39 6 34 Z", S(C.gold)),
             p("M12 33 C15 36 18 38 21 39 M17 27 C14 31 12 33 9 35", St(stroke: O, width: 2.4, strokeOpacity: 0.45, cap: .round)),
             p("M19.5 21 L31.5 28.5", St(stroke: O, width: 6, cap: .round)), p("M19.5 21 L31.5 28.5", St(stroke: C.berry, width: 2, cap: .round))]
        },
        "picture": {
            [nRect(5, 8, 38, 32, rx: 4, S(C.gold)), nRect(10.5, 13.5, 27, 21, rx: 1.5, S(C.sky)),
             nCircle(31, 20, 3.4, St(fill: C.yellow, stroke: O, width: 2.4)),
             p("M10.5 34.5 V30 C14 25 18 24 23 29 C27 26 32 26 37.5 31 V34.5 Z", S(C.leaf))]
        },

        /* ---------- "next up" card */
        "teddy": {
            [nEllipse(24, 37, 11.5, 8.5, S(C.wood)), nCircle(14, 11, 5, S(C.wood)), nCircle(34, 11, 5, S(C.wood)),
             nCircle(24, 20, 11.5, S(C.wood)), nEllipse(24, 24.5, 5.5, 4.4, S(C.cream)),
             nCircle(19.5, 17.5, 1.9, .f(O)), nCircle(28.5, 17.5, 1.9, .f(O)), nEllipse(24, 23, 2, 1.5, .f(O)),
             nEllipse(24, 38, 5, 4, .f(C.cream))]
        },
        "bath": {
            [(15.0, 12.0, 4.5), (24, 8, 3.2), (31, 14, 5)].map { x, y, r in nCircle(x, y, r, St(fill: C.sky, stroke: O, width: 2.6)) } +
                [p("M12 39 L9.5 44 M36 39 L38.5 44", L()),
                 p("M4 22 H44 V26 C44 34 38 40 30 40 H18 C10 40 4 34 4 26 Z", S("#ffffff")),
                 p("M7 27 H41", St(stroke: C.teal, width: 3.2, cap: .round))]
        },
        "bowl": {
            [p("M39 6 L28 21", St(stroke: O, width: 6.5, cap: .round)), p("M39 6 L28 21", St(stroke: C.stone, width: 2, cap: .round)),
             nEllipse(24, 22, 18, 5, S(C.cream)),
             nCircle(17, 21, 2, .f(C.gold)), nCircle(24, 23, 2, .f(C.clay)), nCircle(30, 20.5, 2, .f(C.gold)),
             p("M6 23 C6 34 14 41 24 41 C34 41 42 34 42 23 C38 26 31 27 24 27 C17 27 10 26 6 23 Z", S(C.teal))]
        },
        "sock": {
            [p("M16 5 H31 V25 L38 30 C43 33.5 41.5 43 34 43 H24 C18 43 15.5 39 15.5 34 Z", S(C.berry)),
             nRect(14.5, 4.5, 18, 8, rx: 2.5, S(C.cream)),
             p("M15.5 32 C20 31 23 34 22.5 43 M34 33 C38 34 40 36 40.5 39", St(stroke: C.cream, width: 3.5, cap: .round)),
             p("M16 5 H31 V25 L38 30 C43 33.5 41.5 43 34 43 H24 C18 43 15.5 39 15.5 34 Z M15.5 12.5 V5", L())]
        },
        "tooth": {
            [p("M13.5 9 C17.5 5 21.5 8 24 9.5 C26.5 8 30.5 5 34.5 9 C40 14.5 36.5 24 34.5 30 C33 36 32.5 43 29 43 C25.5 43 26.5 32 24 32 C21.5 32 22.5 43 19 43 C15.5 43 15 36 13.5 30 C11.5 24 8 14.5 13.5 9 Z", S("#ffffff")),
             p("M15 14 C16 11.5 18 11 20 12", L(2.6).so(0.3)),
             star(39, 8, 1.6, 4.6, 4, thin(C.yellow, 2))]
        },
        "books": {
            [nRect(6, 33, 36, 9, rx: 2.5, S(C.teal)), nRect(9, 24, 31, 9, rx: 2.5, S(C.berry)),
             nRect(7, 15, 33, 9, rx: 2.5, S(C.gold)),
             p("M36 33 V42 M13 24 V33 M35 15 V24", St(stroke: C.cream, width: 2.6)),
             nPolygon([(16, 6), (26, 4), (28, 15), (18, 15)], S(C.leaf))]
        },
        "bed": {
            [p("M7 33 V43 M41 33 V43", L(4)), nRect(4, 10, 7, 26, rx: 3, S(C.wood)),
             nRect(9, 28, 35, 9, rx: 3, S(C.cream)),
             nEllipse(17.5, 24, 6.5, 4.5, S("#ffffff")),
             p("M22 21 C30 19 38 20 44 23 V33 H22 Z", S(C.teal)),
             p("M27 25 C32 24 37 24 41 26", St(stroke: C.cream, width: 2.6, cap: .round))]
        },
        "car": {
            [p("M14 21 L18 12 H31 L36 21", S(C.sky)), p("M24.5 12 V21", L(3)),
             p("M5 30 C5 24 8 21 13 21 H37 C42 21 44 25 44 30 V34 H5 Z", S(C.berry)),
             nCircle(14, 35, 5.5, S(C.grey)), nCircle(35, 35, 5.5, S(C.grey)),
             nCircle(14, 35, 1.8, .f(C.cream)), nCircle(35, 35, 1.8, .f(C.cream)),
             nRect(39, 24.5, 4, 3, rx: 1, .f(C.yellow))]
        },
        "puzzle": {
            [p("M8 14 H18 C16 6 30 6 28 14 H38 V23 C45 21 45 35 38 33 V42 H28 C30 35 16 35 18 42 H8 Z", S(C.leaf)),
             p("M12 19 C12 17 13 17.5 15 17.5", shine)]
        },
        "paint": {
            [p("M24 6 C36 6 44 13 44 22 C44 29 38 30 34 29 C30 28 28 31 30 35 C32 39 29 43 23 42 C12 41 4 34 4 24 C4 13 12 6 24 6 Z", S(C.cream)),
             nCircle(14, 22, 3.4, St(fill: C.berry, stroke: O, width: 2.2)), nCircle(19, 13.5, 3.4, St(fill: C.yellow, stroke: O, width: 2.2)),
             nCircle(29, 12.5, 3.4, St(fill: C.teal, stroke: O, width: 2.2)), nCircle(37, 19, 3.4, St(fill: C.leaf, stroke: O, width: 2.2)),
             nCircle(16.5, 32, 3.6, St(fill: "#e9e4dc", stroke: O, width: 2.6))]
        },
        "apple": {
            [p("M24 14 C24 10 25 7 27 5", L()), p("M26 11 C29 5 36 5 38 8 C34 12 29 12 26 11 Z", S(C.leaf)),
             p("M24 15 C19 11 8 12 8 24 C8 34 15 43 21 43 C23 43 23 42 24 42 C25 42 25 43 27 43 C33 43 40 34 40 24 C40 12 29 11 24 15 Z", S(C.berry)),
             p("M13 22 C13 19 15 17 17.5 16.5", shine)]
        },
        "coat": {
            [p("M17 6 L24 11 L31 6 L39 10 L45 29 L39.5 31 L36 23 V43 H12 V23 L8.5 31 L3 29 L9 10 Z", S(C.teal)),
             p("M24 11 V43", L(3)), p("M17 6 L24 11 L20 17 L15 9 M31 6 L24 11 L28 17 L33 9", S(C.tealDk)),
             nCircle(20.5, 25, 1.8, St(fill: C.cream, stroke: O, width: 1.8)), nCircle(20.5, 33, 1.8, St(fill: C.cream, stroke: O, width: 1.8)),
             p("M28 30 H33", L(3))]
        },
        "crayon": {
            [nGroup([p("M4 18 H34 L44 24 L34 30 H4 C2.5 30 2 29 2 28 V20 C2 19 2.5 18 4 18 Z", S(C.berry)),
                     p("M10 18 V30 M26 18 V30", St(stroke: C.cream, width: 3)), nPolygon([(40, 21.5), (44, 24), (40, 26.5)], .f(O)),
                     p("M4 18 H34 L44 24 L34 30 H4 C2.5 30 2 29 2 28 V20 C2 19 2.5 18 4 18 Z M34 18 V30", L())],
                    rotAbout(-45, 24, 24))]
        },
        "toilet": {
            [nRect(9, 4, 18, 16, rx: 3, S("#ffffff")), nPolygon([(17, 43), (19, 33), (29, 33), (31, 43)], S("#ffffff")),
             p("M6 21 H42 C42 30 35 35 24 35 C13 35 6 30 6 21 Z", S("#ffffff")), nEllipse(24, 21, 18, 3.6, S(C.sky)),
             p("M13 9 H17", L(3))]
        },
        "shoe": {
            [p("M2 23 H8 M1 30 H6", St(stroke: O, width: 3.2, cap: .round)),
             p("M10 37 C10 27 12 17 18 15 C21 18 25 18 27 16 L32 26 C38 27 45 29 45 34 V37 Z", S(C.teal)),
             p("M9 37 H46 V40 C46 42 45 43 43 43 H12 C10 43 9 42 9 40 Z", S(C.cream)),
             p("M22 21 L26 19.5 M24 25 L28.5 23", St(stroke: C.cream, width: 2.6, cap: .round))]
        },
        "star": { [star(24, 25.5, 9.5, 20, 5, S(C.yellow)), p("M16 22 L19.5 20", shine)] },
    ]

    /// emoji that older builds saved in settings → the icon that replaces it
    private static let emoji: [String: String] = [
        "🧸": "teddy", "🛁": "bath", "🥣": "bowl", "🧦": "sock", "🦷": "tooth", "📚": "books", "🛏️": "bed", "🛏": "bed",
        "🚗": "car", "🧩": "puzzle", "🎨": "paint", "🍎": "apple", "🧥": "coat", "🖍️": "crayon", "🖍": "crayon",
        "🚽": "toilet", "🏃": "shoe", "⭐": "star",
    ]

    static func has(_ name: String) -> Bool { builders[name] != nil }
    static func fromEmoji(_ e: String) -> String? { emoji[e] }
    static var names: [String] { Array(builders.keys) }

    /// The icon as a node in its 48×48 box (an unknown name draws the star).
    @MainActor
    static func node(_ name: String) -> VNode {
        if let n = cache[name] { return n }
        let n = nGroup((builders[name] ?? builders["star"]!)())
        cache[name] = n
        return n
    }
    @MainActor private static var cache: [String: VNode] = [:]

    static let box = CGRect(x: 0, y: 0, width: 48, height: 48)

    /// A still picture of an icon, for an icon inside a line of text.
    @MainActor
    static func image(_ name: String, size: CGFloat) -> Image {
        let key = "\(name)@\(Int(size))"
        if let img = images[key] { return Image(uiImage: img).renderingMode(.original) }
        let n = node(name), vb = box
        let r = ImageRenderer(content: Canvas { ctx, sz in
            ctx.concatenate(fitTransform(vb, in: sz))
            Renderer.draw(n, in: ctx, now: 0)
        }.frame(width: size, height: size))
        r.scale = max(2, UITraitCollection.current.displayScale)
        let img = r.uiImage ?? UIImage()
        images[key] = img
        return Image(uiImage: img).renderingMode(.original)
    }
    @MainActor private static var images: [String: UIImage] = [:]
}

/// A drawn icon (see Icons).
struct IconView: View {
    let name: String
    var size: CGFloat = 28

    var body: some View {
        StageView(root: Icons.node(name), viewBox: Icons.box, animated: false)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Running text with drawn icons inline: "Behind the {lock} in the corner".
@MainActor
func richText(_ s: String, iconSize: CGFloat = 18) -> Text {
    var out = Text("")
    for (i, part) in s.components(separatedBy: CharacterSet(charactersIn: "{}")).enumerated() {
        if i % 2 == 1 {
            out = out + Text(Icons.image(part, size: iconSize)).baselineOffset(-3)
        } else if !part.isEmpty {
            out = out + Text(part)
        }
    }
    return out
}

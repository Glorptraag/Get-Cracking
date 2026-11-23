import SwiftUI

/// Drawn icons (the native counterpart of the web app's icons.js).
///
/// Every icon in the app is drawn here in the same visual language as the
/// eggs and friends: chunky dark outline, flat warm fills, a 48×48 box.
/// No emoji anywhere, so the UI looks the same on every device.
///
///   IconView("lock", size: 32)   → a SwiftUI view
///   Icons.node("lock")           → the drawing as a VNode tree
///   Icons.has("lock")            → is this a known icon?
///   Icons.resolve("🧸")          → icon name for a name or an emoji saved by older builds
enum Icons {
    static let viewBox = CGRect(x: 0, y: 0, width: 48, height: 48)

    /// the icons offered for the "Next up" card, in picker order
    static let nextUp = ["teddy", "bath", "bowl", "sock", "tooth", "books", "bed", "car", "puzzle", "paint",
                         "apple", "coat", "crayon", "toilet", "shoe", "star"]

    // MARK: lookup

    private static var cache: [String: VNode] = [:]

    static func has(_ name: String) -> Bool { builders[name] != nil }

    /// The drawing for an icon (an unknown name draws the star, as on the web).
    static func node(_ name: String) -> VNode {
        if let n = cache[name] { return n }
        let build = builders[name] ?? builders["star"]
        let kids: [VNode] = build?() ?? []
        let n = nGroup(kids)
        cache[name] = n
        return n
    }

    /// emoji that older builds saved in settings (or still use as ids) → the icon that replaces it
    private static let fromEmojiMap: [String: String] = [
        "🧸": "teddy", "🛁": "bath", "🥣": "bowl", "🧦": "sock", "🦷": "tooth", "📚": "books", "🛏": "bed",
        "🚗": "car", "🧩": "puzzle", "🎨": "paint", "🍎": "apple", "🧥": "coat", "🖍": "crayon",
        "🚽": "toilet", "🏃": "shoe", "⭐": "star",
        // music and hatching-tune choices
        "🎶": "notes", "🎵": "note", "🐦": "bird", "🌧": "rain", "🕰": "clock", "🔇": "quiet",
        "🎤": "mic", "🥁": "drum", "🪇": "maracas", "🐮": "barn",
        "🎉": "tada", "🔔": "bell", "🐤": "chick", "🫧": "bubbles",
        // hatch styles and the rest of the UI
        "🛞": "roll", "💥": "boom", "🧱": "bricks", "🥚": "egg", "🎲": "dice", "🐾": "paw", "📷": "camera",
        "🎁": "gift", "🖼": "picture", "👆": "tap", "🐣": "hatch", "🔒": "lock", "🧹": "broom",
    ]

    /// an emoji without its variation selector ("🛏️" and "🛏" are the same key)
    private static func plain(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for u in s.unicodeScalars where u.value != 0xFE0F { out.append(u) }
        return String(out)
    }

    static func fromEmoji(_ e: String) -> String? { fromEmojiMap[plain(e)] }

    /// An icon name for whatever is stored: a name, an emoji from an older build, or nothing (→ star).
    static func resolve(_ stored: String) -> String {
        if has(stored) { return stored }
        return fromEmoji(stored) ?? "star"
    }

    /// "🎶 Music box" → ("notes", "Music box"): a label that still starts with an emoji
    /// is split into its drawn icon and the plain text. Labels without one come back unchanged.
    static func splitLabel(_ label: String) -> (icon: String?, text: String) {
        guard let space = label.firstIndex(of: " ") else { return (nil, label) }
        let head = String(label[label.startIndex..<space])
        guard let name = fromEmoji(head) else { return (nil, label) }
        let rest = String(label[label.index(after: space)...])
        return (name, rest)
    }

    // MARK: paint

    private static let O = GC.outHex
    private static let cream = "#fdf3e4", teal = "#62b5c5", tealDk = "#4b9bab", gold = "#e0a43c", yellow = "#ffd86b"
    private static let leaf = "#a9d36b", leafDk = "#7fb04a", berry = "#c9483f", clay = "#d98a64", wood = "#b98652"
    private static let bark = "#9a5a3c", pink = "#f7a8c8", sky = "#9fd8e8", stone = "#cbbfae", grey = "#8d8784"
    private static let orange = "#f39a6b", shell = "#fbf1dc", skin = "#fbd3a8", white = "#ffffff"

    /// a filled shape with the 3.5 outline
    private static func S(_ fill: String) -> St { St.o(3.5).filled(fill) }
    /// an outline-coloured line, round caps and joins
    private static func L(_ w: Double = 3.5) -> St { St.o(w) }
    /// a filled shape with a thinner outline
    private static func T(_ fill: String, _ w: Double) -> St { St.o(w).filled(fill) }
    /// a line with round caps
    private static func R(_ c: String, _ w: Double) -> St { St(stroke: c, width: w, cap: .round) }
    /// a line with square ends
    private static func B(_ c: String, _ w: Double) -> St { St(stroke: c, width: w) }
    private static let shine = St.line("#ffffff", 3).so(0.65)

    private static func p(_ d: String, _ st: St) -> VNode { nPath(d, st) }

    // MARK: geometry helpers

    private static func f(_ n: Double) -> Double { (n * 10).rounded() / 10 }

    private static func pt(_ cx: Double, _ cy: Double, _ r: Double, _ deg: Double) -> Pt {
        let a = deg * Double.pi / 180
        return (f(cx + cos(a) * r), f(cy + sin(a) * r))
    }

    /// a toothed wheel: n teeth between radius r0 (root) and r1 (tip)
    private static func gear(_ cx: Double, _ cy: Double, _ r0: Double, _ r1: Double, _ n: Int) -> [Pt] {
        let step = 360.0 / Double(n)
        var d: [Pt] = []
        for i in 0..<n {
            let a = Double(i) * step
            d.append(pt(cx, cy, r0, a - step * 0.5))
            d.append(pt(cx, cy, r0, a - step * 0.28))
            d.append(pt(cx, cy, r1, a - step * 0.18))
            d.append(pt(cx, cy, r1, a + step * 0.18))
            d.append(pt(cx, cy, r0, a + step * 0.28))
        }
        return d
    }

    /// a pointed star or burst
    private static func star(_ cx: Double, _ cy: Double, _ r0: Double, _ r1: Double, _ n: Int, rot: Double = -90) -> [Pt] {
        var d: [Pt] = []
        for i in 0..<(n * 2) {
            let r = i % 2 == 1 ? r0 : r1
            d.append(pt(cx, cy, r, rot + Double(i) * 180.0 / Double(n)))
        }
        return d
    }

    /// a fat curved arrow along a circle, drawn as an outlined ribbon with a head
    private static func arcArrow(_ cx: Double, _ cy: Double, _ r: Double, _ a0: Double, _ a1: Double, _ fill: String) -> [VNode] {
        let p0 = pt(cx, cy, r, a0)
        let p1 = pt(cx, cy, r, a1)
        let large = abs(a1 - a0) > 180 ? 1 : 0
        let sweep = a1 > a0 ? 1 : 0
        let arc = "M\(p0.0) \(p0.1) A\(r) \(r) 0 \(large) \(sweep) \(p1.0) \(p1.1)"
        let dir: Double = sweep == 1 ? 90 : -90 // tangent direction at the end
        let tip = pt(p1.0, p1.1, 7, a1 + dir)
        let b1 = pt(p1.0, p1.1, 7.5, a1)
        let b2 = pt(p1.0, p1.1, -7.5, a1)
        return [
            p(arc, R(O, 10)),
            p(arc, R(fill, 3.6)),
            nPolygon([b1, tip, b2], S(fill)),
        ]
    }

    private static let eggD = "M24 4 C33 4 38 19 38 28 C38 37 32 44 24 44 C16 44 10 37 10 28 C10 19 15 4 24 4 Z"

    private static func chickFace(_ cx: Double, _ cy: Double) -> [VNode] {
        [
            nCircle(cx - 4, cy - 1, 1.9, .f(O)),
            nCircle(cx + 4, cy - 1, 1.9, .f(O)),
            nPolygon([(cx - 2.6, cy + 2.5), (cx + 2.6, cy + 2.5), (cx, cy + 5.6)], T(orange, 2.2)),
        ]
    }

    // MARK: the drawings

    private static let builders: [String: () -> [VNode]] = {
        var b: [String: () -> [VNode]] = [:]
        addNavigation(&b)
        addTimer(&b)
        addChoices(&b)
        addSongs(&b)
        addHatchAndPhotos(&b)
        addNextUpA(&b)
        addNextUpB(&b)
        return b
    }()

    /* ---------- setup + navigation */
    private static func addNavigation(_ b: inout [String: () -> [VNode]]) {
        b["tree"] = {
            [
                p("M20.5 29 V42 H27.5 V29", S(bark)),
                p("M24 5 C33 5 39 11 39 19 C39 27 33 32 24 32 C15 32 9 27 9 19 C9 11 15 5 24 5 Z", S(leaf)),
                p("M15 19 C15 14 18 11 22 10", shine),
                p("M6 42 H42", L()),
            ]
        }
        b["notes"] = {
            [
                p("M17 35 V14 L36 9 V31", L()),
                p("M17 13.5 L36 8.5 V15 L17 20 Z", .f(O)),
                nEllipse(12, 36, 6.3, 5, S(teal)).moved(rotAbout(-20, 12, 36)),
                nEllipse(31, 32, 6.3, 5, S(teal)).moved(rotAbout(-20, 31, 32)),
            ]
        }
        b["note"] = {
            [
                p("M27 34 V7 C30 12 37 13 37 21", L()),
                nEllipse(21, 35, 7.4, 5.8, S(gold)).moved(rotAbout(-20, 21, 35)),
            ]
        }
        b["book"] = {
            [
                p("M3 14 V41 C10 39 18 39 24 43 C30 39 38 39 45 41 V14", S(berry)),
                p("M24 13 C19 9 12 8 6 10 V37 C12 35 19 36 24 40 Z", S(cream)),
                p("M24 13 C29 9 36 8 42 10 V37 C36 35 29 36 24 40 Z", S(cream)),
                p("M10 17 C13 16 17 16 20 18 M10 23 C13 22 17 22 20 24 M28 18 C31 16 35 16 38 17 M28 24 C31 22 35 22 38 23",
                  R(O, 2.4).so(0.35)),
            ]
        }
        b["gear"] = {
            [
                nPolygon(gear(24, 24, 14.5, 20.5, 8), S(stone)),
                nCircle(24, 24, 6.5, S(cream)),
            ]
        }
    }

    /* ---------- timer screen */
    private static func addTimer(_ b: inout [String: () -> [VNode]]) {
        b["tap"] = {
            [
                nRect(17, 2.5, 10, 27, rx: 5, S(skin)),
                p("M14 23 H35 C38 23 40 25 40 28 V33 C40 40 35 45 28 45 H25 C17 45 11 40 11 32 V26 C11 24 12 23 14 23 Z", S(skin)),
                p("M17 24 V32 M27 24 V30 M33.5 24 V30", R(O, 3)),
                p("M20 8 V14", shine),
            ]
        }
        b["lock"] = {
            let shackle = "M15 22 V16 C15 10.5 19 7 24 7 C29 7 33 10.5 33 16 V22"
            return [
                p(shackle, R(O, 9)),
                p(shackle, R(stone, 3)),
                nRect(9, 21, 30, 22, rx: 6, S(gold)),
                p("M24 28 V35", R(O, 5)),
                nCircle(24, 28.5, 3.6, .f(O)),
            ]
        }
        b["egg"] = {
            let spot = "#a9cf8b"
            return [
                p(eggD, S(shell)),
                nCircle(20, 17, 3.2, .f(spot)), nCircle(29, 24, 4.2, .f(spot)),
                nCircle(19, 32, 3.6, .f(spot)), nCircle(29, 37, 2.6, .f(spot)),
                p("M15 30 C14 22 16 14 20 9", shine),
            ]
        }
        b["pause"] = {
            [nRect(11, 9, 9, 30, rx: 3.5, S(teal)), nRect(28, 9, 9, 30, rx: 3.5, S(teal))]
        }
        b["play"] = {
            [p(playD, S(leaf))]
        }
        // the mark on the Start button: the play triangle in cream with a heavier outline
        b["start"] = {
            [p(playD, T(cream, 4.5))]
        }
        b["stop"] = {
            [nRect(10, 10, 28, 28, rx: 6, S(berry))]
        }
        b["hatch"] = {
            var k: [VNode] = [
                p("M24 8 C22.5 5 25 3.5 27 5", L(3)),
                nCircle(24, 20, 11.5, S(yellow)),
            ]
            k += chickFace(24, 19)
            k.append(p("M9 29 L14 24 L19 30 L24 25 L29 30 L34 24 L39 29 C39 39 33 45 24 45 C15 45 9 39 9 29 Z", S(shell)))
            return k
        }
        b["again"] = {
            arcArrow(24, 24, 14, 200, 340, leafDk) + arcArrow(24, 24, 14, 20, 160, teal)
        }
        b["reset"] = {
            arcArrow(24, 25, 13.5, -40, 230, teal)
        }
        b["close"] = { [p("M14 14 L34 34 M34 14 L14 34", R(O, 6))] }
        b["minus"] = { [p("M11 24 H37", R(O, 6))] }
        b["plus"] = { [p("M24 11 V37 M11 24 H37", R(O, 6))] }
    }

    /// the play triangle (also the mark on the Start button)
    static let playD = "M15 9.5 C15 7.5 17 6.5 18.7 7.5 L39 21.5 C40.6 22.6 40.6 25.4 39 26.5 L18.7 40.5 C17 41.5 15 40.5 15 38.5 Z"

    /* ---------- settings choices */
    private static func addChoices(_ b: inout [String: () -> [VNode]]) {
        b["dice"] = {
            var k: [VNode] = [nRect(8, 8, 32, 32, rx: 8, S(cream))]
            let pips: [Pt] = [(16, 16), (32, 16), (24, 24), (16, 32), (32, 32)]
            for q in pips { k.append(nCircle(q.0, q.1, 3.2, .f(berry))) }
            return [nGroup(k, rotAbout(-10, 24, 24))]
        }
        b["bird"] = {
            [
                p("M13 27 L4 21 L6 33 Z", S(tealDk)),
                nCircle(22, 26, 13, S(teal)),
                p("M14 26 C17 33 25 33 28 27", R(O, 3)),
                nCircle(27, 21, 2.1, .f(O)),
                p("M34 20 L42 23 L34 26.5 Z", S(gold)),
                p("M19 39 V44 M25 39 V44", L(3)),
            ]
        }
        b["chick"] = {
            var k: [VNode] = [
                p("M24 10 C22.5 6.5 25 5 27 6.5", L(3)),
                nCircle(24, 27, 15, S(yellow)),
            ]
            k += chickFace(24, 24)
            k.append(p("M10.5 30 C13 35 17 35 18 32", R(O, 3)))
            k.append(p("M37.5 30 C35 35 31 35 30 32", R(O, 3)))
            k.append(nCircle(16, 29, 2.4, .f(pink)))
            k.append(nCircle(32, 29, 2.4, .f(pink)))
            return k
        }
        b["rain"] = {
            var k: [VNode] = [
                p("M13 30 C6.5 30 5.5 21 12 19.5 C12 11.5 22 8.5 26 14.5 C30 10.5 38.5 13 37.5 20 C43.5 21 42.5 30 36 30 Z", S(cream)),
            ]
            let drops: [Pt] = [(15, 35), (24, 38), (33, 35)]
            for q in drops {
                let x = q.0, y = q.1
                let d = "M\(x) \(y) C\(f(x + 2.6)) \(f(y + 3.4)) \(f(x + 3)) \(f(y + 6.4)) \(x) \(f(y + 6.8)) " +
                    "C\(f(x - 3)) \(f(y + 6.4)) \(f(x - 2.6)) \(f(y + 3.4)) \(x) \(y) Z"
                k.append(p(d, T(sky, 2.6)))
            }
            return k
        }
        b["clock"] = {
            [
                p("M15 41 L12.5 45 M33 41 L35.5 45", L()),
                nCircle(24, 25, 17, S(gold)),
                nCircle(24, 25, 12, S(cream)),
                p("M24 25 V17.5 M24 25 L29 28", L()),
                nCircle(24, 25, 2, .f(O)),
                nCircle(24, 5.5, 3, S(gold)),
            ]
        }
        b["quiet"] = {
            [
                p("M7 19 H15 L25 10.5 V37.5 L15 29 H7 Z", S(stone)),
                p("M31 19 L41 29 M41 19 L31 29", R(O, 4.5)),
            ]
        }
        b["tada"] = {
            let cone = "M6 43 L15 17 L32 34 Z"
            return [
                p(cone, S(gold)),
                p("M10.5 31 L20 38.5 M13 24 L26 34.5", R(berry, 3.4)),
                p(cone, L()),
                nPolygon(star(32, 11, 2.4, 6, 4), T(yellow, 2.4)),
                nCircle(41, 22, 3, T(pink, 2.4)),
                nCircle(22, 7, 2.6, T(sky, 2.4)),
                p("M37 33 C40 31 41 35 44 33", R(O, 2.6)),
            ]
        }
        b["bell"] = {
            [
                nCircle(24, 39, 4, S(gold)),
                nCircle(24, 6.5, 2.8, S(gold)),
                p("M24 8.5 C15 8.5 12.5 16 12.5 23 V30 L8 36 H40 L35.5 30 V23 C35.5 16 33 8.5 24 8.5 Z", S(yellow)),
                p("M17.5 28 V22 C17.5 18 19 15.5 21 14.5", shine),
            ]
        }
        b["bubbles"] = {
            var k: [VNode] = []
            let all: [(Double, Double, Double)] = [(19, 27, 13), (36, 14, 7.5), (37, 36, 5)]
            for q in all {
                let x = q.0, y = q.1, r = q.2
                k.append(nCircle(x, y, r, S(sky).fo(0.85)))
                let rr = f(r * 0.58)
                let d = "M\(f(x - r * 0.55)) \(f(y - r * 0.05)) A\(rr) \(rr) 0 0 1 \(f(x - r * 0.05)) \(f(y - r * 0.55))"
                k.append(p(d, shine))
            }
            return k
        }
    }

    /* ---------- the hatching songs */
    private static func addSongs(_ b: inout [String: () -> [VNode]]) {
        b["drum"] = {
            [
                p("M5 9 L19 19 M43 9 L29 19", R(O, 3.5)),
                nCircle(5, 9, 3, S(cream)),
                nCircle(43, 9, 3, S(cream)),
                p("M8 22 V37 C8 41 15 44 24 44 C33 44 40 41 40 37 V22 Z", S(berry)),
                p("M8 25 L16 38 L24 25 L32 38 L40 25", St(stroke: yellow, width: 3, join: .round)),
                p("M8 36 C8 40 15 43 24 43 C33 43 40 40 40 36", L()),
                nEllipse(24, 22, 16, 5.5, S(cream)),
            ]
        }
        // Egg karaoke: a microphone whose head is a cracked egg, and a note
        b["mic"] = {
            [
                p("M19 28 L21 42 C21.3 45 26.7 45 27 42 L29 28 Z", S(berry)),
                p("M22 4 C30 4 34 12 34 19 C34 25 29 30 22 30 C15 30 10 25 10 19 C10 12 14 4 22 4 Z", S(cream)),
                p("M11 18 L15 14.5 L18.5 18.5 L22 14.5 L25.5 18.5 L29 14.5 L33 18", L(2.6)),
                p("M15 9 C16 7.5 17.5 6.5 19 6", shine),
                p("M42 7 V20", L(3)),
                p("M42 7 L46 9", L(3)),
                nEllipse(39.5, 20.5, 3.4, 2.6, .f(O)),
            ]
        }
        b["maracas"] = {
            let sticks = "M17 25 L9 44 M31 25 L39 44"
            return [
                p(sticks, R(O, 7)),
                p(sticks, R(wood, 3)),
                nEllipse(19, 15, 9, 11, S(orange)).moved(rotAbout(22, 19, 15)),
                nEllipse(30, 15, 9, 11, S(leaf)).moved(rotAbout(-22, 30, 15)),
                p("M25 11 L35 15 M24 17 L33 21", R(yellow, 2.8)),
                p("M3 9 C4.5 7 6 7 7 9 M41 4 C42.5 2 44 2 45 4", R(O, 2.6)),
            ]
        }
        b["barn"] = {
            [
                p("M5 43 V21 L14 9 H34 L43 21 V43 Z", S(berry)),
                p("M3 22 L14 8 H34 L45 22", L()),
                p("M15 43 V28 H33 V43 Z", S(cream)),
                p("M15 28 L33 43 M33 28 L15 43", R(O, 3)),
                nRect(20, 13, 8, 8, rx: 1.5, S(yellow)),
            ]
        }
    }

    /* ---------- hatch styles, who hatches, photos, about */
    private static func addHatchAndPhotos(_ b: inout [String: () -> [VNode]]) {
        b["roll"] = {
            let egg = nGroup([
                p("M27 6 C35 6 40 20 40 27 C40 36 34 42 27 42 C20 42 14 36 14 27 C14 20 19 6 27 6 Z", S(shell)),
                p("M14.5 27 L19 23 L23 28 L27 23.5 L31 28 L35 23 L39.5 27", L(3)),
            ], rotAbout(32, 27, 26))
            return [p("M3 20 H11 M1 28 H9 M4 36 H11", R(O, 3.4)), egg]
        }
        b["boom"] = {
            [
                nPolygon(star(24, 24, 11, 21, 9), S(orange)),
                nPolygon(star(24, 24, 6, 11.5, 7, rot: -70), S(yellow)),
            ]
        }
        b["bricks"] = {
            [
                nRect(5, 9, 17, 10, rx: 2, S(clay)), nRect(22, 9, 17, 10, rx: 2, S(clay)),
                nRect(13, 19, 17, 10, rx: 2, S(clay)), nRect(30, 19, 13, 10, rx: 2, S(clay)),
                nRect(5, 19, 8, 10, rx: 2, S(clay)),
                nRect(5, 29, 17, 10, rx: 2, S(clay)), nRect(22, 29, 17, 10, rx: 2, S(clay)),
                p("M40 36 L45 41 L40 44 Z M36 42 L39 46 L34 46 Z", T(clay, 2.6)),
            ]
        }
        b["paw"] = {
            var k: [VNode] = [
                p("M24 24 C31 24 37 31 37 36 C37 41 33 43 29 42 C26.5 41.5 25.5 40.5 24 40.5 C22.5 40.5 21.5 41.5 19 42 C15 43 11 41 11 36 C11 31 17 24 24 24 Z", S(wood)),
            ]
            let toes: [(Double, Double, Double)] = [(11, 20, -20), (19, 12, -6), (29, 12, 6), (37, 20, 20)]
            for t in toes {
                k.append(nEllipse(t.0, t.1, 4.6, 6, S(wood)).moved(rotAbout(t.2, t.0, t.1)))
            }
            return k
        }
        b["camera"] = {
            [
                p("M17 13 L19.5 8 H28.5 L31 13", S(stone)),
                nRect(5, 13, 38, 27, rx: 6, S(teal)),
                nCircle(24, 26.5, 9, S(cream)),
                nCircle(24, 26.5, 4, .f(O)),
                nCircle(22.4, 24.8, 1.4, .f(white)),
                nRect(34, 17, 5, 3.4, rx: 1.4, St(fill: yellow, stroke: O, width: 2.2)),
            ]
        }
        b["gift"] = {
            [
                p("M24 14 C20 6 12 6 13 11 C14 15 20 14 24 14 C28 14 34 15 35 11 C36 6 28 6 24 14 Z", S(gold)),
                nRect(9, 21, 30, 22, rx: 3, S(berry)),
                nRect(6, 14, 36, 8, rx: 3, S(berry)),
                p("M24 14 V43", B(O, 9.5)),
                p("M24 15.6 V41.3", B(gold, 3)),
            ]
        }
        b["broom"] = {
            [
                p("M38 5 L25 25", R(O, 7.5)),
                p("M38 5 L25 25", R(wood, 2.6)),
                p("M20 21 L31 28 L24 44 C18 44 9 39 6 34 Z", S(gold)),
                p("M12 33 C15 36 18 38 21 39 M17 27 C14 31 12 33 9 35", R(O, 2.4).so(0.45)),
                p("M19.5 21 L31.5 28.5", R(O, 6)),
                p("M19.5 21 L31.5 28.5", R(berry, 2)),
            ]
        }
        b["picture"] = {
            [
                nRect(5, 8, 38, 32, rx: 4, S(gold)),
                nRect(10.5, 13.5, 27, 21, rx: 1.5, S(sky)),
                nCircle(31, 20, 3.4, T(yellow, 2.4)),
                p("M10.5 34.5 V30 C14 25 18 24 23 29 C27 26 32 26 37.5 31 V34.5 Z", S(leaf)),
            ]
        }
    }

    /* ---------- "next up" card */
    private static func addNextUpA(_ b: inout [String: () -> [VNode]]) {
        b["teddy"] = {
            [
                nEllipse(24, 37, 11.5, 8.5, S(wood)),
                nCircle(14, 11, 5, S(wood)), nCircle(34, 11, 5, S(wood)),
                nCircle(24, 20, 11.5, S(wood)),
                nEllipse(24, 24.5, 5.5, 4.4, S(cream)),
                nCircle(19.5, 17.5, 1.9, .f(O)), nCircle(28.5, 17.5, 1.9, .f(O)),
                nEllipse(24, 23, 2, 1.5, .f(O)),
                nEllipse(24, 38, 5, 4, .f(cream)),
            ]
        }
        b["bath"] = {
            var k: [VNode] = []
            let suds: [(Double, Double, Double)] = [(15, 12, 4.5), (24, 8, 3.2), (31, 14, 5)]
            for q in suds { k.append(nCircle(q.0, q.1, q.2, St(fill: sky, stroke: O, width: 2.6))) }
            k.append(p("M12 39 L9.5 44 M36 39 L38.5 44", L()))
            k.append(p("M4 22 H44 V26 C44 34 38 40 30 40 H18 C10 40 4 34 4 26 Z", S(white)))
            k.append(p("M7 27 H41", R(teal, 3.2)))
            return k
        }
        b["bowl"] = {
            [
                p("M39 6 L28 21", R(O, 6.5)),
                p("M39 6 L28 21", R(stone, 2)),
                nEllipse(24, 22, 18, 5, S(cream)),
                nCircle(17, 21, 2, .f(gold)), nCircle(24, 23, 2, .f(clay)), nCircle(30, 20.5, 2, .f(gold)),
                p("M6 23 C6 34 14 41 24 41 C34 41 42 34 42 23 C38 26 31 27 24 27 C17 27 10 26 6 23 Z", S(teal)),
            ]
        }
        b["sock"] = {
            let sock = "M16 5 H31 V25 L38 30 C43 33.5 41.5 43 34 43 H24 C18 43 15.5 39 15.5 34 Z"
            return [
                p(sock, S(berry)),
                nRect(14.5, 4.5, 18, 8, rx: 2.5, S(cream)),
                p("M15.5 32 C20 31 23 34 22.5 43 M34 33 C38 34 40 36 40.5 39", R(cream, 3.5)),
                p(sock + " M15.5 12.5 V5", L()),
            ]
        }
        b["tooth"] = {
            [
                p("M13.5 9 C17.5 5 21.5 8 24 9.5 C26.5 8 30.5 5 34.5 9 C40 14.5 36.5 24 34.5 30 C33 36 32.5 43 29 43 C25.5 43 26.5 32 24 32 C21.5 32 22.5 43 19 43 C15.5 43 15 36 13.5 30 C11.5 24 8 14.5 13.5 9 Z", S(white)),
                p("M15 14 C16 11.5 18 11 20 12", L(2.6).so(0.3)),
                nPolygon(star(39, 8, 1.6, 4.6, 4), T(yellow, 2)),
            ]
        }
        b["books"] = {
            [
                nRect(6, 33, 36, 9, rx: 2.5, S(teal)),
                nRect(9, 24, 31, 9, rx: 2.5, S(berry)),
                nRect(7, 15, 33, 9, rx: 2.5, S(gold)),
                p("M36 33 V42 M13 24 V33 M35 15 V24", B(cream, 2.6)),
                p("M16 6 L26 4 L28 15 L18 15 Z", S(leaf)),
            ]
        }
        b["bed"] = {
            [
                p("M7 33 V43 M41 33 V43", L(4)),
                nRect(4, 10, 7, 26, rx: 3, S(wood)),
                nRect(9, 28, 35, 9, rx: 3, S(cream)),
                nEllipse(17.5, 24, 6.5, 4.5, S(white)),
                p("M22 21 C30 19 38 20 44 23 V33 H22 Z", S(teal)),
                p("M27 25 C32 24 37 24 41 26", R(cream, 2.6)),
            ]
        }
        b["car"] = {
            [
                p("M14 21 L18 12 H31 L36 21", S(sky)),
                p("M24.5 12 V21", L(3)),
                p("M5 30 C5 24 8 21 13 21 H37 C42 21 44 25 44 30 V34 H5 Z", S(berry)),
                nCircle(14, 35, 5.5, S(grey)), nCircle(35, 35, 5.5, S(grey)),
                nCircle(14, 35, 1.8, .f(cream)), nCircle(35, 35, 1.8, .f(cream)),
                nRect(39, 24.5, 4, 3, rx: 1, .f(yellow)),
            ]
        }
    }

    private static func addNextUpB(_ b: inout [String: () -> [VNode]]) {
        b["puzzle"] = {
            [
                p("M8 14 H18 C16 6 30 6 28 14 H38 V23 C45 21 45 35 38 33 V42 H28 C30 35 16 35 18 42 H8 Z", S(leaf)),
                p("M12 19 C12 17 13 17.5 15 17.5", shine),
            ]
        }
        b["paint"] = {
            [
                p("M24 6 C36 6 44 13 44 22 C44 29 38 30 34 29 C30 28 28 31 30 35 C32 39 29 43 23 42 C12 41 4 34 4 24 C4 13 12 6 24 6 Z", S(cream)),
                nCircle(14, 22, 3.4, St(fill: berry, stroke: O, width: 2.2)),
                nCircle(19, 13.5, 3.4, St(fill: yellow, stroke: O, width: 2.2)),
                nCircle(29, 12.5, 3.4, St(fill: teal, stroke: O, width: 2.2)),
                nCircle(37, 19, 3.4, St(fill: leaf, stroke: O, width: 2.2)),
                nCircle(16.5, 32, 3.6, St(fill: "#e9e4dc", stroke: O, width: 2.6)),
            ]
        }
        b["apple"] = {
            [
                p("M24 14 C24 10 25 7 27 5", L()),
                p("M26 11 C29 5 36 5 38 8 C34 12 29 12 26 11 Z", S(leaf)),
                p("M24 15 C19 11 8 12 8 24 C8 34 15 43 21 43 C23 43 23 42 24 42 C25 42 25 43 27 43 C33 43 40 34 40 24 C40 12 29 11 24 15 Z", S(berry)),
                p("M13 22 C13 19 15 17 17.5 16.5", shine),
            ]
        }
        b["coat"] = {
            [
                p("M17 6 L24 11 L31 6 L39 10 L45 29 L39.5 31 L36 23 V43 H12 V23 L8.5 31 L3 29 L9 10 Z", S(teal)),
                p("M24 11 V43", L(3)),
                p("M17 6 L24 11 L20 17 L15 9 M31 6 L24 11 L28 17 L33 9", S(tealDk)),
                nCircle(20.5, 25, 1.8, St(fill: cream, stroke: O, width: 1.8)),
                nCircle(20.5, 33, 1.8, St(fill: cream, stroke: O, width: 1.8)),
                p("M28 30 H33", L(3)),
            ]
        }
        b["crayon"] = {
            let body = "M4 18 H34 L44 24 L34 30 H4 C2.5 30 2 29 2 28 V20 C2 19 2.5 18 4 18 Z"
            return [nGroup([
                p(body, S(berry)),
                p("M10 18 V30 M26 18 V30", B(cream, 3)),
                p("M40 21.5 L44 24 L40 26.5 Z", .f(O)),
                p(body + " M34 18 V30", L()),
            ], rotAbout(-45, 24, 24))]
        }
        b["toilet"] = {
            [
                nRect(9, 4, 18, 16, rx: 3, S(white)),
                p("M17 43 L19 33 H29 L31 43 Z", S(white)),
                p("M6 21 H42 C42 30 35 35 24 35 C13 35 6 30 6 21 Z", S(white)),
                nEllipse(24, 21, 18, 3.6, S(sky)),
                p("M13 9 H17", L(3)),
            ]
        }
        b["shoe"] = {
            [
                p("M2 23 H8 M1 30 H6", R(O, 3.2)),
                p("M10 37 C10 27 12 17 18 15 C21 18 25 18 27 16 L32 26 C38 27 45 29 45 34 V37 Z", S(teal)),
                p("M9 37 H46 V40 C46 42 45 43 43 43 H12 C10 43 9 42 9 40 Z", S(cream)),
                p("M22 21 L26 19.5 M24 25 L28.5 23", R(cream, 2.6)),
            ]
        }
        b["star"] = {
            [
                nPolygon(star(24, 25.5, 9.5, 20, 5), S(yellow)),
                p("M16 22 L19.5 20", shine),
            ]
        }
    }
}

/// One drawn icon, sized like the web's `.gc-ico`. Decorative by default:
/// the control around it carries the accessibility label.
struct IconView: View {
    let name: String
    var size: CGFloat = 24

    init(_ name: String, size: CGFloat = 24) {
        self.name = name
        self.size = size
    }

    var body: some View {
        let root = Icons.node(name)
        Canvas { ctx, canvasSize in
            ctx.concatenate(fitTransform(Icons.viewBox, in: canvasSize))
            Renderer.draw(root, in: ctx, now: GC.now)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

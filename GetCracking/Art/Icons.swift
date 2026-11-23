import SwiftUI

/// The drawn icons (web js/icons.js, from 982859f): every icon in the UI is
/// drawn in the same visual language as the eggs and friends (chunky dark
/// outline, flat warm fills) in a 48×48 box, so no emoji anywhere.
///
/// The drawings are the web's markup turned into path data for the app's own
/// vector scene graph (`VNode`, drawn by `Renderer`): the web's gear, star and
/// arc-arrow helpers are already evaluated into the paths below. `IconView`
/// (UI/IconView.swift) shows one in SwiftUI.
///
///   Icons.node("lock")        → a fresh drawing, in the 48×48 box
///   Icons.has("lock")         → is this a known icon?
///   Icons.fromEmoji("🧸")     → "teddy" (a Next-up icon saved by older builds)
enum Icons {
    /// the box every icon is drawn in (icons may poke a little past it)
    static let box = CGRect(x: 0, y: 0, width: 48, height: 48)

    static func has(_ name: String) -> Bool { builders[name] != nil }

    /// A new drawing of `name` (the star for an unknown name, as on the web).
    static func node(_ name: String) -> VNode {
        nGroup((builders[name] ?? star)())
    }

    /// emoji that older builds saved in settings → the icon that replaces it
    static let fromEmojiMap: [String: String] = [
        "🧸": "teddy", "🛁": "bath", "🥣": "bowl", "🧦": "sock", "🦷": "tooth", "📚": "books", "🛏️": "bed", "🛏": "bed",
        "🚗": "car", "🧩": "puzzle", "🎨": "paint", "🍎": "apple", "🧥": "coat", "🖍️": "crayon", "🖍": "crayon",
        "🚽": "toilet", "🏃": "shoe", "⭐": "star",
    ]
    static func fromEmoji(_ e: String) -> String? { fromEmojiMap[e] }

    /// A saved Next-up icon as an icon name: older builds saved an emoji.
    static func normalized(_ saved: String) -> String {
        has(saved) ? saved : (fromEmoji(saved) ?? "star")
    }

    /// the Next-up card's icon choices, in the web's order
    static let nextUp = ["teddy", "bath", "bowl", "sock", "tooth", "books", "bed", "car", "puzzle", "paint",
                         "apple", "coat", "crayon", "toilet", "shoe", "star"]

    /// spoken names for the Next-up choices
    static func label(_ name: String) -> String {
        let names = ["teddy": "Teddy", "bath": "Bath", "bowl": "Breakfast bowl", "sock": "Sock", "tooth": "Tooth",
                     "books": "Books", "bed": "Bed", "car": "Car", "puzzle": "Puzzle", "paint": "Paints",
                     "apple": "Apple", "coat": "Coat", "crayon": "Crayon", "toilet": "Toilet", "shoe": "Shoe", "star": "Star"]
        return names[name] ?? name.capitalized
    }

    /// The icon for a music, hatching-tune or hatch-style choice, by its id
    /// (the web keeps these in GC.MUSIC, GC.END_SOUNDS and each ShellFX).
    static func forChoice(_ id: String) -> String {
        let map = [
            // countdown music
            "musicbox": "notes", "marimba": "note", "forest": "bird", "rain": "rain", "ticktock": "clock", "off": "quiet",
            // hatching tunes
            "karaoke": "mic", "band": "drum", "jungle": "maracas", "farm": "barn", "tada": "tada", "chimes": "bell",
            "birds": "chick", "bubbles": "bubbles",
            // hatch styles
            "roll": "roll", "boom": "boom", "crumble": "bricks", "classic": "egg", "random": "dice",
        ]
        return map[id] ?? "star"
    }

    // MARK: drawing helpers (the web's attribute defaults: no stroke, butt caps, miter joins)

    private static let O = GC.outHex
    private enum C {
        static let cream = "#fdf3e4", teal = "#62b5c5", tealDk = "#4b9bab", gold = "#e0a43c", yellow = "#ffd86b"
        static let leaf = "#a9d36b", leafDk = "#7fb04a", berry = "#c9483f", clay = "#d98a64", wood = "#b98652"
        static let bark = "#9a5a3c", pink = "#f7a8c8", sky = "#9fd8e8", stone = "#cbbfae", grey = "#8d8784"
        static let lilac = "#c5a8f0", orange = "#f39a6b"
    }

    private static func p(_ d: String) -> Path { SVGPath.parse(d) }
    private static func circ(_ cx: Double, _ cy: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    }
    private static func ell(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
    }
    /// an SVG <rect> (circular corners, like the browser draws them)
    private static func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ rx: Double) -> Path {
        let r = CGRect(x: x, y: y, width: w, height: h)
        if rx <= 0 { return Path(r) }
        let c = min(rx, w / 2, h / 2)
        return Path(roundedRect: r, cornerSize: CGSize(width: c, height: c), style: .circular)
    }
    /// paint: fill (nil = none), then an optional stroke
    private static func k(_ fill: String?, _ stroke: String? = nil, _ width: Double = 1,
                          _ cap: CGLineCap = .butt, _ join: CGLineJoin = .miter,
                          fo: Double = 1, so: Double = 1) -> St {
        St(fill: fill, fillOpacity: fo, stroke: stroke, width: stroke == nil ? 0 : width, strokeOpacity: so, cap: cap, join: join)
    }

    // MARK: iPhone-only icons (no web counterpart)

    /// The Whole Nest (an iPhone-only unlock): two eggs in a twig nest.
    private static func nest() -> [VNode] {
        [
            nShape(ell(18, 22, 7.5, 9.5), k("#dcecf6", O, 3.5, .round, .round)).moved(rotAbout(-12, 18, 22)),
            nShape(ell(30, 21, 7.5, 9.5), k("#fbf1dc", O, 3.5, .round, .round)).moved(rotAbout(10, 30, 21)),
            nShape(circ(28, 17, 1.8), k("#a9cf8b")),
            nShape(circ(32.5, 23, 2.2), k("#a9cf8b")),
            nShape(p("M4 25 C4 37 13 44 24 44 C35 44 44 37 44 25 C38 29 31 30 24 30 C17 30 10 29 4 25 Z"), k(C.wood, O, 3.5, .round, .round)),
            nShape(p("M9 32 C15 35 22 36 30 35 M14 39 C20 40 28 40 35 37"), k(nil, C.bark, 2.6, .round, .round)),
            nShape(p("M2 23 L8 27 M46 23 L40 27"), k(nil, O, 3, .round, .round)),
        ]
    }

    // MARK: the web's icons (generated from js/icons.js)

    /// the web's icons, in its order (plus the iPhone-only nest)
    static let names: [String] = [
        "tree", "notes", "note", "book", "gear", "tap", "lock", "egg", "pause", "play", "stop", "hatch", "again",
        "reset", "close", "minus", "plus", "dice", "bird", "chick", "rain", "clock", "quiet", "tada", "drum", "mic",
        "maracas", "barn", "bell", "bubbles", "roll", "boom", "bricks", "paw", "camera", "gift", "broom", "picture",
        "teddy", "bath", "bowl", "sock", "tooth", "books", "bed", "car", "puzzle", "paint", "apple", "coat",
        "crayon", "toilet", "shoe", "star", "nest",
    ]

    private static let builders: [String: () -> [VNode]] = [
        "tree": tree, "notes": notes, "note": note, "book": book, "gear": gear, "tap": tap, "lock": lock, "egg": egg,
        "pause": pause, "play": play, "stop": stop, "hatch": hatch, "again": again, "reset": reset, "close": close,
        "minus": minus, "plus": plus, "dice": dice, "bird": bird, "chick": chick, "rain": rain, "clock": clock,
        "quiet": quiet, "tada": tada, "drum": drum, "mic": mic, "maracas": maracas, "barn": barn, "bell": bell,
        "bubbles": bubbles, "roll": roll, "boom": boom, "bricks": bricks, "paw": paw, "camera": camera, "gift": gift,
        "broom": broom, "picture": picture, "teddy": teddy, "bath": bath, "bowl": bowl, "sock": sock, "tooth": tooth,
        "books": books, "bed": bed, "car": car, "puzzle": puzzle, "paint": paint, "apple": apple, "coat": coat,
        "crayon": crayon, "toilet": toilet, "shoe": shoe, "star": star,
        "nest": nest,
    ]

    private static func tree() -> [VNode] {
        [
            nShape(p("M20.5 29 V42 H27.5 V29"), k(C.bark, O, 3.5, .round, .round)),
            nShape(p("M24 5 C33 5 39 11 39 19 C39 27 33 32 24 32 C15 32 9 27 9 19 C9 11 15 5 24 5 Z"), k(C.leaf, O, 3.5, .round, .round)),
            nShape(p("M15 19 C15 14 18 11 22 10"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
            nShape(p("M6 42 H42"), k(nil, O, 3.5, .round, .round)),
        ]
    }

    private static func notes() -> [VNode] {
        [
            nShape(p("M17 35 V14 L36 9 V31"), k(nil, O, 3.5, .round, .round)),
            nShape(p("M17 13.5 L36 8.5 V15 L17 20 Z"), k(O)),
            nShape(ell(12, 36, 6.3, 5), k(C.teal, O, 3.5, .round, .round)).moved(rotAbout(-20, 12, 36)),
            nShape(ell(31, 32, 6.3, 5), k(C.teal, O, 3.5, .round, .round)).moved(rotAbout(-20, 31, 32)),
        ]
    }

    private static func note() -> [VNode] {
        [
            nShape(p("M27 34 V7 C30 12 37 13 37 21"), k(nil, O, 3.5, .round, .round)),
            nShape(ell(21, 35, 7.4, 5.8), k(C.gold, O, 3.5, .round, .round)).moved(rotAbout(-20, 21, 35)),
        ]
    }

    private static func book() -> [VNode] {
        [
            nShape(p("M3 14 V41 C10 39 18 39 24 43 C30 39 38 39 45 41 V14"), k(C.berry, O, 3.5, .round, .round)),
            nShape(p("M24 13 C19 9 12 8 6 10 V37 C12 35 19 36 24 40 Z"), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M24 13 C29 9 36 8 42 10 V37 C36 35 29 36 24 40 Z"), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M10 17 C13 16 17 16 20 18 M10 23 C13 22 17 22 20 24 M28 18 C31 16 35 16 38 17 M28 24 C31 22 35 22 38 23"), k(nil, O, 2.4, .round, .miter, so: 0.35)),
        ]
    }

    private static func gear() -> [VNode] {
        [
            nShape(p("M37.4 18.5 L38.2 20.8 L44.3 21.1 L44.3 26.9 L38.2 27.2 L37.4 29.5 L36.2 31.8 L40.4 36.3 L36.3 40.4 L31.8 36.2 L29.5 37.4 L27.2 38.2 L26.9 44.3 L21.1 44.3 L20.8 38.2 L18.5 37.4 L16.2 36.2 L11.7 40.4 L7.6 36.3 L11.8 31.8 L10.6 29.5 L9.8 27.2 L3.7 26.9 L3.7 21.1 L9.8 20.8 L10.6 18.5 L11.8 16.2 L7.6 11.7 L11.7 7.6 L16.2 11.8 L18.5 10.6 L20.8 9.8 L21.1 3.7 L26.9 3.7 L27.2 9.8 L29.5 10.6 L31.8 11.8 L36.3 7.6 L40.4 11.7 L36.2 16.2 Z"), k(C.stone, O, 3.5, .round, .round)),
            nShape(circ(24, 24, 6.5), k(C.cream, O, 3.5, .round, .round)),
        ]
    }

    private static func tap() -> [VNode] {
        [
            nShape(rect(17, 2.5, 10, 27, 5), k("#fbd3a8", O, 3.5, .round, .round)),
            nShape(p("M14 23 H35 C38 23 40 25 40 28 V33 C40 40 35 45 28 45 H25 C17 45 11 40 11 32 V26 C11 24 12 23 14 23 Z"), k("#fbd3a8", O, 3.5, .round, .round)),
            nShape(p("M17 24 V32 M27 24 V30 M33.5 24 V30"), k(nil, O, 3, .round, .miter)),
            nShape(p("M20 8 V14"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
        ]
    }

    private static func lock() -> [VNode] {
        [
            nShape(p("M15 22 V16 C15 10.5 19 7 24 7 C29 7 33 10.5 33 16 V22"), k(nil, O, 9, .round, .miter)),
            nShape(p("M15 22 V16 C15 10.5 19 7 24 7 C29 7 33 10.5 33 16 V22"), k(nil, C.stone, 3, .round, .miter)),
            nShape(rect(9, 21, 30, 22, 6), k(C.gold, O, 3.5, .round, .round)),
            nShape(p("M24 28 V35"), k(nil, O, 5, .round, .miter)),
            nShape(circ(24, 28.5, 3.6), k(O)),
        ]
    }

    private static func egg() -> [VNode] {
        [
            nShape(p("M24 4 C33 4 38 19 38 28 C38 37 32 44 24 44 C16 44 10 37 10 28 C10 19 15 4 24 4 Z"), k("#fbf1dc", O, 3.5, .round, .round)),
            nShape(circ(20, 17, 3.2), k("#a9cf8b")),
            nShape(circ(29, 24, 4.2), k("#a9cf8b")),
            nShape(circ(19, 32, 3.6), k("#a9cf8b")),
            nShape(circ(29, 37, 2.6), k("#a9cf8b")),
            nShape(p("M15 30 C14 22 16 14 20 9"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
        ]
    }

    private static func pause() -> [VNode] {
        [
            nShape(rect(11, 9, 9, 30, 3.5), k(C.teal, O, 3.5, .round, .round)),
            nShape(rect(28, 9, 9, 30, 3.5), k(C.teal, O, 3.5, .round, .round)),
        ]
    }

    private static func play() -> [VNode] {
        [
            nShape(p("M15 9.5 C15 7.5 17 6.5 18.7 7.5 L39 21.5 C40.6 22.6 40.6 25.4 39 26.5 L18.7 40.5 C17 41.5 15 40.5 15 38.5 Z"), k(C.leaf, O, 3.5, .round, .round)),
        ]
    }

    private static func stop() -> [VNode] {
        [
            nShape(rect(10, 10, 28, 28, 6), k(C.berry, O, 3.5, .round, .round)),
        ]
    }

    private static func hatch() -> [VNode] {
        [
            nShape(p("M24 8 C22.5 5 25 3.5 27 5"), k(nil, O, 3, .round, .round)),
            nShape(circ(24, 20, 11.5), k(C.yellow, O, 3.5, .round, .round)),
            nShape(circ(20, 18, 1.9), k(O)),
            nShape(circ(28, 18, 1.9), k(O)),
            nShape(p("M21.4 21.5 L26.6 21.5 L24 24.6 Z"), k(C.orange, O, 2.2, .butt, .round)),
            nShape(p("M9 29 L14 24 L19 30 L24 25 L29 30 L34 24 L39 29 C39 39 33 45 24 45 C15 45 9 39 9 29 Z"), k("#fbf1dc", O, 3.5, .round, .round)),
        ]
    }

    private static func again() -> [VNode] {
        [
            nShape(p("M10.8 19.2 A14 14 0 0 1 37.2 19.2"), k(nil, O, 10, .round, .miter)),
            nShape(p("M10.8 19.2 A14 14 0 0 1 37.2 19.2"), k(nil, C.leafDk, 3.6, .round, .miter)),
            nShape(p("M44.2 16.6 L39.6 25.8 L30.2 21.8 Z"), k(C.leafDk, O, 3.5, .round, .round)),
            nShape(p("M37.2 28.8 A14 14 0 0 1 10.8 28.8"), k(nil, O, 10, .round, .miter)),
            nShape(p("M37.2 28.8 A14 14 0 0 1 10.8 28.8"), k(nil, C.teal, 3.6, .round, .miter)),
            nShape(p("M3.8 31.4 L8.4 22.2 L17.8 26.2 Z"), k(C.teal, O, 3.5, .round, .round)),
        ]
    }

    private static func reset() -> [VNode] {
        [
            nShape(p("M34.3 16.3 A13.5 13.5 0 1 1 15.3 14.7"), k(nil, O, 10, .round, .miter)),
            nShape(p("M34.3 16.3 A13.5 13.5 0 1 1 15.3 14.7"), k(nil, C.teal, 3.6, .round, .miter)),
            nShape(p("M10.5 9 L20.7 10.2 L20.1 20.4 Z"), k(C.teal, O, 3.5, .round, .round)),
        ]
    }

    private static func close() -> [VNode] {
        [
            nShape(p("M14 14 L34 34 M34 14 L14 34"), k(nil, O, 6, .round, .miter)),
        ]
    }

    private static func minus() -> [VNode] {
        [
            nShape(p("M11 24 H37"), k(nil, O, 6, .round, .miter)),
        ]
    }

    private static func plus() -> [VNode] {
        [
            nShape(p("M24 11 V37 M11 24 H37"), k(nil, O, 6, .round, .miter)),
        ]
    }

    private static func dice() -> [VNode] {
        [
            nGroup([
                nShape(rect(8, 8, 32, 32, 8), k(C.cream, O, 3.5, .round, .round)),
                nShape(circ(16, 16, 3.2), k(C.berry)),
                nShape(circ(32, 16, 3.2), k(C.berry)),
                nShape(circ(24, 24, 3.2), k(C.berry)),
                nShape(circ(16, 32, 3.2), k(C.berry)),
                nShape(circ(32, 32, 3.2), k(C.berry)),
            ], rotAbout(-10, 24, 24)),
        ]
    }

    private static func bird() -> [VNode] {
        [
            nShape(p("M13 27 L4 21 L6 33 Z"), k(C.tealDk, O, 3.5, .round, .round)),
            nShape(circ(22, 26, 13), k(C.teal, O, 3.5, .round, .round)),
            nShape(p("M14 26 C17 33 25 33 28 27"), k(nil, O, 3, .round, .miter)),
            nShape(circ(27, 21, 2.1), k(O)),
            nShape(p("M34 20 L42 23 L34 26.5 Z"), k(C.gold, O, 3.5, .round, .round)),
            nShape(p("M19 39 V44 M25 39 V44"), k(nil, O, 3, .round, .round)),
        ]
    }

    private static func chick() -> [VNode] {
        [
            nShape(p("M24 10 C22.5 6.5 25 5 27 6.5"), k(nil, O, 3, .round, .round)),
            nShape(circ(24, 27, 15), k(C.yellow, O, 3.5, .round, .round)),
            nShape(circ(20, 23, 1.9), k(O)),
            nShape(circ(28, 23, 1.9), k(O)),
            nShape(p("M21.4 26.5 L26.6 26.5 L24 29.6 Z"), k(C.orange, O, 2.2, .butt, .round)),
            nShape(p("M10.5 30 C13 35 17 35 18 32"), k(nil, O, 3, .round, .miter)),
            nShape(p("M37.5 30 C35 35 31 35 30 32"), k(nil, O, 3, .round, .miter)),
            nShape(circ(16, 29, 2.4), k(C.pink)),
            nShape(circ(32, 29, 2.4), k(C.pink)),
        ]
    }

    private static func rain() -> [VNode] {
        [
            nShape(p("M13 30 C6.5 30 5.5 21 12 19.5 C12 11.5 22 8.5 26 14.5 C30 10.5 38.5 13 37.5 20 C43.5 21 42.5 30 36 30 Z"), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M15 35 C17.6 38.4 18 41.4 15 41.8 C12 41.4 12.4 38.4 15 35 Z"), k(C.sky, O, 2.6, .butt, .round)),
            nShape(p("M24 38 C26.6 41.4 27 44.4 24 44.8 C21 44.4 21.4 41.4 24 38 Z"), k(C.sky, O, 2.6, .butt, .round)),
            nShape(p("M33 35 C35.6 38.4 36 41.4 33 41.8 C30 41.4 30.4 38.4 33 35 Z"), k(C.sky, O, 2.6, .butt, .round)),
        ]
    }

    private static func clock() -> [VNode] {
        [
            nShape(p("M15 41 L12.5 45 M33 41 L35.5 45"), k(nil, O, 3.5, .round, .round)),
            nShape(circ(24, 25, 17), k(C.gold, O, 3.5, .round, .round)),
            nShape(circ(24, 25, 12), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M24 25 V17.5 M24 25 L29 28"), k(nil, O, 3.5, .round, .round)),
            nShape(circ(24, 25, 2), k(O)),
            nShape(circ(24, 5.5, 3), k(C.gold, O, 3.5, .round, .round)),
        ]
    }

    private static func quiet() -> [VNode] {
        [
            nShape(p("M7 19 H15 L25 10.5 V37.5 L15 29 H7 Z"), k(C.stone, O, 3.5, .round, .round)),
            nShape(p("M31 19 L41 29 M41 19 L31 29"), k(nil, O, 4.5, .round, .miter)),
        ]
    }

    private static func tada() -> [VNode] {
        [
            nShape(p("M6 43 L15 17 L32 34 Z"), k(C.gold, O, 3.5, .round, .round)),
            nShape(p("M10.5 31 L20 38.5 M13 24 L26 34.5"), k(nil, C.berry, 3.4, .round, .miter)),
            nShape(p("M6 43 L15 17 L32 34 Z"), k(nil, O, 3.5, .round, .round)),
            nShape(p("M32 5 L33.7 9.3 L38 11 L33.7 12.7 L32 17 L30.3 12.7 L26 11 L30.3 9.3 Z"), k(C.yellow, O, 2.4, .butt, .round)),
            nShape(circ(41, 22, 3), k(C.pink, O, 2.4)),
            nShape(circ(22, 7, 2.6), k(C.sky, O, 2.4)),
            nShape(p("M37 33 C40 31 41 35 44 33"), k(nil, O, 2.6, .round, .miter)),
        ]
    }

    private static func drum() -> [VNode] {
        [
            nShape(p("M5 9 L19 19 M43 9 L29 19"), k(nil, O, 3.5, .round, .miter)),
            nShape(circ(5, 9, 3), k(C.cream, O, 3.5, .round, .round)),
            nShape(circ(43, 9, 3), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M8 22 V37 C8 41 15 44 24 44 C33 44 40 41 40 37 V22 Z"), k(C.berry, O, 3.5, .round, .round)),
            nShape(p("M8 25 L16 38 L24 25 L32 38 L40 25"), k(nil, C.yellow, 3, .butt, .round)),
            nShape(p("M8 36 C8 40 15 43 24 43 C33 43 40 40 40 36"), k(nil, O, 3.5, .round, .round)),
            nShape(ell(24, 22, 16, 5.5), k(C.cream, O, 3.5, .round, .round)),
        ]
    }

    private static func mic() -> [VNode] {
        [
            nShape(p("M19 28 L21 42 C21.3 45 26.7 45 27 42 L29 28 Z"), k(C.berry, O, 3.5, .round, .round)),
            nShape(p("M22 4 C30 4 34 12 34 19 C34 25 29 30 22 30 C15 30 10 25 10 19 C10 12 14 4 22 4 Z"), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M11 18 L15 14.5 L18.5 18.5 L22 14.5 L25.5 18.5 L29 14.5 L33 18"), k(nil, O, 2.6, .round, .round)),
            nShape(p("M15 9 C16 7.5 17.5 6.5 19 6"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
            nShape(p("M42 7 V20"), k(nil, O, 3, .round, .round)),
            nShape(p("M42 7 L46 9"), k(nil, O, 3, .round, .round)),
            nShape(ell(39.5, 20.5, 3.4, 2.6), k(O)),
        ]
    }

    private static func maracas() -> [VNode] {
        [
            nShape(p("M17 25 L9 44 M31 25 L39 44"), k(nil, O, 7, .round, .miter)),
            nShape(p("M17 25 L9 44 M31 25 L39 44"), k(nil, C.wood, 3, .round, .miter)),
            nShape(ell(19, 15, 9, 11), k(C.orange, O, 3.5, .round, .round)).moved(rotAbout(22, 19, 15)),
            nShape(ell(30, 15, 9, 11), k(C.leaf, O, 3.5, .round, .round)).moved(rotAbout(-22, 30, 15)),
            nShape(p("M25 11 L35 15 M24 17 L33 21"), k(nil, C.yellow, 2.8, .round, .miter)),
            nShape(p("M3 9 C4.5 7 6 7 7 9 M41 4 C42.5 2 44 2 45 4"), k(nil, O, 2.6, .round, .miter)),
        ]
    }

    private static func barn() -> [VNode] {
        [
            nShape(p("M5 43 V21 L14 9 H34 L43 21 V43 Z"), k(C.berry, O, 3.5, .round, .round)),
            nShape(p("M3 22 L14 8 H34 L45 22"), k(nil, O, 3.5, .round, .round)),
            nShape(p("M15 43 V28 H33 V43 Z"), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M15 28 L33 43 M33 28 L15 43"), k(nil, O, 3, .round, .miter)),
            nShape(rect(20, 13, 8, 8, 1.5), k(C.yellow, O, 3.5, .round, .round)),
        ]
    }

    private static func bell() -> [VNode] {
        [
            nShape(circ(24, 39, 4), k(C.gold, O, 3.5, .round, .round)),
            nShape(circ(24, 6.5, 2.8), k(C.gold, O, 3.5, .round, .round)),
            nShape(p("M24 8.5 C15 8.5 12.5 16 12.5 23 V30 L8 36 H40 L35.5 30 V23 C35.5 16 33 8.5 24 8.5 Z"), k(C.yellow, O, 3.5, .round, .round)),
            nShape(p("M17.5 28 V22 C17.5 18 19 15.5 21 14.5"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
        ]
    }

    private static func bubbles() -> [VNode] {
        [
            nShape(circ(19, 27, 13), k(C.sky, O, 3.5, .round, .round, fo: 0.85)),
            nShape(p("M11.8 26.4 A7.5 7.5 0 0 1 18.4 19.9"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
            nShape(circ(36, 14, 7.5), k(C.sky, O, 3.5, .round, .round, fo: 0.85)),
            nShape(p("M31.9 13.6 A4.3 4.3 0 0 1 35.6 9.9"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
            nShape(circ(37, 36, 5), k(C.sky, O, 3.5, .round, .round, fo: 0.85)),
            nShape(p("M34.3 35.8 A2.9 2.9 0 0 1 36.8 33.3"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
        ]
    }

    private static func roll() -> [VNode] {
        [
            nShape(p("M3 20 H11 M1 28 H9 M4 36 H11"), k(nil, O, 3.4, .round, .miter)),
            nGroup([
                nShape(p("M27 6 C35 6 40 20 40 27 C40 36 34 42 27 42 C20 42 14 36 14 27 C14 20 19 6 27 6 Z"), k("#fbf1dc", O, 3.5, .round, .round)),
                nShape(p("M14.5 27 L19 23 L23 28 L27 23.5 L31 28 L35 23 L39.5 27"), k(nil, O, 3, .round, .round)),
            ], rotAbout(32, 27, 26)),
        ]
    }

    private static func boom() -> [VNode] {
        [
            nShape(p("M24 3 L27.8 13.7 L37.5 7.9 L33.5 18.5 L44.7 20.4 L34.8 25.9 L42.2 34.5 L31.1 32.4 L31.2 43.7 L24 35 L16.8 43.7 L16.9 32.4 L5.8 34.5 L13.2 25.9 L3.3 20.4 L14.5 18.5 L10.5 7.9 L20.2 13.7 Z"), k(C.orange, O, 3.5, .round, .round)),
            nShape(p("M27.9 13.2 L28.3 19.8 L34.9 20.3 L30 24.7 L33.7 30.2 L27.1 29.1 L25.1 35.4 L21.9 29.6 L15.8 32 L18.3 25.9 L12.6 22.6 L19 20.7 L18 14.2 L23.4 18 Z"), k(C.yellow, O, 3.5, .round, .round)),
        ]
    }

    private static func bricks() -> [VNode] {
        [
            nShape(rect(5, 9, 17, 10, 2), k(C.clay, O, 3.5, .round, .round)),
            nShape(rect(22, 9, 17, 10, 2), k(C.clay, O, 3.5, .round, .round)),
            nShape(rect(13, 19, 17, 10, 2), k(C.clay, O, 3.5, .round, .round)),
            nShape(rect(30, 19, 13, 10, 2), k(C.clay, O, 3.5, .round, .round)),
            nShape(rect(5, 19, 8, 10, 2), k(C.clay, O, 3.5, .round, .round)),
            nShape(rect(5, 29, 17, 10, 2), k(C.clay, O, 3.5, .round, .round)),
            nShape(rect(22, 29, 17, 10, 2), k(C.clay, O, 3.5, .round, .round)),
            nShape(p("M40 36 L45 41 L40 44 Z M36 42 L39 46 L34 46 Z"), k(C.clay, O, 2.6, .butt, .round)),
        ]
    }

    private static func paw() -> [VNode] {
        [
            nShape(p("M24 24 C31 24 37 31 37 36 C37 41 33 43 29 42 C26.5 41.5 25.5 40.5 24 40.5 C22.5 40.5 21.5 41.5 19 42 C15 43 11 41 11 36 C11 31 17 24 24 24 Z"), k(C.wood, O, 3.5, .round, .round)),
            nShape(ell(11, 20, 4.6, 6), k(C.wood, O, 3.5, .round, .round)).moved(rotAbout(-20, 11, 20)),
            nShape(ell(19, 12, 4.6, 6), k(C.wood, O, 3.5, .round, .round)).moved(rotAbout(-6, 19, 12)),
            nShape(ell(29, 12, 4.6, 6), k(C.wood, O, 3.5, .round, .round)).moved(rotAbout(6, 29, 12)),
            nShape(ell(37, 20, 4.6, 6), k(C.wood, O, 3.5, .round, .round)).moved(rotAbout(20, 37, 20)),
        ]
    }

    private static func camera() -> [VNode] {
        [
            nShape(p("M17 13 L19.5 8 H28.5 L31 13"), k(C.stone, O, 3.5, .round, .round)),
            nShape(rect(5, 13, 38, 27, 6), k(C.teal, O, 3.5, .round, .round)),
            nShape(circ(24, 26.5, 9), k(C.cream, O, 3.5, .round, .round)),
            nShape(circ(24, 26.5, 4), k(O)),
            nShape(circ(22.4, 24.8, 1.4), k("#ffffff")),
            nShape(rect(34, 17, 5, 3.4, 1.4), k(C.yellow, O, 2.2)),
        ]
    }

    private static func gift() -> [VNode] {
        [
            nShape(p("M24 14 C20 6 12 6 13 11 C14 15 20 14 24 14 C28 14 34 15 35 11 C36 6 28 6 24 14 Z"), k(C.gold, O, 3.5, .round, .round)),
            nShape(rect(9, 21, 30, 22, 3), k(C.berry, O, 3.5, .round, .round)),
            nShape(rect(6, 14, 36, 8, 3), k(C.berry, O, 3.5, .round, .round)),
            nShape(p("M24 14 V43"), k(nil, O, 9.5)),
            nShape(p("M24 15.6 V41.3"), k(nil, C.gold, 3)),
        ]
    }

    private static func broom() -> [VNode] {
        [
            nShape(p("M38 5 L25 25"), k(nil, O, 7.5, .round, .miter)),
            nShape(p("M38 5 L25 25"), k(nil, C.wood, 2.6, .round, .miter)),
            nShape(p("M20 21 L31 28 L24 44 C18 44 9 39 6 34 Z"), k(C.gold, O, 3.5, .round, .round)),
            nShape(p("M12 33 C15 36 18 38 21 39 M17 27 C14 31 12 33 9 35"), k(nil, O, 2.4, .round, .miter, so: 0.45)),
            nShape(p("M19.5 21 L31.5 28.5"), k(nil, O, 6, .round, .miter)),
            nShape(p("M19.5 21 L31.5 28.5"), k(nil, C.berry, 2, .round, .miter)),
        ]
    }

    private static func picture() -> [VNode] {
        [
            nShape(rect(5, 8, 38, 32, 4), k(C.gold, O, 3.5, .round, .round)),
            nShape(rect(10.5, 13.5, 27, 21, 1.5), k(C.sky, O, 3.5, .round, .round)),
            nShape(circ(31, 20, 3.4), k(C.yellow, O, 2.4)),
            nShape(p("M10.5 34.5 V30 C14 25 18 24 23 29 C27 26 32 26 37.5 31 V34.5 Z"), k(C.leaf, O, 3.5, .round, .round)),
        ]
    }

    private static func teddy() -> [VNode] {
        [
            nShape(ell(24, 37, 11.5, 8.5), k(C.wood, O, 3.5, .round, .round)),
            nShape(circ(14, 11, 5), k(C.wood, O, 3.5, .round, .round)),
            nShape(circ(34, 11, 5), k(C.wood, O, 3.5, .round, .round)),
            nShape(circ(24, 20, 11.5), k(C.wood, O, 3.5, .round, .round)),
            nShape(ell(24, 24.5, 5.5, 4.4), k(C.cream, O, 3.5, .round, .round)),
            nShape(circ(19.5, 17.5, 1.9), k(O)),
            nShape(circ(28.5, 17.5, 1.9), k(O)),
            nShape(ell(24, 23, 2, 1.5), k(O)),
            nShape(ell(24, 38, 5, 4), k(C.cream)),
        ]
    }

    private static func bath() -> [VNode] {
        [
            nShape(circ(15, 12, 4.5), k(C.sky, O, 2.6)),
            nShape(circ(24, 8, 3.2), k(C.sky, O, 2.6)),
            nShape(circ(31, 14, 5), k(C.sky, O, 2.6)),
            nShape(p("M12 39 L9.5 44 M36 39 L38.5 44"), k(nil, O, 3.5, .round, .round)),
            nShape(p("M4 22 H44 V26 C44 34 38 40 30 40 H18 C10 40 4 34 4 26 Z"), k("#ffffff", O, 3.5, .round, .round)),
            nShape(p("M7 27 H41"), k(nil, C.teal, 3.2, .round, .miter)),
        ]
    }

    private static func bowl() -> [VNode] {
        [
            nShape(p("M39 6 L28 21"), k(nil, O, 6.5, .round, .miter)),
            nShape(p("M39 6 L28 21"), k(nil, C.stone, 2, .round, .miter)),
            nShape(ell(24, 22, 18, 5), k(C.cream, O, 3.5, .round, .round)),
            nShape(circ(17, 21, 2), k(C.gold)),
            nShape(circ(24, 23, 2), k(C.clay)),
            nShape(circ(30, 20.5, 2), k(C.gold)),
            nShape(p("M6 23 C6 34 14 41 24 41 C34 41 42 34 42 23 C38 26 31 27 24 27 C17 27 10 26 6 23 Z"), k(C.teal, O, 3.5, .round, .round)),
        ]
    }

    private static func sock() -> [VNode] {
        [
            nShape(p("M16 5 H31 V25 L38 30 C43 33.5 41.5 43 34 43 H24 C18 43 15.5 39 15.5 34 Z"), k(C.berry, O, 3.5, .round, .round)),
            nShape(rect(14.5, 4.5, 18, 8, 2.5), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M15.5 32 C20 31 23 34 22.5 43 M34 33 C38 34 40 36 40.5 39"), k(nil, C.cream, 3.5, .round, .miter)),
            nShape(p("M16 5 H31 V25 L38 30 C43 33.5 41.5 43 34 43 H24 C18 43 15.5 39 15.5 34 Z M15.5 12.5 V5"), k(nil, O, 3.5, .round, .round)),
        ]
    }

    private static func tooth() -> [VNode] {
        [
            nShape(p("M13.5 9 C17.5 5 21.5 8 24 9.5 C26.5 8 30.5 5 34.5 9 C40 14.5 36.5 24 34.5 30 C33 36 32.5 43 29 43 C25.5 43 26.5 32 24 32 C21.5 32 22.5 43 19 43 C15.5 43 15 36 13.5 30 C11.5 24 8 14.5 13.5 9 Z"), k("#ffffff", O, 3.5, .round, .round)),
            nShape(p("M15 14 C16 11.5 18 11 20 12"), k(nil, O, 2.6, .round, .round, so: 0.3)),
            nShape(p("M39 3.4 L40.1 6.9 L43.6 8 L40.1 9.1 L39 12.6 L37.9 9.1 L34.4 8 L37.9 6.9 Z"), k(C.yellow, O, 2, .butt, .round)),
        ]
    }

    private static func books() -> [VNode] {
        [
            nShape(rect(6, 33, 36, 9, 2.5), k(C.teal, O, 3.5, .round, .round)),
            nShape(rect(9, 24, 31, 9, 2.5), k(C.berry, O, 3.5, .round, .round)),
            nShape(rect(7, 15, 33, 9, 2.5), k(C.gold, O, 3.5, .round, .round)),
            nShape(p("M36 33 V42 M13 24 V33 M35 15 V24"), k(nil, C.cream, 2.6)),
            nShape(p("M16 6 L26 4 L28 15 L18 15 Z"), k(C.leaf, O, 3.5, .round, .round)),
        ]
    }

    private static func bed() -> [VNode] {
        [
            nShape(p("M7 33 V43 M41 33 V43"), k(nil, O, 4, .round, .round)),
            nShape(rect(4, 10, 7, 26, 3), k(C.wood, O, 3.5, .round, .round)),
            nShape(rect(9, 28, 35, 9, 3), k(C.cream, O, 3.5, .round, .round)),
            nShape(ell(17.5, 24, 6.5, 4.5), k("#ffffff", O, 3.5, .round, .round)),
            nShape(p("M22 21 C30 19 38 20 44 23 V33 H22 Z"), k(C.teal, O, 3.5, .round, .round)),
            nShape(p("M27 25 C32 24 37 24 41 26"), k(nil, C.cream, 2.6, .round, .miter)),
        ]
    }

    private static func car() -> [VNode] {
        [
            nShape(p("M14 21 L18 12 H31 L36 21"), k(C.sky, O, 3.5, .round, .round)),
            nShape(p("M24.5 12 V21"), k(nil, O, 3, .round, .round)),
            nShape(p("M5 30 C5 24 8 21 13 21 H37 C42 21 44 25 44 30 V34 H5 Z"), k(C.berry, O, 3.5, .round, .round)),
            nShape(circ(14, 35, 5.5), k(C.grey, O, 3.5, .round, .round)),
            nShape(circ(35, 35, 5.5), k(C.grey, O, 3.5, .round, .round)),
            nShape(circ(14, 35, 1.8), k(C.cream)),
            nShape(circ(35, 35, 1.8), k(C.cream)),
            nShape(rect(39, 24.5, 4, 3, 1), k(C.yellow)),
        ]
    }

    private static func puzzle() -> [VNode] {
        [
            nShape(p("M8 14 H18 C16 6 30 6 28 14 H38 V23 C45 21 45 35 38 33 V42 H28 C30 35 16 35 18 42 H8 Z"), k(C.leaf, O, 3.5, .round, .round)),
            nShape(p("M12 19 C12 17 13 17.5 15 17.5"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
        ]
    }

    private static func paint() -> [VNode] {
        [
            nShape(p("M24 6 C36 6 44 13 44 22 C44 29 38 30 34 29 C30 28 28 31 30 35 C32 39 29 43 23 42 C12 41 4 34 4 24 C4 13 12 6 24 6 Z"), k(C.cream, O, 3.5, .round, .round)),
            nShape(circ(14, 22, 3.4), k(C.berry, O, 2.2)),
            nShape(circ(19, 13.5, 3.4), k(C.yellow, O, 2.2)),
            nShape(circ(29, 12.5, 3.4), k(C.teal, O, 2.2)),
            nShape(circ(37, 19, 3.4), k(C.leaf, O, 2.2)),
            nShape(circ(16.5, 32, 3.6), k("#e9e4dc", O, 2.6)),
        ]
    }

    private static func apple() -> [VNode] {
        [
            nShape(p("M24 14 C24 10 25 7 27 5"), k(nil, O, 3.5, .round, .round)),
            nShape(p("M26 11 C29 5 36 5 38 8 C34 12 29 12 26 11 Z"), k(C.leaf, O, 3.5, .round, .round)),
            nShape(p("M24 15 C19 11 8 12 8 24 C8 34 15 43 21 43 C23 43 23 42 24 42 C25 42 25 43 27 43 C33 43 40 34 40 24 C40 12 29 11 24 15 Z"), k(C.berry, O, 3.5, .round, .round)),
            nShape(p("M13 22 C13 19 15 17 17.5 16.5"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
        ]
    }

    private static func coat() -> [VNode] {
        [
            nShape(p("M17 6 L24 11 L31 6 L39 10 L45 29 L39.5 31 L36 23 V43 H12 V23 L8.5 31 L3 29 L9 10 Z"), k(C.teal, O, 3.5, .round, .round)),
            nShape(p("M24 11 V43"), k(nil, O, 3, .round, .round)),
            nShape(p("M17 6 L24 11 L20 17 L15 9 M31 6 L24 11 L28 17 L33 9"), k(C.tealDk, O, 3.5, .round, .round)),
            nShape(circ(20.5, 25, 1.8), k(C.cream, O, 1.8)),
            nShape(circ(20.5, 33, 1.8), k(C.cream, O, 1.8)),
            nShape(p("M28 30 H33"), k(nil, O, 3, .round, .round)),
        ]
    }

    private static func crayon() -> [VNode] {
        [
            nGroup([
                nShape(p("M4 18 H34 L44 24 L34 30 H4 C2.5 30 2 29 2 28 V20 C2 19 2.5 18 4 18 Z"), k(C.berry, O, 3.5, .round, .round)),
                nShape(p("M10 18 V30 M26 18 V30"), k(nil, C.cream, 3)),
                nShape(p("M40 21.5 L44 24 L40 26.5 Z"), k(O)),
                nShape(p("M4 18 H34 L44 24 L34 30 H4 C2.5 30 2 29 2 28 V20 C2 19 2.5 18 4 18 Z M34 18 V30"), k(nil, O, 3.5, .round, .round)),
            ], rotAbout(-45, 24, 24)),
        ]
    }

    private static func toilet() -> [VNode] {
        [
            nShape(rect(9, 4, 18, 16, 3), k("#ffffff", O, 3.5, .round, .round)),
            nShape(p("M17 43 L19 33 H29 L31 43 Z"), k("#ffffff", O, 3.5, .round, .round)),
            nShape(p("M6 21 H42 C42 30 35 35 24 35 C13 35 6 30 6 21 Z"), k("#ffffff", O, 3.5, .round, .round)),
            nShape(ell(24, 21, 18, 3.6), k(C.sky, O, 3.5, .round, .round)),
            nShape(p("M13 9 H17"), k(nil, O, 3, .round, .round)),
        ]
    }

    private static func shoe() -> [VNode] {
        [
            nShape(p("M2 23 H8 M1 30 H6"), k(nil, O, 3.2, .round, .miter)),
            nShape(p("M10 37 C10 27 12 17 18 15 C21 18 25 18 27 16 L32 26 C38 27 45 29 45 34 V37 Z"), k(C.teal, O, 3.5, .round, .round)),
            nShape(p("M9 37 H46 V40 C46 42 45 43 43 43 H12 C10 43 9 42 9 40 Z"), k(C.cream, O, 3.5, .round, .round)),
            nShape(p("M22 21 L26 19.5 M24 25 L28.5 23"), k(nil, C.cream, 2.6, .round, .miter)),
        ]
    }

    private static func star() -> [VNode] {
        [
            nShape(p("M24 5.5 L29.6 17.8 L43 19.3 L33 28.4 L35.8 41.7 L24 35 L12.2 41.7 L15 28.4 L5 19.3 L18.4 17.8 Z"), k(C.yellow, O, 3.5, .round, .round)),
            nShape(p("M16 22 L19.5 20"), k(nil, "#ffffff", 3, .round, .miter, so: 0.65)),
        ]
    }
}

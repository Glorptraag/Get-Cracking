import SwiftUI

/// Everything the painter needs to draw one friend.
///
/// Most friends are a chunky "one-blob" chibi like the Get Cracking animals:
/// head and body in one bean shape, with ears, a face, headwear and extras
/// layered on. The baking friends are cookie shapes instead (`kind`).
struct Look {
    enum Kind { case blob, gingerbread, tree, star, pudding }

    enum Size {
        case round, tall, wide, small, baby

        /// Half-width and height of the bean body, in friend units
        /// (feet at y = 0, the friend grows up to about y = -200).
        var dims: (w: CGFloat, h: CGFloat) {
            switch self {
            case .round: return (64, 128)
            case .tall: return (58, 140)
            case .wide: return (74, 118)
            case .small: return (58, 116)
            case .baby: return (50, 96)
            }
        }
    }

    enum Ears { case none, round, fluffy, long, pointy, mouse, tiny, lamb }

    enum Snout {
        case none
        case nose(Color)
        case muzzle(Color)
        case beak(Color)
        case bill(Color)
        case bigNose(Color)
        case longSnout(Color)
    }

    enum Headwear {
        case none
        case halo
        case crown(Color)
        case tiara(Color)
        case shako
        case bow(Color)
        case wool
        case band(Color)
        case turban(Color)
    }

    enum Extra {
        case wings(Color)
        case cape(Color)
        case tailThin(Color)
        case tailWide(Color)
        case spines(Color)
        case staff
        case wand
        case gift(Color, Color)
        case jar(Color)
        case beard(Color)
        case belt(Color)
        case sash(Color)
        case buttons(Color)
        case bell(Color)
        case pouch
        case fringe(Color)
        case whiskers
        case eyeStripe(Color)
        case webbedFeet(Color)
        case sparkles(Color)
        case snowflake
        case swaddle
        case manger
        case holdNutcracker
    }

    var kind: Kind = .blob
    var body: Color
    var belly: Color? = nil
    /// A face patch in this colour makes the friend a person.
    var skin: Color? = nil
    /// Hair or a veil: fills the top of the head around the face.
    var cap: Color? = nil
    /// How far down the body the cap reaches (fraction of height from the top).
    var capDepth: CGFloat = 0.5
    var ears: Ears = .none
    var snout: Snout = .none
    var head: Headwear = .none
    var extras: [Extra] = []
    var earColor: Color? = nil
    var size: Size = .round

    init(kind: Kind = .blob, body: Color, belly: Color? = nil, skin: Color? = nil, cap: Color? = nil,
         capDepth: CGFloat = 0.5, ears: Ears = .none, snout: Snout = .none, head: Headwear = .none,
         extras: [Extra] = [], earColor: Color? = nil, size: Size = .round) {
        self.kind = kind
        self.body = body
        self.belly = belly
        self.skin = skin
        self.cap = cap
        self.capDepth = capDepth
        self.ears = ears
        self.snout = snout
        self.head = head
        self.extras = extras
        self.earColor = earColor
        self.size = size
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 8) & 0xff) / 255
        let b = Double(hex & 0xff) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }

    /// The chunky dark outline every drawing shares (same as Get Cracking).
    static let ink = Color(hex: 0x3b2224)
    static let cream = Color(hex: 0xfdf3e4)
    static let paper = Color(hex: 0xefe7da)
    static let goldLeaf = Color(hex: 0xf0b63c)
    static let blush = Color(hex: 0xf4a3a0)
}

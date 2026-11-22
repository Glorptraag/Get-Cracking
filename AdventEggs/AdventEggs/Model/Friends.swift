import SwiftUI

/// The four collections the 25 friends are drawn from.
enum Theme: String, CaseIterable, Identifiable {
    case nativity, nutcracker, aussie, baking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nativity: return "The Nativity"
        case .nutcracker: return "The Nutcracker"
        case .aussie: return "Aussie Babies"
        case .baking: return "Christmas Baking"
        }
    }

    var tint: Color {
        switch self {
        case .nativity: return Color(hex: 0x4f6fa8)
        case .nutcracker: return Color(hex: 0xb8434a)
        case .aussie: return Color(hex: 0xc98a3c)
        case .baking: return Color(hex: 0x5f9a5a)
        }
    }
}

/// One day's friend: who hatches from the egg behind door `day`.
struct Friend: Identifiable {
    let day: Int
    let name: String
    /// What the voice says when the friend hatches, e.g. "It's Mary!"
    let spoken: String
    let theme: Theme
    let look: Look

    var id: Int { day }
}

extension Friend {
    static func forDay(_ day: Int) -> Friend {
        all.first { $0.day == day } ?? all[0]
    }

    // Skin tones used across the human friends.
    private static let skinLight = Color(hex: 0xf6d2b4)
    private static let skinWarm = Color(hex: 0xe5b48c)
    private static let skinTan = Color(hex: 0xc68a5e)
    private static let skinDeep = Color(hex: 0x8d5a3b)
    private static let gold = Color(hex: 0xf0b63c)

    /// Day 1 to 25. The themes take turns so every week has a bit of each,
    /// and the Nativity builds towards Christmas Day.
    static let all: [Friend] = [
        Friend(day: 1, name: "Gingerbread Pal", spoken: "It's a Gingerbread Pal!", theme: .baking,
               look: Look(kind: .gingerbread, body: Color(hex: 0xc98447))),

        Friend(day: 2, name: "Joey", spoken: "It's a baby kangaroo, a joey!", theme: .aussie,
               look: Look(body: Color(hex: 0xc98e5c), belly: Color(hex: 0xf3dcc0), ears: .pointy,
                          snout: .muzzle(Color(hex: 0xf3dcc0)), extras: [.tailWide(Color(hex: 0xc98e5c)), .pouch],
                          size: .tall)),

        Friend(day: 3, name: "Nutcracker", spoken: "It's the Nutcracker!", theme: .nutcracker,
               look: Look(body: Color(hex: 0xc23b3f), skin: skinLight, cap: Color(hex: 0xf5f0e6), capDepth: 0.62,
                          head: .shako, extras: [.beard(Color(hex: 0xf5f0e6)), .belt(Color(hex: 0x2d2a3a)), .buttons(gold)],
                          size: .tall)),

        Friend(day: 4, name: "Donkey", spoken: "It's the Donkey!", theme: .nativity,
               look: Look(body: Color(hex: 0x9a9aa4), belly: Color(hex: 0xd9d8de), ears: .long,
                          snout: .muzzle(Color(hex: 0xd9d8de)), extras: [.tailThin(Color(hex: 0x6d6d78)), .fringe(Color(hex: 0x5b5b66))])),

        Friend(day: 5, name: "Christmas Tree Cookie", spoken: "It's a Christmas Tree Cookie!", theme: .baking,
               look: Look(kind: .tree, body: Color(hex: 0x4f9a5c))),

        Friend(day: 6, name: "Koala", spoken: "It's a baby koala!", theme: .aussie,
               look: Look(body: Color(hex: 0x9ea6ae), belly: Color(hex: 0xe6e8ea), ears: .fluffy,
                          snout: .bigNose(Color(hex: 0x3d3a45)), size: .wide)),

        Friend(day: 7, name: "Clara", spoken: "It's Clara!", theme: .nutcracker,
               look: Look(body: Color(hex: 0xf2a0b8), skin: skinWarm, cap: Color(hex: 0x7a4a2a), capDepth: 0.5,
                          head: .bow(Color(hex: 0xd63b4f)), extras: [.sash(Color(hex: 0xfdf3e4)), .holdNutcracker])),

        Friend(day: 8, name: "Lamb", spoken: "It's a little Lamb!", theme: .nativity,
               look: Look(body: Color(hex: 0xfbf6ee), ears: .lamb, snout: .muzzle(Color(hex: 0xf3dfd2)),
                          head: .wool, extras: [.bell(gold)], earColor: Color(hex: 0x8a7468), size: .small)),

        Friend(day: 9, name: "Shortbread Star", spoken: "It's a Shortbread Star!", theme: .baking,
               look: Look(kind: .star, body: Color(hex: 0xebbd62))),

        Friend(day: 10, name: "Wombat", spoken: "It's a baby wombat!", theme: .aussie,
               look: Look(body: Color(hex: 0x8c6a52), belly: Color(hex: 0xb79579), ears: .tiny,
                          snout: .bigNose(Color(hex: 0x3a2a26)), size: .wide)),

        Friend(day: 11, name: "Sugar Plum Fairy", spoken: "It's the Sugar Plum Fairy!", theme: .nutcracker,
               look: Look(body: Color(hex: 0xb98ad6), skin: skinTan, cap: Color(hex: 0x2f2230), capDepth: 0.5,
                          head: .tiara(gold), extras: [.wings(Color(hex: 0xf6c6e6)), .wand, .sparkles(Color(hex: 0xffe27a))])),

        Friend(day: 12, name: "Shepherd", spoken: "It's the Shepherd!", theme: .nativity,
               look: Look(body: Color(hex: 0xa9905e), skin: skinTan, cap: Color(hex: 0xefe4cc), capDepth: 0.36,
                          head: .band(Color(hex: 0xb8434a)), extras: [.staff, .belt(Color(hex: 0x6b4a2e))])),

        Friend(day: 13, name: "Christmas Pudding", spoken: "It's a Christmas Pudding!", theme: .baking,
               look: Look(kind: .pudding, body: Color(hex: 0x7a4630))),

        Friend(day: 14, name: "Platypus", spoken: "It's a baby platypus!", theme: .aussie,
               look: Look(body: Color(hex: 0x8a6448), belly: Color(hex: 0xc9a684), snout: .bill(Color(hex: 0x3f3d48)),
                          extras: [.tailWide(Color(hex: 0x6e4e38)), .webbedFeet(Color(hex: 0x3f3d48))], size: .wide)),

        Friend(day: 15, name: "Mouse King", spoken: "It's the Mouse King!", theme: .nutcracker,
               look: Look(body: Color(hex: 0xa3a0aa), belly: Color(hex: 0xd8d4dc), ears: .mouse,
                          snout: .nose(Color(hex: 0xe58aa0)), head: .crown(gold),
                          extras: [.cape(Color(hex: 0x8c2f45)), .tailThin(Color(hex: 0xe8a3b4)), .whiskers])),

        Friend(day: 16, name: "Angel", spoken: "It's the Angel!", theme: .nativity,
               look: Look(body: Color(hex: 0xfdfaf2), skin: skinWarm, cap: Color(hex: 0xf2c75c), capDepth: 0.5,
                          head: .halo, extras: [.wings(Color(hex: 0xffffff)), .sparkles(Color(hex: 0xffe27a))])),

        Friend(day: 17, name: "Echidna Puggle", spoken: "It's a baby echidna, a puggle!", theme: .aussie,
               look: Look(body: Color(hex: 0x6f5444), belly: Color(hex: 0xb89a80), snout: .longSnout(Color(hex: 0x3a2e2a)),
                          extras: [.spines(Color(hex: 0xeadbbf))], size: .small)),

        Friend(day: 18, name: "Snowflake Fairy", spoken: "It's the Snowflake Fairy!", theme: .nutcracker,
               look: Look(body: Color(hex: 0xbfe1f4), skin: skinLight, cap: Color(hex: 0xf4f7fb), capDepth: 0.5,
                          head: .tiara(Color(hex: 0xdfe8f2)), extras: [.wings(Color(hex: 0xe6f4ff)), .snowflake, .sparkles(Color(hex: 0xffffff))])),

        Friend(day: 19, name: "Kookaburra", spoken: "It's a baby kookaburra!", theme: .aussie,
               look: Look(body: Color(hex: 0xf4ead8), belly: Color(hex: 0xfffaf0), snout: .beak(Color(hex: 0x3f3a40)),
                          extras: [.wings(Color(hex: 0x8a6446)), .eyeStripe(Color(hex: 0x7a5a40)), .tailThin(Color(hex: 0x8a6446))],
                          size: .round)),

        Friend(day: 20, name: "Melchior", spoken: "It's Melchior, a wise man, with gold!", theme: .nativity,
               look: Look(body: Color(hex: 0x7b4fa6), skin: skinLight, cap: Color(hex: 0xb9a0d6), capDepth: 0.36,
                          head: .crown(gold), extras: [.beard(Color(hex: 0xf2efe8)), .gift(gold, Color(hex: 0xc23b3f))])),

        Friend(day: 21, name: "Caspar", spoken: "It's Caspar, a wise man, with frankincense!", theme: .nativity,
               look: Look(body: Color(hex: 0x3f8a6a), skin: skinTan, cap: Color(hex: 0xe8c66a), capDepth: 0.36,
                          head: .crown(gold), extras: [.jar(Color(hex: 0xd8c9e8))])),

        Friend(day: 22, name: "Balthazar", spoken: "It's Balthazar, a wise man, with myrrh!", theme: .nativity,
               look: Look(body: Color(hex: 0xb8434a), skin: skinDeep, cap: Color(hex: 0xf3e2b8), capDepth: 0.36,
                          head: .turban(Color(hex: 0xf3e2b8)), extras: [.beard(Color(hex: 0x2f2626)), .jar(Color(hex: 0x6fb3c9))])),

        Friend(day: 23, name: "Joseph", spoken: "It's Joseph!", theme: .nativity,
               look: Look(body: Color(hex: 0x8a5a3c), skin: skinWarm, cap: Color(hex: 0xd9c49a), capDepth: 0.36,
                          head: .band(Color(hex: 0x6b4a2e)), extras: [.beard(Color(hex: 0x5a3a26)), .staff], size: .tall)),

        Friend(day: 24, name: "Mary", spoken: "It's Mary!", theme: .nativity,
               look: Look(body: Color(hex: 0xf5efe2), skin: skinWarm, cap: Color(hex: 0x4f7fc0), capDepth: 0.3,
                          head: .halo, extras: [.belt(Color(hex: 0x4f7fc0))])),

        Friend(day: 25, name: "Baby Jesus", spoken: "It's Baby Jesus! Merry Christmas!", theme: .nativity,
               look: Look(body: Color(hex: 0xfbf3e2), skin: skinWarm, cap: Color(hex: 0xfbf3e2), capDepth: 0.3,
                          head: .halo, extras: [.swaddle, .manger], size: .baby)),
    ]
}

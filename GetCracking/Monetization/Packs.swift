import Foundation

/// Content packs: the native twin of the web's js/packs.js.
///
/// The 40 friends and 10 worlds are the Classic pack. A new pack drops in by
/// adding its art (friends to `Animals.list`, worlds to `Scenes.list`, calls
/// and voices to the sound files) and one `Pack` entry below. Owning
/// The Whole Nest opens every pack in this list, now and later.
///
/// This file is plain Foundation on purpose: Tests/GateChecks compiles it on
/// its own to check the gate decisions.
struct Pack: Identifiable, Equatable {
    let id: String
    let name: String
    let blurb: String
    /// friend ids, in friend-book order
    let friends: [String]
    /// world ids
    let scenes: [String]
    /// a whole pack given away (e.g. a seasonal freebie); false = needs The Whole Nest
    var isFree = false
    /// what this pack gives away free even without The Whole Nest
    var starterFriends: Set<String> = []
    var starterScenes: Set<String> = []
}

enum Packs {
    /// The Classic pack. Ids must match `Animals.list` and `Scenes.list`
    /// (AppModel checks this in debug builds).
    static let classic = Pack(
        id: "classic",
        name: "Classic friends",
        blurb: "The first 40 friends and 10 worlds",
        friends: [
            "chick", "duckling", "penguin", "owl", "hamster", "bunny", "fox", "kitten", "bearcub", "panda",
            "frog", "turtle", "dino", "dragon", "mouse", "piglet", "koala", "raccoon", "tiger", "lion",
            "calf", "lamb", "fawn", "hedgehog", "otter", "seal", "axolotl", "bat", "mole", "monkey",
            "elephant", "squirrel", "puppy", "unicorn", "capybara", "redpanda", "sloth", "ladybug", "snail", "goat",
        ],
        scenes: ["forest", "pond", "mushroom", "snow", "meadow", "autumn", "desert", "beach", "night", "reef"],
        // the free starter set (the web marks these `starter: true`)
        starterFriends: ["chick", "duckling", "bunny", "kitten", "puppy", "piglet",
                         "fox", "owl", "frog", "penguin", "elephant", "dino"],
        starterScenes: ["meadow", "forest", "pond"]
    )

    /// Aussie Bush (web js/packs/aussie.js). Paid: opens with The Whole Nest.
    static let aussie = Pack(
        id: "aussie",
        name: "Aussie Bush",
        blurb: "Galahs, wombats, a joey and a mole cricket",
        friends: ["galah", "cockatoo", "kookaburra", "emu", "joey", "wombat",
                  "platypus", "echidna", "sugarglider", "frillneck", "bilby", "molecricket"],
        scenes: ["outback", "billabong"]
    )

    /// Christmas (web js/packs/christmas.js). Paid: opens with The Whole Nest.
    static let christmas = Pack(
        id: "christmas",
        name: "Christmas",
        blurb: "Gingerbread, the Nutcracker, a reindeer and a snowy village",
        friends: ["gingerbread", "treecookie", "shortbread", "pudding", "nutcracker", "sugarplum", "mouseking",
                  "snowfairy", "angel", "reindeer", "robin", "snowman", "xmasbeetle"],
        scenes: ["xmasvillage"]
    )

    /// Every pack in the app, in friend-book order. A new pack ported from
    /// the web goes here (and its art in Art/Packs/PackArt.swift).
    static let list: [Pack] = [classic, aussie, christmas]

    static func byId(_ id: String) -> Pack? { list.first { $0.id == id } }
    static func pack(ofFriend id: String) -> Pack? { list.first { $0.friends.contains(id) } }
    static func pack(ofScene id: String) -> Pack? { list.first { $0.scenes.contains(id) } }

    static var allFriends: [String] { list.flatMap(\.friends) }
    static var allScenes: [String] { list.flatMap(\.scenes) }

    static func isStarter(friend id: String) -> Bool {
        guard let p = pack(ofFriend: id) else { return false }
        return p.isFree || p.starterFriends.contains(id)
    }

    static func isStarter(scene id: String) -> Bool {
        guard let p = pack(ofScene: id) else { return false }
        return p.isFree || p.starterScenes.contains(id)
    }

    // MARK: songs and photos

    /// Hatching songs that stay free: the first animal band and the short jingles.
    /// Jungle jam, Farmyard hoedown and any later band need The Whole Nest.
    static let freeEndSounds: Set<String> = ["band", "tada", "chimes", "birds", "bubbles"]
    /// the band a locked song falls back to
    static let defaultEndSound = "band"

    /// photo friends a family can add without The Whole Nest
    static let freePhotoLimit = 1
}

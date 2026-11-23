import Foundation

/// Every "is this unlocked?" decision in one place. A plain value, so it can
/// be checked without StoreKit (Tests/GateChecks).
///
/// Bill of Rights (MONETIZATION.md): the timer and every timer setting,
/// countdown music, hatch styles, the starter friends and worlds, the short
/// jingles and the first animal band are free forever. Photos already added
/// stay and keep hatching; friends already in the friend book stay visible.
struct FeatureGate: Equatable {
    let ownsWholeNest: Bool

    // MARK: single items

    func friend(_ id: String) -> Bool { ownsWholeNest || Packs.isStarter(friend: id) }
    func scene(_ id: String) -> Bool { ownsWholeNest || Packs.isStarter(scene: id) }
    func endSound(_ id: String) -> Bool { ownsWholeNest || Packs.freeEndSounds.contains(id) }
    func pack(_ p: Pack) -> Bool { ownsWholeNest || p.isFree }

    /// Adding photo friends: the free tier keeps one. Counts the photos there
    /// now, so removing one frees the slot again.
    func canAddPhoto(liveCount: Int) -> Bool { ownsWholeNest || liveCount < Packs.freePhotoLimit }
    /// how many more photos may be added right now (nil = no limit)
    func photosLeft(liveCount: Int) -> Int? {
        ownsWholeNest ? nil : max(0, Packs.freePhotoLimit - liveCount)
    }

    // MARK: shuffle pools (only what is owned)

    var friendPool: [String] { Packs.allFriends.filter(friend) }
    var scenePool: [String] { Packs.allScenes.filter(scene) }

    // MARK: settings that point at something locked (after a refund or family-sharing change)

    /// "random" or an owned world; a locked world plays as "Surprise me".
    func effectiveScene(_ setting: String) -> String { setting == "random" || scene(setting) ? setting : "random" }
    func effectiveEndSound(_ setting: String) -> String { endSound(setting) ? setting : Packs.defaultEndSound }

    /// The friend book: found friends always show (downgrade rule);
    /// unfound friends show a lock when they are not owned.
    func bookShowsLock(friend id: String, timesFound: Int) -> Bool { timesFound == 0 && !friend(id) }
}

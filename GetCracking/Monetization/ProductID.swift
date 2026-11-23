import Foundation

/// The one thing for sale: The Whole Nest, a one-time unlock (Non-Consumable)
/// that opens every friend, world and song, unlimited photo friends, and
/// every content pack, including packs added later.
///
/// The id must match App Store Connect exactly (see APP_STORE.md).
enum ProductID {
    static let wholeNest = "com.glorptraag.getcracking.wholenest"

    /// everything that unlocks the full app
    static let unlocksAll: Set<String> = [wholeNest]
    static var all: [String] { [wholeNest] }
}

/// Links shown inside the paywall (behind the parental gate).
/// REPLACE the placeholders with the pages you host before submitting
/// (draft texts are in APP_STORE.md). The App Store Connect metadata must
/// carry the same Privacy Policy URL.
enum LegalLinks {
    /// Apple's standard licence agreement. Swap for your own hosted terms if you publish them.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// The policy page hosted with the web app (privacy.html on main, deployed by Vercel).
    /// Check it opens before submitting; change it here and in App Store Connect if the domain differs.
    static let privacyPolicy = URL(string: "https://getcrackingkids.vercel.app/privacy.html")!
}

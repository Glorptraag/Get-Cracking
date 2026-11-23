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
/// The App Store Connect metadata must carry the same Privacy Policy URL
/// (see APP_STORE.md).
enum LegalLinks {
    /// Apple's standard licence agreement. Swap for your own hosted terms if you publish them.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// privacy.html on the web app (the web repo's main branch). Change it
    /// here and in App Store Connect if the web app moves to another domain.
    static let privacyPolicy = URL(string: "https://getcrackingkids.vercel.app/privacy.html")!
}

import OSLog

/// One choke point for purchase events. Device log only: Get Cracking is in
/// the Kids Category, so nothing here may ever leave the device (no analytics
/// SDK, no network). Real numbers come from App Store Connect.
enum MonetizationLog {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "getcracking", category: "monetization")

    static func event(_ name: String, _ props: [String: String] = [:]) {
        logger.info("\(name, privacy: .public) \(props.description, privacy: .public)")
    }
}

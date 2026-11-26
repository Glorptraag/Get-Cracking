#if DEBUG
import SwiftUI

/// DEBUG-only launch arguments that open the app in a named state, for the
/// screenshot step in tools/screens.sh. None of this is in a Release build.
///
///   -gc-state <name>   setup · run · crack1 … crack8 · timeup · hatch · friend ·
///                      book · world · sound · settings · pack-aussie ·
///                      pack-christmas · gate · paywall
///   -gc-fast           the clock runs 60× (a 5-minute timer takes 5 seconds)
///   -gc-friend <id>    the friend that hatches
///   -gc-scene <id>     the world (default meadow, so screenshots are steady)
///
/// Any -gc-state starts from default settings, with the first-run tip seen.
enum DebugLaunch {
    private static let args = ProcessInfo.processInfo.arguments

    private static func value(_ key: String) -> String? {
        guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static let state = value("-gc-state")
    static let friend = value("-gc-friend")
    static let clockSpeed: Double = args.contains("-gc-fast") ? 60 : 1

    /// the settings row to scroll to when the settings sheet opens
    static var scrollTarget: String? {
        guard let s = state, s.hasPrefix("pack-") else { return nil }
        return s
    }

    /// the paywall opens past the parental gate
    static var skipsGate: Bool { state == "paywall" }

    static func settings(_ saved: Settings) -> Settings {
        guard let state else { return saved }
        var s = Settings()
        s.seenHint = true
        s.scene = value("-gc-scene") ?? "meadow"
        switch state {
        case "run": s.hatchMode = "auto"
        case _ where state.hasPrefix("crack"): s.minutes = 10
        default: break
        }
        return s
    }

    @MainActor
    static func apply(_ model: AppModel) async {
        guard let state else { return }
        switch state {
        case "run":
            model.startRun()
        case _ where state.hasPrefix("crack"):
            guard let n = Int(state.dropFirst(5)), (1...8).contains(n) else { return }
            model.startRun()
            model.run?.debugJump(to: TimerClock.stepAt[n - 1] + 0.02)
        case "timeup":
            model.startRun()
            model.run?.debugJump(to: 1)
        case "hatch", "friend":
            model.startRun()
            await GC.sleep(0.6)
            model.run?.hatchNow()
        case "book": model.sheet = .book
        case "world": model.sheet = .world
        case "sound": model.sheet = .sound
        case "settings", "pack-aussie", "pack-christmas":
            model.sheet = .settings
        case "gate", "paywall":
            model.sheet = .settings
            await GC.sleep(0.8)
            model.askForNest(.settings)
        default:
            break
        }
    }
}
#endif

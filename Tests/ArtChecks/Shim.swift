// The few UIKit names the art code touches, so it compiles as a macOS
// command-line tool (Tests/ArtChecks, never shipped in the app).

#if os(macOS)
import AppKit

typealias UIImage = NSImage

enum UIAccessibility {
    /// flipped by the checks to see reduced motion turn the particles and loops off
    nonisolated(unsafe) static var isReduceMotionEnabled = false
}
#endif

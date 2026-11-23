import SwiftUI

/// The art every content pack adds: the native twin of what the web's
/// `GC.Packs.register` hands to js/animals.js and js/scenes.js.
///
/// A pack's drawings live in their own files (Art/Packs/<Pack>Art.swift for
/// its friends and parts, <Pack>Worlds.swift for its worlds and particles)
/// and are listed here once. Its ids and pricing go in Monetization/Packs.swift.
/// The drawings are ported from the web as path data, same numbers, colours
/// and layer order; idle-loop hooks (web classes c-tail, c-arm-l/-r, c-eyes,
/// c-ears) become `Loops.wag`, `Animals.arm`, and the blink and ear groups
/// `Animals.render` already wraps around every eyes and ears part.
enum PackArt {
    /// part tables, merged into `Animals.parts`
    static let parts: [AnimalParts] = [AussieArt.parts, ChristmasArt.parts]
    /// friends, after the Classic 40 in `Animals.list`
    static let friends: [AnimalDef] = AussieArt.friends + ChristmasArt.friends
    /// worlds, after the Classic 10 in `Scenes.list`
    static let scenes: [SceneDef] = AussieWorlds.scenes + ChristmasWorld.scenes
    /// particle kinds the pack worlds use (the web's `GC.Scenes.PARTICLES`)
    static let particles: [String: Scenes.Particle] = AussieWorlds.particles.merging(ChristmasWorld.particles) { a, _ in a }
}

// MARK: - small helpers the pack drawings share

/// SVG `transform="translate(x y) rotate(deg) scale(sx sy)"`.
func svgMove(_ x: Double, _ y: Double, rot: Double = 0, scale sx: Double = 1, _ sy: Double? = nil) -> CGAffineTransform {
    CGAffineTransform(translationX: x, y: y).rotated(by: rot * .pi / 180).scaledBy(x: sx, y: sy ?? sx)
}

/// A stroke with round caps and the default (miter) join: the web's
/// `stroke-linecap="round"` with no `stroke-linejoin`.
func rcap(_ c: String, _ w: Double) -> St { St(stroke: c, width: w, cap: .round) }

/// A plain stroke with butt caps (the SVG default).
func plain(_ c: String, _ w: Double) -> St { St(stroke: c, width: w) }

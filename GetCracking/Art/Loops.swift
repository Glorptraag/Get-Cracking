import SwiftUI

/// The idle loops (CSS @keyframes in the web version).
enum Loops {
    typealias F = Loop.Frame

    /// translate, rotate, scale in one canonical list
    static func trs(_ tx: Double = 0, _ ty: Double = 0, r: Double = 0, sx: Double = 1, sy: Double = 1) -> [TOp] {
        [.translate(tx, ty), .rotate(r), .scale(sx, sy)]
    }

    // MARK: egg

    static let eggBreathe = Loop(duration: 3.2, frames: [F(at: 0, ops: trs()), F(at: 0.5, ops: trs(sx: 1.025, sy: 0.975)), F(at: 1, ops: trs())])
    static let eggWobble = Loop(duration: 4.5, frames: [0, 0.7, 1].map { F(at: $0, ops: trs()) } +
        [F(at: 0.76, ops: trs(r: -4)), F(at: 0.84, ops: trs(r: 3.5)), F(at: 0.92, ops: trs(r: -1.5))])
    static let eggWobble2 = Loop(duration: 2.8, frames: [0, 0.55, 1].map { F(at: $0, ops: trs()) } +
        [F(at: 0.62, ops: trs(r: -7)), F(at: 0.72, ops: trs(r: 6)), F(at: 0.82, ops: trs(r: -4)), F(at: 0.9, ops: trs(r: 2))])
    static let eggHop = Loop(duration: 1.6, frames: [0, 0.4, 1].map { F(at: $0, ops: trs()) } + [
        F(at: 0.5, ops: trs(sx: 1.08, sy: 0.92)),
        F(at: 0.62, ops: trs(0, -22, r: -5, sx: 0.96, sy: 1.05)),
        F(at: 0.74, ops: trs(r: 4, sx: 1.06, sy: 0.94)),
        F(at: 0.86, ops: trs(r: -2)),
    ])
    static let eggReady = Loop(duration: 1.3, frames: [
        F(at: 0, ops: trs()), F(at: 1, ops: trs()),
        F(at: 0.15, ops: trs(r: -8, sx: 1.03, sy: 0.97)),
        F(at: 0.3, ops: trs(r: 7)),
        F(at: 0.45, ops: trs(0, -8, r: -5)),
        F(at: 0.6, ops: trs(r: 3)),
        F(at: 0.75, ops: trs(sx: 1.05, sy: 0.95)),
    ])
    static let spin = Loop(duration: 30, ease: .linear, frames: [F(at: 0, ops: [.rotate(0)]), F(at: 1, ops: [.rotate(360)])])
    static let glowThrob = Loop(duration: 1.4, frames: [F(at: 0.5, opacity: 0.5)])
    static let halo = Loop(duration: 1.3, frames: [F(at: 0, opacity: 0.35), F(at: 0.5, opacity: 0.75), F(at: 1, opacity: 0.35)])
    static func blink(_ d: Double, delay: Double = 0) -> Loop {
        Loop(duration: d, delay: delay, ease: .ease, origin: .box(0.5, 0.5), frames: [
            F(at: 0, ops: [.scale(1, 1)]), F(at: 0.92, ops: [.scale(1, 1)]), F(at: 0.95, ops: [.scale(1, 0.1)]), F(at: 1, ops: [.scale(1, 1)]),
        ])
    }
    static func zz(delay: Double = 0) -> Loop {
        Loop(duration: 2.4, delay: delay, frames: [
            F(at: 0, ops: [.translate(0, 0)], opacity: 0), F(at: 0.3, opacity: 1), F(at: 1, ops: [.translate(24, -40)], opacity: 0),
        ])
    }

    // MARK: hatched friend (idle only)

    static let critterHop = Loop(duration: 2.6, frames: [
        F(at: 0, ops: trs()), F(at: 1, ops: trs()),
        F(at: 0.1, ops: trs(sx: 1.08, sy: 0.92)),
        F(at: 0.25, ops: trs(0, -26, sx: 0.95, sy: 1.06)),
        F(at: 0.4, ops: trs(sx: 1.08, sy: 0.92)),
        F(at: 0.5, ops: trs()),
        F(at: 0.7, ops: trs(r: -3)),
        F(at: 0.85, ops: trs(r: 3)),
    ])
    /// the shadow shrinks while the friend is in the air (base opacity .18 → .1)
    static let shadowPulse = Loop(duration: 2.6, origin: .box(0.5, 0.5), frames: [F(at: 0.25, ops: [.scale(0.75, 0.75)], opacity: 0.55)])
    static let wave = Loop(duration: 2.6, origin: .box(0.3, 0.2), frames: [
        F(at: 0.55, ops: [.rotate(0)]), F(at: 1, ops: [.rotate(0)]), F(at: 0.62, ops: [.rotate(-40)]),
        F(at: 0.7, ops: [.rotate(-10)]), F(at: 0.78, ops: [.rotate(-40)]), F(at: 0.86, ops: [.rotate(0)]),
    ])
    static let waveL = Loop(duration: 2.6, origin: .box(0.7, 0.2), frames: [
        F(at: 0, ops: [.rotate(0)]), F(at: 0.2, ops: [.rotate(0)]), F(at: 0.3, ops: [.rotate(20)]), F(at: 0.5, ops: [.rotate(0)]), F(at: 1, ops: [.rotate(0)]),
    ])
    static let ears = Loop(duration: 2.6, origin: .box(0.5, 1), frames: [
        F(at: 0, ops: [.rotate(0)]), F(at: 0.6, ops: [.rotate(0)]), F(at: 0.66, ops: [.rotate(-4)]), F(at: 0.74, ops: [.rotate(4)]), F(at: 1, ops: [.rotate(0)]),
    ])
    static let wag = Loop(duration: 0.9, alternate: true, origin: .box(0, 1), frames: [F(at: 0, ops: [.rotate(0)]), F(at: 1, ops: [.rotate(-12)])])

    // MARK: scenery

    static func sway(_ d: Double) -> Loop {
        Loop(duration: d, origin: .box(0.5, 1), frames: [F(at: 0, ops: [.rotate(-1.2)]), F(at: 0.5, ops: [.rotate(1.2)]), F(at: 1, ops: [.rotate(-1.2)])])
    }
    static func seaSway(_ d: Double) -> Loop {
        Loop(duration: d, origin: .box(0.5, 1), frames: [F(at: 0, ops: [.skewX(-7)]), F(at: 0.5, ops: [.skewX(7)]), F(at: 1, ops: [.skewX(-7)])])
    }
    static func bob(_ d: Double) -> Loop { Loop(duration: d, frames: [F(at: 0.5, ops: [.translate(0, -3)])]) }
    static let flicker = Loop(duration: 1.8, origin: .box(0.5, 1), frames: [
        F(at: 0, ops: [.scale(1, 1)], opacity: 1), F(at: 1, ops: [.scale(1, 1)], opacity: 1),
        F(at: 0.3, ops: [.scale(0.92, 1.05)], opacity: 0.75), F(at: 0.6, ops: [.scale(1.05, 0.95)], opacity: 0.95),
    ])
    static func glowPulse(_ d: Double = 3) -> Loop { Loop(duration: d, frames: [F(at: 0.5, opacity: 0.65)]) }
    static func twinkle(_ d: Double, delay: Double) -> Loop { Loop(duration: d, delay: delay, frames: [F(at: 0.5, opacity: 0.2)]) }
    static func drift(_ d: Double) -> Loop { Loop(duration: d, alternate: true, frames: [F(at: 1, ops: [.translate(60, 0)])]) }
    static func sun(_ d: Double) -> Loop { Loop(duration: d, origin: .box(0.5, 0.5), frames: [F(at: 0.5, ops: [.scale(1.06, 1.06)])]) }
    static let ripple = Loop(duration: 3, ease: .easeOut, origin: .box(0.5, 0.5), frames: [
        F(at: 0, ops: [.scale(0.3, 0.3)], opacity: 1), F(at: 1, ops: [.scale(2.2, 2.2)], opacity: 0),
    ])
    static let waveDash = Loop(duration: 3, ease: .linear, frames: [F(at: 0, dash: 0), F(at: 1, dash: -68)])
    static func swim(_ sx: Double, _ d: Double) -> Loop { Loop(duration: d, alternate: true, frames: [F(at: 1, ops: [.translate(sx, 0)])]) }
    static let scuttle = Loop(duration: 4, frames: [
        F(at: 0, ops: [.translate(0, 0)]), F(at: 0.4, ops: [.translate(0, 0)]), F(at: 1, ops: [.translate(0, 0)]),
        F(at: 0.5, ops: [.translate(8, 0)]), F(at: 0.9, ops: [.translate(8, 0)]),
    ])
    static let glide = Loop(duration: 9, alternate: true, frames: [F(at: 1, ops: [.translate(-40, 10)])])
    static func flutter(_ fx: Double, _ fy: Double, _ d: Double = 12) -> Loop {
        Loop(duration: d, frames: [
            F(at: 0, ops: [.translate(fx, fy)]), F(at: 0.25, ops: [.translate(fx + 60, fy - 30)]),
            F(at: 0.5, ops: [.translate(fx + 20, fy - 60)]), F(at: 0.75, ops: [.translate(fx - 40, fy - 20)]),
            F(at: 1, ops: [.translate(fx, fy)]),
        ])
    }
    static let flap = Loop(duration: 0.25, alternate: true, origin: .box(0.5, 0.5), frames: [F(at: 0, ops: [.scale(1, 1)]), F(at: 1, ops: [.scale(0.3, 1)])])

    // MARK: particles

    static func firefly(_ d: Double, dx: Double, delay: Double) -> Loop {
        Loop(duration: d, delay: delay, frames: [
            F(at: 0, ops: [.translate(0, 0)], opacity: 0.1), F(at: 1, ops: [.translate(0, 0)], opacity: 0.1),
            F(at: 0.25, ops: [.translate(dx * 0.6, -18)], opacity: 1), F(at: 0.5, ops: [.translate(dx, 6)], opacity: 0.3),
            F(at: 0.75, ops: [.translate(dx * 0.2, -26)], opacity: 1),
        ])
    }
    static func rise(_ d: Double, dx: Double, delay: Double) -> Loop {
        Loop(duration: d, delay: delay, ease: .linear, frames: [
            F(at: 0, ops: [.translate(0, 0)], opacity: 0), F(at: 0.15, opacity: 1), F(at: 1, ops: [.translate(dx, -380)], opacity: 0),
        ])
    }
    static func fall(_ d: Double, dx: Double, delay: Double) -> Loop {
        Loop(duration: d, delay: delay, ease: .linear, frames: [
            F(at: 0, ops: [.translate(0, 0), .rotate(0)]), F(at: 1, ops: [.translate(dx, 760), .rotate(540)]),
        ])
    }
}

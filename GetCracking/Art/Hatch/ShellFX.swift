import SwiftUI

/// A "shell effect" decides what the eggshell physically does when the egg
/// hatches: roll away, explode, crumble… Each lives in its own file in
/// Art/Hatch/ and is listed in `ShellFX.all`. They are interchangeable.
///
/// ─────────────────────────────── CONTRACT ───────────────────────────────
///
/// When `run(ctx)` is called the shared anticipation (squash → stretch) has
/// already played and the intact egg is hidden. The effect must:
///
///   1. Build shell pieces with ctx.piece(points) so they look exactly like
///      the egg that was just on screen (same colour + pattern + cracks).
///   2. Call ctx.release() once, at the moment the friend should spring out
///      (usually 0–700 ms in). If it never does, the core releases when
///      run() returns, or after 3.5 s as a fallback.
///   3. Return when its main motion is done (aim ≤ 2.5 s). Pieces may stay
///      resting on the ground afterwards — a little rubble pile is charming.
///
/// After release the friend jumps from the egg's centre up to y ≈ -190 and
/// lands at (0, ctx.ground) in ~1.1 s. Keep the friend visible:
///   - anything in ctx.front draws OVER the friend: by ~400 ms after
///     release, front pieces must be clear of the box x ∈ [-75, 75],
///     y ∈ [-200, 60]; move lingering pieces to ctx.back or off to the sides.
///   - anything in ctx.back draws behind the friend (rubble, shadows).
///
/// Coordinates are egg-local: the egg's base is (0,0), the egg spans
/// x ∈ [-64, 64], y ∈ [-170, 0]. +y is toward the viewer / down the screen.
/// The ground is a plane: a piece resting at depth d has its bottom at y ≈ d,
/// where d ∈ [-20, 70] (higher = nearer the viewer). Stay inside ctx.bounds
/// or fade out before leaving it.
///
/// ctx.reduce is Reduce Motion: keep it ≤ 400 ms with no flying pieces.
@MainActor
protocol ShellEffect {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var hidden: Bool { get }
    func run(_ ctx: ShellCtx) async
}

extension ShellEffect {
    var hidden: Bool { false }
}

@MainActor
enum ShellFX {
    static let all: [any ShellEffect] = [RollFX(), BoomFX(), CrumbleFX(), ClassicFX()]

    /// user-facing styles (excludes hidden fallbacks)
    static var list: [any ShellEffect] { all.filter { !$0.hidden } }

    static func get(_ id: String) -> (any ShellEffect)? { all.first { $0.id == id } }

    /// id, "random", or nil → an effect (never fails)
    static func pick(_ id: String?) -> any ShellEffect {
        if let id, id != "random", let fx = get(id) { return fx }
        let pool = list
        return pool.isEmpty ? ClassicFX() : GC.pick(pool)
    }
}

/// Fallback / reference effect: the halves just split and slide apart.
struct ClassicFX: ShellEffect {
    let id = "classic", name = "Split", icon = "🥚"
    var hidden: Bool { true }

    func run(_ ctx: ShellCtx) async {
        let top = ctx.piece([(-90, -230), (90, -230)] + Array(ctx.zig.reversed()))
        let bot = ctx.piece(ctx.zig + [(90, 20), (-90, 20)], layer: ctx.back)
        ctx.release()
        ctx.start(top.el, [KF([.translate(0, 0), .rotate(0)]), KF([.translate(-160, -40), .rotate(-60)], opacity: 0)],
                  duration: 700, easing: .easeIn, fill: true)
        await ctx.animate(bot.el, [KF([.translate(0, 0), .rotate(0)]), KF([.translate(150, 10), .rotate(30)], opacity: 0)],
                          duration: 700, easing: .easeIn, fill: true)
    }
}

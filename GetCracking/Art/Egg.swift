import SwiftUI

/// The live egg on the timer screen: it cracks step by step (the drawing and
/// the crack landmarks are in EggArt.swift), wobbles, and hatches a friend.

extension GC {
    static func sleep(_ seconds: Double) async {
        if seconds > 0 { try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
    }

    @MainActor
    static func after(_ seconds: Double, _ f: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            await GC.sleep(seconds)
            f()
        }
    }
}

/// A one-shot latch you can await (resolves once, for every waiter).
@MainActor
final class Gate {
    private(set) var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func open() {
        guard !isOpen else { return }
        isOpen = true
        let w = waiters
        waiters = []
        for c in w { c.resume() }
    }

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            waiters.append(c)
        }
    }
}

@MainActor
final class Egg {
    let root: VNode
    let pal: EggPalette
    let pattern: EggPattern
    let style: String?
    private(set) var step = 0
    private(set) var hatched = false
    private(set) var ready = false
    private(set) var paused = false
    /// set when the run that owns this egg ends: effects stop making sounds
    var disposed = false
    private(set) var friend: VNode?
    private(set) var styleUsed: String?
    var onBoop: (() -> Void)?
    var onCheer: (() -> Void)?

    let shellBack = VNode(), friendHolder = VNode(), shellFront = VNode(), fx = VNode()
    private let rays: VNode, shadow: VNode, halo: VNode, wobble: VNode, squash: VNode
    private let cracks: VNode, mainLine: VNode
    private var branchLines: [(step: Int, line: VNode)] = []
    /// eases the crack widths to the new step's (the web's 0.5 s stroke-width transition)
    private var widthTask: Task<Void, Never>?
    private var cheering = false

    init(x: Double = 0, y: Double = 0, scale: Double = 1, palette: EggPalette? = nil, pattern: EggPattern? = nil, style: String? = nil) {
        let pal0 = palette ?? GC.pick(EggArt.palettes)
        let pat0 = pattern ?? GC.pick(EggPattern.allCases)
        pal = pal0
        self.pattern = pat0
        self.style = style
        let root0 = nGroup([], CGAffineTransform(translationX: x, y: y).scaledBy(x: scale, y: scale))
        root = root0

        var rayKids: [VNode] = []
        for i in 0..<12 {
            let a = Double(i) / 12 * .pi * 2, b = a + .pi / 12
            rayKids.append(nPath("M0,0 L\(cos(a) * 230),\(sin(a) * 230) L\(cos(b) * 230),\(sin(b) * 230) Z", .f("#fff6c9")))
        }
        let rays0 = nGroup([nGroup([nGroup(rayKids).looping(Loops.spin)], tr(0, -80))])
        rays0.opacity = 0
        rays = rays0

        shadow = nEllipse(0, 2, 70, 13, St.f(GC.outHex).op(0.2))
        let halo0 = nCircle(0, -86, 104, St())
        halo0.radialGlow = (Color(hex: "#fff3b0"), CGPoint(x: 0, y: -86), 112)
        halo0.opacity = 0
        halo = halo0

        let mainLine0 = nPolyline(EggArt.zig, St.line(GC.outHex, EggArt.crackW(0)))
        mainLine = mainLine0
        var lines: [(step: Int, line: VNode)] = []
        for b in EggArt.branches {
            lines.append((b.step, nPolyline(b.pts, St.line(GC.outHex, EggArt.branchW(0)))))
        }
        branchLines = lines
        let cracks0 = nGroup([mainLine0] + lines.map(\.line), clip: EggArt.path)
        cracks = cracks0

        let squash0 = nGroup([EggArt.body(pal0, pat0), cracks0])
        squash = squash0
        let wobble0 = nGroup([squash0])
        wobble = wobble0
        root0.add([rays0, shadow, halo0, wobble0, shellBack, friendHolder, shellFront, fx])
        setStep(0, silent: true)
    }

    /// Egg-local bounds of the egg body (for hit testing / the tap hint).
    static let bodyRect = CGRect(x: -64, y: -170, width: 128, height: 170)

    // MARK: cracking

    /// Advance to a crack step. Cracks never heal, even if time is added.
    /// Each step runs the cracks further, branches new ones, and draws them
    /// all wider and deeper (`EggArt.crackWByStep`).
    @discardableResult
    func setStep(_ n: Int, silent: Bool = false) -> Bool {
        if n < step && !silent { return false }
        let changed = n != step
        step = n
        trim(mainLine, to: EggArt.mainLenByStep[n], duration: 0.35, ease: Ease(0.2, 1.4, 0.5, 1), silent)
        for b in branchLines {
            trim(b.line, to: n >= b.step ? 1 : 0, duration: 0.3, ease: .easeOut, silent)
        }
        setCrackWidth(n, animated: !silent)
        updateWobble()
        if changed && !silent {
            shake()
            chips(4)
        }
        return changed
    }

    private func setCrackWidth(_ n: Int, animated: Bool) {
        widthTask?.cancel()
        widthTask = nil
        let main = (from: Double(mainLine.strokeWidth), to: EggArt.crackW(n))
        let branch = (from: Double(branchLines.first?.line.strokeWidth ?? 0), to: EggArt.branchW(n))
        func apply(_ u: Double) {
            mainLine.strokeWidth = CGFloat(main.from + (main.to - main.from) * u)
            let bw = CGFloat(branch.from + (branch.to - branch.from) * u)
            for b in branchLines { b.line.strokeWidth = bw }
        }
        if !animated || abs(main.to - main.from) < 0.001 { apply(1); return }
        let start = GC.now, ease = Ease.easeOut
        widthTask = Task { @MainActor in
            while !Task.isCancelled {
                let u = min(1, (GC.now - start) / 0.5)
                apply(ease(u))
                if u >= 1 { return }
                await GC.sleep(1.0 / 60)
            }
        }
    }

    private func trim(_ node: VNode, to v: Double, duration: Double, ease: Ease, _ silent: Bool) {
        let from = Double(node.trimTo)
        node.trimTo = CGFloat(v)
        if silent || abs(from - v) < 0.0001 { node.cancelAnims(); return }
        node.play([KF(trimTo: from), KF(trimTo: v)], duration: duration, easing: ease, fill: true)
    }

    private func updateWobble() {
        if hatched { return }
        if GC.reduceMotion { wobble.setLoop(nil, key: "still"); return }
        if ready { wobble.setLoop(Loops.eggReady, key: "ready"); return }
        let lv = step >= 8 ? 3 : step >= 5 ? 2 : step >= 1 ? 1 : 0
        let loops = [Loops.eggBreathe, Loops.eggWobble, Loops.eggWobble2, Loops.eggHop]
        wobble.setLoop(loops[lv], key: "level\(lv)")
    }

    func setReady(_ on: Bool) {
        ready = on
        if on {
            halo.opacity = 1
            halo.loop = Loops.halo
        } else {
            halo.loop = nil
            halo.opacity = 0
        }
        updateWobble()
    }

    func setPaused(_ on: Bool) {
        paused = on
        wobble.pauseLoop(on)
    }

    func shake() {
        squash.play([KF([.rotate(0)]), KF([.rotate(-6)]), KF([.rotate(5)]), KF([.rotate(-3)]), KF([.rotate(0)])],
                    duration: 0.42, easing: .easeOut)
    }

    /// A tap on the egg: a happy squish. Never changes the timer.
    func boop() {
        if hatched || ready { return }
        squash.play([KF([.scale(1, 1)]), KF([.scale(1.08, 0.9)]), KF([.scale(0.96, 1.05)]), KF([.scale(1, 1)])],
                    duration: 0.38, easing: .easeOut)
        onBoop?()
    }

    /// a few little shell chips that pop off when the egg cracks a step
    func chips(_ n: Int) {
        if GC.reduceMotion { return }
        for _ in 0..<n {
            let g = nGroup([], tr(GC.rand(-40, 40), GC.rand(-130, -70)))
            let s = GC.rand(5, 9)
            let p = nPath("M0,\(-s) L\(s),\(s * 0.6) L\(-s * 0.8),\(s * 0.4) Z", St.o(3).filled(pal.shell))
            g.add(p)
            fx.add(g)
            let dx = GC.rand(-90, 90), dy = GC.rand(-90, -40)
            p.play([
                KF([.translate(0, 0), .rotate(0)], opacity: 1),
                KF([.translate(dx * 0.6, dy), .rotate(GC.rand(-300, 300))], offset: 0.5, opacity: 1),
                KF([.translate(dx, dy * 0.2 + 160), .rotate(GC.rand(-500, 500))], opacity: 0),
            ], duration: 0.8, easing: Ease(0.2, 0.7, 0.4, 1), fill: true)
            GC.after(0.85) { g.removeFromParent() }
        }
    }

    func confetti(_ n: Int = 26) {
        let cols = ["#f7a8c8", "#ffd86b", "#9fd8e8", "#a9d36b", "#f39a6b", "#c5a8f0"]
        for i in 0..<n {
            let g = nGroup([], tr(0, -90))
            let c = GC.pick(cols)
            let shape: VNode
            switch i % 3 {
            case 0: shape = nPath("M0,-9 L2.6,-2.6 L9,0 L2.6,2.6 L0,9 L-2.6,2.6 L-9,0 L-2.6,-2.6 Z", St.o(2.5).filled(c))
            case 1: shape = nCircle(0, 0, 6, St.o(2.5).filled(c))
            default: shape = nPath("M0,-10 C6,-6 6,6 0,10 C-6,6 -6,-6 0,-10 Z", St.o(2.5).filled(c))
            }
            g.add(shape)
            fx.add(g)
            let ang = GC.rand(-.pi * 0.95, -.pi * 0.05)
            let dist = GC.rand(140, 300)
            let dx = cos(ang) * dist, dy = sin(ang) * dist
            let dur = GC.rand(1.6, 2.4)
            shape.play([
                KF([.translate(0, 0), .s(0.2), .rotate(0)], opacity: 1),
                KF([.translate(dx, dy), .s(1), .rotate(GC.rand(-200, 200))], offset: 0.45, opacity: 1),
                KF([.translate(dx * 1.2, dy + 260), .s(0.9), .rotate(GC.rand(-400, 400))], opacity: 0),
            ], duration: dur, easing: Ease(0.15, 0.8, 0.35, 1), fill: true)
            GC.after(dur + 0.05) { g.removeFromParent() }
        }
    }

    /// The cracks exactly as they look right now, as static nodes for the
    /// shell pieces.
    func crackNodes() -> VNode { EggArt.cracks(step: step) }

    // MARK: hatching

    /// The big moment.
    ///   1. anticipation: squash → stretch (shared by every style)
    ///   2. the intact egg is swapped for loose shell pieces and the chosen
    ///      shell effect (roll / boom / crumble …) takes over
    ///   3. when the effect calls ctx.release() the friend springs up and
    ///      lands in front with a squash-and-settle bounce, then idles
    func hatch(friend critter: VNode, style requested: String? = nil, onPop: (() -> Void)? = nil) async {
        if hatched { return }
        hatched = true
        let reduce = GC.reduceMotion
        ready = false
        halo.loop = nil
        halo.opacity = 0
        wobble.pauseLoop(false)
        wobble.setLoop(nil, key: "hatch")
        friendHolder.removeAllChildren()
        let friendNode = nGroup([critter])
        friendNode.opacity = 0
        friendHolder.add(friendNode)

        // 1. anticipation
        let d1 = reduce ? 0.2 : 0.52
        squash.play([KF([.scale(1, 1)]), KF([.scale(1.14, 0.84)], offset: 0.6), KF([.scale(0.9, 1.12)])],
                    duration: d1, easing: Ease(0.5, 0, 0.5, 1), fill: true)
        await GC.sleep(d1)

        // 2. hand over to the shell effect
        let effect = ShellFX.pick(requested ?? style)
        cracks.hidden = true
        halo.hidden = true
        shadow.hidden = true
        wobble.hidden = true
        rays.play([KF(opacity: 0), KF(opacity: 0.32)], duration: 0.6, fill: true)
        rays.play([KF([.translate(0, -80), .s(0.2), .translate(0, 80)]), KF([.translate(0, -80), .s(1), .translate(0, 80)])],
                  duration: 1, easing: Ease(0.3, 1.5, 0.5, 1), fill: true)

        let gate = Gate()
        // the friend's own keep-clear box: wide friends (an elephant's ears) need more than the default
        let fb = critter.bounds
        let half = fb.isEmpty ? 75 : max(75, (max(-Double(fb.minX), Double(fb.maxX)) + 4).rounded(.up))
        let ctx = ShellCtx(egg: self, clearHalfWidth: half) { gate.open() }
        Task { @MainActor in
            await effect.run(ctx)
            gate.open()
        }
        GC.after(3.5) { gate.open() }
        await gate.wait()
        styleUsed = effect.id

        // 3. the friend springs out
        if !reduce { confetti() }
        onPop?()
        friendNode.opacity = 1
        let d3 = reduce ? 0.3 : 1.15
        friendNode.play([
            KF([.translate(0, -30), .scale(0.25, 0.25)]),
            KF([.translate(0, -170), .scale(0.86, 1.12)], offset: 0.45),
            KF([.translate(0, -190), .scale(1, 1)], offset: 0.55),
            KF([.translate(0, 48), .scale(1, 1.04)], offset: 0.82),
            KF([.translate(0, 48), .scale(1.2, 0.8)], offset: 0.9),
            KF([.translate(0, 48), .scale(0.96, 1.06)], offset: 0.96),
            KF([.translate(0, 48), .scale(1, 1)]),
        ], duration: d3, easing: Ease(0.4, 0, 0.6, 1), fill: true)
        await GC.sleep(d3)
        friendNode.cancelAnims()
        friendNode.transform = tr(0, 48)
        critter.enableIdle()
        friend = friendNode
    }

    /// Tap the hatched friend: a happy jump, repeatable.
    func cheer() {
        guard let f = friend, !cheering, let inner = f.first(tag: "critter") else { return }
        cheering = true
        inner.play([
            KF([.translate(0, 0), .scale(1, 1)]),
            KF([.translate(0, 0), .scale(1.15, 0.85)], offset: 0.15),
            KF([.translate(0, -70), .scale(0.9, 1.12)], offset: 0.5),
            KF([.translate(0, 0), .scale(1.12, 0.88)], offset: 0.82),
            KF([.translate(0, 0), .scale(1, 1)]),
        ], duration: 0.7, easing: .easeInOut)
        GC.after(0.7) { [weak self] in self?.cheering = false }
        confetti(8)
        onCheer?()
    }
}

/// A shell fragment handed back by `ShellCtx.piece`.
struct Piece {
    /// animate this: its origin is the piece's centroid
    let el: VNode
    /// re-parent this to move the piece between layers
    let wrap: VNode
    let cx: Double
    let cy: Double
}

/// Everything a hatch style may use. Times are in milliseconds, like the
/// web version, so the effects port over line for line. See ShellFX.swift
/// for the contract.
@MainActor
final class ShellCtx {
    unowned let egg: Egg
    private let onRelease: @MainActor () -> Void
    let ground = 48.0
    let bounds = (left: -330.0, right: 330.0, top: -480.0, bottom: 230.0)
    /// the friend's keep-clear box (egg-local): at least x ∈ [-75, 75], wider for a wide friend
    let clear: (l: Double, r: Double, t: Double, b: Double)
    let reduce: Bool

    init(egg: Egg, clearHalfWidth: Double = 75, release: @escaping @MainActor () -> Void) {
        self.egg = egg
        onRelease = release
        clear = (l: -clearHalfWidth, r: clearHalfWidth, t: -200, b: 60)
        reduce = GC.reduceMotion
    }

    var front: VNode { egg.shellFront }
    var back: VNode { egg.shellBack }
    var pal: EggPalette { egg.pal }
    var zig: [Pt] { EggArt.zig }

    func release() { onRelease() }
    func rand(_ a: Double, _ b: Double) -> Double { GC.rand(a, b) }

    // sound effects (silent once the run that owns the egg has ended)
    func crack() { if !egg.disposed { Sound.shared.crack() } }
    func clink(_ p: Double) { if !egg.disposed { Sound.shared.clink(p) } }
    func thud(_ p: Double) { if !egg.disposed { Sound.shared.thud(p) } }
    func whoosh() { if !egg.disposed { Sound.shared.whoosh() } }

    func wait(_ ms: Double) async { await GC.sleep(ms / 1000) }
    func later(_ ms: Double, _ f: @escaping @MainActor () -> Void) { GC.after(ms / 1000, f) }

    /// Start a keyframe animation (fire and forget).
    func start(_ n: VNode, _ kfs: [KF], duration ms: Double, delay: Double = 0, easing: Ease = .linear, fill: Bool = false) {
        n.play(kfs, duration: ms / 1000, delay: delay / 1000, easing: easing, fill: fill)
    }

    /// Run a keyframe animation and wait for it to finish.
    func animate(_ n: VNode, _ kfs: [KF], duration ms: Double, delay: Double = 0, easing: Ease = .linear, fill: Bool = false) async {
        start(n, kfs, duration: ms, delay: delay, easing: easing, fill: fill)
        await GC.sleep((ms + delay) / 1000)
    }

    /// Drive a node from a function of elapsed milliseconds, and wait.
    func drive(_ n: VNode, duration ms: Double, delay: Double = 0, fill: Bool = true, _ fn: @escaping (Double) -> AnimPose) async {
        n.drive(duration: ms / 1000, delay: delay / 1000, fill: fill) { fn($0 * 1000) }
        await GC.sleep((ms + delay) / 1000)
    }

    /// A shell fragment: the egg's painted shell clipped to `points`
    /// (egg-local polygon, may extend past the egg silhouette).
    func piece(_ points: [Pt], layer: VNode? = nil, edge: Double = 4.5, cx cxIn: Double? = nil, cy cyIn: Double? = nil) -> Piece {
        var cx = 0.0, cy = 0.0
        for p in points { cx += p.0; cy += p.1 }
        cx /= Double(max(1, points.count))
        cy /= Double(max(1, points.count))
        if let v = cxIn { cx = v }
        if let v = cyIn { cy = v }
        let poly = polyPath(points, closed: true)
        let outline = nGroup([nShape(poly, St.line(GC.outHex, edge))], clip: EggArt.path)
        let clipped = nGroup([EggArt.body(egg.pal, egg.pattern), egg.crackNodes(), outline], clip: poly)
        let el = nGroup([nGroup([clipped], tr(-cx, -cy))])
        let wrap = nGroup([el], tr(cx, cy))
        (layer ?? front).add(wrap)
        return Piece(el: el, wrap: wrap, cx: cx, cy: cy)
    }

    /// a soft ground shadow at egg-local (x, y)
    @discardableResult
    func shadow(_ x: Double, _ y: Double, _ rx: Double = 20, layer: VNode? = nil) -> VNode {
        let s = nEllipse(x, y, rx, rx * 0.28, St.f(GC.outHex).op(0.18))
        (layer ?? back).add(s)
        return s
    }

    /// a cartoon dust puff (removes itself)
    @discardableResult
    func puff(_ x: Double, _ y: Double, _ r: Double = 18, layer: VNode? = nil) -> VNode {
        let c = nCircle(0, 0, r, St.o(3.5).filled("#fdf3e4").op(0.9))
        let g = nGroup([c], tr(x, y))
        (layer ?? front).add(g)
        c.play([KF([.s(0.2)], opacity: 0.9), KF([.s(1.3)], opacity: 0)], duration: 0.6, easing: .easeOut, fill: true)
        GC.after(0.62) { g.removeFromParent() }
        return g
    }
}

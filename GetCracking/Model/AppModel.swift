import SwiftUI
import UIKit

enum SheetKind: String, Identifiable {
    case world, sound, book, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .world: return "Choose a world"
        case .sound: return "Music & sounds"
        case .book: return "Friend book"
        case .settings: return "Grown-up settings"
        }
    }
}

/// The ground ring around the egg: it empties as time runs out, and its
/// pebbles light up at each crack step.
@MainActor
final class Ring {
    let prog: VNode
    let hand: VNode
    let pebbles: [VNode]
    let color: String
    private var lut: [(len: Double, pt: CGPoint)] = []

    init(layer: VNode, color: String) {
        self.color = color
        let (cx, cy, rx, ry) = Scenes.ring
        let d = "M\(cx),\(cy + ry) A\(rx),\(ry) 0 0 1 \(cx),\(cy - ry) A\(rx),\(ry) 0 0 1 \(cx),\(cy + ry)"
        layer.add(nPath(d, St(stroke: GC.outHex, width: 30)))
        layer.add(nPath(d, St(stroke: "#fdf3e4", width: 18)))
        let p = nPath(d, St.line(color, 18))
        prog = p
        layer.add(p)

        // arc-length table: from the bottom, clockwise on screen (y down)
        var table: [(len: Double, pt: CGPoint)] = []
        var acc = 0.0
        var last = CGPoint(x: cx, y: cy + ry)
        let n = 720
        for i in 0...n {
            let th = Double.pi / 2 + Double(i) / Double(n) * 2 * Double.pi
            let q = CGPoint(x: cx + rx * cos(th), y: cy + ry * sin(th))
            acc += hypot(Double(q.x - last.x), Double(q.y - last.y))
            table.append((acc, q))
            last = q
        }
        lut = table

        let peb = nGroup()
        var pebs: [VNode] = []
        for f in EggArt.stepAt {
            let q = Ring.point(table, f)
            let c = nCircle(Double(q.x), Double(q.y), 5.5, St.o(3).filled("#cbbfae"))
            pebs.append(c)
            peb.add(c)
        }
        pebbles = pebs
        layer.add(peb)

        let h = nGroup([
            nCircle(0, 0, 14, St.o(5).filled("#fdf3e4")),
            nCircle(0, 0, 5, .f(color)),
        ])
        hand = h
        layer.add(h)
    }

    private static func point(_ table: [(len: Double, pt: CGPoint)], _ f: Double) -> CGPoint {
        guard let total = table.last?.len, total > 0 else { return .zero }
        let target = GC.clamp(f, 0, 1) * total
        var lo = 0, hi = table.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if table[mid].len < target { lo = mid + 1 } else { hi = mid }
        }
        return table[lo].pt
    }

    func set(_ elapsed: Double) {
        let r = max(0, 1 - elapsed)
        prog.trimFrom = CGFloat(elapsed)
        prog.trimTo = 1
        prog.opacity = r <= 0.0005 ? 0 : 1
        let q = Ring.point(lut, min(elapsed, 0.9999))
        hand.transform = CGAffineTransform(translationX: q.x, y: q.y)
    }

    func light(_ step: Int) {
        for (i, c) in pebbles.enumerated() { c.fill = Color(hex: i < step ? color : "#cbbfae") }
    }
}

/// One run of the timer.
///   running → (paused ↔ running) → ready (time's up, waiting for a tap)
///           → hatching → hatched
@Observable
@MainActor
final class RunController {
    enum Phase { case running, paused, ready, hatching, hatched }

    private(set) var phase: Phase = .running
    private(set) var timeText = ""
    private(set) var hatchText = ""
    private(set) var showHatchPill = false
    private(set) var showTapHint = false
    private(set) var showNextCard = false
    private(set) var showAgain = false
    private(set) var timeBump = 0
    var trayOpen = false
    var showLockTip = false

    let scene: BuiltScene
    let egg: Egg
    let ring: Ring

    @ObservationIgnored private weak var app: AppModel?
    @ObservationIgnored private var total: Double
    @ObservationIgnored private var endAt: Double
    @ObservationIgnored private var remainingWhenPaused: Double
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var knockTask: Task<Void, Never>?
    @ObservationIgnored private var trayTask: Task<Void, Never>?
    @ObservationIgnored private var zz: [VNode] = []
    @ObservationIgnored private(set) var ended = false

    private static var wall: Double { Date().timeIntervalSinceReferenceDate }

    init(app: AppModel, sceneId: String) {
        let built = Scenes.build(sceneId)
        let egg0 = Egg(x: Scenes.egg.x, y: Scenes.egg.y)
        built.eggLayer.add(egg0.root)
        let ring0 = Ring(layer: built.ringLayer, color: built.scene.ring)
        let t = app.settings.totalSeconds
        self.app = app
        scene = built
        egg = egg0
        ring = ring0
        total = t
        endAt = RunController.wall + t
        remainingWhenPaused = t
        egg0.onBoop = { Sound.shared.boop() }
        ring0.set(0)
        ring0.light(0)
        timeText = GC.fmtTime(t)
    }

    var settings: Settings { app?.settings ?? Settings() }

    func start() {
        let s = settings
        Sound.shared.ensure()
        Sound.shared.setVolume(s.volume)
        Sound.shared.setTension(0)
        Sound.shared.startMusic(s.music)
        UIApplication.shared.isIdleTimerDisabled = true
        let t = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        if !s.seenHint {
            app?.settings.seenHint = true
            GC.after(1.2) { [weak self] in self?.flashLockTip(4) }
        }
        tick()
    }

    var remaining: Double {
        phase == .paused ? remainingWhenPaused : max(0, endAt - RunController.wall)
    }

    func tick() {
        guard !ended, phase == .running || phase == .paused else { return }
        let rem = remaining
        let elapsed = GC.clamp(1 - rem / total, 0, 1)
        ring.set(elapsed)
        let st = EggArt.stepFor(elapsed)
        if st > egg.step {
            egg.setStep(st)
            ring.light(st)
            Sound.shared.crack()
        }
        if elapsed >= 0.9 { Sound.shared.setTension(1) }
        let txt = GC.fmtTime(rem)
        if txt != timeText { timeText = txt }
        if rem <= 0 && phase == .running { timeUp() }
    }

    private func timeUp() {
        phase = .ready
        ring.set(1)
        ring.light(8)
        egg.setStep(8)
        Sound.shared.stopMusic(fade: 1.5)
        if settings.hatchMode == "auto" { hatch(); return }
        // hatch waits for you: a gentle, wordless "come see!"
        egg.setReady(true)
        Sound.shared.ready()
        hatchText = "Tap the egg!"
        showHatchPill = true
        showTapHint = true
        knockTask = Task { @MainActor [weak self] in
            for _ in 0..<60 {
                await GC.sleep(5)
                guard let self, !Task.isCancelled, !self.ended, self.phase == .ready else { return }
                Sound.shared.knock()
            }
        }
    }

    private func pickFriend() -> (node: VNode, name: String, animalId: String?) {
        let photos = app?.photos ?? []
        let who = settings.hatchWho
        let usePhoto = !photos.isEmpty && (who == "photos" || (who == "both" && Double.random(in: 0..<1) < 0.4))
        if usePhoto {
            let p = GC.pick(photos)
            return (Animals.renderPhoto(p.image), "Peekaboo!", nil)
        }
        let id = app?.bag.next() ?? GC.pick(Packs.classic.starterFriends.sorted())
        let a = Animals.byId[id] ?? Animals.list[0]
        return (Animals.render(a), a.name, a.id)
    }

    func hatch() {
        guard !ended, phase != .hatching, phase != .hatched else { return }
        if phase == .paused { setPaused(false) }
        phase = .hatching
        knockTask?.cancel()
        Sound.shared.stopMusic(fade: 0.4)
        showTapHint = false
        showHatchPill = false
        closeTray()
        scene.ringLayer.play([KF(opacity: 1), KF(opacity: 0.25)], duration: 0.8, fill: true)
        let friend = pickFriend()
        let s = settings
        // a song that isn't owned (e.g. after a refund) plays Egg karaoke
        let endSound = app?.gate.effectiveEndSound(s.endSound) ?? Packs.defaultEndSound
        // tapping the friend: it says hello in its own voice
        egg.onCheer = {
            if let id = friend.animalId, Sound.shared.friendCall(id) > 0 { return }
            Sound.shared.cheer()
        }
        Task { @MainActor in
            await egg.hatch(friend: friend.node, style: s.hatchStyle) {
                Sound.shared.pop()
                GC.after(0.12) { Sound.shared.endTune(endSound, friend: friend.animalId) }
            }
            guard !ended else { return }
            phase = .hatched
            hatchText = friend.animalId != nil ? "It's \(GC.aName(friend.name))!" : friend.name
            showHatchPill = true
            if let id = friend.animalId {
                app?.book = Store.addToBook(id)
            }
            // "It's a Fox!" in the recorded voice ("Peekaboo!" for a photo)
            if s.sayName {
                GC.after(0.5) { [weak self] in
                    guard self?.ended == false else { return }
                    Sound.shared.sayFriend(animalId: friend.animalId, name: friend.name)
                }
            }
            if s.nextUp.on && (!s.nextUp.text.isEmpty || s.nextUp.photo != nil) {
                GC.after(2.2) { [weak self] in if self?.ended == false { self?.showNextCard = true } }
            }
            GC.after(3) { [weak self] in if self?.ended == false { self?.showAgain = true } }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    /// Grown-up "Hatch now": jump to time's up, then hatch.
    func hatchNow() {
        guard phase == .running || phase == .paused || phase == .ready else { return }
        if phase == .paused { setPaused(false) }
        if phase == .running {
            endAt = RunController.wall
            tick()
        }
        if phase == .ready { hatch() }
    }

    func togglePause() { setPaused(phase != .paused) }

    func setPaused(_ on: Bool) {
        if on && phase == .running {
            remainingWhenPaused = max(0, endAt - RunController.wall)
            phase = .paused
            egg.setPaused(true)
            Sound.shared.pauseMusic()
            let z1 = VNode(.text("z", size: 34, at: CGPoint(x: 52, y: -150))).looping(Loops.zz())
            let z2 = VNode(.text("z", size: 26, at: CGPoint(x: 70, y: -176))).looping(Loops.zz(delay: -1.2))
            zz = [z1, z2]
            egg.fx.add(zz)
            scene.ringLayer.opacity = 0.55
        } else if !on && phase == .paused {
            endAt = RunController.wall + remainingWhenPaused
            phase = .running
            egg.setPaused(false)
            for z in zz { z.removeFromParent() }
            zz = []
            scene.ringLayer.opacity = 1
            Sound.shared.resumeMusic()
        }
        tick() // show the exact frozen time straight away
    }

    func adjust(_ seconds: Double) {
        guard phase == .running || phase == .paused else { return }
        let rem = remaining
        let next = max(5, rem + seconds)
        let delta = next - rem
        total = max(next, total + delta)
        if phase == .paused { remainingWhenPaused = next } else { endAt = RunController.wall + next }
        if next > 30 { Sound.shared.setTension(0) }
        timeBump += 1
        tick()
    }

    // MARK: grown-up tray

    func openTray() {
        trayOpen = true
        armTray()
    }

    func closeTray() {
        trayOpen = false
        trayTask?.cancel()
    }

    /// the tray closes itself after 9 s without a touch
    func armTray() {
        trayTask?.cancel()
        trayTask = Task { @MainActor [weak self] in
            await GC.sleep(9)
            guard !Task.isCancelled else { return }
            self?.trayOpen = false
        }
    }

    func flashLockTip(_ seconds: Double = 2) {
        showLockTip = true
        GC.after(seconds) { [weak self] in self?.showLockTip = false }
    }

    // MARK: touches on the stage (egg-local coordinates)

    func touch(eggLocal p: CGPoint) {
        guard !ended else { return }
        if egg.friend != nil {
            if CGRect(x: -90, y: -160, width: 180, height: 220).contains(p) { egg.cheer() }
            return
        }
        // during "ready", a tap anywhere hatches — easiest possible target
        if phase == .ready { hatch(); return }
        if Egg.bodyRect.insetBy(dx: -12, dy: -12).contains(p) { egg.boop() }
    }

    func end() {
        guard !ended else { return }
        ended = true
        timer?.invalidate()
        timer = nil
        knockTask?.cancel()
        trayTask?.cancel()
        egg.disposed = true
        Sound.shared.stopMusic(fade: 0.3)
        Sound.shared.stopCelebration(fade: 0.3)
        Sound.shared.releaseMedia()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

@Observable
@MainActor
final class AppModel {
    /// saved by RootView whenever it changes
    var settings: Settings
    var book: [String: Int] = Store.book()
    var photos: [PhotoItem] = PhotoStore.list()
    var run: RunController?
    var sheet: SheetKind?
    /// The Whole Nest paywall (behind the parental gate), shown over a sheet
    var paywall: PaywallPlacement?
    /// StoreKit: what this family owns
    let store = EntitlementStore()
    private(set) var setupScene: BuiltScene
    /// the egg sitting in the middle of the setup dial
    private(set) var dialEgg: Egg

    @ObservationIgnored let bag: ShuffleBag
    @ObservationIgnored let sceneBag: ShuffleBag
    @ObservationIgnored private var pendingScene: String
    @ObservationIgnored private var thumbs: [String: VNode] = [:]

    init() {
        let s = Store.loadSettings()
        settings = s
        // until StoreKit answers (a moment after launch), go by what it said last time
        let gate = FeatureGate(ownsWholeNest: EntitlementStore.lastKnownHasNest)
        bag = ShuffleBag(key: "gc.bag.v1", items: gate.friendPool)
        let sb = ShuffleBag(key: "gc.scenebag.v1", items: gate.scenePool)
        sceneBag = sb
        let pending = gate.effectiveScene(s.scene) == "random" ? sb.next() : s.scene
        pendingScene = pending
        setupScene = Scenes.build(pending)
        dialEgg = AppModel.buildDialEgg()
        Sound.shared.setVolume(s.volume)
        #if DEBUG
        assert(Set(Packs.allFriends) == Set(Animals.list.map(\.id)), "Packs.swift and Animals.list disagree")
        assert(Set(Packs.allScenes) == Set(Scenes.list.map(\.id)), "Packs.swift and Scenes.list disagree")
        #endif
    }

    // MARK: The Whole Nest

    var gate: FeatureGate { store.gate }

    /// After a purchase, restore, refund or family-sharing change: the
    /// shuffles only ever hold what this family owns.
    func applyOwnership() {
        let g = gate
        bag.setItems(g.friendPool)
        sceneBag.setItems(g.scenePool)
        if run == nil {
            // the next world must be one this family owns (and the one they picked, if they own it)
            let sc = g.effectiveScene(settings.scene)
            let stale = sc == "random" ? !g.scene(pendingScene) : pendingScene != sc
            if stale { chooseScene() }
        }
    }

    /// Open the paywall (the parental gate comes first).
    func askForNest(_ placement: PaywallPlacement) {
        guard !store.hasWholeNest else { return }
        MonetizationLog.event("locked_tap", ["placement": placement.rawValue])
        paywall = placement
    }

    /// The egg in the middle of the setup dial (dial units: the ring is 136 from the centre).
    static func buildDialEgg() -> Egg {
        let egg = Egg(x: 0, y: -4, scale: 0.6)
        egg.onBoop = { Sound.shared.boop() }
        return egg
    }

    var sceneBackground: Color { Color(hex: (run?.scene.scene ?? setupScene.scene).bg) }

    /// Pick the next world (shuffled when set to "Surprise me").
    func chooseScene() {
        let sc = gate.effectiveScene(settings.scene)
        pendingScene = sc == "random" ? sceneBag.next() : sc
        setupScene = Scenes.build(pendingScene)
    }

    func startRun() {
        Sound.shared.ensure()
        let r = RunController(app: self, sceneId: pendingScene)
        sheet = nil
        run = r
        r.start()
    }

    func stopToSetup() {
        run?.end()
        run = nil
        chooseScene()
        dialEgg = AppModel.buildDialEgg()
    }

    func restartSame() {
        run?.end()
        run = nil
        let sc = gate.effectiveScene(settings.scene)
        pendingScene = sc == "random" ? sceneBag.next() : sc
        startRun()
    }

    // MARK: setup controls (the egg-timer dial)

    /// One full turn of the dial is 60 minutes. Twisting (or tapping) the ring
    /// sets whole minutes; the − / + buttons step 15 s below 3 minutes and
    /// 1 minute above, so short timers can still be fine-tuned.
    static let minSecs = 15
    static let maxSecs = 3600

    /// the length set on the dial, in seconds
    var setupSeconds: Int { settings.minutes * 60 + settings.seconds }

    /// Set the timer length (clamped to 15 s … 60 min). False when nothing changed.
    @discardableResult
    func setTotal(_ secs: Int) -> Bool {
        let t = min(AppModel.maxSecs, max(AppModel.minSecs, secs))
        if t == setupSeconds { return false }
        settings.minutes = t / 60
        settings.seconds = t % 60
        return true
    }

    /// One step of the − / + buttons. False at the end of the range.
    @discardableResult
    func stepTime(_ dir: Int) -> Bool {
        let t = setupSeconds
        let fine = dir > 0 ? t < 180 : t <= 180
        let unit = fine ? 15 : 60
        // snap to the step grid first, so 0:10 + goes to 0:15 and 4:30 − goes to 4:00
        let next: Int
        if dir > 0 {
            next = (t / unit) * unit + unit
        } else {
            next = ((t + unit - 1) / unit) * unit - unit
        }
        return setTotal(next)
    }

    // MARK: photos

    func addPhotos(_ images: [UIImage]) {
        // free tier: one photo friend; photos already here always stay
        let room = gate.photosLeft(liveCount: photos.count) ?? images.count
        let images = Array(images.prefix(room))
        for img in images { PhotoStore.add(img) }
        photos = PhotoStore.list()
        if !images.isEmpty && settings.hatchWho == "animals" { settings.hatchWho = "both" }
    }

    func removePhoto(_ p: PhotoItem) {
        PhotoStore.remove(p.id)
        photos = PhotoStore.list()
    }

    func setNextUpPhoto(_ image: UIImage) {
        if let old = settings.nextUp.photo { PhotoStore.remove(old) }
        settings.nextUp.photo = PhotoStore.add(image, size: 240, prefix: "next")
    }

    func resetBook() {
        Store.resetBook()
        book = [:]
        sheet = nil
    }

    func resetSettings() {
        settings = Settings()
        Sound.shared.setVolume(settings.volume)
        sheet = nil
        chooseScene()
    }

    /// A still thumbnail of a world with an egg, for the world picker.
    func thumbnail(_ id: String) -> VNode {
        if let t = thumbs[id] { return t }
        let b = Scenes.build(id, particles: false)
        let egg = Egg(x: Scenes.egg.x, y: Scenes.egg.y)
        b.eggLayer.add(egg.root)
        b.root.walk { $0.loop = nil }
        thumbs[id] = b.root
        return b.root
    }
}

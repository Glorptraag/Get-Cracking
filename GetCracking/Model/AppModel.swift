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
            nCircle(0, 0, 13, St.o(5).filled("#fdf3e4")),
            nPath("M0,-4 C-2,-16 -14,-18 -16,-12 C-12,-6 -4,-4 0,-4 Z M0,-4 C2,-16 14,-18 16,-12 C12,-6 4,-4 0,-4 Z", St.o(3).filled("#a9d36b")),
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
        let id = app?.bag.next() ?? GC.pick(Animals.list).id
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
        egg.onCheer = { Sound.shared.cheer() }
        Task { @MainActor in
            await egg.hatch(friend: friend.node, style: s.hatchStyle) {
                Sound.shared.pop()
                GC.after(0.12) { Sound.shared.endTune(s.endSound) }
            }
            guard !ended else { return }
            phase = .hatched
            hatchText = friend.animalId != nil ? "It's a \(friend.name)!" : friend.name
            showHatchPill = true
            if let id = friend.animalId {
                app?.book = Store.addToBook(id)
                if s.sayName { GC.after(0.5) { Sound.shared.say("It's a \(friend.name)!") } }
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
    private(set) var setupScene: BuiltScene
    private(set) var perchRoot: VNode
    private(set) var perchEgg: Egg

    @ObservationIgnored let bag: ShuffleBag
    @ObservationIgnored let sceneBag: ShuffleBag
    @ObservationIgnored private var pendingScene: String
    @ObservationIgnored private var thumbs: [String: VNode] = [:]

    init() {
        let s = Store.loadSettings()
        settings = s
        bag = ShuffleBag(key: "gc.bag.v1", items: Animals.list.map(\.id))
        let sb = ShuffleBag(key: "gc.scenebag.v1", items: Scenes.list.map(\.id))
        sceneBag = sb
        let pending = s.scene == "random" ? sb.next() : s.scene
        pendingScene = pending
        setupScene = Scenes.build(pending)
        let (root, egg) = AppModel.buildPerch()
        perchRoot = root
        perchEgg = egg
        Sound.shared.setVolume(s.volume)
    }

    static func buildPerch() -> (VNode, Egg) {
        let root = VNode()
        root.add(nGroup([
            nEllipse(0, -2, 86, 20, St.o(6).filled("#b98652")),
            nPath("M-74,-6 Q-30,8 10,-4 T76,-6 M-60,6 Q-10,-8 40,6 T80,0", St.line("#8a5a3b", 4)),
        ]))
        let egg = Egg(x: 0, y: 4, scale: 0.92)
        egg.onBoop = { Sound.shared.boop() }
        root.add(egg.root)
        root.add(nPath("M-84,-2 Q-40,22 0,18 Q40,22 84,-2 Q60,20 0,22 Q-60,20 -84,-2 Z", St.o(5).filled("#b98652")))
        root.add(nPath("M-70,6 L-50,0 M-30,12 L-8,6 M20,12 L44,6 M56,6 L74,0", St.line("#8a5a3b", 4)))
        return (root, egg)
    }

    var sceneBackground: Color { Color(hex: (run?.scene.scene ?? setupScene.scene).bg) }

    /// Pick the next world (shuffled when set to "Surprise me").
    func chooseScene() {
        pendingScene = settings.scene == "random" ? sceneBag.next() : settings.scene
        setupScene = Scenes.build(pendingScene)
    }

    func newPerch() {
        let (root, egg) = AppModel.buildPerch()
        perchRoot = root
        perchEgg = egg
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
        newPerch()
    }

    func restartSame() {
        run?.end()
        run = nil
        pendingScene = settings.scene == "random" ? sceneBag.next() : settings.scene
        startRun()
    }

    // MARK: setup controls

    func bumpMinutes() {
        settings.minutes = (settings.minutes + 1) % 61
        if settings.minutes == 0 && settings.seconds == 0 { settings.seconds = 30 }
    }

    func bumpSeconds() {
        settings.seconds = (settings.seconds + 15) % 60
        if settings.minutes == 0 && settings.seconds == 0 { settings.seconds = 15 }
    }

    func setMinutes(_ m: Int) {
        settings.minutes = m
        if m == 0 && settings.seconds == 0 { settings.seconds = 30 }
    }

    func preset(_ m: Int) {
        settings.minutes = m
        settings.seconds = 0
    }

    // MARK: photos

    func addPhotos(_ images: [UIImage]) {
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
    }

    func resetSettings() {
        settings = Settings()
        Sound.shared.setVolume(settings.volume)
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

import SwiftUI

/// "Who's in the egg?" — set the time on the egg-timer dial and press Start
/// (web 2f810aa: the dial, − / + in its corners, quick times, a plain Start).
struct SetupView: View {
    @Environment(AppModel.self) private var model
    @State private var contentHeight: CGFloat = 800
    @State private var timeBump = false

    private static let quickTimes = [1, 2, 5, 10, 15, 30]

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width * 0.92, 420)
            let avail = geo.size.height
            let scale = min(1, avail / max(contentHeight, 1))
            ZStack(alignment: .top) {
                StageView(root: model.setupScene.root, viewBox: Scenes.fullViewBox, slice: true)
                    .blur(radius: 2)
                    .saturation(0.85)
                    .scaleEffect(1.06)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .allowsHitTesting(false)
                Color(red: 70 / 255, green: 62 / 255, blue: 60 / 255).opacity(0.42)
                    .allowsHitTesting(false)

                content
                    .frame(width: width)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: HeightKey.self, value: g.size.height)
                    })
                    .scaleEffect(scale, anchor: .top)
                    .offset(y: max(0, (avail - contentHeight * scale) / 2))
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
            .onPreferenceChange(HeightKey.self) { contentHeight = $0 }
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        VStack(spacing: 14) {
            Text("Who's in the egg?")
                .font(Theme.hand(28))
                .foregroundStyle(Theme.out)
                .padding(.horizontal, 31).padding(.top, 7).padding(.bottom, 8)
                .toy(Theme.pill, radius: 40, border: 5, depth: 5)
                .accessibilityAddTraits(.isHeader)

            timerBox

            startButton
                .padding(.top, 4)

            HStack(spacing: 12) {
                ToySwitch(isOn: Binding(get: { model.settings.hatchMode == "tap" },
                                        set: { model.settings.hatchMode = $0 ? "tap" : "auto" }))
                OutlinedText(text: model.settings.hatchMode == "tap" ? "Hatch waits for a tap" : "Hatches by itself")
            }
            .frame(minHeight: 44)
            .accessibilityElement(children: .combine)

            HStack(spacing: 10) {
                iconButton("tree", "World", a11y: "Choose world", .world)
                iconButton("notes", "Music", a11y: "Choose music", .sound)
                iconButton("book", "Friends", a11y: "Friend book", .book)
                iconButton("gear", "Settings", a11y: "Grown-up settings", .settings)
            }
        }
        .padding(.top, 64)
        .padding(.bottom, 44)
    }

    // MARK: the timer box: the dial with − / + in its corners, and quick times

    private var timerBox: some View {
        let t = model.totalSecs
        return VStack(spacing: 12) {
            TimerDial(timeBump: timeBump)
                .overlay(alignment: .bottomLeading) {
                    RepeatButton(icon: "minus", label: "Less time", enabled: t > TimeDial.minSecs) { model.stepTime(-1) }
                }
                .overlay(alignment: .bottomTrailing) {
                    RepeatButton(icon: "plus", label: "More time", enabled: t < TimeDial.maxSecs) { model.stepTime(1) }
                }
            HStack(spacing: 6) {
                ForEach(Self.quickTimes, id: \.self) { m in
                    let on = t == m * 60
                    Button {
                        if model.setTotal(m * 60) { pulse() }
                    } label: {
                        Text("\(m)")
                            .font(Theme.round(21, .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ToyButtonStyle(fill: on ? Theme.gold : Theme.cream, radius: 16, border: 4, depth: 5))
                    .accessibilityLabel("\(m) minute\(m == 1 ? "" : "s")")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.bottom, 5)
        }
        .padding(.top, 14).padding(.horizontal, 14).padding(.bottom, 26)
        .frame(maxWidth: .infinity)
        .background(
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.out).offset(y: 8)
                RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.tealDark)
                RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.teal).padding(.bottom, 12)
                RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Theme.out, lineWidth: 6)
            }
        )
    }

    private func pulse() {
        withAnimation(.easeOut(duration: 0.1)) { timeBump = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.1)) { timeBump = false }
        }
    }

    // MARK: Start and the option buttons

    private static let playNode = nPath("M15 9.5 C15 7.5 17 6.5 18.7 7.5 L39 21.5 C40.6 22.6 40.6 25.4 39 26.5 L18.7 40.5 C17 41.5 15 40.5 15 38.5 Z",
                                        St(fill: "#fdf3e4", stroke: GC.outHex, width: 4.5, join: .round))

    private var startButton: some View {
        Button {
            model.startRun()
        } label: {
            HStack(spacing: 14) {
                StageView(root: Self.playNode, viewBox: Icons.box, animated: false)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                Text("Start")
                    .font(Theme.hand(46))
                    .tracking(4.6)
                    .foregroundStyle(Theme.out)
            }
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .contentShape(Rectangle())
        }
        .buttonStyle(StartButtonStyle())
        .accessibilityLabel("Start the timer")
    }

    private func iconButton(_ icon: String, _ label: String, a11y: String, _ kind: SheetKind) -> some View {
        Button {
            model.sheet = kind
        } label: {
            VStack(spacing: 1) {
                IconView(name: icon, size: 38)
                Text(label).font(Theme.hand(16))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .contentShape(Rectangle())
        }
        .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 20, border: 4, depth: 5))
        .accessibilityLabel(a11y)
    }
}

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// The egg-timer dial: twist or tap the ring to set whole minutes (one full
/// turn is 60), with the egg in the middle. The egg stays tappable.
struct TimerDial: View {
    @Environment(AppModel.self) private var model
    var timeBump = false
    @State private var touching = false
    @State private var dragging = false

    private static let box = CGRect(x: -170, y: -170, width: 340, height: 340)

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            let u = d / 340
            let t = model.totalSecs
            let f = TimeDial.fraction(t)
            let k = TimeDial.knob(t)
            let ring = CGFloat(TimeDial.radius * 2) * u
            let ease: Animation? = dragging || GC.reduceMotion ? nil : .easeOut(duration: 0.12)
            ZStack {
                Circle().stroke(Theme.out, lineWidth: 42 * u).frame(width: ring, height: ring)
                Circle().stroke(Theme.cream, lineWidth: 30 * u).frame(width: ring, height: ring)
                Circle().trim(from: 0, to: f)
                    .stroke(Theme.gold, style: StrokeStyle(lineWidth: 30 * u, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: ring, height: ring)
                    .animation(ease, value: f)
                Canvas { ctx, size in
                    // a dot for every minute, a bigger one every five
                    for i in 0..<60 {
                        let a = Double(i) / 60 * 2 * .pi, big = i % 5 == 0
                        let r = (big ? 3.6 : 1.7) * u
                        let x = size.width / 2 + CGFloat(sin(a) * TimeDial.radius) * u
                        let y = size.height / 2 - CGFloat(cos(a) * TimeDial.radius) * u
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)),
                                 with: .color(Theme.out.opacity(big ? 0.5 : 0.28)))
                    }
                }
                Circle().fill(Theme.cream).frame(width: CGFloat(TimeDial.radius - 21) * 2 * u, height: CGFloat(TimeDial.radius - 21) * 2 * u)
                StageView(root: model.perchRoot, viewBox: Self.box)
                    .allowsHitTesting(false)
                Text(GC.fmtTime(Double(t)))
                    .font(Theme.round(60 * u, .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .scaleEffect(timeBump ? 1.12 : 1)
                    .position(x: d / 2, y: d / 2 + 58 * u)
                knob(u)
                    .offset(x: CGFloat(k.x) * u, y: CGFloat(k.y) * u)
                    .animation(ease, value: t)
            }
            .frame(width: d, height: d)
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let first = !touching
                    let at = first ? g.startLocation : g.location
                    let x = Double((at.x - d / 2) / u), y = Double((at.y - d / 2) / u)
                    let p = TimeDial.touch(x, y)
                    if first {
                        touching = true
                        if TimeDial.onRing(p.dist) {
                            dragging = true
                            turn(to: p.minutes, first: true)
                        } else if Self.eggArea.contains(CGPoint(x: x, y: y)) {
                            model.perchEgg.boop()
                        }
                    } else if dragging {
                        turn(to: p.minutes, first: false)
                    }
                }
                .onEnded { _ in
                    touching = false
                    dragging = false
                })
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timer length")
        .accessibilityValue(TimeDial.spoken(model.totalSecs))
        .accessibilityHint("Swipe up or down to change it")
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: model.stepTime(1)
            case .decrement: model.stepTime(-1)
            @unknown default: break
            }
        }
    }

    /// the egg in the middle (0.6 scale at 0, -4), in the dial's box
    private static let eggArea = CGRect(x: -42, y: -110, width: 84, height: 112)

    private func turn(to minutes: Int, first: Bool) {
        let m = TimeDial.ringMinutes(minutes, currentSecs: model.totalSecs, first: first)
        model.setTotal(m * 60)
    }

    private func knob(_ u: CGFloat) -> some View {
        ZStack {
            Circle().fill(Theme.out).frame(width: 48 * u, height: 48 * u)
            Circle().fill(Theme.cream).frame(width: 36 * u, height: 36 * u)
            Circle().fill(Theme.gold).frame(width: 16 * u, height: 16 * u)
            Circle().strokeBorder(Theme.out, lineWidth: 3.5 * u).frame(width: 19.5 * u, height: 19.5 * u)
        }
        .shadow(color: Theme.out.opacity(0.35), radius: 0, x: 0, y: 4 * u)
        .allowsHitTesting(false)
    }
}

/// − / + in the dial's corners: one step per tap, repeating while held
/// (slow at first, then faster), like the web's `repeatable()`.
struct RepeatButton: View {
    let icon: String
    let label: String
    let enabled: Bool
    let action: () -> Bool

    @GestureState private var pressed = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        IconView(name: icon, size: 34)
            .frame(width: 56, height: 56)
            .background(ToyBackground(fill: Theme.cream, radius: 28, border: 4, depth: pressed && enabled ? 1 : 5))
            .offset(y: pressed && enabled ? 4 : 0)
            .opacity(enabled ? 1 : 0.45)
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).updating($pressed) { _, state, _ in state = true })
            .onChange(of: pressed) { _, on in
                if on { start() } else { stop() }
            }
            .onDisappear { stop() }
            .animation(.easeOut(duration: 0.08), value: pressed)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if enabled { _ = action() } }
    }

    private func start() {
        stop()
        guard enabled else { return }
        _ = action()
        task = Task { @MainActor in
            var delay = 0.42
            while true {
                await GC.sleep(delay)
                if Task.isCancelled || !action() { return }
                delay = max(0.07, delay * 0.8)
            }
        }
    }

    private func stop() {
        task?.cancel()
        task = nil
    }
}

/// The plain, full-width Start button: leaf green, sinks onto its shadow.
struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        configuration.label
            .background(
                ZStack(alignment: .bottom) {
                    shape.fill(Theme.out).offset(y: pressed ? 3 : 8)
                    shape.fill(Theme.leafDark)
                    shape.fill(Theme.leaf).padding(.bottom, 10)
                    shape.strokeBorder(Theme.out, lineWidth: 6)
                }
            )
            .offset(y: pressed ? 5 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

/// Buttons that just nudge down when pressed (their art draws its own shadow).
struct PressDown: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

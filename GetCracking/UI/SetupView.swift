import SwiftUI

/// "Who's in the egg?" — set the time on the egg-timer dial and press Start.
struct SetupView: View {
    @Environment(AppModel.self) private var model
    @State private var contentHeight: CGFloat = 800
    @State private var timeBump = 0

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
                .padding(.horizontal, 26).padding(.vertical, 6)
                .toy(Theme.pill, radius: 40, border: 5, depth: 5)
                .accessibilityAddTraits(.isHeader)

            timerBox

            startButton
                .padding(.top, 4)

            // the label says what the switch does in both positions
            let tap = model.settings.hatchMode == "tap"
            HStack(spacing: 12) {
                ToySwitch(isOn: Binding(get: { model.settings.hatchMode == "tap" },
                                        set: { model.settings.hatchMode = $0 ? "tap" : "auto" }))
                OutlinedText(text: tap ? "Hatch waits for a tap" : "Hatches by itself")
            }
            .frame(minHeight: 44)
            .padding(.top, 2)
            .accessibilityElement(children: .combine)

            HStack(spacing: 10) {
                iconButton("tree", "World", .world)
                iconButton("notes", "Music", .sound)
                iconButton("book", "Friends", .book)
                iconButton("gear", "Settings", .settings)
            }
        }
        .padding(.top, 54)
        .padding(.bottom, 30)
    }

    // MARK: the timer box: the dial and the quick times

    private var timerBox: some View {
        let t = model.totalSecs
        return VStack(spacing: 12) {
            EggDial(timeBump: timeBump)
                .overlay(alignment: .bottomLeading) {
                    stepButton("minus", label: "Less time", dir: -1, disabled: t <= AppModel.minSecs)
                }
                .overlay(alignment: .bottomTrailing) {
                    stepButton("plus", label: "More time", dir: 1, disabled: t >= AppModel.maxSecs)
                }
            HStack(spacing: 6) {
                ForEach([1, 2, 5, 10, 15, 30], id: \.self) { m in
                    let on = m * 60 == t
                    Button {
                        Sound.shared.ensure()
                        if model.setTotal(m * 60) { timeBump += 1 }
                    } label: {
                        Text("\(m)")
                            .font(Theme.round(21, .bold))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .padding(.bottom, 2)
                    }
                    .buttonStyle(ToyButtonStyle(fill: on ? Theme.gold : Theme.cream, radius: 16, border: 4, depth: 5))
                    .accessibilityLabel(m == 1 ? "1 minute" : "\(m) minutes")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
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

    /// − / + in the dial's corners: 15 s steps under 3 minutes, 1 minute above; repeats while held
    private func stepButton(_ icon: String, label: String, dir: Int, disabled: Bool) -> some View {
        RepeatButton(disabled: disabled, action: { model.stepTime(dir) }) {
            IconView(name: icon, size: 34)
                .frame(width: 56, height: 56)
                .background(ToyBackground(fill: Theme.cream, radius: 28, border: 4, depth: 5))
        }
        .opacity(disabled ? 0.45 : 1)
        .accessibilityLabel(label)
    }

    private var startButton: some View {
        Button {
            model.startRun()
        } label: {
            HStack(spacing: 14) {
                StageView(root: SetupView.startIcon, viewBox: Icons.box, animated: false)
                    .frame(width: 44, height: 44)
                Text("Start")
                    .font(Theme.hand(46))
                    .tracking(4.6)
                    .foregroundStyle(Theme.out)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .padding(.bottom, 8)
        }
        .buttonStyle(StartButtonStyle())
        .accessibilityLabel("Start the timer")
    }

    /// the play triangle on the Start button
    private static let startIcon = nPath("M15 9.5 C15 7.5 17 6.5 18.7 7.5 L39 21.5 C40.6 22.6 40.6 25.4 39 26.5 L18.7 40.5 C17 41.5 15 40.5 15 38.5 Z",
                                         St(fill: "#fdf3e4", stroke: GC.outHex, width: 4.5, join: .round))

    private func iconButton(_ icon: String, _ label: String, _ kind: SheetKind) -> some View {
        Button {
            model.sheet = kind
        } label: {
            VStack(spacing: 1) {
                IconView(name: icon, size: 38)
                Text(label).font(Theme.hand(16))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
        }
        .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 20, border: 4, depth: 5))
        .accessibilityLabel(label)
    }
}

/// The egg-timer dial. One full turn of the ring is 60 minutes: drag (or
/// tap) the ring to set whole minutes. The egg in the middle can be booped.
/// Drawn in the web dial's 340-unit box, centred on (0, 0).
struct EggDial: View {
    @Environment(AppModel.self) private var model
    let timeBump: Int
    @State private var dragging = false
    @State private var onRing = false
    @State private var bumped = false

    init(timeBump: Int = 0) { self.timeBump = timeBump }

    private static let R: CGFloat = 136
    private static let box = CGRect(x: -170, y: -170, width: 340, height: 340)

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let k = side / 340
            let t = model.totalSecs
            let f = GC.clamp(Double(t) / Double(AppModel.maxSecs), 0, 1)
            let a = f * 2 * Double.pi
            let R = EggDial.R
            let c = side / 2
            ZStack {
                Circle().stroke(Theme.out, lineWidth: 42 * k)
                    .frame(width: 2 * R * k, height: 2 * R * k)
                Circle().stroke(Theme.cream, lineWidth: 30 * k)
                    .frame(width: 2 * R * k, height: 2 * R * k)
                Circle().trim(from: 0, to: CGFloat(f))
                    .stroke(Theme.gold, style: StrokeStyle(lineWidth: 30 * k, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 2 * R * k, height: 2 * R * k)
                    .animation(dragging ? nil : .easeOut(duration: 0.12), value: f)
                Canvas { ctx, _ in
                    for i in 0..<60 {
                        let ang = Double(i) / 60 * 2 * Double.pi
                        let big = i % 5 == 0
                        let r: CGFloat = big ? 3.6 : 1.7
                        let x = c + CGFloat(sin(ang)) * R * k, y = c - CGFloat(cos(ang)) * R * k
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r * k, y: y - r * k, width: 2 * r * k, height: 2 * r * k)),
                                 with: .color(Theme.out.opacity(big ? 0.5 : 0.28)))
                    }
                }
                Circle().fill(Theme.cream)
                    .frame(width: 2 * (R - 21) * k, height: 2 * (R - 21) * k)
                Ellipse().fill(Theme.out.opacity(0.13))
                    .frame(width: 92 * k, height: 18 * k)
                    .position(x: c, y: c - 4 * k)
                StageView(root: model.dialEgg.root, viewBox: EggDial.box)
                Text(GC.fmtTime(Double(t)))
                    .font(Theme.round(60 * k, .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .scaleEffect(bumped ? 1.12 : 1)
                    .position(x: c, y: c + 59 * k)
                knob(k)
                    .position(x: c + CGFloat(sin(a)) * R * k, y: c - CGFloat(cos(a)) * R * k)
                    .animation(dragging ? nil : .easeOut(duration: 0.12), value: t)
            }
            .frame(width: side, height: side)
            .contentShape(Circle().inset(by: -14 * k))
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in touch(g.location, side: side, k: k) }
                .onEnded { g in
                    // a tap on the egg (not the ring) boops it
                    if !onRing && hypot(g.translation.width, g.translation.height) < 10 {
                        if polar(g.location, side: side, k: k).dist < R - 26 { model.dialEgg.boop() }
                    }
                    dragging = false
                    onRing = false
                })
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: timeBump) { _, _ in
            withAnimation(.easeOut(duration: 0.1)) { bumped = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.easeIn(duration: 0.1)) { bumped = false } }
        }
        .accessibilityElement()
        .accessibilityLabel("Timer length")
        .accessibilityValue(spoken(model.totalSecs))
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: model.stepTime(1)
            case .decrement: model.stepTime(-1)
            @unknown default: break
            }
        }
    }

    private func knob(_ k: CGFloat) -> some View {
        ZStack {
            Circle().fill(Theme.out).frame(width: 48 * k, height: 48 * k)
            Circle().fill(Theme.cream).frame(width: 36 * k, height: 36 * k)
            Circle().fill(Theme.gold).frame(width: 16 * k, height: 16 * k)
                .overlay(Circle().stroke(Theme.out, lineWidth: 3.5 * k))
        }
        .shadow(color: Theme.out.opacity(0.35), radius: 0, x: 0, y: 4 * k)
        .allowsHitTesting(false)
    }

    /// distance from the centre (in dial units) and the minute under the finger
    private func polar(_ p: CGPoint, side: CGFloat, k: CGFloat) -> (dist: CGFloat, min: Int) {
        let x = p.x - side / 2, y = p.y - side / 2
        var a = atan2(Double(x), Double(-y))
        if a < 0 { a += 2 * Double.pi }
        return (hypot(x, y) / max(k, 0.0001), Int((a / (2 * Double.pi) * 60).rounded()))
    }

    private func touch(_ loc: CGPoint, side: CGFloat, k: CGFloat) {
        let p = polar(loc, side: side, k: k)
        if !dragging {
            dragging = true
            // only the ring itself turns the dial; the egg stays tappable
            onRing = p.dist >= EggDial.R - 26 && p.dist <= EggDial.R + 40
            guard onRing else { return }
            Sound.shared.ensure()
            apply(p.min, first: true)
        } else if onRing {
            apply(p.min, first: false)
        }
    }

    private func apply(_ minute: Int, first: Bool) {
        var m = minute
        let cur = Double(model.totalSecs) / 60
        // 0 and 60 share the top of the ring: stay on whichever side we came from
        if m == 0 { m = cur > 30 ? 60 : 1 }
        if !first {
            if cur >= 45 && m <= 15 { m = 60 } // no wrapping past the top
            if cur <= 15 && m >= 45 { m = 1 }
        }
        model.setTotal(m * 60)
    }

    private func spoken(_ t: Int) -> String {
        let m = t / 60, s = t % 60
        return [m > 0 ? "\(m) minute\(m == 1 ? "" : "s")" : "", s > 0 ? "\(s) seconds" : ""]
            .filter { !$0.isEmpty }.joined(separator: " ")
    }
}

/// A button that repeats while held: slow at first, then fast. `action`
/// returns false when there is nothing more to do (e.g. at the limit).
struct RepeatButton<Label: View>: View {
    let disabled: Bool
    let action: () -> Bool
    let label: Label
    @State private var pressed = false
    @State private var task: Task<Void, Never>?

    init(disabled: Bool = false, action: @escaping () -> Bool, @ViewBuilder label: () -> Label) {
        self.disabled = disabled
        self.action = action
        self.label = label()
    }

    var body: some View {
        label
            .offset(y: pressed ? 3 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed, !disabled else { return }
                    pressed = true
                    start()
                }
                .onEnded { _ in stop() })
            .onDisappear { stop() }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if !disabled { _ = action() } }
    }

    private func start() {
        Sound.shared.ensure()
        guard action() else { return }
        let fn = action
        task = Task { @MainActor in
            var delay = 0.42
            while !Task.isCancelled {
                await GC.sleep(delay)
                if Task.isCancelled || !fn() { break }
                delay = max(0.07, delay * 0.8)
            }
        }
    }

    private func stop() {
        pressed = false
        task?.cancel()
        task = nil
    }
}

/// The plain, full-width Start button: it sinks onto its shadow when pressed.
struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        return configuration.label
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

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
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

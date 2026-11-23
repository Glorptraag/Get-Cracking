import SwiftUI

/// "Who's in the egg?" — twist the egg-timer dial and press Start.
struct SetupView: View {
    @Environment(AppModel.self) private var model
    @State private var contentHeight: CGFloat = 800
    /// counts up when a quick-time button changed the time
    @State private var timeBump = 0

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width * 0.92, 420)
            let avail = geo.size.height
            let scale = min(1, avail / max(contentHeight, 1))
            // too tall for the screen (small phones, large text): shrink the whole column to fit
            ZStack(alignment: .top) {
                content(width: width)
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
        .background { backdrop }
    }

    /// the next world, blurred and dimmed, edge to edge behind everything
    private var backdrop: some View {
        ZStack {
            StageView(root: model.setupScene.root, viewBox: Scenes.fullViewBox, slice: true)
                .blur(radius: 2)
                .saturation(0.85)
                .scaleEffect(1.06)
            Color(red: 70 / 255, green: 62 / 255, blue: 60 / 255).opacity(0.42)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func content(width: CGFloat) -> some View {
        VStack(spacing: 14) {
            Text("Who's in the egg?")
                .font(Theme.hand(28))
                .foregroundStyle(Theme.out)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 26).padding(.vertical, 6)
                .toy(Theme.pill, radius: 40, border: 5, depth: 5)
                .accessibilityAddTraits(.isHeader)

            timerBox(width: width)

            startButton
                .padding(.top, 4)

            hatchToggle
                .padding(.top, 2)

            HStack(spacing: 10) {
                iconButton("tree", "World", "Choose world", .world)
                iconButton("notes", "Music", "Choose music", .sound)
                iconButton("book", "Friends", "Friend book", .book)
                iconButton("gear", "Settings", "Grown-up settings", .settings)
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    // MARK: the timer box: the dial and the quick times

    private func timerBox(width: CGFloat) -> some View {
        let side: CGFloat = max(120, width - 40)
        let corner: CGFloat = 32
        return VStack(spacing: 12) {
            EggDial(side: side, bump: timeBump)
            presets
        }
        .padding(.top, 20).padding(.horizontal, 20).padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Theme.out).offset(y: 8)
                RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Theme.tealDark)
                RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Theme.teal).padding(.bottom, 12)
                RoundedRectangle(cornerRadius: corner, style: .continuous).strokeBorder(Theme.out, lineWidth: 6)
            }
        )
    }

    private var presets: some View {
        let total = model.setupSeconds
        let quick: [Int] = [1, 2, 5, 10, 15, 30]
        return HStack(spacing: 6) {
            ForEach(quick, id: \.self) { m in
                let on = m * 60 == total
                Button {
                    Sound.shared.ensure()
                    if model.setTotal(m * 60) { timeBump += 1 }
                } label: {
                    Text("\(m)")
                        .font(Theme.round(21, .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.bottom, 2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(ToyButtonStyle(fill: on ? Theme.gold : Theme.cream, radius: 16, border: 4, depth: 5))
                .accessibilityLabel(m == 1 ? "1 minute" : "\(m) minutes")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    // MARK: start, the hatch toggle and the option row

    private var startButton: some View {
        Button {
            model.startRun()
        } label: {
            HStack(spacing: 14) {
                IconView("start", size: 44)
                Text("Start")
                    .font(Theme.hand(46))
                    .tracking(4.6)
                    .foregroundStyle(Theme.out)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 88)
        }
        .buttonStyle(StartButtonStyle())
        .accessibilityLabel("Start the timer")
    }

    private var hatchToggle: some View {
        let waits = model.settings.hatchMode == "tap"
        return HStack(spacing: 12) {
            ToySwitch(isOn: Binding(get: { model.settings.hatchMode == "tap" },
                                    set: { model.settings.hatchMode = $0 ? "tap" : "auto" }))
            // the label says what the current state does
            OutlinedText(text: waits ? "Hatch waits for a tap" : "Hatches by itself")
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    private func iconButton(_ icon: String, _ label: String, _ a11y: String, _ kind: SheetKind) -> some View {
        Button {
            model.sheet = kind
        } label: {
            VStack(spacing: 1) {
                IconView(icon, size: 38)
                Text(label)
                    .font(Theme.hand(16))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
        }
        .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 20, border: 4, depth: 5))
        .accessibilityLabel(a11y)
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

/// The plain, full-width Start button: leaf green with a darker lip, sinking
/// onto its shadow when pressed.
struct StartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let corner: CGFloat = 30
        let depth: CGFloat = pressed ? 3 : 8
        return configuration.label
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Theme.out).offset(y: depth)
                    RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Theme.leafDark)
                    RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Theme.leaf).padding(.bottom, 10)
                    RoundedRectangle(cornerRadius: corner, style: .continuous).strokeBorder(Theme.out, lineWidth: 6)
                }
            )
            .offset(y: pressed ? 5 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

// MARK: - the egg-timer dial

/// The egg-timer dial. One full turn of the ring is 60 minutes: twist (or tap)
/// the ring for whole minutes, or use − / + in the corners (15 s steps under
/// 3 minutes, 1 minute above, repeating while held). The egg sits in the middle.
///
/// Drawn in the web dial's units: 340 across, the ring 136 from the centre.
struct EggDial: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let side: CGFloat
    /// counts up when a quick-time button changed the time: the digits give a little bump
    var bump: Int = 0

    @State private var tracking = false
    @State private var dragging = false
    @State private var timeScale: CGFloat = 1

    private static let ringR: CGFloat = 136
    private static let viewBox = CGRect(x: -170, y: -170, width: 340, height: 340)

    var body: some View {
        let total = model.setupSeconds
        let canGoDown = total > AppModel.minSecs
        let canGoUp = total < AppModel.maxSecs
        face(total)
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(twist)
            .accessibilityElement()
            .accessibilityLabel("Timer length")
            .accessibilityValue(spoken(total))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: _ = model.stepTime(1)
                case .decrement: _ = model.stepTime(-1)
                @unknown default: break
                }
            }
            .overlay(alignment: .bottomLeading) {
                RepeatButton(icon: "minus", label: "Less time", enabled: canGoDown) { model.stepTime(-1) }
            }
            .overlay(alignment: .bottomTrailing) {
                RepeatButton(icon: "plus", label: "More time", enabled: canGoUp) { model.stepTime(1) }
            }
            // one soft click for every change, like the ticks of a real egg timer
            .sensoryFeedback(.selection, trigger: total)
            .onChange(of: bump) { _, _ in bumpDigits() }
    }

    private func face(_ total: Int) -> some View {
        let k: CGFloat = side / 340
        let fraction: CGFloat = min(1, max(0, CGFloat(total) / CGFloat(AppModel.maxSecs)))
        let angle: Double = Double(fraction) * 2 * Double.pi
        let r: CGFloat = EggDial.ringR * k
        let ring: CGFloat = 2 * r
        let knobX: CGFloat = CGFloat(sin(angle)) * r
        let knobY: CGFloat = -CGFloat(cos(angle)) * r
        let inner: CGFloat = 2 * (r - 21 * k)
        // the fill and the knob glide to a new time, but follow a finger exactly
        let glide: Animation? = (dragging || reduceMotion) ? nil : Animation.easeOut(duration: 0.12)

        return ZStack {
            Circle().stroke(Theme.out, lineWidth: 42 * k)
                .frame(width: ring, height: ring)
            Circle().stroke(Theme.cream, lineWidth: 30 * k)
                .frame(width: ring, height: ring)
            Circle().trim(from: 0, to: fraction)
                .stroke(Theme.gold, style: StrokeStyle(lineWidth: 30 * k, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: ring, height: ring)
                .animation(glide, value: total)
            DialTicks()
                .frame(width: side, height: side)
            Circle().fill(Theme.cream)
                .frame(width: inner, height: inner)
            Ellipse().fill(Theme.out.opacity(0.13))
                .frame(width: 92 * k, height: 18 * k)
                .offset(y: -4 * k)
            StageView(root: model.dialEgg.root, viewBox: EggDial.viewBox)
                .frame(width: side, height: side)
            Text(GC.fmtTime(Double(total)))
                .font(Theme.digits(60 * k))
                .monospacedDigit()
                .tracking(-0.6 * k)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .fixedSize()
                .scaleEffect(timeScale)
                .offset(y: 60 * k)
            knob(k)
                .offset(x: knobX, y: knobY)
                .animation(glide, value: total)
        }
    }

    private func knob(_ k: CGFloat) -> some View {
        ZStack {
            Circle().fill(Theme.out)
                .frame(width: 48 * k, height: 48 * k)
            Circle().fill(Theme.cream)
                .frame(width: 36 * k, height: 36 * k)
            Circle().fill(Theme.gold)
                .frame(width: 16 * k, height: 16 * k)
                .overlay(Circle().stroke(Theme.out, lineWidth: 3.5 * k))
        }
        .shadow(color: Theme.out.opacity(0.35), radius: 0, x: 0, y: 4)
    }

    /// "5 minutes", "1 minute 30 seconds", "45 seconds"
    private func spoken(_ total: Int) -> String {
        let m = total / 60
        let sec = total % 60
        var parts: [String] = []
        if m > 0 { parts.append(m == 1 ? "1 minute" : "\(m) minutes") }
        if sec > 0 { parts.append("\(sec) seconds") }
        return parts.joined(separator: " ")
    }

    private func bumpDigits() {
        if reduceMotion { return }
        withAnimation(.easeOut(duration: 0.1)) { timeScale = 1.12 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.1)) { timeScale = 1 }
        }
    }

    // MARK: twisting

    private var twist: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if !tracking {
                    tracking = true
                    let start = polar(g.startLocation)
                    // only the ring itself; the egg in the middle stays tappable
                    let onRing = start.dist >= EggDial.ringR - 26 && start.dist <= EggDial.ringR + 40
                    if onRing {
                        Sound.shared.ensure()
                        dragging = true
                        apply(start.minute, first: true)
                    } else {
                        dragging = false
                        boopIfOnEgg(g.startLocation)
                    }
                    return
                }
                if dragging { apply(polar(g.location).minute, first: false) }
            }
            .onEnded { _ in
                tracking = false
                dragging = false
            }
    }

    /// A touch in dial units: how far from the centre, and which minute mark it points at (0…60).
    private func polar(_ p: CGPoint) -> (dist: CGFloat, minute: Int) {
        let k: CGFloat = side / 340
        let x = Double(p.x - side / 2)
        let y = Double(p.y - side / 2)
        let dist = CGFloat(hypot(x, y)) / k
        var a = atan2(x, -y)
        if a < 0 { a += 2 * Double.pi }
        let minute = Int((a / (2 * Double.pi) * 60).rounded())
        return (dist, minute)
    }

    private func apply(_ minute: Int, first: Bool) {
        let cur = Double(model.setupSeconds) / 60
        var m = minute
        // 0 and 60 share the top of the ring: stay on whichever side we came from
        if m == 0 { m = cur > 30 ? 60 : 1 }
        if !first {
            if cur >= 45 && m <= 15 { m = 60 }   // no wrapping past the top
            if cur <= 15 && m >= 45 { m = 1 }
        }
        model.setTotal(m * 60)
    }

    /// a tap on the egg: a happy squish (it never changes the time)
    private func boopIfOnEgg(_ p: CGPoint) {
        let k: CGFloat = side / 340
        let dx = Double((p.x - side / 2) / k)
        let dy = Double((p.y - side / 2) / k)
        // the egg stands at (0, -4) in dial units, at 0.6 of its size
        let local = CGPoint(x: dx / 0.6, y: (dy + 4) / 0.6)
        if Egg.bodyRect.insetBy(dx: -12, dy: -12).contains(local) { model.dialEgg.boop() }
    }
}

/// The 60 minute marks around the ring (a bigger dot every five).
private struct DialTicks: View {
    var body: some View {
        Canvas { ctx, size in
            let k: CGFloat = size.width / 340
            let cx: CGFloat = size.width / 2
            let cy: CGFloat = size.height / 2
            let r: CGFloat = 136 * k
            for i in 0..<60 {
                let a: Double = Double(i) / 60 * 2 * Double.pi
                let big = i % 5 == 0
                let dotR: CGFloat = (big ? 3.6 : 1.7) * k
                let x: CGFloat = cx + CGFloat(sin(a)) * r
                let y: CGFloat = cy - CGFloat(cos(a)) * r
                let dot = Path(ellipseIn: CGRect(x: x - dotR, y: y - dotR, width: 2 * dotR, height: 2 * dotR))
                ctx.fill(dot, with: .color(Theme.out.opacity(big ? 0.5 : 0.28)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// A round − / + button that repeats while held: slow at first, then fast.
struct RepeatButton: View {
    let icon: String
    let label: String
    let enabled: Bool
    /// one step; returns false when it can't go any further
    let action: () -> Bool

    @State private var engaged = false
    @State private var pressed = false
    @State private var repeater: Task<Void, Never>?

    private let size: CGFloat = 56

    var body: some View {
        IconView(icon, size: 34)
            .frame(width: size, height: size)
            .background(ToyBackground(fill: Theme.cream, radius: size / 2, border: 4, depth: pressed ? 1 : 5))
            .offset(y: pressed ? 4 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
            .opacity(enabled ? 1 : 0.45)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if !engaged {
                            engaged = true
                            if enabled { start() }
                        } else if pressed {
                            // sliding off the button stops it, like lifting the finger
                            let zone = CGRect(x: 0, y: 0, width: size, height: size).insetBy(dx: -12, dy: -12)
                            if !zone.contains(g.location) { stop() }
                        }
                    }
                    .onEnded { _ in
                        engaged = false
                        stop()
                    }
            )
            .onDisappear { stop() }
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if enabled { _ = action() } }
    }

    private func start() {
        pressed = true
        Sound.shared.ensure()
        _ = action()
        repeater?.cancel()
        let step = action
        repeater = Task { @MainActor in
            var delay = 0.42
            while !Task.isCancelled {
                await GC.sleep(delay)
                if Task.isCancelled { return }
                if !step() { return }
                delay = max(0.07, delay * 0.8)
            }
        }
    }

    private func stop() {
        repeater?.cancel()
        repeater = nil
        pressed = false
    }
}

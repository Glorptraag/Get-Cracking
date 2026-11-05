import SwiftUI

/// "Who's in the egg?" — set the time and press Start.
struct SetupView: View {
    @Environment(AppModel.self) private var model
    @State private var contentHeight: CGFloat = 800
    @State private var minBump = false
    @State private var secBump = false

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
        return VStack(spacing: 14) {
            Text("Who's in the egg?")
                .font(Theme.hand(30))
                .foregroundStyle(Theme.out)
                .padding(.horizontal, 26).padding(.vertical, 6)
                .toy(Theme.pill, radius: 40, border: 5, depth: 5)
                .padding(.bottom, 120)
                .accessibilityAddTraits(.isHeader)

            timerBox
                .padding(.bottom, 16)

            HStack(spacing: 12) {
                ToySwitch(isOn: Binding(get: { model.settings.hatchMode == "tap" },
                                        set: { model.settings.hatchMode = $0 ? "tap" : "auto" }))
                OutlinedText(text: "Hatch waits for a tap")
            }
            .padding(.top, 8)
            .accessibilityElement(children: .combine)

            startButton
                .padding(.top, 34)

            HStack(spacing: 12) {
                iconButton("🌳", "World", .world)
                iconButton("🎶", "Music", .sound)
                iconButton("📖", "Friends", .book)
                iconButton("⚙️", "Settings", .settings)
            }
            .padding(.top, 10)
        }
        .padding(.top, 70)
        .padding(.bottom, 40)
    }

    // MARK: the timer box with the egg perched on top

    private var timerBox: some View {
        let s = model.settings
        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                dial(String(format: "%02d", s.minutes), bump: minBump, label: "Minutes") {
                    model.bumpMinutes()
                    pulse($minBump)
                }
                VStack(spacing: 18) {
                    colonDot
                    colonDot
                }
                dial(String(format: "%02d", s.seconds), bump: secBump, label: "Seconds") {
                    model.bumpSeconds()
                    pulse($secBump)
                }
            }
            Text(s.minutes == 1 ? "minute" : "minutes")
                .font(Theme.hand(22))
                .foregroundStyle(Theme.out)
                .padding(.horizontal, 16).padding(.bottom, 2)
                .toy(Theme.cream, radius: 12, border: 4, depth: 4)
                .padding(.top, 6)
            MinuteSlider(value: Binding(get: { s.minutes }, set: { model.setMinutes($0) }))
                .frame(height: 46)
                .padding(.horizontal, 10)
            FlowLayout(spacing: 5) {
                ForEach([1, 2, 5, 10, 15, 20, 30], id: \.self) { m in
                    Button("\(m)") { model.preset(m) }
                        .font(Theme.round(16, .semibold))
                        .frame(minWidth: 38, minHeight: 38)
                        .buttonStyle(ToyButtonStyle(fill: s.minutes == m && s.seconds == 0 ? Theme.gold : Theme.cream, radius: 12))
                        .accessibilityLabel("\(m) minutes")
                }
            }
        }
        .padding(.top, 26).padding(.horizontal, 20).padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.out).offset(y: 8)
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.tealDark)
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.teal).padding(.bottom, 12)
                RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Theme.out, lineWidth: 6)
            }
        )
        .background(alignment: .bottom) {
            HStack {
                boxFoot
                Spacer()
                boxFoot
            }
            .padding(.horizontal, 44)
            .offset(y: 30)
        }
        .overlay(alignment: .topLeading) { Sprout().rotationEffect(.degrees(-18)).offset(x: -20, y: -26) }
        .overlay(alignment: .topTrailing) { Sprout().scaleEffect(x: -1).rotationEffect(.degrees(14)).offset(x: 18, y: -24) }
        .overlay(alignment: .bottomTrailing) { Sprout().rotationEffect(.degrees(160)).scaleEffect(0.8).offset(x: -18, y: 22) }
        .overlay(alignment: .top) {
            StageView(root: model.perchRoot, viewBox: CGRect(x: -110, y: -205, width: 220, height: 225))
                .frame(width: 150, height: 150)
                .contentShape(Ellipse().inset(by: 20))
                .onTapGesture { model.perchEgg.boop() }
                .offset(y: -128)
                .accessibilityLabel("The egg")
                .accessibilityAddTraits(.isButton)
        }
    }

    private var colonDot: some View {
        RoundedRectangle(cornerRadius: 4).fill(Theme.gold)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.out, lineWidth: 4))
            .frame(width: 16, height: 16)
    }

    private var boxFoot: some View {
        UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10)
            .fill(Color(hex: "#9a5a3c"))
            .overlay(UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10).stroke(Theme.out, lineWidth: 5))
            .frame(width: 34, height: 26)
    }

    private func dial(_ text: String, bump: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(Theme.round(58, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.top, 4)
                .frame(width: 112, height: 112)
                .background(
                    ZStack {
                        Circle().fill(Theme.out).padding(-9).offset(y: 9)
                        Circle().fill(Theme.out).padding(-9)
                        Circle().fill(Theme.cream)
                        Circle().strokeBorder(Theme.gold, lineWidth: 7)
                    }
                )
        }
        .buttonStyle(PressDown())
        .scaleEffect(bump ? 1.08 : 1)
        .accessibilityLabel("\(label): \(text). Tap to change")
    }

    private func pulse(_ flag: Binding<Bool>) {
        withAnimation(.easeOut(duration: 0.11)) { flag.wrappedValue = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.easeIn(duration: 0.11)) { flag.wrappedValue = false }
        }
    }

    private var startButton: some View {
        Button {
            model.startRun()
        } label: {
            ZStack {
                // planter rim
                RoundedRectangle(cornerRadius: 10).fill(Theme.clay)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.out, lineWidth: 6))
                    .frame(height: 22)
                    .padding(.horizontal, -12)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: -6)
                    .zIndex(1)
                Text("Start")
                    .font(Theme.hand(40))
                    .tracking(4)
                    .foregroundStyle(Theme.out)
                    .padding(.horizontal, 26).padding(.bottom, 2)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.cream))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.out, lineWidth: 4))
                    .offset(y: 8)
                    .zIndex(2)
            }
            .frame(width: 280, height: 96)
            .background(
                ZStack(alignment: .bottom) {
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 18, bottomTrailingRadius: 18, topTrailingRadius: 12)
                        .fill(Theme.out).offset(y: 7)
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 18, bottomTrailingRadius: 18, topTrailingRadius: 12)
                        .fill(Theme.clayDark)
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 18, bottomTrailingRadius: 18, topTrailingRadius: 12)
                        .fill(Theme.clay).padding(.bottom, 10)
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 18, bottomTrailingRadius: 18, topTrailingRadius: 12)
                        .stroke(Theme.out, lineWidth: 6)
                }
            )
            .overlay(alignment: .top) {
                HStack {
                    SproutPair()
                    Spacer()
                    SproutPair(delay: 1.5)
                }
                .padding(.horizontal, 44)
                .offset(y: -40)
                .allowsHitTesting(false)
            }
        }
        .buttonStyle(PressDown())
        .accessibilityLabel("Start the timer")
    }

    private func iconButton(_ icon: String, _ label: String, _ kind: SheetKind) -> some View {
        Button {
            model.sheet = kind
        } label: {
            VStack(spacing: 0) {
                Text(icon).font(.system(size: 28))
                Text(label).font(Theme.hand(15))
            }
            .frame(width: 76, height: 72)
        }
        .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 18, border: 4, depth: 5))
        .accessibilityLabel(label)
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

/// The berry-and-bark minutes slider (0–60).
struct MinuteSlider: View {
    @Binding var value: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let p = CGFloat(value) / 60
            let thumbW: CGFloat = 30
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: "#5a2a2c")).frame(height: 22)
                Capsule().fill(Theme.berry).frame(width: max(22, w * p), height: 22)
                Capsule().strokeBorder(Theme.out, lineWidth: 5).frame(height: 22)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#8a5a3b"))
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6).fill(Color(hex: "#6b4430")).frame(height: 8).padding(5)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.out, lineWidth: 5))
                    .frame(width: thumbW, height: 46)
                    .offset(x: (w - thumbW) * p)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let v = Int(((g.location.x - thumbW / 2) / max(1, w - thumbW) * 60).rounded())
                let nv = min(60, max(0, v))
                if nv != value { value = nv }
            })
        }
        .accessibilityElement()
        .accessibilityLabel("Minutes")
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: value = min(60, value + 1)
            case .decrement: value = max(0, value - 1)
            @unknown default: break
            }
        }
    }
}

/// A pair of little leaves.
struct Sprout: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Leaf().rotationEffect(.degrees(-20), anchor: .bottom).offset(x: 2)
            Leaf().scaleEffect(x: -1).rotationEffect(.degrees(40), anchor: .bottom).offset(x: 20, y: -4)
        }
        .frame(width: 44, height: 30, alignment: .bottomLeading)
        .allowsHitTesting(false)
    }
}

/// Two sprouts that sway on the Start planter.
struct SproutPair: View {
    var delay: Double = 0
    @State private var sway = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Leaf(w: 22, h: 30).rotationEffect(.degrees(-28 + (sway ? 6 : 0)), anchor: .bottom).offset(x: 4)
            Leaf(w: 22, h: 30).scaleEffect(x: -1).rotationEffect(.degrees(28 + (sway ? 6 : 0)), anchor: .bottom).offset(x: 24)
        }
        .frame(width: 54, height: 40, alignment: .bottomLeading)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { sway = true }
            }
        }
    }
}

struct Leaf: View {
    var w: CGFloat = 20
    var h: CGFloat = 26
    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: w, bottomTrailingRadius: 0, topTrailingRadius: w)
        shape.fill(Theme.leaf)
            .overlay(shape.stroke(Theme.out, lineWidth: 4))
            .frame(width: w, height: h)
    }
}

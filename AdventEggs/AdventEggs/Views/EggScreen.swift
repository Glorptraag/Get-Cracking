import SwiftUI

/// Behind the door: the day's 24-hour egg. It cracks a step at a time as the
/// day goes by (Get Cracking's 8 landmarks). When the 24 hours are up it
/// glows and knocks, and a tap hatches the friend, who is added to the gallery.
struct EggScreen: View {
    enum Phase { case egg, hatching, hatched }

    let friend: Friend
    let onGallery: () -> Void

    @Environment(AdventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: Phase = .egg
    @State private var shellOpen = false
    @State private var friendOut = false
    @State private var burstStart: Date?
    @State private var jump = 0
    @State private var talking = false
    @State private var squash = false
    @State private var crackShake = 0
    @State private var showTray = false
    @State private var taps = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { tl in
            let progress = store.eggProgress(friend.day, now: tl.date, doorOpenedAt: store.earlyOpenDate(friend.day))
            let step = EggPainter.step(for: progress)
            screen(progress: progress, step: step, ready: progress >= 1)
                .onChange(of: step) { old, new in
                    guard new > old, phase == .egg else { return }
                    SoundBox.shared.crack()
                    withAnimation(.linear(duration: 0.45)) { crackShake += 1 }
                }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: taps)
        .onAppear {
            if store.hatched.contains(friend.day) {
                phase = .hatched
                shellOpen = true
                friendOut = true
            }
        }
    }

    // MARK: layout

    private func screen(progress: Double, step: Int, ready: Bool) -> some View {
        ZStack {
            backdrop
            VStack(spacing: 12) {
                topBar
                Spacer(minLength: 0)
                stage(step: step, ready: ready)
                    .frame(maxWidth: 460, maxHeight: 460)
                    .aspectRatio(1, contentMode: .fit)
                Spacer(minLength: 0)
                footer(progress: progress, step: step, ready: ready)
                    .frame(minHeight: 150)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            if showTray { tray }
        }
    }

    private var backdrop: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x15203f), Color(hex: 0x3a4a7a), Color(hex: 0x9a8ab4)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(hex: 0xfff1b0).opacity(0.35), .clear],
                           center: UnitPoint(x: 0.5, y: 0.5), startRadius: 10, endRadius: 320)
            GeometryReader { geo in
                Ellipse()
                    .fill(Color(hex: 0xeef3f8))
                    .frame(width: geo.size.width * 1.6, height: geo.size.height * 0.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.98)
            }
            Snowfall(count: 60)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: { RoundIcon(systemName: "xmark", size: 46) }
                .accessibilityLabel("Back to the calendar")
            Spacer()
            Pill(text: "Day \(friend.day)", size: 20)
            Spacer()
            HoldButton(action: { withAnimation { showTray = true } }) {
                RoundIcon(systemName: "lock.fill", size: 46)
            }
            .accessibilityLabel("Grown-up controls, press and hold")
        }
        .padding(.top, 8)
    }

    // MARK: the egg and the friend

    private func stage(step: Int, ready: Bool) -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let eggW = side * 0.56
            let eggH = side * 0.66
            ZStack(alignment: .bottom) {
                if phase == .egg {
                    wholeEgg(step: step, ready: ready)
                        .frame(width: eggW, height: eggH)
                } else {
                    FriendView(look: friend.look, lively: phase == .hatched, jump: jump, mouthOpen: talking)
                        .frame(width: side * 0.95, height: side * 0.95)
                        .scaleEffect(friendOut ? 1 : 0.25, anchor: .bottom)
                        .offset(y: friendOut ? 0 : -side * 0.1)
                        .opacity(friendOut ? 1 : 0)
                        .contentShape(Rectangle())
                        .onTapGesture { sayHello() }
                        .accessibilityLabel(friend.name)
                        .accessibilityAddTraits(.isButton)
                    EggCanvas(day: friend.day, step: 8, part: .bottom)
                        .frame(width: eggW, height: eggH)
                        .offset(y: shellOpen ? side * 0.3 : 0)
                        .opacity(shellOpen ? 0 : 1)
                        .allowsHitTesting(false)
                    EggCanvas(day: friend.day, step: 8, part: .top)
                        .frame(width: eggW, height: eggH)
                        .rotationEffect(.degrees(shellOpen ? 75 : 0))
                        .offset(x: shellOpen ? side * 0.45 : 0, y: shellOpen ? -side * 0.55 : 0)
                        .opacity(shellOpen ? 0 : 1)
                        .allowsHitTesting(false)
                }
                if let start = burstStart {
                    SparkleBurst(start: start).allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }

    private func wholeEgg(step: Int, ready: Bool) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            // a ready egg knocks every few seconds; a cracking egg breathes
            let knock = ready && t.truncatingRemainder(dividingBy: 3) < 0.5
            let angle = knock ? sin(t * 40) * 7 : sin(t * 1.6) * Double(step) * 0.35
            EggCanvas(day: friend.day, step: step, glow: ready)
                .rotationEffect(.degrees(angle), anchor: .bottom)
        }
        .scaleEffect(x: squash ? 1.08 : 1, y: squash ? 0.9 : 1, anchor: .bottom)
        .modifier(Shake(phase: CGFloat(crackShake)))
        .contentShape(Rectangle())
        .onTapGesture { tapEgg(ready: ready) }
        .accessibilityLabel(ready ? "The egg is ready. Tap to hatch." : "The egg is cracking.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: footer

    @ViewBuilder
    private func footer(progress: Double, step: Int, ready: Bool) -> some View {
        switch phase {
        case .hatched:
            VStack(spacing: 14) {
                Pill(text: friend.name, size: 26)
                Text(friend.theme.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(friend.theme.tint))
                HStack(spacing: 14) {
                    Button { dismiss() } label: { labelButton("Calendar", icon: "house.fill") }
                    Button { onGallery() } label: { labelButton("Gallery", icon: "book.closed.fill") }
                }
            }
            .transition(.scale.combined(with: .opacity))
        case .hatching:
            Color.clear
        case .egg:
            VStack(spacing: 14) {
                pebbles(step: ready ? 8 : step)
                if ready {
                    Pill(text: "Tap the egg!", size: 24)
                        .modifier(Pulse())
                } else {
                    Text(timeLeft(progress))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Capsule().fill(Color.cream.opacity(0.9)))
                }
            }
        }
    }

    /// The 8 crack landmarks as pebbles, like Get Cracking's ground ring.
    private func pebbles(step: Int) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(i < step ? Color.goldLeaf : Color.white.opacity(0.5))
                    .overlay(Circle().stroke(Color.ink, lineWidth: 3))
                    .frame(width: 20, height: 20)
                    .scaleEffect(i < step ? 1.1 : 1)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(step) of 8 cracks")
    }

    private func timeLeft(_ progress: Double) -> String {
        let seconds = Int((1 - progress) * AdventDate.eggSeconds)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "Hatches in \(h) h \(m) min" }
        if m > 0 { return "Hatches in \(m) min" }
        return "Almost ready…"
    }

    private func labelButton(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Capsule().fill(Color.cream))
            .overlay(Capsule().stroke(Color.ink, lineWidth: 3.5))
            .background(Capsule().fill(Color.ink).offset(y: 4))
    }

    // MARK: grown-up tray

    private var tray: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture { withAnimation { showTray = false } }
            VStack(spacing: 14) {
                Text("Grown-up controls")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.ink)
                if phase == .egg {
                    Button {
                        withAnimation { showTray = false }
                        store.hurry(friend.day)
                        hatch()
                    } label: { labelButton("Hatch now", icon: "sparkles") }
                }
                Button { withAnimation { showTray = false } } label: { labelButton("Close", icon: "xmark") }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.paper))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.ink, lineWidth: 4))
            .padding(32)
        }
        .transition(.opacity)
    }

    // MARK: actions

    private func tapEgg(ready: Bool) {
        taps += 1
        if ready {
            hatch()
            return
        }
        withAnimation(.easeOut(duration: 0.12)) { squash = true }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4).delay(0.12)) { squash = false }
    }

    private func hatch() {
        guard phase == .egg else { return }
        phase = .hatching
        SoundBox.shared.pop()
        burstStart = .now
        store.hatch(friend.day)
        withAnimation(.easeOut(duration: 0.75)) { shellOpen = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.5).delay(0.12)) { friendOut = true }
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            speak()
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.spring(response: 0.4)) { phase = .hatched }
        }
    }

    private func sayHello() {
        guard phase == .hatched else { return }
        jump += 1
        speak()
    }

    private func speak() {
        SoundBox.shared.sayName(of: friend)
        talking = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            talking = false
        }
    }
}

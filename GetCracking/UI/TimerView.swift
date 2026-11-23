import SwiftUI

/// The running timer: the world, the egg, and (behind a hold-to-open lock)
/// the grown-up controls.
struct TimerView: View {
    @Environment(AppModel.self) private var model
    let run: RunController

    @State private var touching = false
    @State private var lockProgress = 0.0
    @State private var againProgress = 0.0
    @State private var hintBob = false
    @State private var timePulse = false
    @State private var clockDim = false
    @State private var againWiggle = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let s = model.settings
        GeometryReader { geo in
            let size = geo.size
            let vb = size.height / max(size.width, 1) > 1.25 ? Scenes.tallViewBox : Scenes.fullViewBox
            let m = fitTransform(vb, in: size)
            ZStack {
                StageView(root: run.scene.root, viewBox: vb)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            guard !touching else { return }
                            touching = true
                            let p = g.location.applying(m.inverted())
                            run.touch(eggLocal: CGPoint(x: p.x - Scenes.egg.x, y: p.y - Scenes.egg.y))
                        }
                        .onEnded { _ in touching = false })
                    .accessibilityElement()
                    .accessibilityLabel(accessibilityText)
                    .accessibilityAddTraits(run.phase == .ready ? .isButton : [])
                    .accessibilityAction { if run.phase == .ready { run.hatch() } }

                // the pointing finger, at the egg's lower right
                if run.showTapHint {
                    let p = CGPoint(x: Scenes.egg.x + 15, y: Scenes.egg.y - 48).applying(m)
                    IconView(name: "tap", size: 64)
                        .shadow(color: Theme.out, radius: 0, x: 0, y: 3)
                        .rotationEffect(.degrees(hintBob ? -8 : 0))
                        .offset(y: hintBob ? -14 : 0)
                        .position(x: p.x + 32, y: p.y + 32)
                        .allowsHitTesting(false)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { hintBob = true }
                        }
                        .onDisappear { hintBob = false }
                }
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) { GeometryReader { g in topPills(s, width: g.size.width) } }
        .overlay(alignment: .bottom) { bottomBar(s) }
        .persistentSystemOverlays(.hidden)
        .onChange(of: run.phase == .paused, initial: true) { _, paused in
            // the clock pulses gently while paused
            if paused && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { clockDim = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { clockDim = false }
            }
        }
        .onChange(of: run.timeBump) { _, _ in
            withAnimation(.easeOut(duration: 0.15)) { timePulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { withAnimation(.easeIn(duration: 0.15)) { timePulse = false } }
        }
    }

    private var accessibilityText: String {
        switch run.phase {
        case .running: return "The egg is cracking. \(run.timeText) left."
        case .paused: return "Paused. \(run.timeText) left."
        case .ready: return "Time's up! Tap the egg to hatch it."
        case .hatching: return "Hatching!"
        case .hatched: return run.hatchText
        }
    }

    // MARK: top

    private func topPills(_ s: Settings, width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Text(run.hatchText)
                .font(Theme.hand(40))
                .foregroundStyle(Theme.out)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 26).padding(.vertical, 6)
                .toy(Theme.pill, radius: 40, border: 5, depth: 5)
                .scaleEffect(run.showHatchPill ? 1 : 0.6)
                .offset(y: run.showHatchPill ? 0 : -160)
                .opacity(run.showHatchPill ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.55), value: run.showHatchPill)
                .padding(.top, 10)
                .padding(.horizontal, 70)
                .allowsHitTesting(false)

            // the big clock: minutes and seconds, centred at the top
            if s.showNumbers && (run.phase == .running || run.phase == .paused) {
                let size = min(100, max(56, width * 0.17))
                Text(run.timeText)
                    .font(Theme.round(size, .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, size * 0.45)
                    .padding(.top, size * 0.1).padding(.bottom, size * 0.12)
                    .toy(Theme.cream, radius: size, border: 6, depth: 7)
                    .opacity(run.phase == .paused ? (reduceMotion ? 0.6 : (clockDim ? 0.5 : 1)) : 1)
                    .scaleEffect(timePulse ? 1.08 : 1)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: bottom

    private func bottomBar(_ s: Settings) -> some View {
        ZStack(alignment: .bottom) {
            // next-up card
            nextCard(s)
                .padding(.bottom, 84)
                .scaleEffect(run.showNextCard ? 1 : 0.8)
                .offset(y: run.showNextCard ? 0 : 30)
                .opacity(run.showNextCard ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: run.showNextCard)
                .allowsHitTesting(false)

            HStack(alignment: .bottom) {
                lockButton(s)
                Spacer()
                kidControls(s)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)

            againButton(s)
                .offset(y: run.showAgain ? 0 : 140)
                .animation(.spring(response: 0.45, dampingFraction: 0.6), value: run.showAgain)

            tray
                .offset(y: run.trayOpen ? 0 : 420)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: run.trayOpen)
        }
        .padding(.bottom, 12)
    }

    private func lockButton(_ s: Settings) -> some View {
        // the tip sits above the lock, so it never hides behind the − / + / pause buttons
        ZStack(alignment: .bottomLeading) {
            ZStack {
                Circle().fill(Theme.cream.opacity(0.78))
                Circle().strokeBorder(Theme.out, lineWidth: 4)
                IconView(name: "lock", size: 30)
                Circle()
                    .trim(from: 0, to: lockProgress)
                    .stroke(Theme.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(-9)
            }
            .frame(width: 58, height: 58)
            .background(Circle().fill(Theme.out).offset(y: 4))
            .opacity(lockProgress > 0 || run.trayOpen ? 1 : 0.55)
            .holdable(s.holdSeconds, progress: $lockProgress, onTap: {
                if s.longPressStop { run.flashLockTip() } else { run.openTray() }
            }, onHold: { run.openTray() })
            .accessibilityLabel("Grown-ups: hold to open controls")
            .accessibilityAddTraits(.isButton)

            Text("Grown-ups: press & hold")
                .font(Theme.hand(18))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.out.opacity(0.88)))
                .fixedSize()
                .opacity(run.showLockTip ? 1 : 0)
                .offset(y: run.showLockTip ? -74 : -66)
                .animation(.easeOut(duration: 0.25), value: run.showLockTip)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .opacity(run.phase == .hatched ? 0 : 1)
    }

    @ViewBuilder
    private func kidControls(_ s: Settings) -> some View {
        let live = run.phase == .running || run.phase == .paused
        if live {
            HStack(spacing: 10) {
                if s.showAdjust {
                    roundButton("−1", "One minute less") { run.adjust(-60) }
                    roundButton("+1", "One minute more") { run.adjust(60) }
                }
                if s.showPause {
                    Button { run.togglePause() } label: {
                        IconView(name: run.phase == .paused ? "play" : "pause", size: 32).frame(width: 60, height: 60)
                    }
                    .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 30))
                    .accessibilityLabel(run.phase == .paused ? "Resume" : "Pause")
                }
            }
        }
    }

    private func roundButton(_ label: String, _ a11y: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(Theme.round(20, .bold)).frame(width: 60, height: 60)
        }
        .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 30))
        .accessibilityLabel(a11y)
    }

    private func againButton(_ s: Settings) -> some View {
        HStack(spacing: 10) {
            IconView(name: "egg", size: 30)
            Text("Hold for a new egg").font(Theme.hand(20)).foregroundStyle(Theme.out)
                .lineLimit(1).fixedSize()
        }
        .padding(.leading, 16).padding(.trailing, 22)
        .frame(height: 60)
        .background(
            ZStack(alignment: .bottomLeading) {
                Capsule().fill(Theme.out).offset(y: 4)
                Capsule().fill(Theme.cream.opacity(0.92))
                GeometryReader { g in
                    Capsule().fill(Theme.gold).frame(width: g.size.width * againProgress, height: 6)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .clipShape(Capsule())
                Capsule().strokeBorder(Theme.out, lineWidth: 4)
            }
        )
        // a quick tap wiggles, so it's clear the button needs holding
        .phaseAnimator([0.0, -3, 3, -2, 0], trigger: againWiggle) { v, deg in
            v.rotationEffect(.degrees(deg))
        } animation: { _ in .easeInOut(duration: 0.08) }
        .holdable(s.holdSeconds, progress: $againProgress, onTap: { againWiggle += 1 }) { model.stopToSetup() }
        .accessibilityLabel("Hold for a new egg")
        .accessibilityAddTraits(.isButton)
    }

    private func nextCard(_ s: Settings) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Theme.pill)
                if let img = PhotoStore.image(s.nextUp.photo) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    IconView(name: s.nextUp.icon, size: 46)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.out, lineWidth: 4))
            VStack(alignment: .leading, spacing: 0) {
                Text("Next up").font(Theme.hand(16)).opacity(0.7)
                Text(s.nextUp.text).font(Theme.hand(28)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .foregroundStyle(Theme.out)
        }
        .padding(.leading, 12).padding(.trailing, 22).padding(.vertical, 10)
        .toy(Theme.cream, radius: 22, border: 5, depth: 6)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    // MARK: grown-up tray

    private var tray: some View {
        let live = run.phase == .running || run.phase == .paused
        let canHatch = live || run.phase == .ready
        return VStack(spacing: 10) {
            Text("Grown-up controls").font(Theme.hand(22)).foregroundStyle(Theme.out)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                if live {
                    trayButton(run.phase == .paused ? "Resume" : "Pause", icon: run.phase == .paused ? "play" : "pause") { run.togglePause() }
                    trayButton("Minute", text: "−1") { run.adjust(-60) }
                    trayButton("Minute", text: "+1") { run.adjust(60) }
                }
                if canHatch { trayButton("Hatch now", icon: "hatch") { run.hatchNow() } }
                trayButton("New egg", icon: "again") { model.restartSame() }
                trayButton("Stop", icon: "stop", danger: true) { model.stopToSetup() }
            }
        }
        .padding(.top, 14).padding(.horizontal, 16).padding(.bottom, 18)
        .frame(maxWidth: 560)
        .toy(Theme.paper, radius: 26, border: 5, depth: 7)
        .overlay(alignment: .topTrailing) {
            Button { run.closeTray() } label: {
                IconView(name: "close", size: 26)
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 23, border: 4, depth: 3))
            .padding(8)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 12)
        .opacity(run.trayOpen ? 1 : 0)
        .allowsHitTesting(run.trayOpen)
    }

    private func trayButton(_ label: String, icon: String? = nil, text: String? = nil, danger: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button {
            run.armTray()
            action()
        } label: {
            VStack(spacing: 4) {
                if let icon {
                    IconView(name: icon, size: 30)
                } else {
                    Text(text ?? "").font(Theme.round(24, .bold))
                }
                Text(label).font(Theme.hand(17))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
        }
        .buttonStyle(ToyButtonStyle(fill: danger ? Theme.danger : Theme.cream, radius: 16))
    }
}

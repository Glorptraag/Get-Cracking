import SwiftUI

/// A friend, drawn live. When `lively`, it breathes, blinks and bops;
/// bump `jump` to make it hop.
struct FriendView: View {
    let look: Look
    var lively = true
    var jump = 0
    var mouthOpen = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hop: CGFloat = 0

    var body: some View {
        Group {
            if lively && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    let breathe = CGFloat(sin(t * 2.4)) * 0.025
                    let blink = t.truncatingRemainder(dividingBy: 3.7) < 0.14
                    canvas(blink: blink)
                        .scaleEffect(x: 1 - breathe, y: 1 + breathe, anchor: .bottom)
                }
            } else {
                canvas(blink: false)
            }
        }
        .offset(y: hop)
        .onChange(of: jump) {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.18)) { hop = -50 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45).delay(0.18)) { hop = 0 }
        }
    }

    private func canvas(blink: Bool) -> some View {
        Canvas { ctx, size in
            FriendPainter(look: look, blink: blink, mouthOpen: mouthOpen).draw(in: ctx, size: size)
        }
    }
}

struct EggCanvas: View {
    let day: Int
    var step = 0
    var part: EggPainter.Part = .whole
    var glow = false

    var body: some View {
        Canvas { ctx, size in
            EggPainter(day: day, step: step, part: part, glow: glow).draw(in: ctx, size: size)
        }
    }
}

/// Gentle snow over everything. Never takes touches.
struct Snowfall: View {
    var count = 80
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let span = size.height + 20
                for i in 0..<count {
                    let seed = Double(i)
                    let r = 1.2 + hash01(seed * 1.3) * 3.2
                    let speed = 16 + hash01(seed * 2.7) * 34
                    let x0 = CGFloat(hash01(seed * 3.1)) * size.width
                    let fall = (hash01(seed * 4.9) * Double(span) + t * speed).truncatingRemainder(dividingBy: Double(span))
                    let y = CGFloat(fall) - 10
                    let x = x0 + CGFloat(sin(t * 0.7 + seed)) * 12
                    let flake = Draw.circle(x, y, r)
                    ctx.fill(flake, with: .color(.white.opacity(0.5 + 0.45 * hash01(seed * 5.3))))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// A one-off burst of twinkles when a friend hatches.
struct SparkleBurst: View {
    let start: Date
    private let colors: [Color] = [Color(hex: 0xffd86b), Color(hex: 0xf7a8c8), Color(hex: 0x9fd8e8),
                                   Color(hex: 0xa9d36b), .white]

    var body: some View {
        TimelineView(.animation) { tl in
            let e = tl.date.timeIntervalSince(start)
            Canvas { ctx, size in
                guard e < 1.6 else { return }
                let center = CGPoint(x: size.width / 2, y: size.height * 0.55)
                let k = e / 1.6
                for i in 0..<22 {
                    let a = Double(i) / 22 * 2 * .pi + hash01(Double(i)) * 0.4
                    let dist = (60 + hash01(Double(i) * 3) * 140) * (1 - pow(1 - k, 3))
                    let x = center.x + CGFloat(cos(a) * dist)
                    let y = center.y + CGFloat(sin(a) * dist + k * k * 60)
                    var c = ctx
                    c.opacity = 1 - k
                    Draw.fillOut(c, Draw.twinkle(x, y, 9 + hash01(Double(i) * 7) * 6), colors[i % colors.count], 2.5)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// A button grown-ups must press and hold (as in Get Cracking): a quick tap
/// only shows a reminder.
struct HoldButton<Label: View>: View {
    var seconds: Double = 1.2
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var pressing = false
    @State private var showTip = false

    var body: some View {
        label()
            .overlay {
                Circle()
                    .trim(from: 0, to: pressing ? 1 : 0)
                    .stroke(Color.goldLeaf, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(-4)
                    .animation(pressing ? .linear(duration: seconds) : .easeOut(duration: 0.15), value: pressing)
            }
            .overlay(alignment: .bottom) {
                if showTip {
                    Text("Grown-ups: press & hold")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .fixedSize()
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Color.cream))
                        .overlay(Capsule().stroke(Color.ink, lineWidth: 2))
                        .foregroundStyle(Color.ink)
                        .offset(y: 34)
                        .transition(.opacity)
                }
            }
            .onTapGesture {
                withAnimation { showTip = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.8))
                    withAnimation { showTip = false }
                }
            }
            .onLongPressGesture(minimumDuration: seconds, perform: {
                pressing = false
                action()
            }, onPressingChanged: { pressing = $0 })
    }
}

/// The round toy-like icon button used across the app.
struct RoundIcon: View {
    let systemName: String
    var size: CGFloat = 50

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(Color.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(Color.cream))
            .overlay(Circle().stroke(Color.ink, lineWidth: 3.5))
            .background(Circle().fill(Color.ink).offset(y: 4))
    }
}

/// Hand-lettered pill, as in Get Cracking.
struct Pill: View {
    let text: String
    var size: CGFloat = 22

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(Color.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, size * 0.8)
            .padding(.vertical, size * 0.3)
            .background(Capsule().fill(Color(hex: 0xf4efe6)))
            .overlay(Capsule().stroke(Color.ink, lineWidth: 4))
            .background(Capsule().fill(Color.ink).offset(y: 4))
    }
}

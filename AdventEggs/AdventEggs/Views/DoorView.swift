import SwiftUI

/// One painted advent door. Closed, it shows its number; open, it swings
/// back on its hinge to show the egg (or the friend who hatched) inside a
/// warm lit room.
struct DoorView: View {
    enum Status {
        case locked
        /// Today's door (or any door that may open) that hasn't been opened yet.
        case ready
        case open(step: Int, eggReady: Bool, hatched: Bool)
    }

    let slot: DoorSlot
    let friend: Friend
    let status: Status
    let scale: CGFloat
    var shake: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isOpen: Bool {
        if case .open = status { return true }
        return false
    }

    var body: some View {
        let shape = slot.style.shape
        ZStack {
            inside
                .clipShape(shape)
            panel(shape)
                .rotation3DEffect(.degrees(isOpen ? -74 : 0), axis: (x: 0, y: 1, z: 0),
                                  anchor: .leading, perspective: 0.55)
                .animation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.72), value: isOpen)
        }
        .overlay(shape.stroke(Color.ink, lineWidth: max(1.5, 5 * scale)))
        .modifier(Shake(phase: CGFloat(shake)))
        .contentShape(shape)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        switch status {
        case .locked: return "Door \(slot.day), not open yet"
        case .ready: return "Door \(slot.day), ready to open"
        case .open(_, _, let hatched): return hatched ? "Door \(slot.day), \(friend.name)" : "Door \(slot.day), egg inside"
        }
    }

    // MARK: the room behind the door

    private var inside: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: 0xfff2c4), Color(hex: 0xf0b35a), Color(hex: 0xc9773a)],
                           center: .center, startRadius: 1, endRadius: max(slot.rect.width, slot.rect.height) * scale * 0.8)
            switch status {
            case .open(let step, let eggReady, let hatched):
                if hatched {
                    FriendView(look: friend.look, lively: false)
                        .padding(slot.rect.width * scale * 0.04)
                } else {
                    EggCanvas(day: slot.day, step: step, glow: eggReady)
                        .padding(slot.rect.width * scale * 0.12)
                }
            default:
                EmptyView()
            }
        }
    }

    // MARK: the painted panel

    private func panel(_ shape: AnyShape) -> some View {
        let w = slot.rect.width * scale
        let h = slot.rect.height * scale
        let line = max(1, 3 * scale)
        return ZStack {
            shape.fill(slot.paint)
            // painted shading: lighter at the top
            shape.fill(LinearGradient(colors: [.white.opacity(0.18), .clear, .black.opacity(0.12)],
                                      startPoint: .top, endPoint: .bottom))
            details(w: w, h: h, line: line)
            plaque(w: w, h: h, line: line)
            if case .ready = status {
                shape.stroke(Color(hex: 0xffe27a), lineWidth: max(2, 7 * scale))
                    .blur(radius: 3 * scale)
                    .modifier(Pulse())
            }
        }
        .compositingGroup()
    }

    @ViewBuilder
    private func details(w: CGFloat, h: CGFloat, line: CGFloat) -> some View {
        let trimColor = Color.white.opacity(0.32)
        switch slot.style {
        case .door:
            VStack(spacing: h * 0.06) {
                RoundedRectangle(cornerRadius: 6 * scale).stroke(trimColor, lineWidth: line)
                RoundedRectangle(cornerRadius: 6 * scale).stroke(trimColor, lineWidth: line)
            }
            .padding(.horizontal, w * 0.16)
            .padding(.vertical, h * 0.1)
            Circle().fill(Color.goldLeaf)
                .overlay(Circle().stroke(Color.ink, lineWidth: line * 0.8))
                .frame(width: w * 0.12, height: w * 0.12)
                .position(x: w * 0.84, y: h * 0.56)
        case .arch:
            ArchShape().stroke(trimColor, lineWidth: line).padding(w * 0.12)
            Rectangle().fill(Color.ink.opacity(0.35)).frame(width: line, height: h * 0.62).offset(y: h * 0.12)
            Circle().fill(Color.goldLeaf)
                .overlay(Circle().stroke(Color.ink, lineWidth: line * 0.8))
                .frame(width: w * 0.1, height: w * 0.1)
                .position(x: w * 0.4, y: h * 0.62)
        case .window, .round:
            // a painted shutter with slats
            VStack(spacing: h * 0.09) {
                ForEach(0..<5, id: \.self) { _ in
                    Capsule().fill(Color.black.opacity(0.12)).frame(height: max(1, 2.5 * scale))
                }
            }
            .padding(.horizontal, w * 0.12)
            .padding(.vertical, h * 0.1)
        case .gift:
            let ribbon = slot.paint == Color(hex: 0xd39a3a) ? Color(hex: 0xb8434a) : Color(hex: 0xf3d27a)
            Rectangle().fill(ribbon).frame(width: w * 0.16)
            Rectangle().fill(ribbon).frame(height: h * 0.16)
            HStack(spacing: 0) {
                Ellipse().fill(ribbon).overlay(Ellipse().stroke(Color.ink, lineWidth: line))
                    .frame(width: w * 0.24, height: h * 0.16).rotationEffect(.degrees(-20))
                Ellipse().fill(ribbon).overlay(Ellipse().stroke(Color.ink, lineWidth: line))
                    .frame(width: w * 0.24, height: h * 0.16).rotationEffect(.degrees(20))
            }
            .position(x: w * 0.5, y: h * 0.12)
        }
    }

    private func plaque(w: CGFloat, h: CGFloat, line: CGFloat) -> some View {
        let d = min(w, h) * (slot.style == .round ? 0.62 : 0.5)
        let y: CGFloat = {
            switch slot.style {
            case .door: return h * 0.3
            case .arch: return h * 0.36
            case .gift: return h * 0.58
            default: return h * 0.5
            }
        }()
        let x: CGFloat = slot.style == .gift ? w * 0.72 : w * 0.5
        return Text("\(slot.day)")
            .font(.system(size: d * 0.52, weight: .heavy, design: .serif))
            .italic()
            .foregroundStyle(Color.ink)
            .minimumScaleFactor(0.5)
            .frame(width: d, height: d)
            .background(Circle().fill(Color.cream))
            .overlay(Circle().stroke(Color.ink, lineWidth: line))
            .overlay(Circle().stroke(Color.goldLeaf, lineWidth: line * 0.8).padding(line * 1.4))
            .position(x: x, y: y)
    }
}

/// A side-to-side wiggle: "not yet!"
struct Shake: GeometryEffect {
    var phase: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 7 * sin(phase * .pi * 4), y: 0))
    }
}

/// A slow glow pulse for doors that are ready to open.
struct Pulse: ViewModifier {
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion ? 0.8 : (on ? 1 : 0.3))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

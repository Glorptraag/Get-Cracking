import SwiftUI

/// Visual language: chunky dark outlines, flat warm fills, toy-like buttons
/// with an offset "3D" shadow, hand-lettered caps for labels.
enum Theme {
    static let out = Color(hex: "#3b2224")
    static let cream = Color(hex: "#fdf3e4")
    static let paper = Color(hex: "#efe7da")
    static let pill = Color(hex: "#e9e4dc")
    static let teal = Color(hex: "#62b5c5")
    static let tealDark = Color(hex: "#4b9bab")
    static let gold = Color(hex: "#e0a43c")
    static let ink = Color(hex: "#4a3418")
    static let clay = Color(hex: "#d98a64")
    static let clayDark = Color(hex: "#b8694a")
    static let leaf = Color(hex: "#a9d36b")
    static let leafDark = Color(hex: "#7fb04a")
    static let berry = Color(hex: "#c9483f")
    static let danger = Color(hex: "#f6c9bd")

    /// hand-lettered caps (Patrick Hand SC)
    static func hand(_ size: CGFloat) -> Font { .custom("PatrickHandSC-Regular", size: size) }
    /// rounded body face (Fredoka)
    static func round(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black: return .custom("Fredoka-Bold", size: size)
        case .semibold, .medium: return .custom("Fredoka-SemiBold", size: size)
        default: return .custom("Fredoka-Regular", size: size)
        }
    }
}

/// The toy look: fill, dark border, and a solid dark "shadow" offset below.
struct ToyBackground: View {
    var fill: Color
    var radius: CGFloat
    var border: CGFloat = 4
    var depth: CGFloat = 4

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            shape.fill(Theme.out).offset(y: depth)
            shape.fill(fill)
            shape.strokeBorder(Theme.out, lineWidth: border)
        }
    }
}

extension View {
    func toy(_ fill: Color, radius: CGFloat, border: CGFloat = 4, depth: CGFloat = 4) -> some View {
        background(ToyBackground(fill: fill, radius: radius, border: border, depth: depth))
    }
}

/// A button that presses down into its shadow.
struct ToyButtonStyle: ButtonStyle {
    var fill: Color = Theme.cream
    var radius: CGFloat = 14
    var border: CGFloat = 4
    var depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(Theme.out)
            .background(ToyBackground(fill: fill, radius: radius, border: border, depth: pressed ? 1 : depth))
            .offset(y: pressed ? depth - 1 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

/// Cream letters with a dark outline (for text over the scene).
struct OutlinedText: View {
    let text: String
    var font: Font = Theme.hand(22)
    var color: Color = Theme.cream

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { k in
                let a = Double(k) / 8 * 2 * Double.pi
                Text(text).font(font).foregroundStyle(Theme.out).offset(x: 2 * cos(a), y: 2 * sin(a))
            }
            Text(text).font(font).foregroundStyle(Theme.out).offset(y: 2)
            Text(text).font(font).foregroundStyle(color)
        }
    }
}

/// The chunky on/off switch.
struct ToySwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? Theme.leafDark : Color(hex: "#8d8784"))
                Capsule().strokeBorder(Theme.out, lineWidth: 4)
                Circle().fill(Theme.cream).overlay(Circle().strokeBorder(Theme.out, lineWidth: 4))
                    .frame(width: 32, height: 32).padding(2)
            }
            .frame(width: 70, height: 36)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

/// Wraps its children onto as many lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0 && x + s.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            x += s.width + spacing
            rowH = max(rowH, s.height)
            maxX = max(maxX, x - spacing)
        }
        return CGSize(width: min(width, maxX), height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX && x + s.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}

/// Press-and-hold: a quick tap never triggers it. `progress` runs 0 → 1
/// while held so the caller can draw a filling ring or bar.
struct HoldGesture: ViewModifier {
    let seconds: Double
    let onHold: () -> Void
    var onTap: (() -> Void)? = nil
    @Binding var progress: Double

    @State private var pressing = false
    @State private var fired = false
    @State private var startedAt = Date()
    @State private var token = 0

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressing else { return }
                        pressing = true
                        fired = false
                        startedAt = Date()
                        token += 1
                        let mine = token
                        withAnimation(.linear(duration: seconds)) { progress = 1 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            guard pressing, token == mine else { return }
                            fired = true
                            pressing = false
                            withAnimation(.easeOut(duration: 0.15)) { progress = 0 }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onHold()
                        }
                    }
                    .onEnded { _ in
                        let quick = Date().timeIntervalSince(startedAt) < 0.35
                        if pressing && !fired && quick { onTap?() }
                        pressing = false
                        token += 1
                        withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
                    }
            )
            .accessibilityAction { onHold() }
    }
}

extension View {
    func holdable(_ seconds: Double, progress: Binding<Double>, onTap: (() -> Void)? = nil, onHold: @escaping () -> Void) -> some View {
        modifier(HoldGesture(seconds: seconds, onHold: onHold, onTap: onTap, progress: progress))
    }
}

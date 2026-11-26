import SwiftUI

/// Where a grown-up asked to see The Whole Nest. Every one is user-initiated:
/// Get Cracking never pops a paywall on its own.
enum PaywallPlacement: String, Identifiable {
    case settings, lockedFriend, lockedWorld, lockedSong, photoLimit, friendBook, lockedPack
    var id: String { rawValue }
}

/// The parental gate, then the paywall. Purchases and the Terms / Privacy
/// links sit behind it (Kids Category rule, Guideline 1.3).
struct GatedPaywall: View {
    let placement: PaywallPlacement
    #if DEBUG
    @State private var passed = DebugLaunch.skipsGate
    #else
    @State private var passed = false
    #endif

    var body: some View {
        Group {
            if passed {
                PaywallView(placement: placement)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                ParentalGate { withAnimation(.easeInOut(duration: 0.25)) { passed = true } }
            }
        }
        .onAppear { MonetizationLog.event("gate_shown", ["placement": placement.rawValue]) }
    }
}

/// "Ask a grown-up": add two numbers written as words. Early readers can't
/// read "nineteen plus twenty-three"; grown-ups answer in a second.
struct ParentalGate: View {
    let onPass: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var a = Int.random(in: 12...29)
    @State private var b = Int.random(in: 12...29)
    @State private var answer = ""
    @State private var wrong = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                CloseButton { dismiss() }
            }
            IconView(name: "lock", size: 56)
            Text("Ask a grown-up").font(Theme.hand(34))
                .accessibilityAddTraits(.isHeader)
            Text("For grown-ups: type the answer in numbers.")
                .font(Theme.round(16)).opacity(0.8)
                .multilineTextAlignment(.center)
            Text("\(Self.spelled(a)) plus \(Self.spelled(b))")
                .font(Theme.round(24, .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18).padding(.vertical, 10)
                .toy(Theme.cream, radius: 16)
            TextField("Answer", text: $answer)
                .font(Theme.round(28, .semibold))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($focused)
                .frame(width: 150, height: 56)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(wrong ? Theme.berry : Theme.out, lineWidth: 4))
                .accessibilityLabel("Answer")
                .onSubmit(check)
            if wrong {
                Text("Not quite. Here's a new one.").font(Theme.round(15)).foregroundStyle(Theme.berry)
            }
            Button(action: check) {
                Text("Continue").font(Theme.hand(26))
                    .padding(.horizontal, 30).frame(minHeight: 52)
            }
            .buttonStyle(ToyButtonStyle(fill: Theme.gold, radius: 18))
            .disabled(answer.isEmpty)
            Spacer()
        }
        .padding(24)
        .foregroundStyle(Theme.out)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper.ignoresSafeArea())
        .onAppear { focused = true }
    }

    private func check() {
        if Int(answer.trimmingCharacters(in: .whitespaces)) == a + b {
            MonetizationLog.event("gate_passed")
            onPass()
        } else {
            wrong = true
            answer = ""
            a = .random(in: 12...29)
            b = .random(in: 12...29)
        }
    }

    static func spelled(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .spellOut
        f.locale = Locale(identifier: "en")
        return f.string(from: n as NSNumber) ?? String(n)
    }
}

/// The round close button used on the sheets.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            IconView(name: "close", size: 28)
                .frame(width: 46, height: 46)
        }
        .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 23, border: 4, depth: 3))
        .accessibilityLabel("Close")
    }
}

/// A small lock badge for locked items in the grown-up pickers and the friend book.
struct LockBadge: View {
    var size: CGFloat = 26

    var body: some View {
        IconView(name: "lock", size: size * 0.66)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.cream))
            .overlay(Circle().strokeBorder(Theme.out, lineWidth: 2.5))
            .accessibilityHidden(true)
    }
}

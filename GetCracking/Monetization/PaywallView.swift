import StoreKit
import SwiftUI

/// The Whole Nest: one payment, everything unlocked, every future pack.
/// Shown only behind the parental gate, and only when a grown-up asks.
/// All copy speaks to the grown-up.
struct PaywallView: View {
    let placement: PaywallPlacement
    @Environment(EntitlementStore.self) private var store
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss
    @State private var buying = false
    @State private var restoring = false
    @State private var hero = PaywallHero.build()

    private let freeFriends = Packs.classic.starterFriends.count
    private let allFriends = Packs.allFriends.count
    private let allWorlds = Packs.allScenes.count

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    CloseButton { dismiss() }
                }

                StageView(root: hero, viewBox: PaywallHero.viewBox)
                    .aspectRatio(PaywallHero.viewBox.width / PaywallHero.viewBox.height, contentMode: .fit)
                    .background(Color(hex: "#f1e2bd"))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Theme.out, lineWidth: 5))
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text("The Whole Nest").font(Theme.hand(40))
                        .accessibilityAddTraits(.isHeader)
                    Text(headline).font(Theme.round(18, .semibold)).multilineTextAlignment(.center)
                }

                Text("The timer and \(freeFriends) friends are free, forever. The Whole Nest is for families who want every friend, world and song, plus every new pack as it arrives.")
                    .font(Theme.round(15)).opacity(0.8)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    bullet("hatch", "All \(allFriends) friends to hatch and collect in the friend book")
                    bullet("tree", "All \(allWorlds) worlds, from the Snowy Pines to the Coral Reef Tank")
                    bullet("drum", "Every hatching song, with the Jungle jam and Farmyard hoedown bands")
                    bullet("camera", "As many photo friends as you like: grandparents, pets, the whole family")
                    bullet("gift", "Every new pack of friends and worlds as it arrives, at no extra cost")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .toy(Theme.cream, radius: 18)

                purchaseBlock

                Text("Family Sharing is on: everyone in your family group gets The Whole Nest too.")
                    .font(Theme.round(14)).opacity(0.75)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                footer
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 30)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Theme.out)
        .background(Theme.paper.ignoresSafeArea())
        .task {
            MonetizationLog.event("paywall_shown", ["placement": placement.rawValue])
            if store.loadState != .loaded { await store.loadProducts() }
        }
        .onChange(of: store.hasWholeNest) { _, owned in
            if owned { MonetizationLog.event("paywall_converted", ["placement": placement.rawValue]) }
        }
    }

    private var headline: String {
        switch placement {
        case .lockedFriend, .friendBook: return "Every friend can hatch."
        case .lockedWorld: return "Every world for the egg to sit in."
        case .lockedSong: return "Every hatching song."
        case .photoLimit: return "Photo friends for the whole family."
        case .settings: return "Every friend, world and song."
        case .lockedPack: return "Every friend pack, now and later."
        }
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            IconView(name: icon, size: 26)
            Text(text).font(Theme.round(16)).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: price and buttons

    @ViewBuilder private var purchaseBlock: some View {
        if store.hasWholeNest {
            VStack(spacing: 8) {
                Text("You have The Whole Nest. Thank you!").font(Theme.hand(26)).multilineTextAlignment(.center)
                Button { dismiss() } label: {
                    Text("Done").font(Theme.hand(26)).padding(.horizontal, 34).frame(minHeight: 52)
                }
                .buttonStyle(ToyButtonStyle(fill: Theme.leaf, radius: 18))
            }
        } else if store.purchasePending {
            VStack(spacing: 6) {
                IconView(name: "clock", size: 40)
                Text("Waiting for a grown-up to approve").font(Theme.hand(26)).multilineTextAlignment(.center)
                Text("Once it's approved, everything unlocks here by itself.")
                    .font(Theme.round(14)).opacity(0.75).multilineTextAlignment(.center)
            }
            .padding(16).frame(maxWidth: .infinity).toy(Theme.cream, radius: 18)
        } else if let product = store.wholeNest {
            VStack(spacing: 8) {
                // the billed price is the biggest price on the page
                Text(product.displayPrice).font(Theme.round(44, .bold))
                    .accessibilityLabel("Price \(product.displayPrice)")
                Text("One payment. No subscription.").font(Theme.round(15)).opacity(0.8)
                Button { Task { await buy(product) } } label: {
                    Text(buying ? "Opening the App Store…" : "Unlock The Whole Nest")
                        .font(Theme.hand(28))
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(ToyButtonStyle(fill: Theme.gold, radius: 20, depth: 5))
                .disabled(buying || restoring)
                .accessibilityLabel("Unlock The Whole Nest for \(product.displayPrice)")
                if let err = store.lastError {
                    Text(err).font(Theme.round(14)).foregroundStyle(Theme.berry).multilineTextAlignment(.center)
                }
            }
        } else if store.loadState == .failed {
            VStack(spacing: 10) {
                Text("Couldn't reach the App Store just now.").font(Theme.round(16, .semibold)).multilineTextAlignment(.center)
                Button { Task { await store.loadProducts() } } label: {
                    Text("Try again").font(Theme.hand(24)).padding(.horizontal, 28).frame(minHeight: 50)
                }
                .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 16))
            }
        } else {
            ProgressView().tint(Theme.out).frame(minHeight: 120)
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if !store.hasWholeNest {
                Button { Task { await restore() } } label: {
                    Text(restoring ? "Restoring…" : "Restore Purchases")
                        .font(Theme.round(15, .semibold)).padding(.horizontal, 18).frame(minHeight: 44)
                }
                .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 14))
                .disabled(buying || restoring)
            }
            HStack(spacing: 22) {
                Link("Terms of Use", destination: LegalLinks.terms)
                Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
            }
            .font(Theme.round(14, .semibold))
            .underline()
            .tint(Theme.out)
        }
    }

    private func buy(_ product: Product) async {
        buying = true
        defer { buying = false }
        MonetizationLog.event("purchase_started", ["placement": placement.rawValue])
        do {
            let result = try await purchase(product)
            if await store.handle(result) {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                dismiss()
            }
        } catch {
            store.failed(error)
        }
    }

    private func restore() async {
        restoring = true
        await store.restore()
        restoring = false
    }
}

/// A few friends from The Whole Nest, drawn by the app's own renderer,
/// gathered round a nest.
enum PaywallHero {
    static let viewBox = CGRect(x: -330, y: -250, width: 660, height: 290)

    @MainActor
    static func build() -> VNode {
        let root = VNode()
        root.add(nEllipse(0, 6, 320, 34, St.o(6).filled("#cfe3a8")))
        // (id, x, scale): the middle friend stands in front
        let cast: [(String, Double, Double)] = [
            ("dragon", -230, 0.78), ("unicorn", 230, 0.78),
            ("panda", -118, 0.88), ("capybara", 118, 0.88),
            ("axolotl", 0, 1.0),
        ]
        for (id, x, k) in cast {
            guard let a = Animals.byId[id] else { continue }
            let node = Animals.render(a)
            root.add(nGroup([node], CGAffineTransform(translationX: x, y: 0).scaledBy(x: k, y: k)))
        }
        return root
    }
}

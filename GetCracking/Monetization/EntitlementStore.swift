import StoreKit
import Observation

/// StoreKit 2: loads The Whole Nest, tracks whether this family owns it, and
/// handles purchase results. Everything is local (StoreKit keeps the signed
/// receipts on the device), so it works offline once a purchase is known.
@MainActor
@Observable
final class EntitlementStore {
    enum LoadState: Equatable { case idle, loading, loaded, failed }

    private(set) var products: [String: Product] = [:]
    private(set) var owned: Set<String> = []
    private(set) var loadState: LoadState = .idle
    /// Ask to Buy (or extra authentication): the purchase waits for a grown-up
    private(set) var purchasePending = false
    private(set) var lastError: String?

    @ObservationIgnored private var updates: Task<Void, Never>?

    /// What StoreKit said last time, so the first frame after launch is right.
    /// Only a hint: `refreshEntitlements()` runs straight away and has the final word.
    private static let lastKnownKey = "gc.nest.lastKnown"
    static var lastKnownHasNest: Bool { UserDefaults.standard.bool(forKey: lastKnownKey) }

    var hasWholeNest: Bool { !owned.isDisjoint(with: ProductID.unlocksAll) }
    var gate: FeatureGate { FeatureGate(ownsWholeNest: hasWholeNest) }
    var wholeNest: Product? { products[ProductID.wholeNest] }

    init() {
        if Self.lastKnownHasNest { owned = ProductID.unlocksAll }
        // purchases finished elsewhere: Ask to Buy approvals, Family Sharing,
        // another device, refunds and revocations
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self?.apply(transaction)
            }
        }
    }

    /// Call once at launch.
    func start() async {
        await refreshEntitlements()
        await loadProducts()
    }

    func loadProducts() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            let fetched = try await Product.products(for: ProductID.all)
            products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            loadState = fetched.isEmpty ? .failed : .loaded
        } catch {
            loadState = .failed
        }
        MonetizationLog.event("products_loaded", ["state": "\(loadState)", "count": "\(products.count)"])
    }

    /// Re-read what this Apple ID (and its family) owns. Call at launch and on
    /// every return to the foreground: a refund or a family-sharing change
    /// while the app was away sends no update of its own.
    func refreshEntitlements() async {
        var ids = Set<String>()
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let t) = result, t.revocationDate == nil else { continue }
            ids.insert(t.productID)
        }
        owned = ids
        UserDefaults.standard.set(hasWholeNest, forKey: Self.lastKnownKey)
        if hasWholeNest { purchasePending = false }
    }

    /// Feed the result of `purchase(product)` in here. True when it unlocked.
    @discardableResult
    func handle(_ result: Product.PurchaseResult) async -> Bool {
        lastError = nil
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                lastError = "The App Store couldn't confirm that purchase. Nothing was charged twice; try Restore Purchases."
                MonetizationLog.event("purchase_failed", ["reason": "unverified"])
                return false
            }
            await apply(transaction)
            purchasePending = false
            MonetizationLog.event("purchase_succeeded", ["product": transaction.productID])
            return hasWholeNest
        case .pending:
            purchasePending = true
            MonetizationLog.event("purchase_pending")
            return false
        case .userCancelled:
            MonetizationLog.event("purchase_cancelled")
            return false
        @unknown default:
            return false
        }
    }

    func failed(_ error: Error) {
        lastError = "That didn't go through. Please try again."
        MonetizationLog.event("purchase_failed", ["error": String(describing: error)])
    }

    /// Restore Purchases: syncs with the App Store (may ask for the Apple ID password).
    func restore() async {
        lastError = nil
        do {
            try await AppStore.sync()
        } catch {
            lastError = "Couldn't reach the App Store. Check the connection and try again."
        }
        await refreshEntitlements()
        MonetizationLog.event("restore", ["owned": hasWholeNest ? "yes" : "no"])
    }

    private func apply(_ transaction: StoreKit.Transaction) async {
        await transaction.finish()
        await refreshEntitlements()
    }
}

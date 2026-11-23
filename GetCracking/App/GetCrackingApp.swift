import SwiftUI

@main
struct GetCrackingApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.store)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model
        ZStack {
            model.sceneBackground.ignoresSafeArea()
            if let run = model.run {
                TimerView(run: run)
                    .transition(.opacity)
            } else {
                SetupView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.run == nil)
        .statusBarHidden(true)
        .sheet(item: $model.sheet, onDismiss: {
            Sound.shared.stopMusic(fade: 0.3)
            // stop a song being previewed, but not the one celebrating a hatch
            if model.run?.phase != .hatched { Sound.shared.stopCelebration(fade: 0.3) }
        }) { kind in
            SheetView(kind: kind)
                .environment(model)
                .environment(model.store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
        }
        .onChange(of: model.settings) { _, new in Store.save(new) }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            model.run?.tick()
            // a refund or family-sharing change while away sends no update of its own
            Task { await model.store.refreshEntitlements() }
        }
        .onChange(of: model.store.hasWholeNest) { _, _ in model.applyOwnership() }
        .task {
            await model.store.start()
            model.applyOwnership()
        }
    }
}

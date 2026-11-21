import SwiftUI

@main
struct AdventEggsApp: App {
    @State private var store = AdventStore()

    var body: some Scene {
        WindowGroup {
            CalendarView()
                .environment(store)
                .preferredColorScheme(.light)
                .persistentSystemOverlays(.hidden)
        }
    }
}

#Preview("Calendar") {
    CalendarView().environment(AdventStore())
}

#Preview("Friends") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
            ForEach(Friend.all) { f in
                VStack {
                    FriendView(look: f.look).frame(width: 150, height: 150)
                    Text(f.name).font(.caption)
                }
            }
        }
    }
}

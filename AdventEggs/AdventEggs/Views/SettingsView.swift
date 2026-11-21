import SwiftUI

/// Grown-up settings, reached by pressing and holding the gear.
struct SettingsView: View {
    @Environment(AdventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Doors open at", selection: openingTime, displayedComponents: .hourAndMinute)
                } footer: {
                    Text("Each door opens at this time on its day in December. Its egg then cracks over the next 24 hours and is ready to hatch when the next door opens.")
                }

                Section {
                    Toggle("Let any door open", isOn: Binding(get: { store.openAnyDoor }, set: { store.setOpenAnyDoor($0) }))
                } footer: {
                    Text("For catching up or trying the calendar out. An egg opened early still takes 24 hours, unless you use Hatch now (press and hold the lock on the egg screen).")
                }

                Section("Sound") {
                    Toggle("Sounds", isOn: Binding(get: { store.soundsOn }, set: { store.setSoundsOn($0) }))
                    Toggle("Say each friend's name", isOn: Binding(get: { store.speakNames }, set: { store.setSpeakNames($0) }))
                }

                Section {
                    Button("Start the calendar again", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Closes every door and empties the gallery.")
                }
            }
            .navigationTitle("Grown-up settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Start the calendar again?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Close every door", role: .destructive) { store.resetAll() }
            } message: {
                Text("All doors close and the gallery is emptied.")
            }
        }
    }

    /// The opening time as a Date for the picker, stored as minutes after midnight.
    private var openingTime: Binding<Date> {
        Binding(
            get: {
                let cal = Calendar.current
                return cal.date(bySettingHour: store.openingMinute / 60, minute: store.openingMinute % 60,
                                second: 0, of: .now) ?? .now
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.setOpeningMinute((comps.hour ?? 7) * 60 + (comps.minute ?? 0))
            }
        )
    }
}

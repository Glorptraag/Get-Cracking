import SwiftUI

/// Every friend hatched so far, grouped by collection. Eggs not yet hatched
/// show as a numbered egg.
struct GalleryView: View {
    @Environment(AdventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Friend?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    ForEach(Theme.allCases) { theme in
                        section(theme)
                    }
                }
                .padding(16)
            }
            .background(Color.paper.ignoresSafeArea())
            .navigationTitle("My Friends  \(store.hatched.count)/25")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selected) { friend in
                FriendCard(friend: friend)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func section(_ theme: Theme) -> some View {
        let friends = Friend.all.filter { $0.theme == theme }
        let found = friends.filter { store.hatched.contains($0.day) }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(theme.title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                Spacer()
                Text("\(found) of \(friends.count)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(theme.tint))
            }
            .foregroundStyle(Color.ink)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(friends) { friend in
                    cell(friend)
                }
            }
        }
    }

    private func cell(_ friend: Friend) -> some View {
        let hatched = store.hatched.contains(friend.day)
        return Button {
            if hatched { selected = friend }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18).fill(hatched ? Color.cream : Color.white.opacity(0.5))
                    if hatched {
                        FriendView(look: friend.look, lively: false).padding(6)
                    } else {
                        EggCanvas(day: friend.day)
                            .padding(18)
                            .saturation(0)
                            .opacity(0.45)
                    }
                    Text("\(friend.day)")
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ink)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.white))
                        .overlay(Circle().stroke(Color.ink, lineWidth: 2))
                        .padding(6)
                }
                .aspectRatio(1, contentMode: .fit)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.ink, lineWidth: 3))
                Text(hatched ? friend.name : "?")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 34, alignment: .top)
            }
        }
        .buttonStyle(.plain)
        .disabled(!hatched)
        .accessibilityLabel(hatched ? "Day \(friend.day), \(friend.name)" : "Day \(friend.day), not hatched yet")
    }
}

/// One friend, big: tap to hear them again.
struct FriendCard: View {
    let friend: Friend
    @State private var jump = 0
    @State private var talking = false

    var body: some View {
        VStack(spacing: 16) {
            FriendView(look: friend.look, jump: jump, mouthOpen: talking)
                .frame(width: 280, height: 280)
                .contentShape(Rectangle())
                .onTapGesture { hello() }
            Pill(text: friend.name, size: 24)
            Text("Day \(friend.day) · \(friend.theme.title)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink.opacity(0.7))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
        .onAppear { hello() }
    }

    private func hello() {
        jump += 1
        SoundBox.shared.sayName(of: friend)
        talking = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            talking = false
        }
    }
}

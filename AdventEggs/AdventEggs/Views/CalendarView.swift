import SwiftUI

/// The advent calendar: the painted village with its 25 doors.
struct CalendarView: View {
    @Environment(AdventStore.self) private var store

    @State private var active: Friend?
    @State private var showGallery = false
    @State private var showSettings = false
    @State private var shakes: [Int: Int] = [:]
    @State private var bubble: (day: Int, text: String)?
    @State private var tapCount = 0

    private let topPadding: CGFloat = 76

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let fit = SceneFit(size: geo.size, topPadding: topPadding + geo.safeAreaInsets.top)
                // refresh every 30 s so doors open (and eggs crack) on their own
                TimelineView(.periodic(from: .now, by: 30)) { tl in
                    ZStack(alignment: .topLeading) {
                        Canvas { ctx, size in
                            VillagePainter(fit: fit).draw(in: ctx, size: size)
                        }
                        ForEach(DoorSlot.all) { slot in
                            door(slot, fit: fit, now: tl.date)
                        }
                        if let b = bubble, let slot = DoorSlot.all.first(where: { $0.day == b.day }) {
                            Pill(text: b.text, size: 17)
                                .fixedSize()
                                .position(fit.point(slot.rect.midX, slot.rect.minY - 10))
                                .offset(y: -24)
                                .transition(.scale.combined(with: .opacity))
                                .allowsHitTesting(false)
                        }
                        Snowfall()
                    }
                }
            }
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .fullScreenCover(item: $active) { friend in
            EggScreen(friend: friend) {
                active = nil
                Task {
                    try? await Task.sleep(for: .seconds(0.6))
                    showGallery = true
                }
            }
        }
        .sheet(isPresented: $showGallery) { GalleryView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onChange(of: store.soundsOn, initial: true) { SoundBox.shared.soundsOn = store.soundsOn }
        .onChange(of: store.speakNames, initial: true) { SoundBox.shared.speakNames = store.speakNames }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            Button { showGallery = true } label: {
                VStack(spacing: 2) {
                    RoundIcon(systemName: "book.closed.fill")
                    Text("\(store.hatched.count)/25")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
            }
            .accessibilityLabel("Gallery, \(store.hatched.count) of 25 friends")
            Spacer()
            Pill(text: "Advent Eggs", size: 22)
                .padding(.top, 4)
            Spacer()
            HoldButton(action: { showSettings = true }) {
                RoundIcon(systemName: "gearshape.fill")
            }
            .accessibilityLabel("Grown-up settings, press and hold")
        }
    }

    // MARK: doors

    private func status(_ day: Int, now: Date) -> DoorView.Status {
        guard store.isUnlocked(day, now: now) || store.opened.contains(day) else { return .locked }
        guard store.opened.contains(day) else { return .ready }
        let progress = store.eggProgress(day, now: now, doorOpenedAt: store.earlyOpenDate(day))
        return .open(step: EggPainter.step(for: progress), eggReady: progress >= 1, hatched: store.hatched.contains(day))
    }

    private func door(_ slot: DoorSlot, fit: SceneFit, now: Date) -> some View {
        let friend = Friend.forDay(slot.day)
        return DoorView(slot: slot, friend: friend, status: status(slot.day, now: now),
                        scale: fit.scale, shake: shakes[slot.day] ?? 0)
            .frame(width: slot.rect.width * fit.scale, height: slot.rect.height * fit.scale)
            .onTapGesture { tapped(slot.day, friend: friend) }
            .position(fit.point(slot.rect.midX, slot.rect.midY))
    }

    private func tapped(_ day: Int, friend: Friend) {
        tapCount += 1
        let now = Date.now
        if store.opened.contains(day) {
            active = friend
            return
        }
        guard store.isUnlocked(day, now: now) else {
            withAnimation(.linear(duration: 0.45)) { shakes[day, default: 0] += 1 }
            let sleeps = store.sleepsUntil(day, now: now)
            let text: String
            if sleeps == 0 {
                text = "Opens at " + store.openingDate(day, now: now).formatted(date: .omitted, time: .shortened)
            } else {
                text = sleeps == 1 ? "1 more sleep!" : "\(sleeps) more sleeps!"
            }
            showBubble(day, text)
            return
        }
        store.noteEarlyOpen(day, now: now)
        store.open(day)
        Task {
            try? await Task.sleep(for: .seconds(0.75))
            active = friend
        }
    }

    private func showBubble(_ day: Int, _ text: String) {
        withAnimation(.spring(response: 0.3)) { bubble = (day, text) }
        Task {
            try? await Task.sleep(for: .seconds(2))
            if bubble?.day == day {
                withAnimation { bubble = nil }
            }
        }
    }
}

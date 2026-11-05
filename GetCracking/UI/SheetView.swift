import SwiftUI
import PhotosUI

/// World, music, friend book and grown-up settings.
struct SheetView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let kind: SheetKind

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(kind.title).font(Theme.hand(32)).foregroundStyle(Theme.out)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { dismiss() } label: {
                    Text("✕").font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.out)
                        .frame(width: 46, height: 46)
                }
                .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 23, border: 4, depth: 3))
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch kind {
                    case .world:
                        WorldSection()
                    case .sound:
                        SoundSection()
                    case .book:
                        BookSection()
                    case .settings:
                        WorldSection()
                        SoundSection()
                        StyleSection()
                        HatchSection()
                        ScreenSection()
                        NextUpSection()
                        AboutSection()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .padding(.top, 6)
            }
        }
        .background(Theme.paper.ignoresSafeArea())
        .foregroundStyle(Theme.out)
        .tint(Theme.gold)
    }
}

// MARK: - building blocks

struct SheetSection<Content: View>: View {
    let title: String
    var hint: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.hand(24)).accessibilityAddTraits(.isHeader)
            if let hint {
                Text(hint).font(Theme.round(14)).opacity(0.75).padding(.bottom, 6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Option: Identifiable {
    let id: String
    let label: String
}

/// A row of chunky choice chips.
struct OptionChips: View {
    let options: [Option]
    let selected: String
    let onPick: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { o in
                Button { onPick(o.id) } label: {
                    Text(o.label).font(Theme.round(15, .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .frame(minHeight: 44)
                }
                .buttonStyle(ToyButtonStyle(fill: o.id == selected ? Theme.gold : Theme.cream, radius: 14))
                .accessibilityAddTraits(o.id == selected ? .isSelected : [])
            }
        }
    }
}

struct ToggleRow: View {
    let label: String
    var sub: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(Theme.round(16, .semibold))
                if let sub { Text(sub).font(Theme.round(13)).opacity(0.7) }
            }
            Spacer()
            ToySwitch(isOn: $isOn)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityAction { isOn.toggle() }
    }
}

// MARK: - world

struct WorldSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SheetSection(title: "World", hint: "Where the egg sits. Surprise me picks a different one each time.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                card(id: "random", name: "Surprise me") {
                    Text("🎲").font(.system(size: 40))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.pill)
                }
                ForEach(Scenes.list) { sc in
                    card(id: sc.id, name: sc.name) {
                        StageView(root: model.thumbnail(sc.id), viewBox: CGRect(x: 40, y: 90, width: 520, height: 540), animated: false)
                            .background(Color(hex: sc.bg))
                    }
                }
            }
        }
    }

    private func card<V: View>(id: String, name: String, @ViewBuilder art: () -> V) -> some View {
        let on = model.settings.scene == id
        return Button {
            model.settings.scene = id
            if model.run == nil { model.chooseScene() }
        } label: {
            VStack(spacing: 0) {
                art().aspectRatio(1, contentMode: .fit).clipped()
                Text(name).font(Theme.hand(15)).lineLimit(1).minimumScaleFactor(0.7)
                    .padding(.horizontal, 4).padding(.top, 2).padding(.bottom, 5)
            }
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ToyButtonStyle(fill: Theme.cream, radius: 16))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.gold, lineWidth: on ? 5 : 0).padding(-4))
        .accessibilityLabel(name)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

// MARK: - music & sounds

struct SoundSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        SheetSection(title: "Countdown music", hint: "Plays quietly while the timer runs. Tap one to hear a sample.") {
            OptionChips(options: Sound.music.map { Option(id: $0.id, label: "\($0.icon) \($0.name)") },
                        selected: model.settings.music) { id in
                model.settings.music = id
                Sound.shared.setVolume(model.settings.volume)
                Sound.shared.preview(music: id)
            }
            Text("Hatching tune").font(Theme.hand(24)).padding(.top, 18)
            Text("Plays when the egg hatches. Tap one to hear it.").font(Theme.round(14)).opacity(0.75).padding(.bottom, 6)
            OptionChips(options: Sound.endSounds.map { Option(id: $0.id, label: "\($0.icon) \($0.name)") },
                        selected: model.settings.endSound) { id in
                model.settings.endSound = id
                Sound.shared.setVolume(model.settings.volume)
                Sound.shared.preview(end: id)
            }
            HStack {
                Text("Volume").font(Theme.round(16, .semibold))
                Slider(value: $model.settings.volume, in: 0...1, step: 0.05, onEditingChanged: { editing in
                    if !editing { Sound.shared.boop() }
                })
                .onChange(of: model.settings.volume) { _, v in Sound.shared.setVolume(v) }
            }
            .padding(.top, 12)
            ToggleRow(label: "Say the friend's name", sub: "“It's a Fox!” (uses the device voice)", isOn: $model.settings.sayName)
        }
    }
}

// MARK: - hatch style

struct StyleSection: View {
    @Environment(AppModel.self) private var model
    @State private var preview = StylePreview()

    var body: some View {
        SheetSection(title: "Hatch style", hint: "What the shell does when the egg hatches. Tap a style to watch it, or tap the egg to replay.") {
            OptionChips(options: [Option(id: "random", label: "🎲 Surprise me")] + ShellFX.list.map { Option(id: $0.id, label: "\($0.icon) \($0.name)") },
                        selected: model.settings.hatchStyle) { id in
                model.settings.hatchStyle = id
                preview.play(id, volume: model.settings.volume)
            }
            StageView(root: preview.root, viewBox: CGRect(x: -200, y: -260, width: 400, height: 330))
                .aspectRatio(400.0 / 330.0, contentMode: .fit)
                .background(Color(hex: "#9fcdc4"))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.out, lineWidth: 4))
                .frame(maxWidth: 360)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .onTapGesture { preview.play(model.settings.hatchStyle, volume: model.settings.volume) }
                .accessibilityLabel("Hatch style preview. Tap to replay.")
                .accessibilityAddTraits(.isButton)
        }
    }
}

/// A little egg on a lawn that hatches on demand.
@MainActor
final class StylePreview {
    let root = VNode()
    private var busy = false

    init() { reset() }

    @discardableResult
    private func reset() -> Egg {
        root.removeAllChildren()
        root.add(nEllipse(0, 40, 190, 40, St.o(5).filled("#cfe3a8")))
        let egg = Egg(x: 0, y: 10, scale: 0.9)
        egg.setStep(8, silent: true)
        root.add(egg.root)
        return egg
    }

    func play(_ style: String, volume: Double) {
        guard !busy else { return }
        busy = true
        Sound.shared.ensure()
        Sound.shared.setVolume(volume)
        let egg = reset()
        let friend = Animals.render(GC.pick(Animals.list))
        Task { @MainActor in
            await egg.hatch(friend: friend, style: style == "random" ? nil : style) { Sound.shared.pop() }
            busy = false
        }
    }
}

// MARK: - who hatches

struct HatchSection: View {
    @Environment(AppModel.self) private var model
    @State private var picks: [PhotosPickerItem] = []

    var body: some View {
        SheetSection(title: "Who hatches?", hint: "Animals come in a shuffled order: no repeats until all 40 have hatched. Photos you add can hatch too and never leave this device.") {
            OptionChips(options: [Option(id: "animals", label: "🐾 Animals"), Option(id: "photos", label: "📷 My photos"), Option(id: "both", label: "🎁 Both")],
                        selected: model.settings.hatchWho) { model.settings.hatchWho = $0 }
            FlowLayout(spacing: 10) {
                ForEach(model.photos) { p in
                    Image(uiImage: p.image).resizable().scaledToFill()
                        .frame(width: 78, height: 78)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Theme.out, lineWidth: 4))
                        .overlay(alignment: .topTrailing) {
                            Button { model.removePhoto(p) } label: {
                                Text("✕").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.out)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color.white))
                                    .overlay(Circle().strokeBorder(Theme.out, lineWidth: 3))
                            }
                            .offset(x: 2, y: -2)
                            .accessibilityLabel("Remove photo")
                        }
                }
                PhotosPicker(selection: $picks, maxSelectionCount: 12, matching: .images) {
                    Text("＋").font(.system(size: 30)).foregroundStyle(Theme.out)
                        .frame(width: 78, height: 78)
                        .overlay(Circle().strokeBorder(Theme.out, style: StrokeStyle(lineWidth: 4, dash: [8, 6])))
                }
                .accessibilityLabel("Add photos")
            }
            .padding(.top, 12)
            .onChange(of: picks) { _, items in
                guard !items.isEmpty else { return }
                Task { @MainActor in
                    var images: [UIImage] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) { images.append(img) }
                    }
                    model.addPhotos(images)
                    picks = []
                }
            }

            Text("When time is up").font(Theme.hand(24)).padding(.top, 18)
            Text("Wait for a tap: the egg wiggles and knocks until someone taps it. Hatch by itself: it hatches the moment time runs out.")
                .font(Theme.round(14)).opacity(0.75).padding(.bottom, 6)
                .fixedSize(horizontal: false, vertical: true)
            OptionChips(options: [Option(id: "tap", label: "👆 Wait for a tap"), Option(id: "auto", label: "🐣 Hatch by itself")],
                        selected: model.settings.hatchMode) { model.settings.hatchMode = $0 }
        }
    }
}

// MARK: - timer screen

struct ScreenSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        SheetSection(title: "Timer screen", hint: "Pause, ±1 minute and Stop are always available behind the 🔒 in the bottom corner. The options below put extra buttons on screen.") {
            ToggleRow(label: "Long-press 🔒 for grown-up controls", sub: "A quick tap does nothing, so little fingers can't stop the timer", isOn: $model.settings.longPressStop)
            HStack {
                Text("Hold for").font(Theme.round(16, .semibold))
                Spacer()
                OptionChips(options: [1.0, 1.5, 2, 3].map { Option(id: String($0), label: "\($0.formatted())s") },
                            selected: String(model.settings.holdSeconds)) { id in
                    if let v = Double(id) { model.settings.holdSeconds = v }
                }
                .fixedSize()
            }
            ToggleRow(label: "Show pause button", sub: "Always on screen (one tap)", isOn: $model.settings.showPause)
            ToggleRow(label: "Show −1 / +1 minute buttons", sub: "Always on screen (one tap)", isOn: $model.settings.showAdjust)
            ToggleRow(label: "Show numbers", sub: "Small clock in the corner for grown-ups", isOn: $model.settings.showNumbers)
        }
    }
}

// MARK: - next up

struct NextUpSection: View {
    @Environment(AppModel.self) private var model
    @State private var pick: PhotosPickerItem?

    private let icons = ["🧸", "🛁", "🥣", "🧦", "🦷", "📚", "🛏️", "🚗", "🧩", "🎨", "🍎", "🧥", "🖍️", "🚽", "🏃", "⭐"]

    var body: some View {
        @Bindable var model = model
        SheetSection(title: "Next up card", hint: "Shown after the hatch: what happens next, with an icon or your own photo.") {
            ToggleRow(label: "Show a “Next up” card", isOn: $model.settings.nextUp.on)
            TextField("e.g. Bath time", text: $model.settings.nextUp.text)
                .font(Theme.round(17))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.cream))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.out, lineWidth: 4))
                .onChange(of: model.settings.nextUp.text) { _, t in
                    if t.count > 40 { model.settings.nextUp.text = String(t.prefix(40)) }
                }
            FlowLayout(spacing: 6) {
                ForEach(icons, id: \.self) { ic in
                    let on = model.settings.nextUp.photo == nil && model.settings.nextUp.icon == ic
                    Button {
                        if let old = model.settings.nextUp.photo { PhotoStore.remove(old) }
                        model.settings.nextUp.photo = nil
                        model.settings.nextUp.icon = ic
                    } label: {
                        Text(ic).font(.system(size: 24)).frame(width: 46, height: 46)
                            .background(RoundedRectangle(cornerRadius: 12).fill(on ? Theme.gold : Theme.cream))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.out, lineWidth: 3))
                    }
                    .buttonStyle(PressDown())
                }
                PhotosPicker(selection: $pick, matching: .images) {
                    Text(model.settings.nextUp.photo == nil ? "📷" : "🖼️").font(.system(size: 24)).frame(width: 46, height: 46)
                        .background(RoundedRectangle(cornerRadius: 12).fill(model.settings.nextUp.photo == nil ? Theme.cream : Theme.gold))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.out, lineWidth: 3))
                }
                .accessibilityLabel("Use a photo")
            }
            .padding(.top, 8)
            .onChange(of: pick) { _, item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                        model.setNextUpPhoto(img)
                    }
                    pick = nil
                }
            }
        }
    }
}

// MARK: - about

struct AboutSection: View {
    @Environment(AppModel.self) private var model
    @State private var confirmBook = false
    @State private var confirmSettings = false

    var body: some View {
        SheetSection(title: "About", hint: "Get Cracking works fully offline. No login, no account, no ads — settings, photos and the friend book stay on this device.") {
            FlowLayout(spacing: 8) {
                Button { confirmBook = true } label: {
                    Text("🧹 Reset friend book").font(Theme.round(15, .semibold)).padding(.horizontal, 14).frame(minHeight: 44)
                }
                .buttonStyle(ToyButtonStyle())
                Button { confirmSettings = true } label: {
                    Text("↺ Reset settings").font(Theme.round(15, .semibold)).padding(.horizontal, 14).frame(minHeight: 44)
                }
                .buttonStyle(ToyButtonStyle())
            }
        }
        .confirmationDialog("Clear the friend book?", isPresented: $confirmBook, titleVisibility: .visible) {
            Button("Clear friend book", role: .destructive) { model.resetBook() }
        }
        .confirmationDialog("Reset all settings?", isPresented: $confirmSettings, titleVisibility: .visible) {
            Button("Reset settings", role: .destructive) { model.resetSettings() }
        }
    }
}

// MARK: - friend book

struct BookSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let book = model.book
        let found = Animals.list.filter { (book[$0.id] ?? 0) > 0 }.count
        SheetSection(title: "\(found) of \(Animals.list.count) friends found", hint: "Every hatch adds a friend to the book.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(Animals.list) { a in
                    BookCard(animal: a, count: book[a.id] ?? 0)
                }
            }
        }
    }
}

struct BookCard: View {
    let animal: AnimalDef
    let count: Int
    @State private var node: VNode?

    var body: some View {
        let seen = count > 0
        VStack(spacing: 2) {
            Group {
                if let node {
                    StageView(root: node, viewBox: CGRect(x: -112, y: -218, width: 224, height: 232), animated: false)
                } else {
                    Color.clear
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .colorMultiply(seen ? .white : .black)
            .opacity(seen ? 1 : 0.18)
            Text(seen ? animal.name : "?").font(Theme.hand(15)).lineLimit(1).minimumScaleFactor(0.7)
                .opacity(seen ? 1 : 0.45)
        }
        .padding(.top, 4).padding(.bottom, 6).padding(.horizontal, 2)
        .toy(Theme.cream, radius: 16)
        .overlay(alignment: .topTrailing) {
            if count > 1 {
                Text("×\(count)").font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .background(Capsule().fill(Theme.gold))
                    .overlay(Capsule().strokeBorder(Theme.out, lineWidth: 2))
                    .padding(4)
            }
        }
        .onAppear { if node == nil { node = Animals.render(animal) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(seen ? (count > 1 ? "\(animal.name), hatched \(count) times" : animal.name) : "Not found yet")
    }
}

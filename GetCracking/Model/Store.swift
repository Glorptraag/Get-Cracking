import SwiftUI
import UIKit

/// Local-only storage. No accounts, no network.
/// Settings + friend book live in UserDefaults; photos as JPEG files in
/// Application Support.

struct NextUp: Codable, Equatable {
    var on = false
    var text = "Tidy-up time"
    var icon = "🧸"
    /// file name of a photo in the photo folder, if one was picked
    var photo: String? = nil
}

struct Settings: Codable, Equatable {
    var minutes = 5
    var seconds = 0
    var scene = "random"        // scene id or "random"
    var music = "musicbox"
    var endSound = "tada"
    var volume = 0.7
    var sayName = true
    var hatchWho = "animals"    // "animals" | "photos" | "both"
    var hatchStyle = "random"   // shell effect id, or "random"
    var hatchMode = "tap"       // "tap" (hatch waits for you) | "auto"
    var showPause = false       // pause button visible on the timer screen
    var showAdjust = false      // −/+ time buttons visible on the timer screen
    var longPressStop = true    // grown-up controls need a long press
    var holdSeconds = 1.5
    var showNumbers = true      // small m:ss for grown-ups
    var nextUp = NextUp()
    var seenHint = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Settings()
        minutes = (try? c.decodeIfPresent(Int.self, forKey: .minutes)) ?? d.minutes
        seconds = (try? c.decodeIfPresent(Int.self, forKey: .seconds)) ?? d.seconds
        scene = (try? c.decodeIfPresent(String.self, forKey: .scene)) ?? d.scene
        music = (try? c.decodeIfPresent(String.self, forKey: .music)) ?? d.music
        endSound = (try? c.decodeIfPresent(String.self, forKey: .endSound)) ?? d.endSound
        volume = (try? c.decodeIfPresent(Double.self, forKey: .volume)) ?? d.volume
        sayName = (try? c.decodeIfPresent(Bool.self, forKey: .sayName)) ?? d.sayName
        hatchWho = (try? c.decodeIfPresent(String.self, forKey: .hatchWho)) ?? d.hatchWho
        hatchStyle = (try? c.decodeIfPresent(String.self, forKey: .hatchStyle)) ?? d.hatchStyle
        hatchMode = (try? c.decodeIfPresent(String.self, forKey: .hatchMode)) ?? d.hatchMode
        showPause = (try? c.decodeIfPresent(Bool.self, forKey: .showPause)) ?? d.showPause
        showAdjust = (try? c.decodeIfPresent(Bool.self, forKey: .showAdjust)) ?? d.showAdjust
        longPressStop = (try? c.decodeIfPresent(Bool.self, forKey: .longPressStop)) ?? d.longPressStop
        holdSeconds = (try? c.decodeIfPresent(Double.self, forKey: .holdSeconds)) ?? d.holdSeconds
        showNumbers = (try? c.decodeIfPresent(Bool.self, forKey: .showNumbers)) ?? d.showNumbers
        nextUp = (try? c.decodeIfPresent(NextUp.self, forKey: .nextUp)) ?? d.nextUp
        seenHint = (try? c.decodeIfPresent(Bool.self, forKey: .seenHint)) ?? d.seenHint
    }

    /// total length of the timer in seconds (never less than 10 s)
    var totalSeconds: Double { Double(max(10, minutes * 60 + seconds)) }
}

enum Store {
    private static let settingsKey = "gc.settings.v1"
    private static let bookKey = "gc.book.v1"

    static func loadSettings() -> Settings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let s = try? JSONDecoder().decode(Settings.self, from: data) else { return Settings() }
        return s
    }

    static func save(_ s: Settings) {
        if let data = try? JSONEncoder().encode(s) { UserDefaults.standard.set(data, forKey: settingsKey) }
    }

    /// friend book: id → times hatched
    static func book() -> [String: Int] {
        (UserDefaults.standard.dictionary(forKey: bookKey) as? [String: Int]) ?? [:]
    }

    @discardableResult
    static func addToBook(_ id: String) -> [String: Int] {
        var b = book()
        b[id, default: 0] += 1
        UserDefaults.standard.set(b, forKey: bookKey)
        return b
    }

    static func resetBook() { UserDefaults.standard.removeObject(forKey: bookKey) }
}

struct PhotoItem: Identifiable, Equatable {
    let id: String      // file name
    let image: UIImage
    static func == (a: PhotoItem, b: PhotoItem) -> Bool { a.id == b.id }
}

/// Photos that can hatch from the egg. They never leave the device.
enum PhotoStore {
    static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            var v = URLResourceValues()
            v.isExcludedFromBackup = false
            var d = dir
            try? d.setResourceValues(v)
        }
        return dir
    }

    /// the hatchable photos, oldest first (the "next up" photo is kept separately)
    static func list() -> [PhotoItem] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: folder.path) else { return [] }
        return names.filter { $0.hasPrefix("ph") && $0.hasSuffix(".jpg") }.sorted().compactMap { name in
            guard let img = UIImage(contentsOfFile: folder.appendingPathComponent(name).path) else { return nil }
            return PhotoItem(id: name, image: img)
        }
    }

    /// Centre-crop to a square, shrink, and save. Returns the file name.
    @discardableResult
    static func add(_ image: UIImage, size: CGFloat = 480, prefix: String = "ph") -> String? {
        guard let data = squareJPEG(image, size: size) else { return nil }
        let stamp = Int(Date().timeIntervalSince1970 * 1000)
        let name = "\(prefix)\(stamp)\(Int.random(in: 1000...9999)).jpg"
        do {
            try data.write(to: folder.appendingPathComponent(name), options: [.atomic, .completeFileProtection])
            return name
        } catch {
            return nil
        }
    }

    static func remove(_ name: String) {
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }

    static func image(_ name: String?) -> UIImage? {
        guard let name else { return nil }
        return UIImage(contentsOfFile: folder.appendingPathComponent(name).path)
    }

    static func squareJPEG(_ image: UIImage, size: CGFloat) -> Data? {
        let w = image.size.width, h = image.size.height
        guard w > 0, h > 0 else { return nil }
        let s = min(w, h)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let r = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        let out = r.image { _ in
            let k = size / s
            image.draw(in: CGRect(x: -(w - s) / 2 * k, y: -(h - s) / 2 * k, width: w * k, height: h * k))
        }
        return out.jpegData(compressionQuality: 0.85)
    }
}

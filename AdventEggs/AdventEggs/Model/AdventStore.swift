import SwiftUI
import Observation

/// Which doors are open, which eggs have hatched, and the grown-up settings.
/// Saved in UserDefaults; nothing leaves the device.
///
/// The calendar's clock: door `day` opens at the opening time on `day`
/// December. Its egg is a 24-hour egg: it cracks in 8 steps over the next
/// 24 hours (like Get Cracking's timer) and is ready to hatch the moment the
/// next door opens. A ready egg waits for a tap.
@Observable
final class AdventStore {
    private(set) var opened: Set<Int>
    private(set) var hatched: Set<Int>
    private(set) var hatchedOrder: [Int]
    /// Eggs a grown-up has made ready early with "Hatch now".
    private(set) var hurried: Set<Int>
    private(set) var openAnyDoor: Bool
    private(set) var speakNames: Bool
    private(set) var soundsOn: Bool
    /// Minutes after midnight that each door opens (default 7:00 am).
    private(set) var openingMinute: Int

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        opened = Set(defaults.array(forKey: Keys.opened) as? [Int] ?? [])
        hatchedOrder = defaults.array(forKey: Keys.hatched) as? [Int] ?? []
        hatched = Set(defaults.array(forKey: Keys.hatched) as? [Int] ?? [])
        hurried = Set(defaults.array(forKey: Keys.hurried) as? [Int] ?? [])
        openAnyDoor = defaults.bool(forKey: Keys.openAny)
        speakNames = defaults.object(forKey: Keys.speak) as? Bool ?? true
        soundsOn = defaults.object(forKey: Keys.sounds) as? Bool ?? true
        openingMinute = defaults.object(forKey: Keys.openingMinute) as? Int ?? 7 * 60
    }

    // MARK: - Doors and eggs

    func open(_ day: Int) {
        guard !opened.contains(day) else { return }
        opened.insert(day)
        defaults.set(Array(opened), forKey: Keys.opened)
    }

    func hatch(_ day: Int) {
        open(day)
        guard !hatched.contains(day) else { return }
        hatched.insert(day)
        hatchedOrder.append(day)
        defaults.set(hatchedOrder, forKey: Keys.hatched)
    }

    /// Grown-up "Hatch now": the egg is ready straight away.
    func hurry(_ day: Int) {
        hurried.insert(day)
        defaults.set(Array(hurried), forKey: Keys.hurried)
    }

    func resetAll() {
        opened = []
        hatched = []
        hatchedOrder = []
        hurried = []
        for k in [Keys.opened, Keys.hatched, Keys.hurried] { defaults.removeObject(forKey: k) }
    }

    // MARK: - Settings

    func setOpenAnyDoor(_ on: Bool) { openAnyDoor = on; defaults.set(on, forKey: Keys.openAny) }
    func setSpeakNames(_ on: Bool) { speakNames = on; defaults.set(on, forKey: Keys.speak) }
    func setSoundsOn(_ on: Bool) { soundsOn = on; defaults.set(on, forKey: Keys.sounds) }
    func setOpeningMinute(_ m: Int) {
        openingMinute = min(max(m, 0), 23 * 60 + 59)
        defaults.set(openingMinute, forKey: Keys.openingMinute)
    }

    // MARK: - The calendar clock

    func openingDate(_ day: Int, now: Date = .now) -> Date {
        AdventDate.opening(day, minute: openingMinute, now: now)
    }

    func isUnlocked(_ day: Int, now: Date = .now) -> Bool {
        openAnyDoor || now >= openingDate(day, now: now)
    }

    /// How far through its 24 hours day `day`'s egg is, 0...1.
    /// An egg opened early with the grown-up override starts its 24 hours
    /// from when its door was first opened, so it still cracks properly.
    func eggProgress(_ day: Int, now: Date = .now, doorOpenedAt: Date? = nil) -> Double {
        if hurried.contains(day) { return 1 }
        var start = openingDate(day, now: now)
        if now < start, let early = doorOpenedAt { start = early }
        let elapsed = now.timeIntervalSince(start)
        return min(max(elapsed / AdventDate.eggSeconds, 0), 1)
    }

    func isReadyToHatch(_ day: Int, now: Date = .now, doorOpenedAt: Date? = nil) -> Bool {
        eggProgress(day, now: now, doorOpenedAt: doorOpenedAt) >= 1
    }

    /// When an early-opened door was first opened (for the override case).
    func earlyOpenDate(_ day: Int) -> Date? {
        let t = defaults.double(forKey: Keys.earlyOpen + String(day))
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    func noteEarlyOpen(_ day: Int, now: Date = .now) {
        guard now < openingDate(day, now: now), earlyOpenDate(day) == nil else { return }
        defaults.set(now.timeIntervalSince1970, forKey: Keys.earlyOpen + String(day))
    }

    func sleepsUntil(_ day: Int, now: Date = .now) -> Int {
        AdventDate.sleepsUntil(day, now: now)
    }

    private enum Keys {
        static let opened = "advent.opened"
        static let hatched = "advent.hatched"
        static let hurried = "advent.hurried"
        static let openAny = "advent.openAnyDoor"
        static let speak = "advent.speakNames"
        static let sounds = "advent.sounds"
        static let openingMinute = "advent.openingMinute"
        static let earlyOpen = "advent.earlyOpen."
    }
}

enum AdventDate {
    static let eggSeconds: Double = 24 * 60 * 60

    /// The December this calendar belongs to: this year's, or last year's
    /// while it is still January.
    static func seasonYear(now: Date, calendar: Calendar = .current) -> Int {
        let year = calendar.component(.year, from: now)
        return calendar.component(.month, from: now) == 1 ? year - 1 : year
    }

    static func opening(_ day: Int, minute: Int, now: Date, calendar: Calendar = .current) -> Date {
        let comps = DateComponents(year: seasonYear(now: now, calendar: calendar), month: 12, day: day,
                                   hour: minute / 60, minute: minute % 60)
        return calendar.date(from: comps) ?? now
    }

    /// How many nights until door `day` opens (0 if today or already open).
    static func sleepsUntil(_ day: Int, now: Date, calendar: Calendar = .current) -> Int {
        let comps = DateComponents(year: seasonYear(now: now, calendar: calendar), month: 12, day: day)
        guard let target = calendar.date(from: comps) else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: target).day ?? 0
        return max(0, days)
    }
}

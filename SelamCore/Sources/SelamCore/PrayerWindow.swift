import Foundation

/// The interval during which a prayer can be performed on time.
public struct PrayerWindow: Equatable, Sendable {
    public let prayer: Prayer
    public let start: Date
    public let end: Date

    public init(prayer: Prayer, start: Date, end: Date) {
        self.prayer = prayer
        self.start = start
        self.end = end
    }
}

public enum PrayerWindows {
    /// Minimum isha window, used when the night midpoint falls before isha (high latitudes).
    static let minimumIshaWindow: TimeInterval = 3_600

    /// Windows per spec 4.3. Isha ends at the midpoint between maghrib and the next fajr.
    public static func windows(for day: DayTimes) -> [PrayerWindow] {
        let nightMidpoint = day.maghrib.addingTimeInterval(day.nextFajr.timeIntervalSince(day.maghrib) / 2)
        let ishaEnd = max(nightMidpoint, day.isha.addingTimeInterval(minimumIshaWindow))
        return [
            PrayerWindow(prayer: .fajr, start: day.fajr, end: day.sunrise),
            PrayerWindow(prayer: .dhuhr, start: day.dhuhr, end: day.asr),
            PrayerWindow(prayer: .asr, start: day.asr, end: day.maghrib),
            PrayerWindow(prayer: .maghrib, start: day.maghrib, end: day.isha),
            PrayerWindow(prayer: .isha, start: day.isha, end: ishaEnd),
        ]
    }
}

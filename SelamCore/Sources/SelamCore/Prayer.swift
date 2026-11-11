import Foundation

/// The five obligatory prayers.
public enum Prayer: String, CaseIterable, Codable, Sendable {
    case fajr, dhuhr, asr, maghrib, isha
}

/// Prayer instants for one calendar day at one location, plus the following day's fajr.
public struct DayTimes: Equatable, Sendable {
    public let fajr: Date
    public let sunrise: Date
    public let dhuhr: Date
    public let asr: Date
    public let maghrib: Date
    public let isha: Date
    public let nextFajr: Date

    public init(fajr: Date, sunrise: Date, dhuhr: Date, asr: Date, maghrib: Date, isha: Date, nextFajr: Date) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.nextFajr = nextFajr
    }

    public func adhan(_ prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: fajr
        case .dhuhr: dhuhr
        case .asr: asr
        case .maghrib: maghrib
        case .isha: isha
        }
    }
}

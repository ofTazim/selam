import Adhan
import Foundation

public struct Coordinate: Equatable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// The only file in SelamCore that touches Adhan.
public enum PrayerCalculator {
    /// Prayer times for the calendar day that contains `date` in `timeZone`.
    public static func dayTimes(
        on date: Date,
        at coordinate: Coordinate,
        timeZone: TimeZone,
        settings: CalcSettings
    ) -> DayTimes? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let parameters = parameters(for: settings)

        let todayParts = calendar.dateComponents([.year, .month, .day], from: date)
        let tomorrowParts = calendar.dateComponents([.year, .month, .day], from: tomorrow)

        guard
            let today = PrayerTimes(coordinates: coordinates, date: todayParts, calculationParameters: parameters),
            let next = PrayerTimes(coordinates: coordinates, date: tomorrowParts, calculationParameters: parameters)
        else { return nil }

        return DayTimes(
            fajr: today.fajr,
            sunrise: today.sunrise,
            dhuhr: today.dhuhr,
            asr: today.asr,
            maghrib: today.maghrib,
            isha: today.isha,
            nextFajr: next.fajr
        )
    }

    private static func parameters(for settings: CalcSettings) -> CalculationParameters {
        var parameters = method(settings.method).params
        parameters.madhab = settings.madhab == .hanafi ? .hanafi : .shafi
        parameters.highLatitudeRule = highLatitudeRule(settings.highLatitudeRule)
        parameters.adjustments = PrayerAdjustments(
            fajr: settings.adjustments[.fajr] ?? 0,
            sunrise: 0,
            dhuhr: settings.adjustments[.dhuhr] ?? 0,
            asr: settings.adjustments[.asr] ?? 0,
            maghrib: settings.adjustments[.maghrib] ?? 0,
            isha: settings.adjustments[.isha] ?? 0
        )
        return parameters
    }

    private static func method(_ method: CalcMethod) -> CalculationMethod {
        switch method {
        case .muslimWorldLeague: .muslimWorldLeague
        case .egyptian: .egyptian
        case .karachi: .karachi
        case .ummAlQura: .ummAlQura
        case .dubai: .dubai
        case .moonsightingCommittee: .moonsightingCommittee
        case .northAmerica: .northAmerica
        case .kuwait: .kuwait
        case .qatar: .qatar
        case .singapore: .singapore
        case .tehran: .tehran
        case .turkey: .turkey
        }
    }

    private static func highLatitudeRule(_ rule: SelamCore.HighLatitudeRule) -> Adhan.HighLatitudeRule {
        switch rule {
        case .middleOfTheNight: .middleOfTheNight
        case .seventhOfTheNight: .seventhOfTheNight
        case .twilightAngle: .twilightAngle
        }
    }
}

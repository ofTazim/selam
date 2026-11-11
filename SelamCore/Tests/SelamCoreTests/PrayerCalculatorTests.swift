import XCTest
@testable import SelamCore

final class PrayerCalculatorTests: XCTestCase {
    private let istanbul = Coordinate(latitude: 41.0082, longitude: 28.9784)
    private let istanbulZone = TimeZone(identifier: "Europe/Istanbul")!
    private let mecca = Coordinate(latitude: 21.4225, longitude: 39.8262)
    private let meccaZone = TimeZone(identifier: "Asia/Riyadh")!

    /// Noon local time on 2026-11-11 in the given zone.
    private func noon(in zone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 12))!
    }

    private func localMinutes(_ date: Date, in zone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return parts.hour! * 60 + parts.minute!
    }

    func testIstanbulTimesAreOrdered() throws {
        let day = try XCTUnwrap(PrayerCalculator.dayTimes(
            on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone,
            settings: MethodResolver.defaults(forCountryCode: "TR")
        ))

        XCTAssertLessThan(day.fajr, day.sunrise)
        XCTAssertLessThan(day.sunrise, day.dhuhr)
        XCTAssertLessThan(day.dhuhr, day.asr)
        XCTAssertLessThan(day.asr, day.maghrib)
        XCTAssertLessThan(day.maghrib, day.isha)
        XCTAssertLessThan(day.isha, day.nextFajr)
    }

    func testIstanbulNovemberTimesFallInPlausibleLocalRanges() throws {
        let day = try XCTUnwrap(PrayerCalculator.dayTimes(
            on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone,
            settings: MethodResolver.defaults(forCountryCode: "TR")
        ))

        // Mid-November Istanbul (UTC+3): solar noon is shortly before 13:00, sunset shortly before 18:00.
        XCTAssertTrue((5 * 60 + 30...6 * 60 + 30).contains(localMinutes(day.fajr, in: istanbulZone)))
        XCTAssertTrue((7 * 60 + 15...8 * 60).contains(localMinutes(day.sunrise, in: istanbulZone)))
        XCTAssertTrue((12 * 60 + 40...13 * 60 + 10).contains(localMinutes(day.dhuhr, in: istanbulZone)))
        XCTAssertTrue((15 * 60...16 * 60).contains(localMinutes(day.asr, in: istanbulZone)))
        XCTAssertTrue((17 * 60 + 30...18 * 60 + 15).contains(localMinutes(day.maghrib, in: istanbulZone)))
        XCTAssertTrue((18 * 60 + 45...19 * 60 + 45).contains(localMinutes(day.isha, in: istanbulZone)))
    }

    func testNextFajrIsRoughlyOneDayAfterFajr() throws {
        let day = try XCTUnwrap(PrayerCalculator.dayTimes(
            on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone,
            settings: MethodResolver.defaults(forCountryCode: "TR")
        ))

        let gap = day.nextFajr.timeIntervalSince(day.fajr)
        XCTAssertEqual(gap, 86_400, accuracy: 300)
    }

    func testHanafiAsrIsLaterThanStandardAsr() throws {
        let standard = CalcSettings(method: .karachi, madhab: .standard)
        let hanafi = CalcSettings(method: .karachi, madhab: .hanafi)

        let standardDay = try XCTUnwrap(PrayerCalculator.dayTimes(on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone, settings: standard))
        let hanafiDay = try XCTUnwrap(PrayerCalculator.dayTimes(on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone, settings: hanafi))

        XCTAssertGreaterThan(hanafiDay.asr, standardDay.asr.addingTimeInterval(20 * 60))
        XCTAssertEqual(hanafiDay.dhuhr, standardDay.dhuhr)
    }

    func testAdjustmentsShiftOnlyTheAdjustedPrayer() throws {
        let base = MethodResolver.defaults(forCountryCode: "TR")
        var adjusted = base
        adjusted.adjustments = [.dhuhr: 3]

        let baseDay = try XCTUnwrap(PrayerCalculator.dayTimes(on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone, settings: base))
        let adjustedDay = try XCTUnwrap(PrayerCalculator.dayTimes(on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone, settings: adjusted))

        XCTAssertEqual(adjustedDay.dhuhr.timeIntervalSince(baseDay.dhuhr), 180, accuracy: 60)
        XCTAssertEqual(adjustedDay.asr, baseDay.asr)
        XCTAssertEqual(adjustedDay.fajr, baseDay.fajr)
    }

    func testCalendarDayIsTakenFromTheLocationTimeZone() throws {
        // 2026-11-11 23:30 in Istanbul is still the 11th there, although it is 20:30 UTC.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = istanbulZone
        let lateEvening = calendar.date(from: DateComponents(year: 2026, month: 11, day: 11, hour: 23, minute: 30))!
        let settings = MethodResolver.defaults(forCountryCode: "TR")

        let fromNoon = try XCTUnwrap(PrayerCalculator.dayTimes(on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone, settings: settings))
        let fromEvening = try XCTUnwrap(PrayerCalculator.dayTimes(on: lateEvening, at: istanbul, timeZone: istanbulZone, settings: settings))

        XCTAssertEqual(fromEvening, fromNoon)
    }

    func testMeccaWithUmmAlQuraIsOrderedAndDhuhrIsNearNoon() throws {
        let day = try XCTUnwrap(PrayerCalculator.dayTimes(
            on: noon(in: meccaZone), at: mecca, timeZone: meccaZone,
            settings: MethodResolver.defaults(forCountryCode: "SA")
        ))

        XCTAssertLessThan(day.fajr, day.sunrise)
        XCTAssertLessThan(day.maghrib, day.isha)
        XCTAssertTrue((11 * 60 + 50...12 * 60 + 25).contains(localMinutes(day.dhuhr, in: meccaZone)))
    }

    func testEveryMethodProducesTimesForIstanbul() {
        for method in CalcMethod.allCases {
            let settings = CalcSettings(method: method, madhab: .standard)
            XCTAssertNotNil(
                PrayerCalculator.dayTimes(on: noon(in: istanbulZone), at: istanbul, timeZone: istanbulZone, settings: settings),
                method.rawValue
            )
        }
    }
}

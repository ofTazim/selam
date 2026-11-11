import XCTest
@testable import SelamCore

final class PrayerWindowTests: XCTestCase {
    func testWindowsFollowSpecTable() {
        let windows = PrayerWindows.windows(for: sampleDay())

        XCTAssertEqual(windows.map(\.prayer), [.fajr, .dhuhr, .asr, .maghrib, .isha])
        XCTAssertEqual(windows[0], PrayerWindow(prayer: .fajr, start: at(6, 0), end: at(7, 30)))
        XCTAssertEqual(windows[1], PrayerWindow(prayer: .dhuhr, start: at(13, 0), end: at(15, 30)))
        XCTAssertEqual(windows[2], PrayerWindow(prayer: .asr, start: at(15, 30), end: at(18, 0)))
        XCTAssertEqual(windows[3], PrayerWindow(prayer: .maghrib, start: at(18, 0), end: at(19, 30)))
    }

    func testIshaEndsAtMidpointBetweenMaghribAndNextFajr() {
        // maghrib 18:00, next fajr 06:00 next day -> 12 h apart -> midpoint 00:00 next day.
        let isha = PrayerWindows.windows(for: sampleDay())[4]

        XCTAssertEqual(isha.start, at(19, 30))
        XCTAssertEqual(isha.end, at(0, 0, day: 1))
    }

    func testIshaWindowIsAtLeastOneHourWhenMidpointFallsBeforeIsha() {
        // High-latitude summer: maghrib 22:00, isha 23:50, next fajr 01:00 -> midpoint 23:30 is before isha.
        let day = DayTimes(
            fajr: at(1, 0), sunrise: at(3, 30), dhuhr: at(13, 0), asr: at(17, 30),
            maghrib: at(22, 0), isha: at(23, 50), nextFajr: at(1, 0, day: 1)
        )

        let isha = PrayerWindows.windows(for: day)[4]

        XCTAssertEqual(isha.end, at(0, 50, day: 1))
    }

    func testAdhanLookup() {
        let day = sampleDay()

        XCTAssertEqual(day.adhan(.fajr), at(6, 0))
        XCTAssertEqual(day.adhan(.isha), at(19, 30))
    }
}

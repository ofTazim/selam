import Foundation
@testable import SelamCore

/// Fixed reference midnight (2026-11-11 00:00:00 UTC). All test times are offsets from it.
let referenceMidnight = Date(timeIntervalSince1970: 1_794_355_200)

func at(_ hour: Int, _ minute: Int, day: Int = 0) -> Date {
    referenceMidnight.addingTimeInterval(TimeInterval(day * 86_400 + hour * 3_600 + minute * 60))
}

/// A plausible day: fajr 06:00, sunrise 07:30, dhuhr 13:00, asr 15:30, maghrib 18:00, isha 19:30, next fajr 06:00.
func sampleDay(day: Int = 0) -> DayTimes {
    DayTimes(
        fajr: at(6, 0, day: day),
        sunrise: at(7, 30, day: day),
        dhuhr: at(13, 0, day: day),
        asr: at(15, 30, day: day),
        maghrib: at(18, 0, day: day),
        isha: at(19, 30, day: day),
        nextFajr: at(6, 0, day: day + 1)
    )
}

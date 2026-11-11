import XCTest
@testable import SelamCore

final class StagePlannerTests: XCTestCase {
    private let dhuhr = PrayerWindow(prayer: .dhuhr, start: at(12, 0), end: at(15, 0))

    private func segment(_ stage: Stage, _ start: Date, _ end: Date) -> StageSegment {
        StageSegment(prayer: .dhuhr, stage: stage, start: start, end: end)
    }

    func testWithoutMosqueThereAreThreeStages() {
        let segments = StagePlanner.segments(for: dhuhr, congregation: nil)

        XCTAssertEqual(segments, [
            segment(.approaching, at(11, 30), at(12, 0)),
            segment(.entered, at(12, 0), at(14, 40)),
            segment(.lastCall, at(14, 40), at(15, 0)),
        ])
    }

    func testLeaveTimeIsCongregationMinusWalkMinusBuffer() {
        let congregation = Congregation(offset: 10 * 60, walk: 7 * 60)

        // 12:00 + 10 - 7 - 2 = 12:01
        XCTAssertEqual(StagePlanner.leaveTime(adhan: at(12, 0), congregation: congregation), at(12, 1))
    }

    func testShortWalkPutsLeaveNowAfterAdhan() {
        let congregation = Congregation(offset: 10 * 60, walk: 7 * 60)

        let segments = StagePlanner.segments(for: dhuhr, congregation: congregation)

        XCTAssertEqual(segments, [
            segment(.approaching, at(11, 30), at(12, 0)),
            segment(.entered, at(12, 0), at(12, 1)),
            segment(.leaveNow, at(12, 1), at(12, 10)),
            segment(.entered, at(12, 10), at(14, 40)),
            segment(.lastCall, at(14, 40), at(15, 0)),
        ])
    }

    func testLongWalkPutsLeaveNowBeforeAdhan() {
        let congregation = Congregation(offset: 10 * 60, walk: 20 * 60)

        let segments = StagePlanner.segments(for: dhuhr, congregation: congregation)

        // leave = 12:00 + 10 - 20 - 2 = 11:48
        XCTAssertEqual(segments, [
            segment(.approaching, at(11, 30), at(11, 48)),
            segment(.leaveNow, at(11, 48), at(12, 10)),
            segment(.entered, at(12, 10), at(14, 40)),
            segment(.lastCall, at(14, 40), at(15, 0)),
        ])
    }

    func testVeryLongWalkClampsLeaveNowToApproachStart() {
        let congregation = Congregation(offset: 10 * 60, walk: 60 * 60)

        let segments = StagePlanner.segments(for: dhuhr, congregation: congregation)

        XCTAssertEqual(segments.first, segment(.leaveNow, at(11, 30), at(12, 10)))
        XCTAssertFalse(segments.contains { $0.stage == .approaching })
    }

    func testWindowShorterThanLastCallHasNoEnteredStage() {
        let short = PrayerWindow(prayer: .dhuhr, start: at(12, 0), end: at(12, 15))

        let segments = StagePlanner.segments(for: short, congregation: nil)

        XCTAssertEqual(segments, [
            segment(.approaching, at(11, 30), at(12, 0)),
            segment(.lastCall, at(12, 0), at(12, 15)),
        ])
    }

    func testSegmentsAreContiguousAndCoverLeadToEnd() {
        let congregation = Congregation(offset: 5 * 60, walk: 12 * 60)

        let segments = StagePlanner.segments(for: dhuhr, congregation: congregation)

        XCTAssertEqual(segments.first?.start, at(11, 30))
        XCTAssertEqual(segments.last?.end, at(15, 0))
        for (previous, next) in zip(segments, segments.dropFirst()) {
            XCTAssertEqual(previous.end, next.start)
            XCTAssertNotEqual(previous.stage, next.stage)
        }
    }

    func testCustomLeadIsRespected() {
        let config = StageConfig(lead: 45 * 60, lastCall: 10 * 60, leaveBuffer: 120)

        let segments = StagePlanner.segments(for: dhuhr, congregation: nil, config: config)

        XCTAssertEqual(segments.first?.start, at(11, 15))
        XCTAssertEqual(segments.last, segment(.lastCall, at(14, 50), at(15, 0)))
    }
}

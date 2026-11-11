import XCTest
@testable import SelamCore

final class NotificationPlannerTests: XCTestCase {
    private func schedules(days: Int, leaveLead: TimeInterval? = nil) -> [PrayerSchedule] {
        (0..<days).flatMap { day in
            PrayerWindows.windows(for: sampleDay(day: day)).map { window in
                PrayerSchedule(window: window, leaveTime: leaveLead.map { window.start.addingTimeInterval(-$0) })
            }
        }
    }

    func testDefaultKindsForOneDay() {
        let plan = NotificationPlanner.plan(schedules: schedules(days: 1), now: at(0, 0))

        let prayerNotifications = plan.filter { $0.kind != .keepAlive }
        XCTAssertEqual(prayerNotifications.count, 10)
        XCTAssertEqual(prayerNotifications.filter { $0.kind == .entered }.count, 5)
        XCTAssertEqual(prayerNotifications.filter { $0.kind == .lastCall }.count, 5)
        // dhuhr 13:00-15:30 -> entered 13:00, last call 15:10
        XCTAssertTrue(plan.contains { $0.kind == .entered && $0.prayer == .dhuhr && $0.fireDate == at(13, 0) })
        XCTAssertTrue(plan.contains { $0.kind == .lastCall && $0.prayer == .dhuhr && $0.fireDate == at(15, 10) })
    }

    func testPastNotificationsAreDropped() {
        let plan = NotificationPlanner.plan(schedules: schedules(days: 1), now: at(14, 0))

        XCTAssertFalse(plan.contains { $0.fireDate <= at(14, 0) })
        XCTAssertFalse(plan.contains { $0.kind == .entered && $0.prayer == .dhuhr })
        XCTAssertTrue(plan.contains { $0.kind == .lastCall && $0.prayer == .dhuhr })
    }

    func testPlanIsSortedByFireDate() {
        let plan = NotificationPlanner.plan(schedules: schedules(days: 3), now: at(0, 0))

        XCTAssertEqual(plan.map(\.fireDate), plan.map(\.fireDate).sorted())
    }

    func testPlanNeverExceedsLimitAndKeepsEarliest() {
        // 7 days x 10 = 70 candidates; limit 64 -> 63 prayer notifications + 1 keepAlive.
        let plan = NotificationPlanner.plan(schedules: schedules(days: 7), now: at(0, 0))

        XCTAssertEqual(plan.count, 64)
        XCTAssertEqual(plan.filter { $0.kind == .keepAlive }.count, 1)
        XCTAssertEqual(plan.first?.fireDate, at(6, 0))
    }

    func testKeepAliveFiresOneDayBeforeLastPlannedNotification() {
        let plan = NotificationPlanner.plan(schedules: schedules(days: 7), now: at(0, 0))

        let lastPrayerNotification = plan.filter { $0.kind != .keepAlive }.map(\.fireDate).max()!
        let keepAlive = plan.first { $0.kind == .keepAlive }!
        XCTAssertEqual(keepAlive.fireDate, lastPrayerNotification.addingTimeInterval(-86_400))
        XCTAssertNil(keepAlive.prayer)
    }

    func testKeepAliveIsNeverInThePast() {
        // Only today's remaining notifications: last one minus 24 h would be in the past.
        let plan = NotificationPlanner.plan(schedules: schedules(days: 1), now: at(12, 0))

        let keepAlive = plan.first { $0.kind == .keepAlive }!
        XCTAssertEqual(keepAlive.fireDate, at(12, 1))
    }

    func testOptionalKindsWhenEnabled() {
        let config = NotificationConfig(enabled: [.beforeAdhan, .leaveNow, .entered, .lastCall])

        let plan = NotificationPlanner.plan(schedules: schedules(days: 1, leaveLead: 300), now: at(0, 0), config: config)

        // dhuhr 13:00 -> before adhan 12:45, leave 12:55
        XCTAssertTrue(plan.contains { $0.kind == .beforeAdhan && $0.prayer == .dhuhr && $0.fireDate == at(12, 45) })
        XCTAssertTrue(plan.contains { $0.kind == .leaveNow && $0.prayer == .dhuhr && $0.fireDate == at(12, 55) })
        XCTAssertEqual(plan.filter { $0.kind != .keepAlive }.count, 20)
    }

    func testLeaveNowIsSkippedWithoutMosque() {
        let config = NotificationConfig(enabled: [.leaveNow, .entered])

        let plan = NotificationPlanner.plan(schedules: schedules(days: 1), now: at(0, 0), config: config)

        XCTAssertFalse(plan.contains { $0.kind == .leaveNow })
    }

    func testIdentifiersAreUnique() {
        let plan = NotificationPlanner.plan(schedules: schedules(days: 6), now: at(0, 0))

        XCTAssertEqual(Set(plan.map(\.id)).count, plan.count)
    }

    func testEmptyInputGivesEmptyPlan() {
        XCTAssertEqual(NotificationPlanner.plan(schedules: [], now: at(0, 0)), [])
    }
}

import Foundation

public enum NotificationKind: String, CaseIterable, Codable, Sendable {
    case beforeAdhan, leaveNow, entered, lastCall, keepAlive
}

public struct PlannedNotification: Equatable, Sendable {
    public let id: String
    public let kind: NotificationKind
    public let prayer: Prayer?
    public let fireDate: Date

    public init(id: String, kind: NotificationKind, prayer: Prayer?, fireDate: Date) {
        self.id = id
        self.kind = kind
        self.prayer = prayer
        self.fireDate = fireDate
    }
}

/// One prayer window plus the moment to leave for congregation, if a mosque is selected.
public struct PrayerSchedule: Equatable, Sendable {
    public let window: PrayerWindow
    public let leaveTime: Date?

    public init(window: PrayerWindow, leaveTime: Date?) {
        self.window = window
        self.leaveTime = leaveTime
    }
}

public struct NotificationConfig: Equatable, Sendable {
    public var enabled: Set<NotificationKind>
    public var beforeAdhanLead: TimeInterval
    public var lastCallLead: TimeInterval
    /// iOS allows at most 64 pending local notifications per app.
    public var limit: Int

    public init(
        enabled: Set<NotificationKind> = [.entered, .lastCall],
        beforeAdhanLead: TimeInterval = 900,
        lastCallLead: TimeInterval = 1_200,
        limit: Int = 64
    ) {
        self.enabled = enabled
        self.beforeAdhanLead = beforeAdhanLead
        self.lastCallLead = lastCallLead
        self.limit = limit
    }
}

public enum NotificationPlanner {
    /// Sorted notifications after `now`, at most `config.limit`, the earliest kept.
    /// One slot is reserved for a keep-alive reminder asking the user to open the app.
    public static func plan(
        schedules: [PrayerSchedule],
        now: Date,
        config: NotificationConfig = NotificationConfig()
    ) -> [PlannedNotification] {
        var candidates: [PlannedNotification] = []

        func add(_ kind: NotificationKind, _ prayer: Prayer, _ fireDate: Date) {
            guard config.enabled.contains(kind), fireDate > now else { return }
            let id = "selam.\(prayer.rawValue).\(kind.rawValue).\(Int(fireDate.timeIntervalSince1970))"
            candidates.append(PlannedNotification(id: id, kind: kind, prayer: prayer, fireDate: fireDate))
        }

        for schedule in schedules {
            let window = schedule.window
            add(.beforeAdhan, window.prayer, window.start.addingTimeInterval(-config.beforeAdhanLead))
            if let leaveTime = schedule.leaveTime {
                add(.leaveNow, window.prayer, leaveTime)
            }
            add(.entered, window.prayer, window.start)
            let lastCall = window.end.addingTimeInterval(-config.lastCallLead)
            if lastCall > window.start {
                add(.lastCall, window.prayer, lastCall)
            }
        }

        var plan = Array(candidates.sorted { $0.fireDate < $1.fireDate }.prefix(max(0, config.limit - 1)))
        guard let last = plan.last else { return [] }

        let keepAliveDate = max(now.addingTimeInterval(60), last.fireDate.addingTimeInterval(-86_400))
        plan.append(PlannedNotification(
            id: "selam.keepAlive.\(Int(keepAliveDate.timeIntervalSince1970))",
            kind: .keepAlive,
            prayer: nil,
            fireDate: keepAliveDate
        ))
        return plan.sorted { $0.fireDate < $1.fireDate }
    }
}

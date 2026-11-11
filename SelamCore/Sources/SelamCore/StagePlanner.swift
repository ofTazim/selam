import Foundation

/// Live Activity stages for one prayer (spec 4.1).
public enum Stage: String, Codable, Sendable {
    case approaching, leaveNow, entered, lastCall
}

public struct StageSegment: Equatable, Sendable {
    public let prayer: Prayer
    public let stage: Stage
    public let start: Date
    public let end: Date

    public init(prayer: Prayer, stage: Stage, start: Date, end: Date) {
        self.prayer = prayer
        self.stage = stage
        self.start = start
        self.end = end
    }
}

/// How the user reaches congregation: minutes after adhan it starts, and travel time to the mosque.
public struct Congregation: Equatable, Sendable {
    public let offset: TimeInterval
    public let walk: TimeInterval

    public init(offset: TimeInterval, walk: TimeInterval) {
        self.offset = offset
        self.walk = walk
    }
}

public struct StageConfig: Equatable, Sendable {
    /// How long before adhan the activity appears.
    public var lead: TimeInterval
    /// How long before the window closes the last-call stage starts.
    public var lastCall: TimeInterval
    /// Safety margin subtracted from the leave time.
    public var leaveBuffer: TimeInterval

    public init(lead: TimeInterval = 1_800, lastCall: TimeInterval = 1_200, leaveBuffer: TimeInterval = 120) {
        self.lead = lead
        self.lastCall = lastCall
        self.leaveBuffer = leaveBuffer
    }
}

public enum StagePlanner {
    /// The moment the user must leave to catch congregation.
    public static func leaveTime(adhan: Date, congregation: Congregation, config: StageConfig = StageConfig()) -> Date {
        adhan.addingTimeInterval(congregation.offset - congregation.walk - config.leaveBuffer)
    }

    /// Contiguous stage segments from `window.start - lead` to `window.end`.
    public static func segments(
        for window: PrayerWindow,
        congregation: Congregation?,
        config: StageConfig = StageConfig()
    ) -> [StageSegment] {
        let approachStart = window.start.addingTimeInterval(-config.lead)
        let lastCallStart = max(window.start, window.end.addingTimeInterval(-config.lastCall))

        var leaveRange: (start: Date, end: Date)?
        if let congregation {
            let congregationTime = window.start.addingTimeInterval(congregation.offset)
            let start = max(approachStart, leaveTime(adhan: window.start, congregation: congregation, config: config))
            let end = min(congregationTime, lastCallStart)
            if start < end {
                leaveRange = (start, end)
            }
        }

        var cuts: Set<Date> = [approachStart, window.start, lastCallStart, window.end]
        if let leaveRange {
            cuts.insert(leaveRange.start)
            cuts.insert(leaveRange.end)
        }
        let points = cuts.sorted()

        func stage(at instant: Date) -> Stage {
            if let leaveRange, instant >= leaveRange.start, instant < leaveRange.end { return .leaveNow }
            if instant < window.start { return .approaching }
            if instant < lastCallStart { return .entered }
            return .lastCall
        }

        var segments: [StageSegment] = []
        for (start, end) in zip(points, points.dropFirst()) {
            let current = stage(at: start)
            if let last = segments.last, last.stage == current {
                segments[segments.count - 1] = StageSegment(prayer: window.prayer, stage: current, start: last.start, end: end)
            } else {
                segments.append(StageSegment(prayer: window.prayer, stage: current, start: start, end: end))
            }
        }
        return segments
    }
}

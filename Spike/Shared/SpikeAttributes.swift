import ActivityKit
import AppIntents
import Foundation

struct SpikeAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var label: String
        var target: Date
    }
    var name: String
}

struct DoneIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Kıldım"

    func perform() async throws -> some IntentResult {
        for activity in Activity<SpikeAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}

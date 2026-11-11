import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct SpikeWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpikeLiveActivity()
    }
}

struct SpikeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpikeAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(context.isStale ? "BAYAT · \(context.state.label)" : "TAZE · \(context.state.label)")
                    .font(.headline)
                Text(context.state.target, style: .timer)
                    .font(.largeTitle.monospacedDigit())
                Button(intent: DoneIntent()) {
                    Text("Kıldım")
                }
            }
            .padding()
            .activityBackgroundTint(context.isStale ? .orange : .indigo)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.isStale ? "BAYAT · \(context.state.label)" : "TAZE · \(context.state.label)")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.target, style: .timer)
                }
            } compactLeading: {
                Text(context.isStale ? "B" : "T")
            } compactTrailing: {
                Text(context.state.target, style: .timer)
                    .frame(maxWidth: 56)
            } minimal: {
                Text(context.isStale ? "B" : "T")
            }
        }
    }
}

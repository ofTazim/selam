import ActivityKit
import SwiftUI

@main
struct SpikeApp: App {
    var body: some Scene {
        WindowGroup {
            SpikeView()
        }
    }
}

struct SpikeView: View {
    @State private var log: [String] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Denemeler") {
                    Button("S1 · 2 dk sonra tek etkinlik") {
                        schedule(label: "S1", startIn: 120, staleAfter: nil, countdown: 300)
                    }
                    Button("S2 · 2 dk sonra başla, 2 dk sonra bayatla") {
                        schedule(label: "S2", startIn: 120, staleAfter: 120, countdown: 120)
                    }
                    Button("S3 · art arda iki (2 dk ve 4 dk)") {
                        schedule(label: "S3-A", startIn: 120, staleAfter: nil, countdown: 120)
                        schedule(label: "S3-B", startIn: 240, staleAfter: nil, countdown: 120)
                    }
                    Button("S4 · 12 etkinlik (2 dk arayla)") {
                        for index in 1...12 {
                            schedule(label: "S4-\(index)", startIn: Double(index) * 120, staleAfter: nil, countdown: 120)
                        }
                    }
                    Button("Hepsini bitir", role: .destructive) {
                        Task {
                            for activity in Activity<SpikeAttributes>.activities {
                                await activity.end(nil, dismissalPolicy: .immediate)
                            }
                            append("Hepsi bitirildi")
                        }
                    }
                    Button("Durumu listele") {
                        let activities = Activity<SpikeAttributes>.activities
                        append("Toplam \(activities.count) etkinlik")
                        for activity in activities {
                            append("\(activity.attributes.name): \(activity.activityState)")
                        }
                    }
                }
                Section("Kayıt") {
                    ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.footnote.monospaced())
                    }
                }
            }
            .navigationTitle("Selam deneme")
        }
    }

    private func schedule(label: String, startIn: TimeInterval, staleAfter: TimeInterval?, countdown: TimeInterval) {
        let start = Date.now.addingTimeInterval(startIn)
        let state = SpikeAttributes.ContentState(label: label, target: start.addingTimeInterval(countdown))
        let content = ActivityContent(state: state, staleDate: staleAfter.map { start.addingTimeInterval($0) })
        let alert = AlertConfiguration(title: "Selam deneme", body: "\(label) başladı", sound: .default)
        do {
            _ = try Activity.request(
                attributes: SpikeAttributes(name: label),
                content: content,
                pushType: nil,
                style: .standard,
                alertConfiguration: alert,
                start: start
            )
            append("\(label) zamanlandı: \(start.formatted(date: .omitted, time: .standard))")
        } catch {
            append("\(label) HATA: \(error)")
        }
    }

    private func append(_ line: String) {
        log.insert(line, at: 0)
    }
}

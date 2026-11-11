# Selam Plan 1 — Canlı Etkinlik Denemesi ve SelamCore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zamanlanmış Canlı Etkinlik davranışını gerçek iPhone'da kanıtlamak ve arayüzden bağımsız, test edilmiş `SelamCore` paketini (vakit hesabı, vakit pencereleri, aşama planı, bildirim planı, yöntem seçimi) üretmek.

**Architecture:** `SelamCore` saf fonksiyonlardan oluşan bir Swift paketidir; sistem API'lerine dokunmaz. Adhan kütüphanesi tek bir dosyanın (`PrayerCalculator.swift`) arkasına gizlenir; diğer her şey paketin kendi `DayTimes` türü üzerinde çalışır ve elle kurulmuş tarihlerle test edilir. Deneme (`Spike/`) atılacak koddur; yalnızca sonuç dokümanı kalıcıdır.

**Tech Stack:** Swift 6.2, Swift Package Manager, XCTest, Adhan Swift (`batoulapps/adhan-swift`), XcodeGen, ActivityKit, WidgetKit, App Intents.

**Spec:** `docs/superpowers/specs/2026-11-11-selam-v1-design.md`

**Bu planın kapsamı:** Spec yol haritasının 1. ve 2. adımları. Uygulama, uzantılar, saat, yerelleştirme ve yayın için ayrı planlar yazılır; Plan 2, Task 1'in sonucu belli olduktan sonra yazılır çünkü Canlı Etkinlik tasarımı o sonuca bağlıdır. Gökyüzü durumu ve hicri tarih `SelamCore`'a Plan 2'de eklenir.

## Global Constraints

- iOS 26+, watchOS 26+. Native Swift / SwiftUI.
- Sunucu, hesap, analitik yok. Tüm hesaplama cihazda.
- `SelamCore` yalnızca Foundation ve Adhan'a bağımlıdır; UIKit, SwiftUI, ActivityKit, UserNotifications, CoreLocation, MapKit içe aktarılmaz.
- Adhan türleri `PrayerCalculator.swift` dışına sızmaz.
- Canlı Etkinlik varsayılanları: "Yaklaşıyor" ezandan 30 dk önce; "Son dakikalar" vaktin çıkmasına 20 dk kala; çıkma payı 2 dk.
- Cemaat saati = ezan + kaydırma; varsayılan 10 dk, akşamda 5 dk.
- Bekleyen bildirim sınırı 64; plan bu sayıyı aşmaz.
- Varsayılan açık bildirim türleri: "vakit girdi" ve "vakit çıkıyor".
- Kod Windows'ta yazılır, Mac'te derlenir. Xcode projesi XcodeGen ile üretilir; `.xcodeproj` depoya girmez.
- Kod içi adlar ve yorumlar İngilizce; kullanıcıya görünen metinler bu planda yalnızca denemede geçer ve Türkçedir.

## Dosya Yapısı

```
Spike/                                   (atılacak; Task 1)
  project.yml                            XcodeGen yapılandırması
  App/SpikeApp.swift                     Deneme düğmeleri ve durum listesi
  Shared/SpikeAttributes.swift           ActivityAttributes + "Kıldım" intent'i
  Widgets/SpikeWidgets.swift             Canlı Etkinlik görünümü
docs/superpowers/spikes/
  2026-11-11-live-activity-results.md    Deneme sonuçları (kalıcı)
SelamCore/
  Package.swift
  Sources/SelamCore/
    Prayer.swift                         Prayer, DayTimes
    PrayerWindow.swift                   Vakit pencereleri
    StagePlanner.swift                   Canlı Etkinlik aşama zaman çizelgesi
    NotificationPlanner.swift            Bildirim planı ve 64 sınırı
    MethodResolver.swift                 CalcMethod, Madhab, ülke → varsayılan
    PrayerCalculator.swift               Adhan sarmalayıcısı (tek Adhan bağımlısı)
  Tests/SelamCoreTests/
    TestDates.swift                      Test tarih yardımcıları
    PrayerWindowTests.swift
    StagePlannerTests.swift
    NotificationPlannerTests.swift
    MethodResolverTests.swift
    PrayerCalculatorTests.swift
```

Task 1 (deneme) ile Task 2-6 (çekirdek) birbirinden bağımsızdır ve aynı anda yürüyebilir. Task 1'i proje sahibi Mac ve iPhone'da çalıştırır.

---

### Task 1: Canlı Etkinlik denemesi (Mac + gerçek iPhone)

Yanıtlanacak sorular:

| # | Soru |
|---|---|
| S1 | Ön plandan zamanlanan etkinlik, uygulama kapatıldıktan sonra belirlenen saatte kendiliğinden başlıyor mu? |
| S2 | `staleDate` geldiğinde görünüm yeniden çiziliyor mu (`context.isStale`)? Bu, tek etkinlikte iki aşama demektir. |
| S3 | Art arda iki zamanlanmış etkinlikte ikincisi başlayınca ne oluyor: yan yana mı duruyor, ilkinin yerini mi alıyor? |
| S4 | Aynı anda kaç etkinlik zamanlanabiliyor? (12 denenir; Apple sınırın sayısını belgelemiyor.) |
| S5 | Kilit ekranındaki "Kıldım" düğmesi uygulamayı açmadan çalışıyor mu ve bekleyen (pending) etkinlikleri de iptal ediyor mu? |

**Files:**
- Create: `Spike/project.yml`
- Create: `Spike/App/SpikeApp.swift`
- Create: `Spike/Shared/SpikeAttributes.swift`
- Create: `Spike/Widgets/SpikeWidgets.swift`
- Create: `docs/superpowers/spikes/2026-11-11-live-activity-results.md`

**Interfaces:**
- Consumes: yok.
- Produces: doldurulmuş sonuç dokümanı. Plan 2 bu dokümana göre yazılır. Kod başka hiçbir görev tarafından kullanılmaz.

- [ ] **Step 1: XcodeGen yapılandırmasını yaz**

`Spike/project.yml`:

```yaml
name: SelamSpike
options:
  bundleIdPrefix: app.selam.spike
  deploymentTarget:
    iOS: "26.0"
settings:
  base:
    SWIFT_VERSION: "5.0"
    CODE_SIGN_STYLE: Automatic
targets:
  SelamSpike:
    type: application
    platform: iOS
    sources:
      - App
      - Shared
    info:
      path: App/Info.plist
      properties:
        NSSupportsLiveActivities: true
        UILaunchScreen: {}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.selam.spike
    dependencies:
      - target: SelamSpikeWidgets
  SelamSpikeWidgets:
    type: app-extension
    platform: iOS
    sources:
      - Widgets
      - Shared
    info:
      path: Widgets/Info.plist
      properties:
        NSExtension:
          NSExtensionPointIdentifier: com.apple.widgetkit-extension
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.selam.spike.widgets
```

Deneme Swift 5 dil kipinde derlenir; amaç eşzamanlılık denetimiyle uğraşmadan davranışı görmektir.

- [ ] **Step 2: Paylaşılan türleri yaz**

`Spike/Shared/SpikeAttributes.swift`:

```swift
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
```

- [ ] **Step 3: Canlı Etkinlik görünümünü yaz**

`Spike/Widgets/SpikeWidgets.swift`:

```swift
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
```

- [ ] **Step 4: Deneme uygulamasını yaz**

`Spike/App/SpikeApp.swift`:

```swift
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
```

- [ ] **Step 5: Sonuç dokümanı şablonunu yaz**

`docs/superpowers/spikes/2026-11-11-live-activity-results.md`:

```markdown
# Canlı Etkinlik denemesi sonuçları

Cihaz: (model)  · iOS sürümü: (sürüm)  · Tarih: (tarih)

| # | Soru | Sonuç (Evet/Hayır) | Gözlem |
|---|---|---|---|
| S1 | Uygulama kapalıyken zamanında başladı mı? | | |
| S2 | staleDate gelince görünüm "BAYAT" ve turuncuya döndü mü? | | |
| S3 | İkinci etkinlik başlayınca ilki ne oldu? | | |
| S4 | 12 etkinliğin kaçı zamanlandı, kaçı başladı? Hata metni? | | |
| S5 | "Kıldım" uygulamayı açmadan çalıştı mı? Bekleyenleri de iptal etti mi? | | |

## Karar

(Spec 4.6'daki dallardan biri: dört aşama / iki aşama / push-to-start)
```

- [ ] **Step 6: Commit**

```bash
git add Spike docs/superpowers/spikes
git commit -m "spike: scheduled Live Activity probe project"
```

- [ ] **Step 7: Mac'te projeyi üret ve iPhone'a kur (proje sahibi)**

Mac'te, depo kökünde:

```bash
brew install xcodegen
```

```bash
cd Spike && xcodegen generate && open SelamSpike.xcodeproj
```

Xcode'da: her iki hedef için Signing & Capabilities sekmesinde Team seç. Bundle identifier kullanılıyor hatası çıkarsa `project.yml` içindeki `app.selam.spike` önekini kendi adınla değiştir ve `xcodegen generate` komutunu yeniden çalıştır. iPhone'u bağla, hedef cihaz olarak seç, Run.

Beklenen: uygulama açılır, "Selam deneme" başlıklı liste görünür. Derleme hatası çıkarsa hata metninin tamamını bu oturuma yapıştır.

- [ ] **Step 8: Denemeleri çalıştır ve sonuçları yaz (proje sahibi)**

Her denemeden önce "Hepsini bitir" düğmesine bas. iPhone'da Ayarlar → Selam deneme → Canlı Etkinlikler açık olmalı.

1. **S1:** "S1" düğmesine bas, uygulamayı uygulama değiştiriciden yukarı kaydırarak kapat, telefonu kilitle. 2 dk bekle. Beklenen: kilit ekranında lacivert "TAZE · S1" kartı ve bir uyarı sesi/bildirimi.
2. **S2:** "S2" düğmesine bas, uygulamayı kapat, kilitle. 2 dk sonra kart lacivert "TAZE · S2" olarak gelmeli; ondan 2 dk sonra kendiliğinden turuncu "BAYAT · S2" olup olmadığına bak.
3. **S3:** "S3" düğmesine bas, kapat, kilitle. 2. dakikada "S3-A", 4. dakikada "S3-B" gelmeli. İkisi yan yana mı duruyor, biri diğerinin yerini mi aldı, Dynamic Island'da hangisi görünüyor, not et.
4. **S4:** "S4" düğmesine bas. Kayıt bölümünde kaç satır "zamanlandı", kaç satır "HATA" yazıyor ve hata metni ne, not et. "Durumu listele" ile toplamı kontrol et. İlk 3-4 etkinliğin gelişini izle.
5. **S5:** "S3" düğmesine bas, kapat, kilitle. "S3-A" gelince kilit ekranındaki "Kıldım" düğmesine bas (S3-B henüz bekliyor olmalı). Kart kapandı mı? 4. dakikada "S3-B" yine de geldi mi?

Gözlemleri `docs/superpowers/spikes/2026-11-11-live-activity-results.md` tablosuna yaz, "Karar" bölümünü boş bırak ve dosyayı (ya da içeriğini) bu oturuma getir.

- [ ] **Step 9: Kararı yaz ve commit et**

Sonuçlara göre "Karar" bölümü doldurulur:

- S1 Evet, S2 Evet → dört aşama, vakit başına iki etkinlik (her biri taze/bayat ile iki görünüm) ya da S3'e göre aşama başına bir etkinlik.
- S1 Evet, S2 Hayır, S3 "yan yana" → iki aşama (ezan öncesi, ezan sonrası), tek etkinlik.
- S1 Hayır → push-to-start; spec güncellenir.
- S4'teki sayı, kaç vaktin önceden zamanlanabileceğini belirler.

```bash
git add docs/superpowers/spikes/2026-11-11-live-activity-results.md
git commit -m "spike: record scheduled Live Activity results and decision"
```

---

### Task 2: Paket iskeleti, temel türler ve vakit pencereleri

**Files:**
- Create: `SelamCore/Package.swift`
- Create: `SelamCore/Sources/SelamCore/Prayer.swift`
- Create: `SelamCore/Sources/SelamCore/PrayerWindow.swift`
- Create: `SelamCore/Tests/SelamCoreTests/TestDates.swift`
- Test: `SelamCore/Tests/SelamCoreTests/PrayerWindowTests.swift`

**Interfaces:**
- Consumes: yok.
- Produces:
  - `enum Prayer: String, CaseIterable, Codable, Sendable { case fajr, dhuhr, asr, maghrib, isha }`
  - `struct DayTimes: Equatable, Sendable` — alanlar `fajr, sunrise, dhuhr, asr, maghrib, isha, nextFajr: Date`; `func adhan(_ prayer: Prayer) -> Date`
  - `struct PrayerWindow: Equatable, Sendable { let prayer: Prayer; let start: Date; let end: Date }`
  - `PrayerWindows.windows(for: DayTimes) -> [PrayerWindow]`
  - Test yardımcıları: `at(_ hour: Int, _ minute: Int, day: Int = 0) -> Date`, `sampleDay(day: Int = 0) -> DayTimes`

- [ ] **Step 1: Package.swift yaz**

`SelamCore/Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SelamCore",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "SelamCore", targets: ["SelamCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/batoulapps/adhan-swift", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "SelamCore",
            dependencies: [.product(name: "Adhan", package: "adhan-swift")]
        ),
        .testTarget(name: "SelamCoreTests", dependencies: ["SelamCore"])
    ]
)
```

- [ ] **Step 2: Test yardımcılarını ve başarısız testi yaz**

`SelamCore/Tests/SelamCoreTests/TestDates.swift`:

```swift
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
```

`SelamCore/Tests/SelamCoreTests/PrayerWindowTests.swift`:

```swift
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
```

- [ ] **Step 3: Testin başarısız olduğunu gör**

Run: `cd SelamCore && swift test --filter PrayerWindowTests`
Expected: derleme hatası, "cannot find 'DayTimes' in scope".

- [ ] **Step 4: Uygulamayı yaz**

`SelamCore/Sources/SelamCore/Prayer.swift`:

```swift
import Foundation

/// The five obligatory prayers.
public enum Prayer: String, CaseIterable, Codable, Sendable {
    case fajr, dhuhr, asr, maghrib, isha
}

/// Prayer instants for one calendar day at one location, plus the following day's fajr.
public struct DayTimes: Equatable, Sendable {
    public let fajr: Date
    public let sunrise: Date
    public let dhuhr: Date
    public let asr: Date
    public let maghrib: Date
    public let isha: Date
    public let nextFajr: Date

    public init(fajr: Date, sunrise: Date, dhuhr: Date, asr: Date, maghrib: Date, isha: Date, nextFajr: Date) {
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.nextFajr = nextFajr
    }

    public func adhan(_ prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: fajr
        case .dhuhr: dhuhr
        case .asr: asr
        case .maghrib: maghrib
        case .isha: isha
        }
    }
}
```

`SelamCore/Sources/SelamCore/PrayerWindow.swift`:

```swift
import Foundation

/// The interval during which a prayer can be performed on time.
public struct PrayerWindow: Equatable, Sendable {
    public let prayer: Prayer
    public let start: Date
    public let end: Date

    public init(prayer: Prayer, start: Date, end: Date) {
        self.prayer = prayer
        self.start = start
        self.end = end
    }
}

public enum PrayerWindows {
    /// Minimum isha window, used when the night midpoint falls before isha (high latitudes).
    static let minimumIshaWindow: TimeInterval = 3_600

    /// Windows per spec 4.3. Isha ends at the midpoint between maghrib and the next fajr.
    public static func windows(for day: DayTimes) -> [PrayerWindow] {
        let nightMidpoint = day.maghrib.addingTimeInterval(day.nextFajr.timeIntervalSince(day.maghrib) / 2)
        let ishaEnd = max(nightMidpoint, day.isha.addingTimeInterval(minimumIshaWindow))
        return [
            PrayerWindow(prayer: .fajr, start: day.fajr, end: day.sunrise),
            PrayerWindow(prayer: .dhuhr, start: day.dhuhr, end: day.asr),
            PrayerWindow(prayer: .asr, start: day.asr, end: day.maghrib),
            PrayerWindow(prayer: .maghrib, start: day.maghrib, end: day.isha),
            PrayerWindow(prayer: .isha, start: day.isha, end: ishaEnd),
        ]
    }
}
```

`PrayerCalculator.swift` henüz olmadığı için Adhan bu aşamada yalnızca çözülür, kullanılmaz.

- [ ] **Step 5: Testin geçtiğini gör**

Run: `cd SelamCore && swift test --filter PrayerWindowTests`
Expected: 4 test, hepsi PASS.

- [ ] **Step 6: Commit**

```bash
git add SelamCore
git commit -m "feat(core): package skeleton, Prayer, DayTimes and prayer windows"
```

---

### Task 3: Canlı Etkinlik aşama planlayıcısı

Bir vakit penceresini aşama dilimlerine böler (spec 4.1). Kural: zaman ekseni kesim noktalarına ayrılır; her dilimin aşaması şu öncelikle belirlenir: çıkma aralığındaysa `leaveNow`, ezandan önceyse `approaching`, son dakikalardan önceyse `entered`, değilse `lastCall`. Ardışık aynı aşamalar birleştirilir.

**Files:**
- Create: `SelamCore/Sources/SelamCore/StagePlanner.swift`
- Test: `SelamCore/Tests/SelamCoreTests/StagePlannerTests.swift`

**Interfaces:**
- Consumes: `PrayerWindow`, `Prayer` (Task 2); test yardımcısı `at(_:_:day:)`.
- Produces:
  - `enum Stage: String, Codable, Sendable { case approaching, leaveNow, entered, lastCall }`
  - `struct StageSegment: Equatable, Sendable { let prayer: Prayer; let stage: Stage; let start: Date; let end: Date }`
  - `struct Congregation: Equatable, Sendable { let offset: TimeInterval; let walk: TimeInterval }`
  - `struct StageConfig: Equatable, Sendable { var lead: TimeInterval = 1800; var lastCall: TimeInterval = 1200; var leaveBuffer: TimeInterval = 120 }`
  - `StagePlanner.leaveTime(adhan: Date, congregation: Congregation, config: StageConfig = StageConfig()) -> Date`
  - `StagePlanner.segments(for: PrayerWindow, congregation: Congregation?, config: StageConfig = StageConfig()) -> [StageSegment]`

- [ ] **Step 1: Başarısız testi yaz**

`SelamCore/Tests/SelamCoreTests/StagePlannerTests.swift`:

```swift
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
```

- [ ] **Step 2: Testin başarısız olduğunu gör**

Run: `cd SelamCore && swift test --filter StagePlannerTests`
Expected: derleme hatası, "cannot find 'StagePlanner' in scope".

- [ ] **Step 3: Uygulamayı yaz**

`SelamCore/Sources/SelamCore/StagePlanner.swift`:

```swift
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
```

- [ ] **Step 4: Testin geçtiğini gör**

Run: `cd SelamCore && swift test --filter StagePlannerTests`
Expected: 8 test, hepsi PASS.

- [ ] **Step 5: Commit**

```bash
git add SelamCore
git commit -m "feat(core): Live Activity stage planner"
```

---

### Task 4: Bildirim planlayıcısı

Birden çok günün vakit pencerelerinden, 64 sınırını aşmayan sıralı bir bildirim listesi üretir (spec 4.5). Son sırayı her zaman "Selam'ı aç" (`keepAlive`) bildirimi alır.

**Files:**
- Create: `SelamCore/Sources/SelamCore/NotificationPlanner.swift`
- Test: `SelamCore/Tests/SelamCoreTests/NotificationPlannerTests.swift`

**Interfaces:**
- Consumes: `PrayerWindow`, `Prayer`, `PrayerWindows.windows(for:)` (Task 2); test yardımcıları `at(_:_:day:)`, `sampleDay(day:)`.
- Produces:
  - `enum NotificationKind: String, CaseIterable, Codable, Sendable { case beforeAdhan, leaveNow, entered, lastCall, keepAlive }`
  - `struct PlannedNotification: Equatable, Sendable { let id: String; let kind: NotificationKind; let prayer: Prayer?; let fireDate: Date }`
  - `struct PrayerSchedule: Equatable, Sendable { let window: PrayerWindow; let leaveTime: Date? }`
  - `struct NotificationConfig: Equatable, Sendable { var enabled: Set<NotificationKind> = [.entered, .lastCall]; var beforeAdhanLead: TimeInterval = 900; var lastCallLead: TimeInterval = 1200; var limit: Int = 64 }`
  - `NotificationPlanner.plan(schedules: [PrayerSchedule], now: Date, config: NotificationConfig = NotificationConfig()) -> [PlannedNotification]`

- [ ] **Step 1: Başarısız testi yaz**

`SelamCore/Tests/SelamCoreTests/NotificationPlannerTests.swift`:

```swift
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
```

- [ ] **Step 2: Testin başarısız olduğunu gör**

Run: `cd SelamCore && swift test --filter NotificationPlannerTests`
Expected: derleme hatası, "cannot find 'NotificationPlanner' in scope".

- [ ] **Step 3: Uygulamayı yaz**

`SelamCore/Sources/SelamCore/NotificationPlanner.swift`:

```swift
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
```

- [ ] **Step 4: Testin geçtiğini gör**

Run: `cd SelamCore && swift test --filter NotificationPlannerTests`
Expected: 10 test, hepsi PASS.

- [ ] **Step 5: Commit**

```bash
git add SelamCore
git commit -m "feat(core): notification planner with 64-pending cap and keep-alive"
```

---

### Task 5: Hesaplama ayarları ve ülkeye göre varsayılanlar

Ülke koduna göre varsayılan hesaplama yöntemi ve Asr mezhebi (spec 3.4, 6.2). Not: Türkiye'de Diyanet takvimi ikindiyi asr-ı evvele göre verir; bu yüzden TR için Asr varsayılanı `standard`'dır, `hanafi` değil.

**Files:**
- Create: `SelamCore/Sources/SelamCore/MethodResolver.swift`
- Test: `SelamCore/Tests/SelamCoreTests/MethodResolverTests.swift`

**Interfaces:**
- Consumes: `Prayer` (Task 2).
- Produces:
  - `enum CalcMethod: String, CaseIterable, Codable, Sendable { case muslimWorldLeague, egyptian, karachi, ummAlQura, dubai, moonsightingCommittee, northAmerica, kuwait, qatar, singapore, tehran, turkey }`
  - `enum AsrMadhab: String, CaseIterable, Codable, Sendable { case standard, hanafi }`
  - `enum HighLatitudeRule: String, CaseIterable, Codable, Sendable { case middleOfTheNight, seventhOfTheNight, twilightAngle }`
  - `struct CalcSettings: Equatable, Codable, Sendable { var method: CalcMethod; var madhab: AsrMadhab; var highLatitudeRule: HighLatitudeRule; var adjustments: [Prayer: Int] }` ve `init(method:madhab:highLatitudeRule:adjustments:)` (son iki parametre varsayılan `.middleOfTheNight` ve `[:]`)
  - `MethodResolver.defaults(forCountryCode: String?) -> CalcSettings`

- [ ] **Step 1: Başarısız testi yaz**

`SelamCore/Tests/SelamCoreTests/MethodResolverTests.swift`:

```swift
import XCTest
@testable import SelamCore

final class MethodResolverTests: XCTestCase {
    func testTurkeyUsesDiyanetMethodWithStandardAsr() {
        let settings = MethodResolver.defaults(forCountryCode: "TR")

        XCTAssertEqual(settings.method, .turkey)
        XCTAssertEqual(settings.madhab, .standard)
    }

    func testSouthAsiaUsesKarachiWithHanafiAsr() {
        for code in ["PK", "IN", "BD", "AF"] {
            let settings = MethodResolver.defaults(forCountryCode: code)
            XCTAssertEqual(settings.method, .karachi, code)
            XCTAssertEqual(settings.madhab, .hanafi, code)
        }
    }

    func testRegionalMethods() {
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "SA").method, .ummAlQura)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "AE").method, .dubai)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "KW").method, .kuwait)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "QA").method, .qatar)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "EG").method, .egyptian)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "IR").method, .tehran)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "ID").method, .singapore)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "MY").method, .singapore)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "SG").method, .singapore)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "US").method, .northAmerica)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "CA").method, .northAmerica)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "GB").method, .moonsightingCommittee)
    }

    func testUnknownOrMissingCountryFallsBackToMuslimWorldLeague() {
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "FR").method, .muslimWorldLeague)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: nil).method, .muslimWorldLeague)
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "FR").madhab, .standard)
    }

    func testCountryCodeIsCaseInsensitive() {
        XCTAssertEqual(MethodResolver.defaults(forCountryCode: "tr").method, .turkey)
    }

    func testDefaultsHaveNoAdjustmentsAndMiddleOfTheNight() {
        let settings = MethodResolver.defaults(forCountryCode: "TR")

        XCTAssertEqual(settings.adjustments, [:])
        XCTAssertEqual(settings.highLatitudeRule, .middleOfTheNight)
    }

    func testSettingsRoundTripThroughJSON() throws {
        var settings = MethodResolver.defaults(forCountryCode: "PK")
        settings.adjustments = [.fajr: 2, .isha: -1]

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(CalcSettings.self, from: data)

        XCTAssertEqual(decoded, settings)
    }
}
```

- [ ] **Step 2: Testin başarısız olduğunu gör**

Run: `cd SelamCore && swift test --filter MethodResolverTests`
Expected: derleme hatası, "cannot find 'MethodResolver' in scope".

- [ ] **Step 3: Uygulamayı yaz**

`SelamCore/Sources/SelamCore/MethodResolver.swift`:

```swift
import Foundation

public enum CalcMethod: String, CaseIterable, Codable, Sendable {
    case muslimWorldLeague, egyptian, karachi, ummAlQura, dubai, moonsightingCommittee
    case northAmerica, kuwait, qatar, singapore, tehran, turkey
}

/// Asr shadow rule. `standard` is shadow length x1 (Shafi, Maliki, Hanbali); `hanafi` is x2.
public enum AsrMadhab: String, CaseIterable, Codable, Sendable {
    case standard, hanafi
}

public enum HighLatitudeRule: String, CaseIterable, Codable, Sendable {
    case middleOfTheNight, seventhOfTheNight, twilightAngle
}

public struct CalcSettings: Equatable, Codable, Sendable {
    public var method: CalcMethod
    public var madhab: AsrMadhab
    public var highLatitudeRule: HighLatitudeRule
    /// Per-prayer correction in minutes, applied on top of the method.
    public var adjustments: [Prayer: Int]

    public init(
        method: CalcMethod,
        madhab: AsrMadhab,
        highLatitudeRule: HighLatitudeRule = .middleOfTheNight,
        adjustments: [Prayer: Int] = [:]
    ) {
        self.method = method
        self.madhab = madhab
        self.highLatitudeRule = highLatitudeRule
        self.adjustments = adjustments
    }
}

public enum MethodResolver {
    private static let methods: [String: CalcMethod] = [
        "TR": .turkey,
        "SA": .ummAlQura,
        "AE": .dubai,
        "KW": .kuwait,
        "QA": .qatar,
        "EG": .egyptian,
        "IR": .tehran,
        "PK": .karachi, "IN": .karachi, "BD": .karachi, "AF": .karachi,
        "ID": .singapore, "MY": .singapore, "SG": .singapore,
        "US": .northAmerica, "CA": .northAmerica,
        "GB": .moonsightingCommittee,
    ]

    private static let hanafiCountries: Set<String> = ["PK", "IN", "BD", "AF"]

    /// Default calculation settings for an ISO 3166-1 alpha-2 country code.
    public static func defaults(forCountryCode code: String?) -> CalcSettings {
        let key = code?.uppercased() ?? ""
        return CalcSettings(
            method: methods[key] ?? .muslimWorldLeague,
            madhab: hanafiCountries.contains(key) ? .hanafi : .standard
        )
    }
}
```

- [ ] **Step 4: Testin geçtiğini gör**

Run: `cd SelamCore && swift test --filter MethodResolverTests`
Expected: 7 test, hepsi PASS.

- [ ] **Step 5: Commit**

```bash
git add SelamCore
git commit -m "feat(core): calculation settings and per-country defaults"
```

---

### Task 6: Vakit hesaplayıcısı (Adhan sarmalayıcısı)

Paketin Adhan'a dokunan tek dosyası. Adhan'ın API adları bu plan yazılırken derlenerek doğrulanamadı; adlar kütüphanenin README'sindeki kullanımla eşleşecek şekilde yazıldı. Derleme hatası çıkarsa yalnızca `PrayerCalculator.swift` düzeltilir (kaynak: `SelamCore/.build/checkouts/adhan-swift/README.md`); testler ve diğer dosyalar değişmez.

Testler belirli dakikaları değil, sağlamlık sınırlarını doğrular; dakika düzeyinde doğruluk spec 8'deki resmi takvim karşılaştırmasıyla ayrıca yapılır.

**Files:**
- Create: `SelamCore/Sources/SelamCore/PrayerCalculator.swift`
- Test: `SelamCore/Tests/SelamCoreTests/PrayerCalculatorTests.swift`

**Interfaces:**
- Consumes: `DayTimes`, `Prayer` (Task 2); `CalcSettings`, `CalcMethod`, `AsrMadhab`, `HighLatitudeRule`, `MethodResolver.defaults(forCountryCode:)` (Task 5).
- Produces:
  - `struct Coordinate: Equatable, Codable, Sendable { let latitude: Double; let longitude: Double }`
  - `PrayerCalculator.dayTimes(on: Date, at: Coordinate, timeZone: TimeZone, settings: CalcSettings) -> DayTimes?` — `on` içindeki anın `timeZone`'daki takvim günü için hesaplar; hesaplanamazsa `nil`.

- [ ] **Step 1: Başarısız testi yaz**

`SelamCore/Tests/SelamCoreTests/PrayerCalculatorTests.swift`:

```swift
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
```

- [ ] **Step 2: Testin başarısız olduğunu gör**

Run: `cd SelamCore && swift test --filter PrayerCalculatorTests`
Expected: derleme hatası, "cannot find 'PrayerCalculator' in scope".

- [ ] **Step 3: Uygulamayı yaz**

`SelamCore/Sources/SelamCore/PrayerCalculator.swift`:

```swift
import Adhan
import Foundation

public struct Coordinate: Equatable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// The only file in SelamCore that touches Adhan.
public enum PrayerCalculator {
    /// Prayer times for the calendar day that contains `date` in `timeZone`.
    public static func dayTimes(
        on date: Date,
        at coordinate: Coordinate,
        timeZone: TimeZone,
        settings: CalcSettings
    ) -> DayTimes? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
        let coordinates = Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let parameters = parameters(for: settings)

        let todayParts = calendar.dateComponents([.year, .month, .day], from: date)
        let tomorrowParts = calendar.dateComponents([.year, .month, .day], from: tomorrow)

        guard
            let today = PrayerTimes(coordinates: coordinates, date: todayParts, calculationParameters: parameters),
            let next = PrayerTimes(coordinates: coordinates, date: tomorrowParts, calculationParameters: parameters)
        else { return nil }

        return DayTimes(
            fajr: today.fajr,
            sunrise: today.sunrise,
            dhuhr: today.dhuhr,
            asr: today.asr,
            maghrib: today.maghrib,
            isha: today.isha,
            nextFajr: next.fajr
        )
    }

    private static func parameters(for settings: CalcSettings) -> CalculationParameters {
        var parameters = method(settings.method).params
        parameters.madhab = settings.madhab == .hanafi ? .hanafi : .shafi
        parameters.highLatitudeRule = highLatitudeRule(settings.highLatitudeRule)
        parameters.adjustments = PrayerAdjustments(
            fajr: settings.adjustments[.fajr] ?? 0,
            sunrise: 0,
            dhuhr: settings.adjustments[.dhuhr] ?? 0,
            asr: settings.adjustments[.asr] ?? 0,
            maghrib: settings.adjustments[.maghrib] ?? 0,
            isha: settings.adjustments[.isha] ?? 0
        )
        return parameters
    }

    private static func method(_ method: CalcMethod) -> CalculationMethod {
        switch method {
        case .muslimWorldLeague: .muslimWorldLeague
        case .egyptian: .egyptian
        case .karachi: .karachi
        case .ummAlQura: .ummAlQura
        case .dubai: .dubai
        case .moonsightingCommittee: .moonsightingCommittee
        case .northAmerica: .northAmerica
        case .kuwait: .kuwait
        case .qatar: .qatar
        case .singapore: .singapore
        case .tehran: .tehran
        case .turkey: .turkey
        }
    }

    private static func highLatitudeRule(_ rule: SelamCore.HighLatitudeRule) -> Adhan.HighLatitudeRule {
        switch rule {
        case .middleOfTheNight: .middleOfTheNight
        case .seventhOfTheNight: .seventhOfTheNight
        case .twilightAngle: .twilightAngle
        }
    }
}
```

- [ ] **Step 4: Testin geçtiğini gör**

Run: `cd SelamCore && swift test --filter PrayerCalculatorTests`
Expected: 8 test, hepsi PASS.

Derleme hatası Adhan adlarından kaynaklanıyorsa (`Coordinates`, `PrayerTimes`, `CalculationMethod`, `PrayerAdjustments`, `Madhab`, `HighLatitudeRule`), `SelamCore/.build/checkouts/adhan-swift/README.md` ve `Sources/` altındaki tanımlara bakıp yalnızca bu dosyayı düzelt. Bir "plausible range" testi başarısız olursa hesaplanan yerel saati yazdır ve Diyanet'in o günkü İstanbul vakitleriyle karşılaştır; sınırı ancak resmi vakit sınırın dışındaysa değiştir.

- [ ] **Step 5: Tüm paketi çalıştır**

Run: `cd SelamCore && swift test`
Expected: 37 test (4 + 8 + 10 + 7 + 8), hepsi PASS.

- [ ] **Step 6: Commit**

```bash
git add SelamCore
git commit -m "feat(core): prayer time calculator wrapping Adhan"
```

---

## Sonraki planlar

| Plan | İçerik | Ön koşul |
|---|---|---|
| Plan 2 | Uygulama iskeleti (XcodeGen), Bugün ekranı ve gökyüzü, Canlı Etkinlik ve bildirim bağdaştırıcıları, "Kıldım" | Task 1 kararı |
| Plan 3 | Camilerim, yürüme süresi, Ayarlar, karşılama, bağış | Plan 2 |
| Plan 4 | Widget'lar ve Apple Watch | Plan 2 |
| Plan 5 | Yerelleştirme (6 dil, sağdan sola) | Plan 3 |
| Plan 6 | Yayın hazırlığı ve tanıtım | Plan 4-5 |

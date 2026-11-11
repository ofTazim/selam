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

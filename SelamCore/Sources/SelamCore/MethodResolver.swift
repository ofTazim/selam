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

import Foundation
@preconcurrency import Lingo
import Solver

public struct SupportedLanguage: Sendable {
    public let locale: Locale
    public let solver: Solver
    private let lingo: Lingo

    public init(locale: Locale, solver: Solver, lingo: Lingo) {
        precondition(
            locale.language.languageCode != nil,
            "Locale must have a valid language code")
        self.locale = locale
        self.solver = solver
        self.lingo = lingo
    }

    public var languageCode: String {
        locale.language.languageCode!.identifier
    }

    public func localize(_ key: String, interpolations: [String: String]? = nil) -> String {
        return lingo.localize(
            key, locale: languageCode, interpolations: interpolations ?? [:]
        )
    }
}

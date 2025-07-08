import ArgumentParser
import Foundation
@preconcurrency import Lingo
import Solver

extension Lingo {
    private static let _fromBundleLocalisations: Result<Lingo, Error> = Result {
        let localizationsURL = Bundle.module.url(forResource: "Localisations", withExtension: nil)!
        return try Lingo(rootPath: localizationsURL.path, defaultLocale: "en")
    }
    static var fromBundleLocalisations: Lingo { get throws { try _fromBundleLocalisations.get() } }
}

public struct SupportedLanguage: Sendable {
    public let locale: Locale
    public let solver: Solver
    private let lingo: Lingo
    public let localisedName: String

    public init(locale: Locale, solver: Solver, lingo: Lingo) {
        let languageCode = locale.language.languageCode
        precondition(
            languageCode != nil,
            "Locale must have a valid language code")
        self.locale = locale
        let localisedName = locale.localizedString(forLanguageCode: languageCode!.identifier)
        precondition(localisedName != nil, "Locale must have a localised name")
        self.localisedName = localisedName!
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

extension SupportedLanguage: ExpressibleByArgument {
    public init?(argument: String) {
        let locale = Locale(identifier: argument)
        guard
            let languageCode = locale.language.languageCode?.identifier,
            let url = Bundle.module.url(forResource: "words-\(languageCode)", withExtension: "txt"),
            let contents = try? String(contentsOf: url, encoding: .utf8),
            let lingo = try? Lingo.fromBundleLocalisations
        else { return nil }

        self.init(
            locale: locale, solver: Solver(words: contents.components(separatedBy: .newlines)),
            lingo: lingo)
    }
}

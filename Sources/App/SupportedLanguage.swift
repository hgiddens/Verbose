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

    /// User-facing description of the language, e.g. "English" or "Deutsch (Schweiz)"
    public let localisedName: String

    /// The full language identifier, possibly including region code, e.g. "en-NZ".
    public let identifier: String

    /// The language identifer, without region code, e.g. "en".
    public let languageCode: String

    /// The region code identifier (if present), e.g. "NZ".
    public let regionCode: String?

    public init(locale: Locale, solver: Solver, lingo: Lingo) {
        let languageCode: Locale.LanguageCode! = locale.language.languageCode
        precondition(
            languageCode != nil,
            "Locale must have a valid language code")
        self.locale = locale

        // Generate localized name
        let languageName = locale.localizedString(forLanguageCode: languageCode.identifier)
        precondition(languageName != nil, "Locale must have a localised language name")

        if let region = locale.language.region {
            let regionName = locale.localizedString(forRegionCode: region.identifier)
            precondition(regionName != nil, "Locale must have a localised region name")
            self.localisedName = lingo.localize(
                "language.combined",
                locale: languageCode.identifier,
                interpolations: ["language": languageName!, "region": regionName!]
            )
            self.identifier = "\(languageCode.identifier)-\(region.identifier)"
            self.regionCode = region.identifier
        } else {
            self.localisedName = languageName!
            self.identifier = languageCode.identifier
            self.regionCode = nil
        }

        self.languageCode = languageCode.identifier
        self.solver = solver
        self.lingo = lingo
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
            let lingo = try? Lingo.fromBundleLocalisations,
            let wordsURLs = Bundle.module.urls(
                forResourcesWithExtension: "txt", subdirectory: "words") as [URL]?
        else {
            return nil
        }

        let matchingURLs: [URL]
        if let region = locale.language.region {
            let targetFilename = "\(languageCode)_\(region.identifier).txt"
            matchingURLs = wordsURLs.filter { $0.lastPathComponent == targetFilename }
        } else {
            let prefix = "\(languageCode)_"
            matchingURLs = wordsURLs.filter { $0.lastPathComponent.hasPrefix(prefix) }
        }
        if matchingURLs.isEmpty { return nil }

        var wordSet: Set<String> = []
        for url in matchingURLs {
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
                return nil
            }
            wordSet.formUnion(contents.components(separatedBy: .newlines))
        }

        var words = Array(wordSet)
        words.sort()

        self.init(locale: locale, solver: Solver(words: words), lingo: lingo)
    }
}

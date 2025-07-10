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

        // Generate localized name
        let languageName = locale.localizedString(forLanguageCode: languageCode!.identifier)
        precondition(languageName != nil, "Locale must have a localised language name")

        if let region = locale.language.region {
            let regionName = locale.localizedString(forRegionCode: region.identifier)
            precondition(regionName != nil, "Locale must have a localised region name")
            self.localisedName = lingo.localize(
                "language.combined",
                locale: languageCode!.identifier,
                interpolations: ["language": languageName!, "region": regionName!]
            )
        } else {
            self.localisedName = languageName!
        }

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
            let lingo = try? Lingo.fromBundleLocalisations
        else { return nil }

        // Find matching word files
        guard
            let wordsURLs = Bundle.module.urls(
                forResourcesWithExtension: "txt", subdirectory: "words")
        else {
            return nil
        }

        let matchingURLs: [URL]
        if let region = locale.language.region {
            // Specific region requested - look for exact match
            let targetFilename = "\(languageCode)_\(region.identifier).txt"
            matchingURLs = wordsURLs.filter { $0.lastPathComponent == targetFilename }
        } else {
            // Language only - collect all files for this language
            let prefix = "\(languageCode)_"
            matchingURLs = wordsURLs.filter { $0.lastPathComponent.hasPrefix(prefix) }
        }

        // Return nil if no matching files found
        guard !matchingURLs.isEmpty else { return nil }

        // Load and combine contents from all matching files
        var allWords: [String] = []
        for url in matchingURLs {
            guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
                return nil
            }
            allWords.append(contentsOf: contents.components(separatedBy: .newlines))
        }

        // Remove empty strings and duplicates
        let uniqueWords = Array(Set(allWords.filter { !$0.isEmpty }))

        self.init(
            locale: locale,
            solver: Solver(words: uniqueWords),
            lingo: lingo)
    }
}

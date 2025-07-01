import Foundation
import Hummingbird
@preconcurrency import Lingo
import Logging
import Solver

public protocol AppArguments {
    var hostname: String { get }
    var logLevel: Logger.Level? { get }
    var port: Int { get }
}

func buildSupportedLanguages() throws -> [SupportedLanguage] {
    // This runs at app startup and will never change, so I'm not going to
    // bother defining a custom error type to deal with it "properly".
    let availableLanguageCodes = ["en", "de"]
    let localeMap: [String: Locale] = [
        "en": Locale(identifier: "en_NZ"),
        "de": Locale(identifier: "de_DE"),
    ]

    let lingo = try Lingo.fromBundleLocalisations
    var supportedLanguages: [SupportedLanguage] = []

    for languageCode in availableLanguageCodes {
        let locale = localeMap[languageCode]!
        let url = Bundle.module.url(forResource: "words-\(languageCode)", withExtension: "txt")!
        let contents = try String(contentsOf: url, encoding: .utf8)
        let lines = contents.components(separatedBy: .newlines)
        let solver = Solver(words: lines)

        supportedLanguages.append(SupportedLanguage(locale: locale, solver: solver, lingo: lingo))
    }

    return supportedLanguages
}

extension Lingo {
    private static let _fromBundleLocalisations: Result<Lingo, Error> = Result {
        let localizationsURL = Bundle.module.url(forResource: "Localisations", withExtension: nil)!
        return try Lingo(rootPath: localizationsURL.path, defaultLocale: "en")
    }
    static var fromBundleLocalisations: Lingo { get throws { try _fromBundleLocalisations.get() } }
}

public func buildApplication(
    _ arguments: some AppArguments, supportedLanguages: [SupportedLanguage]
) async throws
    -> some ApplicationProtocol
{
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "Verbose")
        logger.logLevel =
            arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap {
                Logger.Level(rawValue: $0)
            }
            ?? .info
        return logger
    }()
    for language in supportedLanguages {
        logger.debug(
            "Loaded word list for \(language.languageCode) with \(language.solver.totalWords) words"
        )
    }
    let router = buildRouter(supportedLanguages: supportedLanguages)
    return Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Verbose",
        ),
        logger: logger,
    )
}

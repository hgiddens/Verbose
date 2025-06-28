import Foundation
import Hummingbird
@preconcurrency import Lingo
import Logging
import Solver

public enum SupportedLanguage: CaseIterable, Sendable, CustomStringConvertible {
    case english

    public static let `default`: SupportedLanguage = .english

    public var description: String {
        switch self {
        case .english: return "en"
        }
    }

    public var wordListResourceURL: URL? {
        return Bundle.module.url(forResource: "words-\(self.description)", withExtension: "txt")
    }
}

public protocol AppArguments {
    var hostname: String { get }
    var logLevel: Logger.Level? { get }
    var port: Int { get }
}

private func buildSolvers() throws -> @Sendable (SupportedLanguage) -> Solver {
    // This runs at app startup and will never change, so I'm not going to
    // bother defining a custom error type to deal with it "properly".
    var solversDict: [SupportedLanguage: Solver] = [:]

    for language in SupportedLanguage.allCases {
        let url = language.wordListResourceURL!
        let contents = try String(contentsOf: url, encoding: .utf8)
        let lines = contents.components(separatedBy: .newlines)
        solversDict[language] = Solver(words: lines)
    }

    let solvers = solversDict  // Make immutable
    return { language in solvers[language]! }
}

private func buildLingo() throws -> Lingo {
    let localizationsURL = Bundle.module.url(forResource: "Localisations", withExtension: nil)!
    return try Lingo(rootPath: localizationsURL.path, defaultLocale: "en")
}

public func buildApplication(_ arguments: some AppArguments) async throws
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
    let solvers = try buildSolvers()
    for language in SupportedLanguage.allCases {
        let solver = solvers(language)
        logger.debug("Loaded word list for \(language) with \(solver.totalWords) words")
    }
    let lingo = try buildLingo()
    logger.debug("Loaded localisations")
    let router = buildRouter(solvers: solvers, lingo: lingo)
    return Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Verbose",
        ),
        logger: logger,
    )
}

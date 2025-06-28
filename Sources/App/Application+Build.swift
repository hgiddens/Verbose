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

private func buildSolver() throws -> Solver {
    // This runs at app startup and will never change, so I'm not going to
    // bother defining a custom error type to deal with it "properly".
    let url = Bundle.module.url(forResource: "words-en", withExtension: "txt")!
    let contents = try String(contentsOf: url, encoding: .utf8)
    let lines = contents.components(separatedBy: .newlines)
    return Solver(words: lines)
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
    let solver = try buildSolver()
    logger.debug("Loaded word list with \(solver.totalWords) words")
    let lingo = try buildLingo()
    logger.debug("Loaded localisations")
    let router = buildRouter(solver: solver, lingo: lingo)
    return Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Verbose",
        ),
        logger: logger,
    )
}

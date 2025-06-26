import Foundation
import Hummingbird
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
    let url = Bundle.module.url(forResource: "words", withExtension: "txt")!
    let contents = try String(contentsOf: url, encoding: .utf8)
    let lines = contents.components(separatedBy: .newlines)
    return Solver(words: lines)
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
    let router = buildRouter(solver: solver)
    return Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Verbose",
        ),
        logger: logger,
    )
}

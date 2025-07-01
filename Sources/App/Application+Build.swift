import Foundation
import Hummingbird
import Logging

public protocol AppArguments {
    var hostname: String { get }
    var logLevel: Logger.Level? { get }
    var port: Int { get }
    var languages: [SupportedLanguage] { get }
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
    for language in arguments.languages {
        logger.debug(
            "Loaded word list for \(language.languageCode) with \(language.solver.totalWords) words"
        )
    }
    let router = buildRouter(supportedLanguages: arguments.languages)
    return Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Verbose",
        ),
        logger: logger,
    )
}

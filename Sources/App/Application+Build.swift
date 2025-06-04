import Hummingbird
import Logging

public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "Verbose")
        logger.logLevel =
          arguments.logLevel ??
          environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
          .info
        return logger
    }()
    let router = buildRouter()
    return Application(
      router: router,
      configuration: .init(
        address: .hostname(arguments.hostname, port: arguments.port),
        serverName: "Verbose",
      ),
      logger: logger,
    )
}

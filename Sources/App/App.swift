import ArgumentParser
import Hummingbird
import Logging

extension Logger.Level: @retroactive ExpressibleByArgument {}

@main
struct AppCommand: AsyncParsableCommand, AppArguments {
    @Option var hostname = "127.0.0.1"
    @Option var port = 8080
    @Option var logLevel: Logger.Level?

    func run() async throws {
        let app = try await buildApplication(self)
        try await app.runService()
    }
}

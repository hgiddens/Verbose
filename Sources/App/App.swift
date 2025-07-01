import ArgumentParser
import Hummingbird
import Logging

extension Logger.Level: @retroactive ExpressibleByArgument {}

@main
struct AppCommand: AsyncParsableCommand, AppArguments {
    @Option var hostname = "127.0.0.1"
    @Option var logLevel: Logger.Level?
    @Option var port = 8080

    func run() async throws {
        let supportedLanguages = try buildSupportedLanguages()
        let app = try await buildApplication(self, supportedLanguages: supportedLanguages)
        try await app.runService()
    }
}

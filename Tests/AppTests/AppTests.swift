import Foundation
import Hummingbird
import HummingbirdTesting
@preconcurrency import Lingo
import Logging
import Solver
import Testing

@testable import Verbose

@Suite final class AppTests {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let logLevel: Logger.Level? = .trace
        let port = 0
        let languages: [SupportedLanguage]
    }

    func createTestSupportedLanguages() throws -> [SupportedLanguage] {
        let lingo = try Lingo(dataSource: TestLocalizationDataSource(), defaultLocale: "en")

        let englishSolver = Solver(words: ["xylophone", "test", "word", "example"])
        let englishLanguage = SupportedLanguage(
            locale: Locale(identifier: "en_NZ"),
            solver: englishSolver,
            lingo: lingo
        )

        let germanSolver = Solver(words: ["test", "wort", "beispiel"])
        let germanLanguage = SupportedLanguage(
            locale: Locale(identifier: "de_DE"),
            solver: germanSolver,
            lingo: lingo
        )

        return [englishLanguage, germanLanguage]
    }

    @Test func testRedirectDefault() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.status == .found)
                #expect(response.headers[.location] == "en")
            }
        }
    }

    @Test func testAcceptLanguageNegotiation() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/",
                method: .get,
                headers: [.acceptLanguage: "en-US,en;q=0.9"]
            ) { response in
                #expect(response.status == .found)
                #expect(response.headers[.location] == "en")
            }
        }
    }

    @Test func testAcceptLanguageUnsupported() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/",
                method: .get,
                headers: [.acceptLanguage: "es-ES,es;q=0.9,fr;q=0.8"]
            ) { response in
                #expect(response.status == .found)
                #expect(response.headers[.location] == "en")
            }
        }
    }

    @Test func testGet() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/en", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentSecurityPolicy] == "frame-ancestors 'none'")
                #expect(response.headers[.contentType] == "text/html; charset=utf-8")
                let bodyString = response.body.getString(
                    at: 0,
                    length: response.body.readableBytes,
                    encoding: .utf8)
                try #expect(#require(bodyString).contains("<a href=\"de\">Deutsch</a>"))
            }
        }
    }

    @Test func testGetGerman() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/de", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentType] == "text/html; charset=utf-8")
                let bodyString = response.body.getString(
                    at: 0,
                    length: response.body.readableBytes,
                    encoding: .utf8)
                try #expect(#require(bodyString).contains("Lösen wir mal ein Wort!"))
                try #expect(#require(bodyString).contains("<a href=\"en\">English</a>"))
            }
        }
    }

    @Test func testPostWithGoodPattern() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/en",
                method: .post,
                headers: [.contentType: "application/x-www-form-urlencoded"],
                body: ByteBuffer(staticString: "pattern=xylophon?")
            ) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentType] == "text/html; charset=utf-8")
                let bodyString = response.body.getString(
                    at: 0,
                    length: response.body.readableBytes,
                    encoding: .utf8)
                try #expect(
                    #require(bodyString).contains("https://en.wiktionary.org/wiki/xylophone"))
            }
        }
    }

    @Test func testPostWithBadPattern() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/en",
                method: .post,
                headers: [.contentType: "application/x-www-form-urlencoded"],
                body: ByteBuffer(staticString: "pattern=inv@lid!")
            ) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentType] == "text/html; charset=utf-8")
                let bodyString = response.body.getString(
                    at: 0,
                    length: response.body.readableBytes,
                    encoding: .utf8)
                try #expect(#require(bodyString).contains("inv@lid!"))
            }
        }
    }

    @Test func testStaticCSSFile() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/static/styles.css", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentType] == "text/css")
                let bodyString = response.body.getString(
                    at: 0,
                    length: response.body.readableBytes,
                    encoding: .utf8)
                try #expect(#require(bodyString).contains("/* Verbose - CSS Styles */"))
            }
        }
    }

    @Test func testHTMLContainsStylesheetLink() async throws {
        let supportedLanguages = try createTestSupportedLanguages()
        let args = TestArguments(languages: supportedLanguages)
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/en", method: .get) { response in
                #expect(response.status == .ok)
                let bodyString = response.body.getString(
                    at: 0,
                    length: response.body.readableBytes,
                    encoding: .utf8)
                try #expect(
                    #require(bodyString).contains(
                        "<link rel=\"stylesheet\" href=\"/static/styles.css\">"))
            }
        }
    }
}

import Hummingbird
import HummingbirdTesting
import Logging
import Testing

@testable import Verbose

@Suite final class AppTests {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let logLevel: Logger.Level? = .trace
        let port = 0
    }

    @Test func testRedirectDefault() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.status == .found)
                #expect(response.headers[.location] == "/en")
            }
        }
    }

    @Test func testAcceptLanguageNegotiation() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/",
                method: .get,
                headers: [.acceptLanguage: "en-US,en;q=0.9"]
            ) { response in
                #expect(response.status == .found)
                #expect(response.headers[.location] == "/en")
            }
        }
    }

    @Test func testAcceptLanguageUnsupported() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(
                uri: "/",
                method: .get,
                headers: [.acceptLanguage: "es-ES,es;q=0.9,fr;q=0.8"]
            ) { response in
                #expect(response.status == .found)
                #expect(response.headers[.location] == "/en")
            }
        }
    }

    @Test func testGet() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/en", method: .get) { response in
                #expect(response.status == .ok)
                #expect(response.headers[.contentSecurityPolicy] == "frame-ancestors 'none'")
                #expect(response.headers[.contentType] == "text/html; charset=utf-8")
            }
        }
    }

    @Test func testPostWithGoodPattern() async throws {
        let args = TestArguments()
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
        let args = TestArguments()
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
}

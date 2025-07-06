import Foundation
import Testing

@testable import Verbose

@Suite final class StaticFileTests {
    @Test func testValidStaticFileIdentifierGeneration() throws {
        let provider = StaticFileProvider(bundlePath: "/test/bundle")

        let validId = provider.getFileIdentifier("/static/styles.css")
        #expect(validId == "/test/bundle/static/styles.css")
    }

    @Test func testInvalidPathsReturnNil() throws {
        let provider = StaticFileProvider(bundlePath: "/test/bundle")

        let invalidId = provider.getFileIdentifier("/words-en.txt")
        #expect(invalidId == nil)
    }

    @Test func testDirectoryTraversalPrevention() throws {
        let provider = StaticFileProvider(bundlePath: "/test/bundle")

        let path = "/static/../words-en.txt"
        #expect(provider.getFileIdentifier(path) == nil)
        #expect(provider.getFileIdentifier(path) == nil)
    }

    @Test func testNonStaticPathsBlocked() throws {
        let provider = StaticFileProvider(bundlePath: "/test/bundle")

        #expect(provider.getFileIdentifier("/words-en.txt") == nil)
    }

    @Test func testValidStaticPaths() throws {
        let provider = StaticFileProvider(bundlePath: "/test/bundle")

        #expect(
            provider.getFileIdentifier("/static/styles.css") == "/test/bundle/static/styles.css")
    }

    @Test func testGetAttributes() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testBundle = tempDir.appendingPathComponent("test-bundle-\(UUID())")
        let staticDir = testBundle.appendingPathComponent("static")

        try FileManager.default.createDirectory(at: staticDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: testBundle) }

        let cssFile = staticDir.appendingPathComponent("test.css")
        let cssContent = "/* Test CSS */"
        try cssContent.write(to: cssFile, atomically: true, encoding: .utf8)

        let provider = StaticFileProvider(bundlePath: testBundle.path)
        let fileId = testBundle.path + "/static/test.css"

        let attributes = try await provider.getAttributes(id: fileId)
        #expect(attributes?.isFolder == false)
        #expect(attributes?.size == cssContent.utf8.count)
    }

    @Test func testGetAttributesMissingFile() async throws {
        let provider = StaticFileProvider(bundlePath: "/nonexistent")

        let attributes = try await provider.getAttributes(id: "/nonexistent/static/missing.css")
        #expect(attributes == nil)
    }
}

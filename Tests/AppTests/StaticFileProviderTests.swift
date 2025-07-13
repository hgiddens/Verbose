import Foundation
import Testing

@testable import Verbose

@Suite final class StaticFileTests {
    let provider = StaticFileProvider()

    @Test func validStaticFileIdentifierGeneration() throws {
        let expectedIdentifier = provider.resourceURL.appending(components: "static", "styles.css")
            .path
        #expect(FileManager.default.fileExists(atPath: expectedIdentifier))
        #expect(provider.getFileIdentifier("/static/styles.css") == expectedIdentifier)
    }

    @Test func invalidPathsReturnNil() throws {
        #expect(provider.getFileIdentifier("/no-such-file.txt") == nil)
    }

    @Test func directoryTraversalPrevention() throws {
        let wordsFile = provider.resourceURL.appending(path: "static/../words/en_GB.txt")
        #expect(FileManager.default.fileExists(atPath: wordsFile.path))
        #expect(provider.getFileIdentifier("/static/../words/en_GB.txt") == nil)
    }

    @Test func nonStaticPathsBlocked() throws {
        #expect(
            FileManager.default.fileExists(
                atPath: provider.resourceURL.appending(components: "words", "en_GB.txt").path))
        #expect(provider.getFileIdentifier("/words/en_GB.txt") == nil)
    }

    @Test func getAttributes() async throws {
        let styles = provider.resourceURL.appending(components: "static", "styles.css")
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: styles.path)

        let fileId = try #require(provider.getFileIdentifier("/static/styles.css"))
        let attributes = try await provider.getAttributes(id: fileId)

        #expect(attributes?.isFolder == false)
        #expect(try #require(attributes?.size) == (fileAttributes as NSDictionary).fileSize())
    }

    @Test func getAttributesMissingFile() async throws {
        let attributes = try await provider.getAttributes(id: "/nonexistent")
        #expect(attributes == nil)
    }
}

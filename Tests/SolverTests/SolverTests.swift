import Foundation
import Testing

@testable import Solver

private let locale: Locale = .init(identifier: "en_NZ")

@Suite final class PatternTests {
    @Test func nullPattern() {
        #expect(Pattern(string: "", locale: locale) == nil)
    }

    @Test func simplePattern() throws {
        let pattern = try #require(Pattern(string: "AZaz?", locale: locale))
        #expect(pattern.matches(string: "AZazb"))
        #expect(pattern.matches(string: "AZazé"))
        #expect(!pattern.matches(string: "xAZazbx"))
    }

    @Test func spacesRemoved() throws {
        #expect(Pattern(string: " ", locale: locale) == nil)

        let pattern = try #require(Pattern(string: " a ? b ? ", locale: locale))
        #expect(pattern.matches(string: "axby"))
    }

    @Test func diacritics() throws {
        let pattern = try #require(Pattern(string: "café", locale: locale))

        #expect(pattern.matches(string: "CAFE"))
        #expect(pattern.matches(string: "CAFÉ"))
        #expect(pattern.matches(string: "cafe"))
        #expect(pattern.matches(string: "café"))
    }

    @Test func invalidCharacters() throws {
        #expect(Pattern(string: "grand-mother", locale: locale) == nil)
        #expect(Pattern(string: "123", locale: locale) == nil)
    }
}

@Suite final class SolverTests {
    @Test func matches() throws {
        let pattern = try #require(Pattern(string: "f??d", locale: locale))
        let solver = Solver(words: ["fade", "Ford", "FEED", "reed"])
        #expect(solver.solve(pattern: pattern) == Set(["FEED", "Ford"]))
    }

    @Test func diacritics() throws {
        let solver = Solver(words: ["CAFE", "CAFÉ", "cafe", "café"])

        let barePattern = try #require(Pattern(string: "cafe", locale: locale))
        #expect(solver.solve(pattern: barePattern) == Set(solver.words))

        let diacriticPattern = try #require(Pattern(string: "café", locale: locale))
        #expect(solver.solve(pattern: diacriticPattern) == Set(solver.words))
    }

    @Test func noMatches() throws {
        let pattern = try #require(Pattern(string: "f??d", locale: locale))
        #expect(Solver(words: []).solve(pattern: pattern) == Set())
        #expect(Solver(words: ["fud"]).solve(pattern: pattern) == Set())
    }
}

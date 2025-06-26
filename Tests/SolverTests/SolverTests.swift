import Foundation
import Testing

@testable import Solver

private let locale: Locale = .init(identifier: "en_NZ")

@Suite final class PatternTests {
    @Test func nullPattern() {
        #expect(Pattern(string: "") == nil)
    }

    @Test func simplePattern() throws {
        let pattern = try #require(Pattern(string: "AZaz?"))
        let compiled = try CompiledPattern(pattern: pattern, locale: locale)
        #expect(compiled.matches(string: "AZazb"))
        #expect(compiled.matches(string: "AZazé"))
        #expect(!compiled.matches(string: "xAZazbx"))
    }

    @Test func spacesRemoved() throws {
        #expect(Pattern(string: " ") == nil)

        let pattern = try #require(Pattern(string: " a ? b ? "))
        let compiled = try CompiledPattern(pattern: pattern, locale: locale)
        #expect(compiled.matches(string: "axby"))
    }

    @Test func diacritics() throws {
        let pattern = try #require(Pattern(string: "café"))
        let compiled = try CompiledPattern(pattern: pattern, locale: locale)

        #expect(compiled.matches(string: "CAFE"))
        #expect(compiled.matches(string: "CAFÉ"))
        #expect(compiled.matches(string: "cafe"))
        #expect(compiled.matches(string: "café"))
    }

    @Test func invalidCharacters() throws {
        #expect(Pattern(string: "grand-mother") == nil)
        #expect(Pattern(string: "123") == nil)
    }
}

@Suite final class SolverTests {
    @Test func matches() throws {
        let pattern = try #require(Pattern(string: "f??d"))
        let solver = Solver(words: ["fade", "Ford", "FEED", "reed"])
        let result = try solver.solve(pattern: pattern, locale: locale)
        #expect(result == Set(["FEED", "Ford"]))
    }

    @Test func diacritics() throws {
        let allWords = ["CAFE", "CAFÉ", "cafe", "café"]
        let solver = Solver(words: allWords)

        let barePattern = try #require(Pattern(string: "cafe"))
        let bareResult = try solver.solve(pattern: barePattern, locale: locale)
        #expect(bareResult == Set(allWords))

        let diacriticPattern = try #require(Pattern(string: "café"))
        let diacriticResult = try solver.solve(pattern: diacriticPattern, locale: locale)
        #expect(diacriticResult == Set(allWords))
    }

    @Test func noMatches() throws {
        let pattern = try #require(Pattern(string: "f??d"))
        let emptyResult = try Solver(words: []).solve(pattern: pattern, locale: locale)
        #expect(emptyResult == Set())
        let noMatchResult = try Solver(words: ["fud"]).solve(pattern: pattern, locale: locale)
        #expect(noMatchResult == Set())
    }
}

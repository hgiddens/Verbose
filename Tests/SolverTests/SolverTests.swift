import Testing

@testable import Solver

@Suite final class PatternTests {
    @Test func nullPattern() {
        #expect(Pattern(string: "") == nil)
    }

    @Test func simplePattern() throws {
        let pattern = try #require(Pattern(string: "AZaz?"))
        #expect(pattern.matches(string: "AZazb"))
        #expect(!pattern.matches(string: "AZazé"))
    }

    @Test func spacesRemoved() throws {
        #expect(Pattern(string: " ") == nil)

        let pattern = try #require(Pattern(string: " a ? b ? "))
        #expect(pattern.matches(string: "axby"))
    }

    @Test func invalidCharacters() throws {
        #expect(Pattern(string: "café") == nil)
        #expect(Pattern(string: "grand-mother") == nil)
        #expect(Pattern(string: "123") == nil)
    }
}

@Suite final class SolverTests {
    @Test func matches() throws {
        let pattern = try #require(Pattern(string: "f??d"))
        let solver = Solver(words: ["fade", "Ford", "FEED", "reed"])
        #expect(solver.solve(pattern: pattern) == ["FEED", "Ford"])
    }

    @Test func noMatches() throws {
        let pattern = try #require(Pattern(string: "f??d"))
        #expect(Solver(words: []).solve(pattern: pattern) == [])
        #expect(Solver(words: ["fud"]).solve(pattern: pattern) == [])
    }
}

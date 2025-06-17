import Foundation

public struct Pattern {
    private let value: Regex<AnyRegexOutput>

    private static func validChar(_ c: Character) -> Bool {
        guard let v = c.asciiValue else { return false }

        // I don't care about anything other than literally ASCII right now.
        return
          v == "?".first!.asciiValue! ||
          ("A".first!.asciiValue! ... "Z".first!.asciiValue!).contains(v) ||
          ("a".first!.asciiValue! ... "z".first!.asciiValue!).contains(v)
    }

    public init?(string: String) {
        let pattern = string.filter { !$0.isWhitespace }

        guard
          pattern.count > 0,
          pattern.allSatisfy(Self.validChar)
        else { return nil }

        guard let regex = try? Regex("^" + pattern.replacingOccurrences(of: "?", with: "\\w") + "$")
        else { return nil }

        self.value = regex.asciiOnlyCharacterClasses().ignoresCase()
    }

    public func matches(string: String) -> Bool {
        let match = try? value.wholeMatch(in: string)
        return match != nil
    }
}

public struct Solver: Sendable {
    public let words: [String]

    public init(words: [String]) {
        self.words = words
    }

    public func solve(pattern: Pattern) -> [String] {
        words.filter(pattern.matches).sorted()
    }
}

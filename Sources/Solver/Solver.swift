import Foundation

extension String {
    fileprivate func foldedDiacritics(locale: Locale) -> String {
        self.folding(options: .diacriticInsensitive, locale: locale)
    }
}

public struct Pattern {
    private let value: Regex<AnyRegexOutput>
    private let locale: Locale

    public init?(string: String, locale: Locale) {
        let pattern = string.filter { !$0.isWhitespace }

        guard
            pattern.count > 0,
            pattern.allSatisfy({ $0 == "?" || $0.isLetter })
        else { return nil }

        guard
            let regex = try? Regex(
                pattern.foldedDiacritics(locale: locale).replacingOccurrences(of: "?", with: "\\w"))
        else { return nil }

        self.value = regex.ignoresCase()
        self.locale = locale
    }

    public func matches(string: String) -> Bool {
        let match = try? value.wholeMatch(in: string.foldedDiacritics(locale: locale))
        return match != nil
    }
}

public struct Solver: Sendable {
    public let words: [String]

    public init(words: [String]) {
        self.words = words
    }

    public func solve(pattern: Pattern) -> Set<String> {
        Set(words.filter(pattern.matches))
    }
}

import Foundation

public struct PatternCompilationError: Error, LocalizedError {
    public let pattern: String

    public var errorDescription: String? {
        "Failed to compile pattern: \(pattern)"
    }
}

extension String {
    fileprivate func foldedDiacritics(locale: Locale) -> String {
        self.folding(options: .diacriticInsensitive, locale: locale)
    }
}

public struct Pattern {
    public let value: String

    public init?(string: String) {
        let pattern = string.filter { !$0.isWhitespace }

        guard
            pattern.count > 0,
            pattern.allSatisfy({ $0 == "?" || $0.isLetter })
        else { return nil }

        self.value = pattern
    }
}

internal struct CompiledPattern {
    private let regex: Regex<AnyRegexOutput>
    private let locale: Locale

    public init(pattern: Pattern, locale: Locale) throws {
        guard
            let regex = try? Regex(
                pattern.value.foldedDiacritics(locale: locale).replacingOccurrences(
                    of: "?", with: "\\w"))
        else {
            throw PatternCompilationError(pattern: pattern.value)
        }

        self.regex = regex.ignoresCase()
        self.locale = locale
    }

    public func matches(string: String) -> Bool {
        let match = try? regex.wholeMatch(in: string.foldedDiacritics(locale: locale))
        return match != nil
    }
}

public struct Solver: Sendable {
    public let words: [String]

    public init(words: [String]) {
        self.words = words
    }

    public func solve(pattern: Pattern, locale: Locale) throws -> Set<String> {
        let compiled = try CompiledPattern(pattern: pattern, locale: locale)
        return Set(words.filter(compiled.matches))
    }
}

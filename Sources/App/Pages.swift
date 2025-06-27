import Elementary
import Foundation
@preconcurrency import Lingo

final class Localizer: Sendable {
    let lingo: Lingo
    let locale: Locale

    init(lingo: Lingo, locale: Locale) {
        self.lingo = lingo
        self.locale = locale
    }

    func localize(_ key: String, interpolations: [String: String]? = nil) -> String {
        let localeCode = locale.language.languageCode?.identifier ?? "en"
        return lingo.localize(key, locale: localeCode, interpolations: interpolations ?? [:])
    }
}

extension MainLayout: Sendable where Body: Sendable {}
struct MainLayout<Body: HTML>: HTMLDocument {
    let localizer: Localizer
    var title: String { localizer.localize("app.title") }
    let lang = "en"

    @HTMLBuilder var pageContent: Body

    var head: some HTML {
        meta(.charset(.utf8))
        meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))
    }

    var body: some HTML {
        header {
            hgroup {
                h1 { title }
                h2 { localizer.localize("app.subtitle") }
            }
        }

        pageContent
    }
}

struct EntryForm: HTML {
    let localizer: Localizer

    struct FormData: Decodable {
        let pattern: String
    }

    var content: some HTML {
        section {
            h3 { localizer.localize("entry.title") }
            p {
                localizer.localize("entry.instructions")
            }
            p { localizer.localize("entry.example") }
            form(.method(.post)) {
                p {
                    label(.for("pattern")) { localizer.localize("entry.label") }
                    input(
                        .id("pattern"),
                        .name("pattern"),
                        .placeholder(localizer.localize("entry.placeholder")),
                        .type(.text),
                        .required,
                        .autocomplete(.off),
                    )
                }
                p {
                    input(.type(.submit), .value(localizer.localize("entry.button")))
                }
            }
        }
    }
}

struct BadPattern: HTML {
    let pattern: String
    let localizer: Localizer

    var content: some HTML {
        section {
            h3 { localizer.localize("error.title") }
            p {
                localizer.localize("error.pattern", interpolations: ["pattern": pattern])
            }
            p { localizer.localize("error.pattern.help") }
        }
    }
}

struct Word: HTML {
    let word: String
    let locale: Locale

    init(_ word: String, locale: Locale) {
        self.word = word
        self.locale = locale
    }

    var content: some HTML {
        let lang = locale.language.languageCode?.identifier ?? "en"
        word
        " "
        a(
            .href("https://\(lang).wiktionary.org/wiki/\(word)"), .target(.blank),
            .rel("noopener noreferrer")
        ) {
            "📖"
        }
    }
}

struct WordList: HTML {
    let words: [String]
    let corpusSize: Int
    let duration: Duration
    let locale: Locale
    let localizer: Localizer

    var content: some HTML {
        section {
            if words.count == 0 {
                p { localizer.localize("results.none") }
            } else {
                h3 { localizer.localize("results.title") }
                ul {
                    ForEach(words) { word in
                        li { Word(word, locale: locale) }
                    }
                }
                aside {
                    p {
                        let durationString = duration.formatted(
                            .units(
                                allowed: [.seconds, .milliseconds],
                                width: .narrow,
                                maximumUnitCount: 1,
                            ).locale(locale))
                        localizer.localize(
                            "results.stats",
                            interpolations: [
                                "count": corpusSize.formatted(.number.locale(locale)),
                                "duration": durationString,
                            ])
                    }
                }
            }
        }
    }
}

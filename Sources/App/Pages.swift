import Elementary
import Foundation
@preconcurrency import Lingo

extension MainLayout: Sendable where Body: Sendable {}
struct MainLayout<Body: HTML>: HTMLDocument {
    let language: SupportedLanguage
    let currentLanguage: SupportedLanguage
    let supportedLanguages: [SupportedLanguage]
    var title: String { language.localize("app.title") }
    var lang: String { currentLanguage.languageCode }

    @HTMLBuilder var pageContent: Body

    var head: some HTML {
        meta(.charset(.utf8))
        meta(.name(.viewport), .content("width=device-width, initial-scale=1.0"))
    }

    var body: some HTML {
        header {
            hgroup {
                h1 { title }
                h2 { language.localize("app.subtitle") }
            }
        }

        pageContent

        Footer(currentLanguage: currentLanguage, supportedLanguages: supportedLanguages)
    }
}

struct EntryForm: HTML {
    let language: SupportedLanguage

    struct FormData: Decodable {
        let pattern: String
    }

    var content: some HTML {
        section {
            h3 { language.localize("entry.title") }
            p {
                language.localize("entry.instructions")
            }
            p { language.localize("entry.example") }
            form(.method(.post)) {
                p {
                    label(.for("pattern")) { language.localize("entry.label") }
                    input(
                        .id("pattern"),
                        .name("pattern"),
                        .placeholder(language.localize("entry.placeholder")),
                        .type(.text),
                        .required,
                        .autocomplete(.off),
                    )
                }
                p {
                    input(.type(.submit), .value(language.localize("entry.button")))
                }
            }
        }
    }
}

struct BadPattern: HTML {
    let pattern: String
    let language: SupportedLanguage

    var content: some HTML {
        section {
            h3 { language.localize("error.title") }
            p {
                language.localize("error.pattern", interpolations: ["pattern": pattern])
            }
            p { language.localize("error.pattern.help") }
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
    let language: SupportedLanguage

    var content: some HTML {
        section {
            if words.count == 0 {
                p { language.localize("results.none") }
            } else {
                h3 { language.localize("results.title") }
                ul {
                    ForEach(words) { word in
                        li { Word(word, locale: language.locale) }
                    }
                }
                aside {
                    p {
                        let durationString = duration.formatted(
                            .units(
                                allowed: [.seconds, .milliseconds],
                                width: .narrow,
                                maximumUnitCount: 1,
                            ).locale(language.locale))
                        language.localize(
                            "results.stats",
                            interpolations: [
                                "count": corpusSize.formatted(.number.locale(language.locale)),
                                "duration": durationString,
                            ])
                    }
                }
            }
        }
    }
}

struct Footer: HTML {
    let currentLanguage: SupportedLanguage
    let supportedLanguages: [SupportedLanguage]

    var content: some HTML {
        let otherLanguages = supportedLanguages.filter {
            $0.languageCode != currentLanguage.languageCode
        }

        if !otherLanguages.isEmpty {
            footer {
                nav {
                    ul {
                        ForEach(otherLanguages) { language in
                            li {
                                a(.href("\(language.languageCode)")) { language.languageCode }
                            }
                        }
                    }
                }
            }
        }
    }
}

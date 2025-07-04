import Elementary
import Foundation
@preconcurrency import Lingo
import Solver

private enum AppEnvironment {
    @TaskLocal static var language: SupportedLanguage? = nil
    @TaskLocal static var supportedLanguages: [SupportedLanguage] = []
}

extension HTML {
    fileprivate func withAppEnvironment(
        language: SupportedLanguage, supportedLanguages: [SupportedLanguage]
    ) -> some HTML {
        self
            .environment(AppEnvironment.$language, language)
            .environment(AppEnvironment.$supportedLanguages, supportedLanguages)
    }
}

extension MainLayout: Sendable where Body: Sendable {}
struct MainLayout<Body: HTML>: HTMLDocument {
    let language: SupportedLanguage
    let supportedLanguages: [SupportedLanguage]

    var title: String { language.localize("app.title") }
    var lang: String { language.languageCode }

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

        pageContent.withAppEnvironment(language: language, supportedLanguages: supportedLanguages)

        Footer().withAppEnvironment(language: language, supportedLanguages: supportedLanguages)
    }
}

struct EntryForm: HTML {
    @Environment(AppEnvironment.$language) var language: SupportedLanguage!

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
    @Environment(AppEnvironment.$language) var language: SupportedLanguage!

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
    @Environment(AppEnvironment.$language) var language: SupportedLanguage!

    var content: some HTML {
        word
        " "
        a(
            .href("https://\(language.languageCode).wiktionary.org/wiki/\(word)"), .target(.blank),
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
    @Environment(AppEnvironment.$language) var language: SupportedLanguage!

    var content: some HTML {
        section {
            if words.count == 0 {
                p { language.localize("results.none") }
            } else {
                h3 { language.localize("results.title") }
                ul {
                    ForEach(words) { word in
                        li { Word(word: word) }
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
    @Environment(AppEnvironment.$language) var currentLanguage: SupportedLanguage!
    @Environment(AppEnvironment.$supportedLanguages) var supportedLanguages

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

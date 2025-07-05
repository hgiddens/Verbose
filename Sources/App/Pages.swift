import Elementary
import Foundation
@preconcurrency import Lingo
import Solver

private enum AppEnvironment {
    @TaskLocal static var language: SupportedLanguage? = nil
}

extension HTML {
    fileprivate func withAppEnvironment(language: SupportedLanguage) -> some HTML {
        self.environment(AppEnvironment.$language, language)
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

        // Help web fonts load faster. I think this could be a middleware (there's a header which
        // triggers preconnect even earlier) but that feels like it might be a little
        // over-engineered for this.
        link(.rel("preconnect"), .href("https://fonts.googleapis.com"))
        link(.rel("preconnect"), .href("https://fonts.gstatic.com"), .crossorigin(.anonymous))
        link(
            .rel(.stylesheet),
            .href("https://fonts.googleapis.com/css2?family=Crimson+Text:wght@400;600&display=swap")
        )
    }

    var body: some HTML {
        header {
            hgroup {
                h1 { title }
                h2 { language.localize("app.subtitle") }
            }
        }

        let otherLanguages = supportedLanguages.filter {
            $0.languageCode != language.languageCode
        }
        // TODO: should this be in the header?
        nav {
            ul {
                ForEach(otherLanguages) { language in
                    li {
                        a(.href("\(language.languageCode)")) {
                            // TODO: aren't I guaranteed that _my_ locales have a language code?
                            language.locale.localizedString(
                                forLanguageCode: language.locale.language.languageCode?.identifier
                                    ?? "") ?? "Unknown"
                        }
                    }
                }
            }
        }

        pageContent.withAppEnvironment(language: language)
    }
}

struct EntryForm: HTML {
    @Environment(AppEnvironment.$language) var language: SupportedLanguage!

    struct FormData: Decodable {
        let pattern: String
    }

    var content: some HTML {
        section {
            form(.method(.post)) {
                span(.class("pattern-gradient-border")) {
                    // TODO: I can kill entry.label I think
                    // label(.for("pattern")) { language.localize("entry.label") }
                    input(
                        .id("pattern"),
                        .name("pattern"),
                        .placeholder(language.localize("entry.placeholder")),
                        .type(.text),
                        .required,
                        .autocomplete(.off),
                    )
                }
                button(.type(.submit)) {
                    language.localize("entry.button")
                }
            }
        }
        // TODO: This shouldn't be displayed all the time
        section {
            h3 { language.localize("entry.title") }
            p {
                language.localize("entry.instructions")
            }
            p { language.localize("entry.example") }
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
        a(
            .href("https://\(language.languageCode).wiktionary.org/wiki/\(word)"), .target(.blank),
            .rel("noopener noreferrer")
        ) {
            word
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
                h2 { language.localize("results.none") }
            } else {
                h2 { language.localize("results.title") }
                hr()
                ul {
                    ForEach(words) { word in
                        li { Word(word: word) }
                    }
                }
                hr()
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

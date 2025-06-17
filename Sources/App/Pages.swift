import Elementary
import Foundation

extension MainLayout: Sendable where Body: Sendable {}
struct MainLayout<Body: HTML>: HTMLDocument {
    let title = "Verbose"
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
                h2 { "Because words shouldn't make you cross" }
            }
        }

        pageContent
    }
}

struct EntryForm: HTML {
    struct FormData: Decodable {
        let pattern: String
    }

    var content: some HTML {
        section {
            h3 { "Let's solve a word!" }
            p {
                "Enter a word, replacing unknown letters with a question mark. "
                "Case is ignored. "
                "Then hit enter or press the button!"
            }
            p { "For example: v?r?o?e → variole, verbose" }
            form(.method(.post), .action("/")) {
                p {
                    label(.for("pattern")) { "Word pattern: " }
                    input(
                      .id("pattern"),
                      .name("pattern"),
                      .placeholder("v?r?o?e"),
                      .type(.text),
                      .required,
                      .autocomplete(.off),
                    )
                }
                p {
                    input(.type(.submit), .value("Let's go!"))
                }
            }
        }
    }
}

struct BadPattern: HTML {
    let pattern: String
    var content: some HTML {
        section {
            h3 { "Sorry!" }
            p { "I didn't understand the pattern “\(pattern)”." }
            p { "It should only be letters (where known) and question marks (where not)." }
        }
    }
}

struct WordList: HTML {
    let words: [String]
    let corpusSize: Int
    let duration: Duration

    var content: some HTML {
        section {
            if words.count == 0 {
                p { "No words found :(" }
            } else {
                h3 { "Words:" }
                ul {
                    ForEach(words) { word in
                        li { word }
                    }
                }
                aside {
                    p {
                        let durationString = duration.formatted(.units(
                                                                  allowed: [.seconds, .milliseconds],
                                                                  width: .narrow,
                                                                  maximumUnitCount: 1,
                                                                ))
                        "Checked \(corpusSize.formatted(.number)) words in \(durationString)"
                    }
                }
            }
        }
    }
}

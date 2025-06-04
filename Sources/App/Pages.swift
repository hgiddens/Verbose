import Elementary

extension Page: Sendable {}
struct Page: HTMLDocument {
    var title: String
    var lang = "en"  // could this be a let?
    var head: some HTML {
        meta(.charset(.utf8))
    }
    var body: some HTML {
        h1 { title }
    }
}

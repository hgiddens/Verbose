import Foundation
import Hummingbird
import HummingbirdElementary
import Solver

struct AppRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    var requestDecoder: URLEncodedFormDecoder { .init() }

    let locale: Locale = .init(identifier: "en_NZ")

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}

func buildRouter(solver: Solver) -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)

    // Add middleware
    router.addMiddleware { LogRequestsMiddleware(.info) }
    router.addMiddleware { SecurityHeadersMiddleware() }

    // Add routes
    router.get("/") { _, _ in HTMLResponse { MainLayout { EntryForm() } } }
    router.post("/") { request, context in
        let data = try await request.decode(as: EntryForm.FormData.self, context: context)
        guard let pattern = Pattern(string: data.pattern) else {
            return HTMLResponse {
                MainLayout {
                    EntryForm()
                    BadPattern(pattern: data.pattern)
                }
            }
        }

        let start = ContinuousClock.now
        let resultSet = try solver.solve(pattern: pattern, locale: context.locale)
        let end = ContinuousClock.now

        return HTMLResponse {
            MainLayout {
                EntryForm()
                WordList(
                    words: Array(resultSet).sorted { (a, b) in
                        switch a.compare(b, options: .caseInsensitive, locale: context.locale) {
                        case .orderedSame:
                            // By default, compare orders attic before Attic
                            // which makes my soul hurt.
                            return a < b
                        case let ordering:
                            return ordering == .orderedAscending
                        }
                    },
                    corpusSize: solver.words.count,
                    duration: end - start,
                    locale: context.locale
                )
            }
        }
    }

    return router
}

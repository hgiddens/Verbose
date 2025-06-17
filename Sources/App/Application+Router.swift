import Hummingbird
import HummingbirdElementary
import Solver

struct AppRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    var requestDecoder: URLEncodedFormDecoder { .init() }

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}

func buildRouter(solver: Solver) -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)

    // Add middleware
    router.addMiddleware { LogRequestsMiddleware(.info) }

    // Add routes
    router.get("/") { _,_ in HTMLResponse { MainLayout() { EntryForm() } } }
    router.post("/") { request, context in
        let data = try await request.decode(as: EntryForm.FormData.self, context: context)

        return HTMLResponse {
            MainLayout() {
                EntryForm()
                if let pattern = Pattern(string: data.pattern) {
                    let start = ContinuousClock.now
                    let result = solver.solve(pattern: pattern)
                    let end = ContinuousClock.now

                    WordList(words: result, corpusSize: solver.words.count, duration: end - start)
                } else {
                    BadPattern(pattern: data.pattern)
                }
            }

        }
    }

    return router
}

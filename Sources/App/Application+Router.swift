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

private func negotiateLanguage(from acceptLanguage: String, supportedLanguages: [SupportedLanguage])
    -> SupportedLanguage
{
    let supportedCodes = Set(supportedLanguages.map { $0.languageCode })

    let languages =
        acceptLanguage
        .components(separatedBy: ",")
        .compactMap { component -> (String, Double)? in
            let parts = component.trimmingCharacters(in: .whitespaces).components(
                separatedBy: ";q=")
            let lang = parts[0].components(separatedBy: "-")[0]
            let quality = parts.count > 1 ? Double(parts[1]) ?? 1.0 : 1.0
            return (lang, quality)
        }
        .sorted { $0.1 > $1.1 }

    for (lang, _) in languages {
        if supportedCodes.contains(lang) {
            return supportedLanguages.first { $0.languageCode == lang }!
        }
    }

    return supportedLanguages[0]  // Use first language as default
}

func buildRouter(supportedLanguages: [SupportedLanguage])
    -> Router<AppRequestContext>
{
    precondition(!supportedLanguages.isEmpty, "Must have at least one supported language")
    let uniqueLanguageCodes = Set(supportedLanguages.map { $0.languageCode })
    precondition(
        supportedLanguages.count == uniqueLanguageCodes.count,
        "All supported languages must have unique language codes")

    let router = Router(context: AppRequestContext.self)

    // Add middleware
    router.addMiddleware { LogRequestsMiddleware(.info) }
    router.addMiddleware { SecurityHeadersMiddleware() }

    // Add routes
    router.get("/") { request, context in
        let acceptLanguage = request.headers[.acceptLanguage] ?? ""
        let negotiatedLanguage = negotiateLanguage(
            from: acceptLanguage, supportedLanguages: supportedLanguages)
        return Response(status: .found, headers: [.location: "\(negotiatedLanguage.languageCode)"])
    }

    for language in supportedLanguages {
        router.get("/\(language.languageCode)") { request, context in
            return HTMLResponse {
                MainLayout(
                    language: language,
                    supportedLanguages: supportedLanguages
                ) {
                    EntryForm()
                }
            }
        }

        router.post("/\(language.languageCode)") { request, context in
            let data = try await request.decode(as: EntryForm.FormData.self, context: context)
            guard let pattern = Pattern(string: data.pattern) else {
                return HTMLResponse {
                    MainLayout(
                        language: language,
                        supportedLanguages: supportedLanguages
                    ) {
                        EntryForm()
                        BadPattern(pattern: data.pattern)
                    }
                }
            }

            let start = ContinuousClock.now
            let resultSet = try language.solver.solve(pattern: pattern, locale: language.locale)
            let end = ContinuousClock.now

            return HTMLResponse {
                MainLayout(
                    language: language,
                    supportedLanguages: supportedLanguages
                ) {
                    EntryForm()
                    WordList(
                        words: Array(resultSet).sorted { (a, b) in
                            switch a.compare(b, options: .caseInsensitive, locale: language.locale)
                            {
                            case .orderedSame:
                                // By default, compare orders attic before Attic
                                // which makes my soul hurt.
                                return a < b
                            case let ordering:
                                return ordering == .orderedAscending
                            }
                        },
                        corpusSize: language.solver.totalWords,
                        duration: end - start
                    )
                }
            }
        }
    }

    return router
}

import Foundation
import Hummingbird
import HummingbirdCompression
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
    let supportedIdentifiers = Set(supportedLanguages.map { $0.identifier })
    let supportedLanguageCodes = Set(supportedLanguages.map { $0.languageCode })

    let languages =
        acceptLanguage
        .components(separatedBy: ",")
        .compactMap { component -> (String, Double)? in
            let parts = component.trimmingCharacters(in: .whitespaces).components(
                separatedBy: ";q=")
            let langTag = parts[0].trimmingCharacters(in: .whitespaces)
            let quality = parts.count > 1 ? Double(parts[1]) ?? 1.0 : 1.0
            return (langTag, quality)
        }
        .sorted { $0.1 > $1.1 }

    // First pass: try exact matches (including region codes)
    for (langTag, _) in languages {
        if supportedIdentifiers.contains(langTag) {
            return supportedLanguages.first { $0.identifier == langTag }!
        }
    }

    // Second pass: try language-only matches (fallback for regions)
    for (langTag, _) in languages {
        let languageCode = langTag.components(separatedBy: "-")[0]
        if supportedLanguageCodes.contains(languageCode) {
            return supportedLanguages.first { $0.languageCode == languageCode }!
        }
    }

    return supportedLanguages[0]  // Use first language as default
}

func buildRouter(supportedLanguages: [SupportedLanguage])
    -> Router<AppRequestContext>
{
    precondition(!supportedLanguages.isEmpty, "Must have at least one supported language")
    let uniqueLanguageIdentifiers = Set(supportedLanguages.map { $0.identifier })
    precondition(
        supportedLanguages.count == uniqueLanguageIdentifiers.count,
        "All supported languages must have unique language codes")

    let router = Router(context: AppRequestContext.self)

    // Add middleware
    router.addMiddleware { LogRequestsMiddleware(.info) }
    router.addMiddleware { SecurityHeadersMiddleware() }
    router.addMiddleware { ResponseCompressionMiddleware(minimumResponseSizeToCompress: 512) }
    router.addMiddleware {
        FileMiddleware(
            fileProvider: StaticFileProvider(bundlePath: Bundle.module.bundleURL.path)
        )
    }

    // Add routes
    router.get("/") { request, context in
        let acceptLanguage = request.headers[.acceptLanguage] ?? ""
        let negotiatedLanguage = negotiateLanguage(
            from: acceptLanguage, supportedLanguages: supportedLanguages)
        return Response(status: .found, headers: [.location: "\(negotiatedLanguage.identifier)"])
    }

    for language in supportedLanguages {
        router.get("/\(language.identifier)") { request, context in
            return HTMLResponse {
                MainLayout(
                    language: language,
                    supportedLanguages: supportedLanguages
                ) {
                    EntryForm()
                    Help()
                }
            }
        }

        router.post("/\(language.identifier)") { request, context in
            let data = try await request.decode(as: EntryForm.FormData.self, context: context)
            guard let pattern = Pattern(string: data.pattern) else {
                return HTMLResponse {
                    MainLayout(
                        language: language,
                        supportedLanguages: supportedLanguages
                    ) {
                        EntryForm()
                        BadPattern(pattern: data.pattern)
                        Help()
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

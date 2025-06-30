import Foundation
import Hummingbird
import HummingbirdElementary
@preconcurrency import Lingo
import Solver

struct AppRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage
    var requestDecoder: URLEncodedFormDecoder { .init() }

    let locale: Locale = .init(identifier: "en_NZ")

    init(source: Source) {
        self.coreContext = .init(source: source)
    }
}

private func negotiateLanguage(from acceptLanguage: String) -> SupportedLanguage {
    let supportedCodes = Set(SupportedLanguage.allCases.map { $0.description })

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
            return SupportedLanguage.allCases.first { $0.description == lang }!
        }
    }

    return SupportedLanguage.default
}

func buildRouter(solvers: @escaping @Sendable (SupportedLanguage) -> Solver, lingo: Lingo)
    -> Router<AppRequestContext>
{
    let router = Router(context: AppRequestContext.self)

    // Add middleware
    router.addMiddleware { LogRequestsMiddleware(.info) }
    router.addMiddleware { SecurityHeadersMiddleware() }

    // Add routes
    router.get("/") { request, context in
        let acceptLanguage = request.headers[.acceptLanguage] ?? ""
        let negotiatedLanguage = negotiateLanguage(from: acceptLanguage)
        return Response(status: .found, headers: [.location: "/\(negotiatedLanguage)"])
    }

    router.get("/:language") { request, context in
        guard let languageCode = context.parameters.get("language"),
            let language = SupportedLanguage.allCases.first(where: {
                $0.description == languageCode
            })
        else {
            throw HTTPError(.notFound)
        }
        let localizer = Localizer(lingo: lingo, locale: context.locale)
        return HTMLResponse {
            MainLayout(localizer: localizer, currentLanguage: language) {
                EntryForm(localizer: localizer)
            }
        }
    }
    router.post("/:language") { request, context in
        guard let languageCode = context.parameters.get("language"),
            let language = SupportedLanguage.allCases.first(where: {
                $0.description == languageCode
            })
        else {
            throw HTTPError(.notFound)
        }
        let solver = solvers(language)
        let localizer = Localizer(lingo: lingo, locale: context.locale)
        let data = try await request.decode(as: EntryForm.FormData.self, context: context)
        guard let pattern = Pattern(string: data.pattern) else {
            return HTMLResponse {
                MainLayout(localizer: localizer, currentLanguage: language) {
                    EntryForm(localizer: localizer)
                    BadPattern(pattern: data.pattern, localizer: localizer)
                }
            }
        }

        let start = ContinuousClock.now
        let resultSet = try solver.solve(pattern: pattern, locale: context.locale)
        let end = ContinuousClock.now

        return HTMLResponse {
            MainLayout(localizer: localizer, currentLanguage: language) {
                EntryForm(localizer: localizer)
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
                    corpusSize: solver.totalWords,
                    duration: end - start,
                    locale: context.locale,
                    localizer: localizer
                )
            }
        }
    }

    return router
}

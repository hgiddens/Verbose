import Hummingbird

struct SecurityHeadersMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(
        _ request: Request, context: Context, next: (Request, Context) async throws -> Response
    ) async throws -> Response {
        var response = try await next(request, context)
        response.headers[.contentSecurityPolicy] = "frame-ancestors 'none'"
        return response
    }
}

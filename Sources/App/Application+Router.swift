import Hummingbird
import HummingbirdElementary

// Request context used by application.
typealias AppRequestContext = BasicRequestContext

func buildRouter() -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)

    // Add middleware
    router.addMiddleware { LogRequestsMiddleware(.info) }

    // Add routes
    router.get("/") { _,_ in HTMLResponse { Page(title: "Hi, mum!") } }

    return router
}

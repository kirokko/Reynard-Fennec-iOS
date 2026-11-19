// GPL-3.0. Tests the real engine module, not a Gecko/UI double.
import UIKit
import WebKit

@main
@MainActor
final class WebKitSmokeApp: UIResponder, UIApplicationDelegate, WebKitSessionDelegate {
    var window: UIWindow?
    var session: WebKitSession!
    var failures: [String] = []
    var passed: [String] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window
        Task {
            do { try await run() } catch { failures.append(String(describing: error)) }
            let result: [String: Any] = ["passed": passed, "failures": failures,
                "scope": "real WKWebView simulator integration; not production browser or SideStore acceptance"]
            let data = try! JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            try! data.write(to: documents.appendingPathComponent("result.json"), options: .atomic)
        }
        return true
    }

    enum Failure: Error { case assertion(String), timeout(String) }
    func check(_ value: @autoclosure () -> Bool, _ label: String) throws {
        guard value() else { throw Failure.assertion(label) }
        passed.append(label)
    }
    func wait(_ label: String, until predicate: () async throws -> Bool) async throws {
        for _ in 0..<200 {
            if try await predicate() { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw Failure.timeout(label)
    }
    func navigate(_ path: String) async throws {
        try session.load(URL(string: "http://127.0.0.1:8765/\(path)")!)
        try await wait("navigation \(path)") { self.session.state.url?.path == "/\(path)" && !self.session.state.isLoading }
    }
    func cookies(_ store: WKWebsiteDataStore) async -> [HTTPCookie] {
        await withCheckedContinuation { c in store.httpCookieStore.getAllCookies { c.resume(returning: $0) } }
    }
    func setCookie(_ cookie: HTTPCookie, store: WKWebsiteDataStore) async {
        await withCheckedContinuation { c in store.httpCookieStore.setCookie(cookie) { c.resume() } }
    }
    func run() async throws {
        let normal = WebKitBrowsingProfile(isPrivate: false)
        let privateProfile = WebKitBrowsingProfile(isPrivate: true)
        let secondPrivate = WebKitBrowsingProfile(isPrivate: true)
        try check(normal.dataStore.isPersistent, "normal uses persistent website store")
        try check(!privateProfile.dataStore.isPersistent, "private uses nonpersistent website store")
        session = try WebKitSession(profile: normal)
        session.delegate = self
        let view = window!.rootViewController!.view!
        session.webView.frame = view.bounds
        view.addSubview(session.webView)
        try check(session.webView.configuration.allowsInlineMediaPlayback, "inline video configured")
        try check(session.webView.configuration.allowsPictureInPictureMediaPlayback, "PiP configured")
        try await navigate("one.html")
        try check(session.state.title == "One", "title observation")
        let js = try await session.webView.evaluateJavaScript("21 * 2") as? Int
        try check(js == 42, "system WebKit JavaScript execution (NOT a JIT proof)")
        try await navigate("two.html")
        try check(session.state.canGoBack, "back availability")
        session.goBack()
        try await wait("back") { self.session.state.title == "One" && !self.session.state.isLoading }
        try check(session.state.canGoForward, "forward availability")
        session.goForward()
        try await wait("forward") { self.session.state.title == "Two" && !self.session.state.isLoading }
        let before = try await session.webView.evaluateJavaScript("performance.timeOrigin") as! Double
        try session.reload()
        try await wait("reload") {
            let after = try await self.session.webView.evaluateJavaScript("performance.timeOrigin") as? Double
            return !self.session.state.isLoading && after != before
        }
        passed.append("reload creates new document")
        let cookie = HTTPCookie(properties: [.domain: "127.0.0.1", .path: "/", .name: "private-only", .value: "secret"])!
        await setCookie(cookie, store: privateProfile.dataStore)
        let own = await cookies(privateProfile.dataStore)
        let regularCookies = await cookies(normal.dataStore)
        let newPrivateCookies = await cookies(secondPrivate.dataStore)
        try check(own.contains { $0.name == "private-only" }, "private cookie roundtrip")
        try check(!regularCookies.contains { $0.name == "private-only" }, "private cookie absent from normal store")
        try check(!newPrivateCookies.contains { $0.name == "private-only" }, "new private profile isolated")
        let samePrivateTab = try WebKitSession(profile: privateProfile)
        try check(samePrivateTab.webView.configuration.websiteDataStore === privateProfile.dataStore, "private tabs can share one ephemeral profile")
        samePrivateTab.close()
        do {
            _ = try WebKitSession(profile: privateProfile, popupConfiguration: normal.configuration())
            throw Failure.assertion("cross-profile popup accepted")
        } catch WebKitSession.SessionError.wrongPopupProfile { passed.append("cross-profile popup rejected") }
        do {
            try session.load(URL(string: "moz-extension://old-extension/options.html")!)
            throw Failure.assertion("Gecko extension URL accepted")
        } catch WebKitSession.SessionError.unsupportedURL { passed.append("unconverted Gecko URL explicitly rejected") }
        // Actual slow response: stop must cancel in-flight work rather than be an empty method.
        try session.load(URL(string: "http://127.0.0.1:8765/slow")!)
        try await wait("loading slow response") { self.session.state.isLoading }
        session.stop()
        try await wait("stop") { !self.session.state.isLoading }
        passed.append("stop cancels in-flight navigation")
        session.close()
        try check(session.isClosed && session.webView.superview == nil, "close detaches and marks closed")
        do {
            try session.load(URL(string: "https://example.com")!)
            throw Failure.assertion("closed session loaded")
        } catch WebKitSession.SessionError.closed { passed.append("closed session rejects load") }
    }
    func sessionDidChange(_ session: WebKitSession) {}
    func session(_ session: WebKitSession, didFail error: Error) { failures.append("navigation: \(error)") }
    func sessionWebProcessDidTerminate(_ session: WebKitSession) { failures.append("web process terminated") }
}

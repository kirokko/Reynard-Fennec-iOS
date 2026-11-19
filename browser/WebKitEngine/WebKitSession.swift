// GPL-3.0. Engine-only migration module; not yet connected to the production UI.
import UIKit
import WebKit

@MainActor
final class WebKitBrowsingProfile {
    let isPrivate: Bool
    let dataStore: WKWebsiteDataStore

    init(isPrivate: Bool) {
        self.isPrivate = isPrivate
        dataStore = isPrivate ? .nonPersistent() : .default()
    }

    func configuration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = dataStore
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        return configuration
    }
}

@MainActor
protocol WebKitSessionDelegate: AnyObject {
    func sessionDidChange(_ session: WebKitSession)
    func session(_ session: WebKitSession, didFail error: Error)
    func sessionWebProcessDidTerminate(_ session: WebKitSession)
}

// This is deliberately not a GeckoSession typealias or a simulated Gecko event
// dispatcher. Unported permission/download/extension APIs must not report success.
@MainActor
final class WebKitSession: NSObject, WKNavigationDelegate, WKUIDelegate {
    struct State {
        let url: URL?
        let title: String
        let progress: Double
        let isLoading: Bool
        let canGoBack: Bool
        let canGoForward: Bool
    }

    enum SessionError: Error { case closed, unsupportedURL, wrongPopupProfile }
    let profile: WebKitBrowsingProfile
    let webView: WKWebView
    weak var delegate: WebKitSessionDelegate?
    // The host must supply its EXISTING tab/popup UI and retain the returned session.
    var openPopup: ((WKWebViewConfiguration, WKNavigationAction) -> WebKitSession?)?
    private var observations: [NSKeyValueObservation] = []
    private(set) var isClosed = false

    var state: State {
        State(url: webView.url, title: webView.title ?? "", progress: webView.estimatedProgress,
              isLoading: webView.isLoading, canGoBack: webView.canGoBack, canGoForward: webView.canGoForward)
    }

    init(profile: WebKitBrowsingProfile, popupConfiguration: WKWebViewConfiguration? = nil) throws {
        if let popupConfiguration, popupConfiguration.websiteDataStore !== profile.dataStore {
            throw SessionError.wrongPopupProfile
        }
        self.profile = profile
        webView = WKWebView(frame: .zero, configuration: popupConfiguration ?? profile.configuration())
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        // Existing chrome owns swipe/refresh presentation. Do not enable Safari's
        // navigation gesture UI in addition to the app's gesture coordinators.
        webView.allowsBackForwardNavigationGestures = false
        observe(\.url)
        observe(\.title)
        observe(\.estimatedProgress)
        observe(\.isLoading)
        observe(\.canGoBack)
        observe(\.canGoForward)
    }

    private func observe<T>(_ keyPath: KeyPath<WKWebView, T>) {
        observations.append(webView.observe(keyPath, options: [.new]) { [weak self] _, _ in
            // WebKit UI/KVO changes are delivered on the UI thread.
            MainActor.assumeIsolated {
                guard let self, !self.isClosed else { return }
                self.delegate?.sessionDidChange(self)
            }
        })
    }

    @discardableResult
    func load(_ url: URL) throws -> WKNavigation? {
        guard !isClosed else { throw SessionError.closed }
        guard Self.permits(url) else { throw SessionError.unsupportedURL }
        return webView.load(URLRequest(url: url))
    }

    func reload(bypassCache: Bool = false) throws {
        guard !isClosed else { throw SessionError.closed }
        if bypassCache { webView.reloadFromOrigin() } else { webView.reload() }
    }
    func stop() { webView.stopLoading() }
    func goBack() { if !isClosed { webView.goBack() } }
    func goForward() { if !isClosed { webView.goForward() } }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        webView.stopLoading()
        observations.removeAll()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.removeFromSuperview()
        delegate = nil
        openPopup = nil
        // Never delete cookies, the Gecko profile or app-owned stores on close.
    }

    private static func permits(_ url: URL) -> Bool {
        // External schemes and local files need explicit host approval. In
        // particular, restored Gecko about:/moz-extension: URLs are not WK URLs.
        ["http", "https"].contains(url.scheme?.lowercased() ?? "") || url.absoluteString == "about:blank"
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(!isClosed && navigationAction.request.url.map(Self.permits) == true ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { delegate?.session(self, didFail: error) }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.webView(webView, didFail: navigation, withError: error)
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // Do not automatically reload POSTs or hide the failure behind success.
        delegate?.sessionWebProcessDidTerminate(self)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard !isClosed, navigationAction.targetFrame == nil,
              let popup = openPopup?(configuration, navigationAction),
              popup.profile === profile, !popup.isClosed else { return nil }
        return popup.webView
    }
}

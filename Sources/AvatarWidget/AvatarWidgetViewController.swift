import UIKit
import WebKit

final class AvatarWidgetViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private static let messageHandlerName = "avatarHost"

    private var webView: WKWebView!
    private var didSendIdentify = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 249 / 255, green: 250 / 255, blue: 251 / 255, alpha: 1)

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.userContentController.add(self, name: Self.messageHandlerName)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // Chat layout scrolls inside the page; panning the WebView itself
        // pushes header/composer off-screen when the keyboard opens.
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        loadPanel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView.hideFormInputAccessory()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.hideFormInputAccessory()
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.messageHandlerName)
    }

    @objc private func closeTapped() {
        AvatarWidget.presented = nil
        dismiss(animated: true)
    }

    private func loadPanel() {
        guard let url = Self.panelURL() else { return }
        webView.load(URLRequest(url: url))
    }

    private static func panelURL() -> URL? {
        guard var components = URLComponents(string: AvatarWidget.panelOrigin) else { return nil }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "surface", value: "webview"))
        items.append(URLQueryItem(name: "pk", value: AvatarWidget.publishableKey))
        if let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty {
            items.append(URLQueryItem(name: "bundle", value: bundleId))
        }
        components.queryItems = items
        return components.url
    }

    func allowIdentifyResend() {
        didSendIdentify = false
    }

    func sendIdentifyIfNeeded() {
        guard let identity = AvatarWidget.identity, !didSendIdentify else { return }
        postToPanel(event: "WIDGET_IDENTIFY", payload: [
            "userId": identity.userId,
            "hmac": identity.hmac,
        ])
        didSendIdentify = true
    }

    private func postToPanel(event: String, payload: [String: Any]) {
        let envelope: [String: Any] = [
            "source": "avatar_host_script",
            "event": event,
            "payload": payload.merging(["timestamp": Int(Date().timeIntervalSince1970 * 1000)]) { _, new in new },
        ]
        guard
            let data = try? JSONSerialization.data(withJSONObject: envelope, options: []),
            let json = String(data: data, encoding: .utf8)
        else { return }
        webView.evaluateJavaScript("window.postMessage(\(json), window.location.origin);", completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let object: Any?
        if let string = message.body as? String, let data = string.data(using: .utf8) {
            object = try? JSONSerialization.jsonObject(with: data)
        } else {
            object = message.body
        }
        guard
            let dict = object as? [String: Any],
            dict["source"] as? String == "avatar_core_iframe",
            let event = dict["event"] as? String
        else { return }

        let payload = dict["payload"] as? [String: Any] ?? [:]
        if event == "WIDGET_READY" {
            sendIdentifyIfNeeded()
        }
        if event == "WIDGET_CLOSE" {
            DispatchQueue.main.async { [weak self] in
                self?.closeTapped()
            }
        }
        AvatarWidget.events.dispatch(event: event, payload: payload)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if url.scheme == "about" {
            decisionHandler(.allow)
            return
        }
        if isPanelHost(url) {
            decisionHandler(.allow)
            return
        }
        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    private func isPanelHost(_ url: URL) -> Bool {
        guard let panel = URL(string: AvatarWidget.panelOrigin) else { return false }
        return url.host == panel.host && url.scheme == panel.scheme
    }
}

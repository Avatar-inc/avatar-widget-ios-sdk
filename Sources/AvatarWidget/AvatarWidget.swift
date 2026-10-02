import UIKit

/// Thin iOS helper SDK — presents the shared chat panel in a `WKWebView`.
/// Proposal §5.4 / Appendix B: `configure`, `identify`, `present`, `shutdown`, `events`.
///
/// Customers always load the platform-hosted panel (non-goal: white-labelled /
/// self-hosted panel origin). The host URL is baked into the SDK artifact at build time
/// via `PanelHost.origin` — customers never pass a URL.
public enum AvatarWidget {
    public static let events = AvatarWidgetEvents()

    /// Platform-hosted panel origin for this SDK artifact (no trailing slash).
    /// UAT artifact → `widget-uat.myegdev2.com`; production artifact → `widget.avatar.inc`.
    public static var panelOrigin: String { debugPanelOrigin ?? PanelHost.origin }

    /// Dev/sample override — **not part of the customer API**.
    /// Set to a local Vite origin (e.g. `http://localhost:5173`) for local dev;
    /// `nil` restores the baked-in `PanelHost.origin`.
    public static var debugPanelOrigin: String? = nil

    static var publishableKey: String = ""
    static var identity: (userId: String, hmac: String)?
    static weak var presented: AvatarWidgetViewController?

    /// Call once at app launch (proposal Appendix B).
    public static func configure(publishableKey: String) {
        self.publishableKey = publishableKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Beta — stores the HMAC identity payload and forwards it to the panel when presented.
    /// Re-sends only when `userId` or `hmac` differs from the last stored token (HMAC refresh).
    public static func identify(userId: String, hmac: String) {
        let changed = identity.map { $0.userId != userId || $0.hmac != hmac } ?? true
        identity = (userId, hmac)
        if changed {
            presented?.allowIdentifyResend()
        }
        presented?.sendIdentifyIfNeeded()
    }

    public static func present(from viewController: UIViewController) {
        precondition(
            !publishableKey.isEmpty,
            "AvatarWidget.configure(publishableKey:) must be called first",
        )

        if presented != nil { return }

        let chat = AvatarWidgetViewController()
        chat.modalPresentationStyle = .fullScreen
        presented = chat
        viewController.present(chat, animated: true)
    }

    public static func shutdown() {
        identity = nil
        guard let presented else { return }
        presented.dismiss(animated: true)
        self.presented = nil
    }
}

public extension UIApplication {
    /// Topmost presented view controller — for SwiftUI hosts that need a
    /// `UIViewController` to pass to ``AvatarWidget/present(from:)``
    /// (proposal Appendix B: `UIApplication.shared.topController`).
    var topController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.flatMap(\.windows).first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}

import Foundation

public final class AvatarWidgetEvents {
    public var onReady: (() -> Void)?
    public var onConversationStarted: ((_ payload: [String: Any]) -> Void)?
    public var onMessageReceived: ((_ payload: [String: Any]) -> Void)?
    public var onUnreadChanged: ((_ count: Int) -> Void)?
    public var onError: ((_ reason: String) -> Void)?

    public init() {}

    func dispatch(event: String, payload: [String: Any]) {
        DispatchQueue.main.async {
            switch event {
            case "WIDGET_READY":
                self.onReady?()
            case "CONVERSATION_STARTED":
                self.onConversationStarted?(payload)
            case "MESSAGE_RECEIVED":
                self.onMessageReceived?(payload)
            case "UNREAD_CHANGED":
                let count = payload["unreadCount"] as? Int
                    ?? (payload["unreadCount"] as? NSNumber)?.intValue
                    ?? 0
                self.onUnreadChanged?(count)
            case "API_STREAM_ERROR":
                let reason = payload["reason"] as? String ?? "Unknown error"
                self.onError?(reason)
            default:
                break
            }
        }
    }
}

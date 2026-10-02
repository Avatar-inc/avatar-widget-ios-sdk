import ObjectiveC
import UIKit
import WebKit

extension WKWebView {
    /// Hide the < > Done bar that WKWebView inserts above the software keyboard.
    /// That accessory steals a large slice of the remaining viewport in chat.
    func hideFormInputAccessory() {
        guard let contentView = scrollView.subviews.first(where: {
            String(describing: type(of: $0)).hasPrefix("WKContent")
        }) else { return }

        let subclassName = "AvatarWKNoInputAccessoryView"
        if let existing = NSClassFromString(subclassName) {
            object_setClass(contentView, existing)
            return
        }

        guard
            let original = object_getClass(contentView),
            let subclass = objc_allocateClassPair(original, subclassName, 0)
        else { return }

        let selector = sel_registerName("inputAccessoryView")
        let impl: @convention(block) (AnyObject) -> UIView? = { _ in nil }
        class_addMethod(subclass, selector, imp_implementationWithBlock(impl), "@@:")
        objc_registerClassPair(subclass)
        object_setClass(contentView, subclass)
    }
}

// Real UITextField marked-text lifecycle and pure capture policy. This does not
// automate a Chinese system keyboard, capture a real recording or exercise Gecko.
import UIKit

func checkInputAndPrivacy() {
    for sensitive in [false, true] {
        for inactive in [false, true] {
            for captured in [false, true] {
                precondition(FennecPrivacyShield.shouldCover(isSensitive: sensitive, isInactive: inactive, isCaptured: captured)
                             == (sensitive && (inactive || captured)))
            }
        }
    }
    let host = UIViewController()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    window.rootViewController = host
    window.makeKeyAndVisible()
    let field = AddressBarTextField(frame: CGRect(x: 12, y: 60, width: 340, height: 44))
    host.view.addSubview(field)
    field.becomeFirstResponder()
    var calls = 0
    field.onWillSetMarkedText = {
        calls += 1
        field.isAutocompleteActive = false
        field.textColor = .label
        field.tintColor = .systemPurple
    }
    // Model the transparent completion overlay at the start of an IME run.
    field.textColor = .clear
    field.isAutocompleteActive = true
    field.setMarkedText("c", selectedRange: NSRange(location: 1, length: 0))
    precondition(calls == 1 && field.text == "c")
    precondition(field.markedTextRange != nil)
    field.setMarkedText("cn", selectedRange: NSRange(location: 2, length: 0))
    precondition(calls == 2 && field.text == "cn")
    precondition(field.textColor == .label && !field.isAutocompleteActive)
    field.unmarkText()
    precondition(field.text == "cn" && field.markedTextRange == nil)
    field.resignFirstResponder()
    window.isHidden = true
}

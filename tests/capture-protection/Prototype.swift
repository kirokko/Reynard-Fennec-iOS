// GPL-3.0. ISOLATED EXPERIMENT ONLY: not linked into the browser.
// UITextField documents protection for its own secure text, NOT arbitrary child
// views. Hosting content under its implementation canvas is unsupported behavior.
// A successful Simulator experiment cannot establish actual-device protection.
import UIKit

final class SecureCanvasPrototype: UIView {
    private final class Carrier: UITextField {
        weak var hostedContent: UIView?
        override var canBecomeFirstResponder: Bool { false }
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            guard let content = hostedContent else { return nil }
            return content.hitTest(content.convert(point, from: self), with: event)
        }
    }
    private let carrier = Carrier()
    let content = UIView()
    private var contentConstraints: [NSLayoutConstraint] = []
    private(set) var discoveredCanvasName = "none"
    private(set) var canvasFound = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        carrier.frame = bounds
        carrier.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        carrier.borderStyle = .none
        carrier.backgroundColor = .clear
        carrier.textColor = .clear
        carrier.tintColor = .clear
        carrier.text = " "
        addSubview(carrier)
        carrier.hostedContent = content
        content.translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError() }

    @discardableResult
    func setProtected(_ value: Bool) -> Bool {
        // Never move/reassign CALayers, call private selectors, change engine
        // surfaces, or suppress capture notifications to fake a successful test.
        carrier.isSecureTextEntry = value
        carrier.setNeedsLayout()
        carrier.layoutIfNeeded()
        func candidates(_ view: UIView) -> [UIView] {
            view.subviews.flatMap { [$0] + candidates($0) }
        }
        guard let canvas = candidates(carrier).first(where: {
            let name = NSStringFromClass(type(of: $0))
            return name.hasSuffix("UITextLayoutCanvasView") || name.hasSuffix("UITextFieldCanvasView")
        }) else {
            canvasFound = false
            discoveredCanvasName = carrier.subviews.map { NSStringFromClass(type(of: $0)) }.joined(separator: ",")
            return false
        }
        canvasFound = true
        discoveredCanvasName = NSStringFromClass(type(of: canvas))
        canvas.isUserInteractionEnabled = true
        if content.superview !== canvas {
            NSLayoutConstraint.deactivate(contentConstraints)
            canvas.addSubview(content)
            contentConstraints = [
                content.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
                content.topAnchor.constraint(equalTo: canvas.topAnchor),
                content.bottomAnchor.constraint(equalTo: canvas.bottomAnchor),
            ]
            NSLayoutConstraint.activate(contentConstraints)
        }
        layoutIfNeeded()
        return true
    }
}

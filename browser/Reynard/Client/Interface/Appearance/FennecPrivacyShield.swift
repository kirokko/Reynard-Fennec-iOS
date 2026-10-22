// GPL-3.0. Public-API capture/background protection, NOT screenshot prevention.
import UIKit

/// iOS exposes recording/mirroring state, but no Android FLAG_SECURE equivalent
/// for arbitrary UIKit/Gecko screenshots. A screenshot notification is too late.
/// While captured we deliberately cover the local private UI too (fail closed).
final class FennecPrivacyShield {
    private var cover: UIWindow?
    private var observers: [NSObjectProtocol] = []
    private weak var scene: UIWindowScene?
    var isSensitive: () -> Bool = { false }
    private var isInactive = false

    static func shouldCover(isSensitive: Bool, isInactive: Bool, isCaptured: Bool) -> Bool {
        isSensitive && (isInactive || isCaptured)
    }

    func attach(to scene: UIWindowScene) {
        guard self.scene !== scene else { update(); return }
        self.scene = scene
        isInactive = scene.activationState != .foregroundActive
        if observers.isEmpty {
            let center = NotificationCenter.default
            observers.append(center.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { [weak self] _ in self?.update() })
            observers.append(center.addObserver(forName: UIScene.willDeactivateNotification, object: scene, queue: .main) { [weak self] _ in
                self?.isInactive = true
                self?.update()
            })
            observers.append(center.addObserver(forName: UIScene.didActivateNotification, object: scene, queue: .main) { [weak self] _ in
                self?.isInactive = false
                self?.update()
            })
        }
        update()
    }

    func update() {
        guard let scene else { return }
        let hidden = Self.shouldCover(isSensitive: isSensitive(), isInactive: isInactive, isCaptured: scene.screen.isCaptured)
        guard hidden else {
            cover?.isHidden = true
            return
        }
        if cover == nil {
            let window = UIWindow(windowScene: scene)
            // Cover presented controllers too, without replacing the key window
            // or reparenting Gecko/text fields into undocumented secure layers.
            window.windowLevel = .alert + 1
            let controller = UIViewController()
            controller.view.backgroundColor = .black
            controller.view.accessibilityLabel = FennecTheme.text("Private content hidden")
            window.rootViewController = controller
            cover = window
        }
        UIView.performWithoutAnimation { cover?.isHidden = false }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        cover?.isHidden = true
    }
}

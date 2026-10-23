// GPL-3.0. Private-tab access lock, NOT screenshot/recording protection.
import UIKit
import LocalAuthentication

/// Authentication is process-memory-only: a fresh launch always locks private UI.
/// This is an access gate, not encryption or a change to tab persistence.
final class FennecPrivacyShield {
    private static var access = FennecPrivateAccessState()
    private static let didUnlock = Notification.Name("FennecPrivateTabsDidUnlock")
    private var cover: UIWindow?
    private weak var previousKeyWindow: UIWindow?
    private var observers: [NSObjectProtocol] = []
    private weak var scene: UIWindowScene?
    private var context: LAContext?
    private var isInactive = false
    var isSensitive: () -> Bool = { false }
    var onReturnToRegular: (() -> Void)?
    var blocksPrivateAccess: Bool { Self.access.needsAuthentication(isSensitive: isSensitive()) }

    static func shouldCover(isSensitive: Bool, isInactive: Bool, isCaptured: Bool) -> Bool {
        // Recording never changes the local presentation.
        isSensitive && isInactive
    }

    func attach(to scene: UIWindowScene) {
        guard self.scene !== scene else { update(); return }
        self.scene = scene
        isInactive = scene.activationState != .foregroundActive
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
        observers = [
            center.addObserver(forName: UIScene.willDeactivateNotification, object: scene, queue: .main) { [weak self] _ in
                self?.isInactive = true
                self?.update()
            },
            center.addObserver(forName: UIScene.didActivateNotification, object: scene, queue: .main) { [weak self] _ in
                self?.isInactive = false
                self?.update()
            },
            center.addObserver(forName: Self.didUnlock, object: nil, queue: .main) { [weak self] _ in self?.update() }
        ]
        update()
    }

    func update() {
        guard let scene else { return }
        let sensitive = isSensitive()
        let locked = Self.access.needsAuthentication(isSensitive: sensitive)
        let hidden = Self.shouldCover(isSensitive: sensitive, isInactive: isInactive, isCaptured: false)
        guard locked || hidden else {
            let wasKey = cover?.isKeyWindow == true
            cover?.isHidden = true
            if wasKey { previousKeyWindow?.makeKey() }
            return
        }
        if cover == nil {
            let window = UIWindow(windowScene: scene)
            window.windowLevel = .alert + 1
            let controller = FennecPrivateLockViewController()
            controller.onUnlock = { [weak self] in self?.authenticate() }
            controller.onRegular = { [weak self] in self?.onReturnToRegular?() }
            window.rootViewController = controller
            cover = window
        }
        (cover?.rootViewController as? FennecPrivateLockViewController)?.setLocked(locked)
        UIView.performWithoutAnimation {
            cover?.isHidden = false
            if locked && !isInactive && cover?.isKeyWindow != true {
                previousKeyWindow = scene.windows.first(where: { $0.isKeyWindow && $0 !== cover })
                previousKeyWindow?.endEditing(true)
                cover?.makeKey()
            }
        }
    }

    private func authenticate() {
        guard context == nil, !isInactive, Self.access.needsAuthentication(isSensitive: isSensitive()) else { return }
        let candidate = LAContext()
        var error: NSError?
        // System Face ID / Touch ID, with the system device-passcode fallback.
        // Never accept an app-stored PIN or mark cancellation/failure as success.
        guard candidate.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            showFailure()
            return
        }
        context = candidate
        candidate.evaluatePolicy(.deviceOwnerAuthentication,
            localizedReason: FennecTheme.text("Unlock your private tabs")) { [weak self] success, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.context = nil
                Self.access.authenticationFinished(success: success)
                if success {
                    NotificationCenter.default.post(name: Self.didUnlock, object: nil)
                } else {
                    self.showFailure()
                }
            }
        }
    }

    private func showFailure() {
        (cover?.rootViewController as? FennecPrivateLockViewController)?.showFailure()
    }

    deinit {
        context?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        cover?.isHidden = true
    }
}

final class FennecPrivateLockViewController: UIViewController {
    var onUnlock: (() -> Void)?
    var onRegular: (() -> Void)?
    private let stack = UIStackView()
    private let message = UILabel()
    private var locked = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FennecTheme.privateSurface
        view.accessibilityViewIsModal = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 20
        let title = UILabel()
        title.text = FennecTheme.text("Private tabs locked")
        title.font = .preferredFont(forTextStyle: .title2)
        for label in [title, message] {
            label.textColor = .white
            label.numberOfLines = 0
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            stack.addArrangedSubview(label)
        }
        message.font = .preferredFont(forTextStyle: .body)
        message.text = FennecTheme.text("Unlock your private tabs")
        for (text, selector) in [("Unlock private tabs", #selector(unlock)), ("Return to normal browsing", #selector(regular))] {
            let button = UIButton(type: .system)
            button.setTitle(FennecTheme.text(text), for: .normal)
            button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.tintColor = .white
            button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            button.layer.cornerRadius = 12
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            button.addTarget(self, action: selector, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
        ])
        let width = stack.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -48)
        width.priority = .defaultHigh
        width.isActive = true
        stack.isHidden = !locked
    }

    func setLocked(_ value: Bool) {
        locked = value
        if isViewLoaded { stack.isHidden = !value }
    }
    func showFailure() {
        loadViewIfNeeded()
        message.text = FennecTheme.text("Private tabs remain locked. Try again or return to normal browsing.")
        UIAccessibility.post(notification: .announcement, argument: message.text)
    }
    @objc private func unlock() { onUnlock?() }
    @objc private func regular() { onRegular?() }
}

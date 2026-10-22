// App-owned full-screen orientation: portrait first, sensor landscape on demand.
// No changes to the user's system orientation lock. GPL-3.0.
import UIKit
import CoreMotion

struct FennecFullscreenRotationState {
    enum Mode { case inactive, portrait, landscape }
    private(set) var mode: Mode = .inactive
    private(set) var orientation: UIInterfaceOrientation = .portrait
    private var lastLandscape: UIInterfaceOrientation = .landscapeRight
    private var candidate: UIInterfaceOrientation?
    private var candidateSamples = 0

    var mask: UIInterfaceOrientationMask {
        switch orientation {
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .portrait
        }
    }
    mutating func enter() {
        mode = .portrait
        orientation = .portrait
        lastLandscape = .landscapeRight
        candidate = nil
        candidateSamples = 0
    }
    mutating func exit() {
        mode = .inactive
        orientation = .portrait
        candidate = nil
        candidateSamples = 0
    }
    mutating func toggle() {
        guard mode != .inactive else { return }
        mode = mode == .portrait ? .landscape : .portrait
        orientation = mode == .portrait ? .portrait : lastLandscape
    }
    // Gravity still works when interface autorotation is locked. Device and
    // interface landscape names are opposite; require stable samples/deadzone.
    mutating func updateGravity(x: Double, y: Double) -> Bool {
        guard mode != .inactive, x.isFinite, y.isFinite,
              abs(x) > 0.65, abs(x) > abs(y) + 0.15 else {
            candidate = nil
            candidateSamples = 0
            return false
        }
        let side: UIInterfaceOrientation = x > 0 ? .landscapeLeft : .landscapeRight
        if candidate == side { candidateSamples += 1 } else { candidate = side; candidateSamples = 1 }
        guard candidateSamples >= 2 else { return false }
        lastLandscape = side
        guard mode == .landscape, orientation != side else { return false }
        orientation = side
        return true
    }
}

final class FennecFullscreenRotationController: NSObject {
    private(set) var state = FennecFullscreenRotationState()
    var onRequestOrientation: ((UIInterfaceOrientation) -> Void)?
    let button = UIButton(type: .custom)
    private let errorLabel = UILabel()
    private let motion = CMMotionManager()

    override init() {
        super.init()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.black.withAlphaComponent(0.65)
        button.tintColor = .white
        button.layer.cornerRadius = 22
        button.setImage(UIImage(systemName: "rotate.right"), for: .normal)
        button.accessibilityIdentifier = "fullscreen.rotate"
        button.isHidden = true
        button.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.text = FennecTheme.text("Unable to rotate video")
        errorLabel.textColor = .white
        errorLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        errorLabel.font = .preferredFont(forTextStyle: .caption1)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resume), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    deinit {
        motion.stopAccelerometerUpdates()
        NotificationCenter.default.removeObserver(self)
    }
    func install(in view: UIView) {
        guard button.superview == nil else { return }
        view.addSubview(button)
        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -8),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            errorLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 260),
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -56),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    func enter() {
        state.enter()
        errorLabel.isHidden = true
        button.isHidden = false
        button.superview?.bringSubviewToFront(button)
        updateButton()
        onRequestOrientation?(.portrait)
        resume()
    }
    func exit() {
        pause()
        state.exit()
        button.isHidden = true
        errorLabel.isHidden = true
    }
    func showRotationFailure() {
        guard state.mode != .inactive else { return }
        errorLabel.isHidden = false
        errorLabel.superview?.bringSubviewToFront(errorLabel)
        UIAccessibility.post(notification: .announcement, argument: errorLabel.text)
    }
    @objc private func toggle() {
        guard state.mode != .inactive else { return }
        errorLabel.isHidden = true
        state.toggle()
        updateButton()
        onRequestOrientation?(state.orientation)
    }
    private func updateButton() {
        button.accessibilityLabel = FennecTheme.text(state.mode == .landscape ? "Return to portrait" : "Rotate video")
        button.accessibilityValue = FennecTheme.text(state.mode == .landscape ? "Landscape follows device" : "Portrait")
    }
    @objc private func pause() { motion.stopAccelerometerUpdates() }
    @objc private func resume() {
        guard state.mode != .inactive, motion.isAccelerometerAvailable, !motion.isAccelerometerActive else { return }
        motion.accelerometerUpdateInterval = 0.25
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let acceleration = data?.acceleration else { return }
            if self.state.updateGravity(x: acceleration.x, y: acceleration.y) {
                self.onRequestOrientation?(self.state.orientation)
            }
        }
    }
}

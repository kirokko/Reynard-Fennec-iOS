// GPL-3.0. Device-only diagnostic screen: no browser data is hosted here.
import UIKit

final class FennecCaptureProbeViewController: UIViewController {
    private let host = FennecSecureCanvasExperiment()
    private let modes = UISegmentedControl(items: ["0", "1", "2"])
    private let status = UILabel()
    private var taps = 0
    private var lastMode = -1
    private let button = FennecClosureButton(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = FennecTheme.text("Capture protection experiment")
        view.backgroundColor = FennecTheme.surface
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let explanation = UILabel()
        explanation.text = FennecTheme.text("Synthetic test only. 0: normal; 1: secure canvas; 2: experimental layer flag. Keep using the red area, take a screenshot and record the screen. Protection is demonstrated only if the red area stays visible on the phone but disappears from the captures. This does not protect browser tabs.")
        explanation.numberOfLines = 0
        explanation.font = .preferredFont(forTextStyle: .subheadline)
        explanation.textColor = FennecTheme.ink
        status.numberOfLines = 0
        status.font = .preferredFont(forTextStyle: .caption1)
        status.textColor = FennecTheme.ink
        modes.selectedSegmentIndex = 0
        modes.addTarget(self, action: #selector(changeMode), for: .valueChanged)
        for child in [explanation, modes, status, host] { stack.addArrangedSubview(child) }
        host.heightAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.removeFromSuperview()
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
        ])
        host.content.backgroundColor = .red
        button.setTitle(FennecTheme.text("Tap to test interaction"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.onTap = { [weak self] in
            guard let self else { return }
            self.taps += 1
            self.button.setTitle("\(FennecTheme.text("Tap to test interaction")): \(self.taps)", for: .normal)
        }
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.content.addSubview(button)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyMode()
        button.frame = host.content.bounds
    }
    @objc private func changeMode() { applyMode(); view.setNeedsLayout() }
    private func applyMode() {
        guard lastMode != modes.selectedSegmentIndex || !host.canvasFound else { return }
        lastMode = modes.selectedSegmentIndex
        let secure = host.setProtected(modes.selectedSegmentIndex == 1)
        let flag = host.setExperimentalLayerFlag(modes.selectedSegmentIndex == 2)
        status.text = "\(FennecTheme.text("Not verified on this device"))\ncanvas=\(secure), layer setter=\(flag), mode=\(modes.selectedSegmentIndex)"
    }
}

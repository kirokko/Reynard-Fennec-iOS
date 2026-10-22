// Fennec private homepage: dark surface, mask badge and concise explanation.
// GPL-3.0. No normal homepage wordmark, donation panel or blur compositor.
import UIKit

final class PrivateBrowsingSectionViewController: UIViewController {
    private let stack = UIStackView()
    private var isPrivateBrowsing = false
    private var contentMode: HomepageContentMode = .embeddedNarrow

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.accessibilityIdentifier = "homepage.private"
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        view.addSubview(stack)

        let badge = UIView()
        badge.backgroundColor = FennecTheme.accentContainer
        badge.layer.cornerRadius = 28
        let icon = UIImageView(image: FennecTheme.privateBrowsingImage)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = FennecTheme.selectedOutline
        icon.contentMode = .scaleAspectFit
        badge.addSubview(icon)
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 56),
            badge.heightAnchor.constraint(equalToConstant: 56),
            icon.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 32),
            icon.heightAnchor.constraint(equalToConstant: 32),
        ])
        stack.addArrangedSubview(badge)
        let heading = UILabel()
        heading.text = FennecTheme.text("Leave no traces on this device")
        heading.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        heading.textColor = FennecTheme.ink
        let message = UILabel()
        message.text = FennecTheme.text("ieynec clears private browsing history and cookies when you close private tabs. Downloads and bookmarks are kept.")
        message.font = .preferredFont(forTextStyle: .subheadline)
        message.textColor = .secondaryLabel
        for label in [heading, message] {
            label.numberOfLines = 0
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            stack.addArrangedSubview(label)
            label.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -28),
        ])
        let preferredWidth = stack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
        view.isHidden = !isPrivateBrowsing
    }

    func setContentMode(_ mode: HomepageContentMode) { contentMode = mode }
    func setPrivateBrowsing(_ value: Bool) {
        isPrivateBrowsing = value
        if isViewLoaded { view.isHidden = !value }
    }
}

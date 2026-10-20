// Unofficial Fennec-inspired presentation for Reynard. GPL-3.0.
import UIKit

enum FennecTheme {
    static let surface = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.08, green: 0.075, blue: 0.11, alpha: 1)
        : UIColor(red: 0.975, green: 0.975, blue: 0.99, alpha: 1) }
    static let container = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.18, green: 0.17, blue: 0.22, alpha: 1)
        : UIColor(red: 0.885, green: 0.88, blue: 0.915, alpha: 1) }
    static let accent = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.81, green: 0.76, blue: 1, alpha: 1)
        : UIColor(red: 0.19, green: 0.15, blue: 0.38, alpha: 1) }
    static let accentContainer = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.27, green: 0.23, blue: 0.40, alpha: 1)
        : UIColor(red: 0.90, green: 0.86, blue: 1, alpha: 1) }

    static var overflowImage: UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { _ in
            UIColor.black.setFill()
            for y in [5.0, 12.0, 19.0] {
                UIBezierPath(ovalIn: CGRect(x: 10.5, y: y - 1.5, width: 3, height: 3)).fill()
            }
        }.withRenderingMode(.alwaysTemplate)
    }

    static func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: "FennecLocalizable", comment: "")
    }
}

/// Shared 44pt targets, used in both top and bottom single-row browser bars.
final class FennecToolbarControls: UIStackView {
    var onNewTab: (() -> Void)?
    var onTabs: (() -> Void)?
    var onMenu: (() -> Void)?
    lazy var newTabButton = ToolbarButton(buttonType: .newTab, target: self, action: #selector(newTab))
    lazy var tabButton = ToolbarButton(buttonType: .tabOverview, target: self, action: #selector(tabs))
    lazy var menuButton = ToolbarButton(buttonType: .library, target: self, action: #selector(menu))
    private let countLabel = UILabel()
    private let downloadProgress = UIProgressView(progressViewStyle: .bar)

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        distribution = .fillEqually
        for button in [newTabButton, tabButton, menuButton] { addArrangedSubview(button) }
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 132),
            heightAnchor.constraint(equalToConstant: 44),
        ])
        newTabButton.accessibilityLabel = FennecTheme.text("New tab")
        menuButton.accessibilityLabel = FennecTheme.text("Menu")
        menuButton.setImage(FennecTheme.overflowImage, for: .normal)
        tabButton.setImage(nil, for: .normal)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        countLabel.textAlignment = .center
        countLabel.layer.borderWidth = 1.8
        countLabel.layer.cornerRadius = 3
        countLabel.isUserInteractionEnabled = false
        countLabel.isAccessibilityElement = false
        tabButton.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: tabButton.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: tabButton.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 22),
            countLabel.heightAnchor.constraint(equalToConstant: 22),
        ])
        downloadProgress.translatesAutoresizingMaskIntoConstraints = false
        downloadProgress.progressTintColor = FennecTheme.accent
        downloadProgress.isHidden = true
        downloadProgress.isUserInteractionEnabled = false
        downloadProgress.isAccessibilityElement = false
        menuButton.addSubview(downloadProgress)
        NSLayoutConstraint.activate([
            downloadProgress.centerXAnchor.constraint(equalTo: menuButton.centerXAnchor),
            downloadProgress.centerYAnchor.constraint(equalTo: menuButton.centerYAnchor, constant: 17),
            downloadProgress.widthAnchor.constraint(equalToConstant: 24),
        ])
        setTabCount(0)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        countLabel.layer.borderColor = UIColor.label.resolvedColor(with: traitCollection).cgColor
    }

    func setTabCount(_ count: Int) {
        countLabel.text = count > 99 ? "∞" : String(max(0, count))
        countLabel.layer.borderColor = UIColor.label.resolvedColor(with: traitCollection).cgColor
        tabButton.accessibilityLabel = FennecTheme.text("Tabs")
        tabButton.accessibilityValue = String(count)
    }

    func updateDownload(_ summary: DownloadStoreSummary) {
        downloadProgress.progress = min(1, max(0, Float(summary.aggregateProgress)))
        downloadProgress.isHidden = summary.activeCount == 0
        menuButton.accessibilityHint = summary.activeCount > 0 ? FennecTheme.text("Active downloads") : nil
    }

    @objc private func newTab() { onNewTab?() }
    @objc private func tabs() { onTabs?() }
    @objc private func menu() { onMenu?() }
}

// GPL-3.0. Anchored Android-style provider popup, not a bottom sheet.
import UIKit

struct FennecSearchPopupItem {
    let title: String
    let image: UIImage?
    let action: () -> Void
}

final class FennecSearchPopup: UIViewController {
    private weak var sourceView: UIView?
    private let groups: [[FennecSearchPopupItem]]
    private let panel = UIView()
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private var rows = 0

    init(sourceView: UIView, groups: [[FennecSearchPopupItem]]) {
        self.sourceView = sourceView
        self.groups = groups
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) { fatalError() }

    // Kept pure so five viewport widths, both toolbar positions and clipping
    // near the keyboard/system safe area can be tested without a browser.
    static func panelFrame(bounds: CGRect, safe: UIEdgeInsets, anchor: CGRect, contentHeight: CGFloat) -> CGRect {
        let available = bounds.inset(by: UIEdgeInsets(top: safe.top + 8, left: safe.left + 8,
                                                     bottom: safe.bottom + 8, right: safe.right + 8))
        let width = min(available.width, min(280, max(220, bounds.width * 0.58)))
        let height = min(available.height, contentHeight)
        let x = min(max(anchor.minX - 8, available.minX), available.maxX - width)
        let prefersAbove = anchor.midY > bounds.midY
        let y = prefersAbove ? anchor.maxY - height : anchor.minY
        return CGRect(x: x, y: min(max(y, available.minY), available.maxY - height), width: width, height: height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let outside = FennecClosureButton(frame: view.bounds)
        outside.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        outside.accessibilityLabel = FennecTheme.text("Close menu")
        outside.onTap = { [weak self] in self?.dismiss(animated: false) }
        view.addSubview(outside)
        panel.backgroundColor = FennecTheme.card
        panel.layer.cornerRadius = 6
        panel.layer.shadowColor = UIColor.black.cgColor
        panel.layer.shadowOpacity = 0.25
        panel.layer.shadowRadius = 8
        panel.layer.shadowOffset = CGSize(width: 0, height: 3)
        panel.accessibilityViewIsModal = true
        panel.accessibilityIdentifier = "search.providerPopup"
        view.addSubview(panel)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.layer.cornerRadius = 6
        scroll.clipsToBounds = true
        scroll.contentInsetAdjustmentBehavior = .never
        panel.addSubview(scroll)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: panel.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])
        let header = UILabel()
        header.text = FennecTheme.text("This time search in")
        header.font = .preferredFont(forTextStyle: .body)
        header.textColor = FennecTheme.ink
        header.numberOfLines = 0
        let heading = UIView()
        heading.translatesAutoresizingMaskIntoConstraints = false
        header.translatesAutoresizingMaskIntoConstraints = false
        heading.addSubview(header)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: heading.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: heading.trailingAnchor, constant: -12),
            header.topAnchor.constraint(equalTo: heading.topAnchor, constant: 12),
            header.bottomAnchor.constraint(equalTo: heading.bottomAnchor, constant: -12),
            heading.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
        ])
        stack.addArrangedSubview(heading)
        for (groupIndex, group) in groups.enumerated() {
            if groupIndex > 0 {
                let divider = UIView()
                divider.backgroundColor = .separator
                divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
                stack.addArrangedSubview(divider)
            }
            for item in group { stack.addArrangedSubview(row(item)); rows += 1 }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let anchor = sourceView.map { $0.convert($0.bounds, to: view) }
            ?? CGRect(x: 16, y: view.bounds.maxY - view.safeAreaInsets.bottom - 44, width: 44, height: 44)
        let estimate = CGFloat(rows) * 48 + 52 + CGFloat(max(0, groups.count - 1))
        let initial = Self.panelFrame(bounds: view.bounds, safe: view.safeAreaInsets, anchor: anchor, contentHeight: estimate)
        // Establish the measurement width only when it changes. Resetting the
        // estimated height on EVERY pass oscillates estimate -> wrapped height
        // forever on narrow phones (e.g. DuckDuckGo (HTML) spans two lines).
        if panel.bounds.width != initial.width || panel.bounds.height == 0 {
            panel.frame = initial
            panel.layoutIfNeeded()
        }
        let measured = stack.systemLayoutSizeFitting(CGSize(width: initial.width, height: 0),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        let target = Self.panelFrame(bounds: view.bounds, safe: view.safeAreaInsets, anchor: anchor, contentHeight: max(estimate, measured))
        if panel.frame != target { panel.frame = target }
    }

    private func row(_ item: FennecSearchPopupItem) -> UIView {
        let button = FennecClosureButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = item.title
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        let icon = UIImageView(image: item.image)
        icon.tintColor = FennecTheme.ink
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = item.title
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = FennecTheme.ink
        label.numberOfLines = 0
        for child in [icon, label] {
            child.translatesAutoresizingMaskIntoConstraints = false
            child.isUserInteractionEnabled = false
            child.isAccessibilityElement = false
            button.addSubview(child)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24), icon.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12),
        ])
        button.onTap = { [weak self] in self?.dismiss(animated: false, completion: item.action) }
        return button
    }
}

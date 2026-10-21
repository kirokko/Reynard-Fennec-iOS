// Unofficial Material-style main menu, ordered after Fennec 158. GPL-3.0.
import UIKit

struct FennecMenuItem {
    let title: String
    let symbol: String
    var enabled = true
    var badge: String? = nil
    var children: [FennecMenuItem] = []
    var action: (() -> Void)? = nil
    var longPressAction: (() -> Void)? = nil
}

final class FennecClosureButton: UIButton {
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(held(_:))))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func tapped() { onTap?() }
    @objc private func held(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { onLongPress?() }
    }
}

final class FennecMenuViewController: UIViewController {
    enum Group {
        case rows([FennecMenuItem])
        case tiles([FennecMenuItem])
        case navigation([FennecMenuItem])
    }
    private let groups: [Group]
    private let panel = UIView()
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var panelHeight: NSLayoutConstraint!

    init(groups: [Group]) {
        self.groups = groups
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.38)
        let outside = FennecClosureButton(frame: .zero)
        outside.translatesAutoresizingMaskIntoConstraints = false
        outside.accessibilityLabel = FennecTheme.text("Close menu")
        outside.onTap = { [weak self] in self?.dismiss(animated: false) }
        view.addSubview(outside)
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = FennecTheme.surface
        panel.layer.cornerRadius = 28
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.clipsToBounds = true
        panel.accessibilityViewIsModal = true
        view.addSubview(panel)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never
        panel.addSubview(scrollView)
        let handle = FennecClosureButton(frame: .zero)
        handle.translatesAutoresizingMaskIntoConstraints = false
        handle.accessibilityLabel = FennecTheme.text("Close menu")
        handle.onTap = { [weak self] in self?.dismiss(animated: false) }
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = .systemGray
        line.layer.cornerRadius = 2
        handle.addSubview(line)
        panel.addSubview(handle)
        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: panel.topAnchor),
            handle.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 80),
            handle.heightAnchor.constraint(equalToConstant: 36),
            line.centerXAnchor.constraint(equalTo: handle.centerXAnchor),
            line.centerYAnchor.constraint(equalTo: handle.centerYAnchor),
            line.widthAnchor.constraint(equalToConstant: 32), line.heightAnchor.constraint(equalToConstant: 4),
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        scrollView.addSubview(stack)
        panelHeight = panel.heightAnchor.constraint(equalToConstant: 400)
        NSLayoutConstraint.activate([
            outside.topAnchor.constraint(equalTo: view.topAnchor),
            outside.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            outside.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            outside.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor), panelHeight,
            scrollView.topAnchor.constraint(equalTo: panel.topAnchor, constant: 44),
            scrollView.bottomAnchor.constraint(equalTo: panel.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            scrollView.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
        for group in groups {
            switch group {
            case .rows(let items):
                let groupStack = UIStackView()
                groupStack.axis = .vertical
                groupStack.backgroundColor = FennecTheme.card
                groupStack.layer.cornerRadius = 28
                groupStack.clipsToBounds = true
                groupStack.spacing = 2
                for item in items { groupStack.addArrangedSubview(row(item)) }
                stack.addArrangedSubview(groupStack)
            case .tiles(let items), .navigation(let items):
                let tileStack = UIStackView()
                tileStack.axis = .horizontal
                tileStack.distribution = .fillEqually
                tileStack.spacing = 2
                tileStack.backgroundColor = FennecTheme.surface
                tileStack.layer.cornerRadius = 28
                tileStack.clipsToBounds = true
                for item in items { tileStack.addArrangedSubview(tile(item)) }
                stack.addArrangedSubview(tileStack)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let target = stack.systemLayoutSizeFitting(
            CGSize(width: scrollView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel
        ).height + view.safeAreaInsets.bottom + 52
        let limit = max(100, view.bounds.height - view.safeAreaInsets.top - 12)
        let height = min(target, limit)
        if abs(panelHeight.constant - height) > 0.5 { panelHeight.constant = height }
    }

    override func accessibilityPerformEscape() -> Bool { dismiss(animated: false); return true }

    private func invoke(_ action: (() -> Void)?) {
        dismiss(animated: false, completion: action)
    }

    private func row(_ item: FennecMenuItem) -> UIView {
        let wrapper = UIStackView()
        wrapper.axis = .vertical
        let button = FennecClosureButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = item.enabled
        button.accessibilityLabel = item.title
        button.accessibilityValue = item.badge
        button.backgroundColor = FennecTheme.card
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        let icon = UIImageView(image: UIImage(systemName: item.symbol))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = item.enabled ? .label : .tertiaryLabel
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = item.title
        label.textColor = item.enabled ? .label : .tertiaryLabel
        let badge = UILabel()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.font = .preferredFont(forTextStyle: .caption1)
        badge.text = item.children.isEmpty ? item.badge : "⌄"
        badge.textColor = FennecTheme.accent
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)
        for child in [icon, label, badge] { button.addSubview(child); child.isUserInteractionEnabled = false; child.isAccessibilityElement = false }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24), icon.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: button.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -14),
            label.trailingAnchor.constraint(lessThanOrEqualTo: badge.leadingAnchor, constant: -8),
            badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            badge.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        wrapper.addArrangedSubview(button)
        if item.children.isEmpty {
            button.onTap = { [weak self] in self?.invoke(item.action) }
        } else {
            let nested = UIStackView()
            nested.axis = .vertical
            nested.isHidden = true
            for child in item.children { nested.addArrangedSubview(row(child)) }
            wrapper.addArrangedSubview(nested)
            button.accessibilityValue = FennecTheme.text("Collapsed")
            button.onTap = { [weak self, weak nested, weak button, weak badge] in
                guard let nested else { return }
                nested.isHidden.toggle()
                badge?.text = nested.isHidden ? "⌄" : "⌃"
                button?.accessibilityValue = FennecTheme.text(nested.isHidden ? "Collapsed" : "Expanded")
                self?.view.setNeedsLayout()
            }
        }
        button.onLongPress = { [weak self] in
            guard let action = item.longPressAction else { return }
            self?.invoke(action)
        }
        return wrapper
    }

    private func tile(_ item: FennecMenuItem) -> UIView {
        let button = FennecClosureButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = item.enabled
        button.accessibilityLabel = item.title
        button.backgroundColor = FennecTheme.card
        button.layer.cornerRadius = 2
        let icon = UIImageView(image: UIImage(systemName: item.symbol))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.tintColor = item.enabled ? .label : .tertiaryLabel
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = item.title
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = item.enabled ? .label : .tertiaryLabel
        for child in [icon, label] { button.addSubview(child); child.isAccessibilityElement = false; child.isUserInteractionEnabled = false }
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 76),
            icon.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            icon.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24), icon.heightAnchor.constraint(equalToConstant: 24),
            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4),
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -10),
        ])
        button.onTap = { [weak self] in self?.invoke(item.action) }
        button.onLongPress = { [weak self] in
            guard let action = item.longPressAction else { return }
            self?.invoke(action)
        }
        return button
    }
}

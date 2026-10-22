// Compact accessible category chips. GPL-3.0.
import UIKit

final class FennecDownloadFilterView: UIStackView {
    var onSelect: ((FennecDownloadFilter) -> Void)?
    private(set) var selected: FennecDownloadFilter = .all
    private var buttons: [FennecClosureButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .horizontal
        alignment = .center
        spacing = 8
        for filter in FennecDownloadFilter.allCases {
            let button = FennecClosureButton(frame: .zero)
            button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            button.layer.cornerRadius = 18
            button.accessibilityLabel = FennecTheme.text(filter.title)
            button.onTap = { [weak self] in self?.select(filter) }
            buttons.append(button)
            addArrangedSubview(button)
        }
        addArrangedSubview(UIView())
        updateAppearance()
    }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func select(_ filter: FennecDownloadFilter) {
        guard selected != filter else { return }
        selected = filter
        UIView.performWithoutAnimation { updateAppearance() }
        onSelect?(filter)
    }
    private func updateAppearance() {
        for (filter, button) in zip(FennecDownloadFilter.allCases, buttons) {
            let active = filter == selected
            button.setTitle((active ? "✓ " : "") + FennecTheme.text(filter.title), for: .normal)
            button.backgroundColor = active ? FennecTheme.accentContainer : .clear
            button.setTitleColor(FennecTheme.ink, for: .normal)
            button.accessibilityTraits = active ? [.button, .selected] : .button
        }
    }
}

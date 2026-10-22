// Fennec-style categories, compact plus and search/overflow pill. GPL-3.0.
import UIKit

final class TabOverviewTopToolbar: UIView {
    var onClearTabs: (() -> Void)?
    var onClearTabsOlderThan: ((TabOverviewClearTabsMenu.Age) -> Void)?
    var onAddTab: (() -> Void)?
    var onDone: (() -> Void)?
    var onTabModeChange: ((TabOverview.Mode) -> Void)?
    var onGroups: (() -> Void)?
    var onSearch: (() -> Void)?
    var onRecentlyClosed: (() -> Void)?
    var onMenu: (() -> Void)?
    let floatingControls = UIView()
    private let categoryStack = UIStackView()
    private let privateButton = FennecClosureButton(frame: .zero)
    private let regularButton = FennecClosureButton(frame: .zero)
    private let groupsButton = FennecClosureButton(frame: .zero)
    private let indicator = UIView()
    private let countLabel = UILabel()
    private let overflow = FennecClosureButton(frame: .zero)
    private let search = FennecClosureButton(frame: .zero)
    private let add = FennecClosureButton(frame: .zero)
    private var indicatorCenter: NSLayoutConstraint!
    private var currentMode: TabOverview.Mode = .regularTabs

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = FennecTheme.surface
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryStack.axis = .horizontal
        categoryStack.distribution = .fillEqually
        for button in [privateButton, regularButton, groupsButton] {
            categoryStack.addArrangedSubview(button)
            button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        privateButton.setImage(FennecTheme.privateBrowsingImage, for: .normal)
        privateButton.imageView?.contentMode = .scaleAspectFit
        privateButton.accessibilityLabel = FennecTheme.text("Private")
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.text = "0"
        countLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        countLabel.textAlignment = .center
        countLabel.layer.borderWidth = 1.8
        countLabel.layer.cornerRadius = 3
        countLabel.isUserInteractionEnabled = false
        countLabel.isAccessibilityElement = false
        regularButton.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: regularButton.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: regularButton.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 26),
            countLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
        regularButton.accessibilityLabel = FennecTheme.text("Tabs")
        groupsButton.setImage(UIImage(systemName: "square.grid.2x2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23, weight: .regular)), for: .normal)
        groupsButton.accessibilityLabel = FennecTheme.text("Tab groups")
        groupsButton.tintColor = .secondaryLabel
        groupsButton.onTap = { [weak self] in self?.onGroups?() }
        privateButton.onTap = { [weak self] in self?.onTabModeChange?(.privateTabs) }
        regularButton.onTap = { [weak self] in self?.onTabModeChange?(.regularTabs) }
        addSubview(categoryStack)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.backgroundColor = FennecTheme.ink
        indicator.layer.cornerRadius = 2
        addSubview(indicator)
        indicatorCenter = indicator.centerXAnchor.constraint(equalTo: regularButton.centerXAnchor)
        NSLayoutConstraint.activate([
            categoryStack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            categoryStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            categoryStack.topAnchor.constraint(equalTo: topAnchor),
            categoryStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 24),
            indicator.heightAnchor.constraint(equalToConstant: 3),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor), indicatorCenter,
        ])
        floatingControls.translatesAutoresizingMaskIntoConstraints = false
        let pill = UIStackView(arrangedSubviews: [search, overflow])
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.axis = .horizontal
        pill.distribution = .fillEqually
        pill.backgroundColor = FennecTheme.container
        pill.layer.cornerRadius = 28
        pill.clipsToBounds = true
        overflow.setImage(FennecTheme.overflowImage, for: .normal)
        overflow.tintColor = FennecTheme.ink
        overflow.accessibilityLabel = FennecTheme.text("Menu")
        overflow.onTap = { [weak self] in self?.onMenu?() }
        search.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        search.tintColor = FennecTheme.ink
        search.accessibilityLabel = FennecTheme.text("Search tabs")
        search.onTap = { [weak self] in self?.onSearch?() }
        add.translatesAutoresizingMaskIntoConstraints = false
        add.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)), for: .normal)
        add.tintColor = FennecTheme.accent
        add.backgroundColor = UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.36, green: 0.24, blue: 0.53, alpha: 1)
            : UIColor(red: 0.82, green: 0.71, blue: 1, alpha: 1) }
        add.layer.cornerRadius = 16
        add.layer.shadowColor = UIColor.black.cgColor
        add.layer.shadowOpacity = 0.2
        add.layer.shadowOffset = CGSize(width: 0, height: 3)
        add.layer.shadowRadius = 5
        add.onTap = { [weak self] in self?.onAddTab?() }
        add.onLongPress = { [weak self] in self?.onRecentlyClosed?() }
        floatingControls.addSubview(pill)
        floatingControls.addSubview(add)
        NSLayoutConstraint.activate([
            pill.leadingAnchor.constraint(equalTo: floatingControls.leadingAnchor),
            pill.bottomAnchor.constraint(equalTo: floatingControls.bottomAnchor),
            pill.widthAnchor.constraint(equalToConstant: 112), pill.heightAnchor.constraint(equalToConstant: 56),
            add.trailingAnchor.constraint(equalTo: floatingControls.trailingAnchor),
            add.bottomAnchor.constraint(equalTo: floatingControls.bottomAnchor),
            add.leadingAnchor.constraint(greaterThanOrEqualTo: pill.trailingAnchor, constant: 16),
            add.heightAnchor.constraint(equalToConstant: 56), add.widthAnchor.constraint(equalToConstant: 56),
            add.topAnchor.constraint(greaterThanOrEqualTo: floatingControls.topAnchor),
        ])
        setMode(.regularTabs)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func setMode(_ mode: TabOverview.Mode) {
        currentMode = mode
        overrideUserInterfaceStyle = mode == .privateTabs ? .dark : .unspecified
        floatingControls.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        backgroundColor = mode == .privateTabs ? FennecTheme.privateSurface : FennecTheme.surface
        privateButton.tintColor = mode == .privateTabs ? FennecTheme.ink : .secondaryLabel
        countLabel.textColor = mode == .regularTabs ? FennecTheme.ink : .secondaryLabel
        countLabel.layer.borderColor = countLabel.textColor.resolvedColor(with: traitCollection).cgColor
        privateButton.accessibilityTraits = mode == .privateTabs ? [.button, .selected] : .button
        regularButton.accessibilityTraits = mode == .regularTabs ? [.button, .selected] : .button
        indicatorCenter.isActive = false
        indicatorCenter = indicator.centerXAnchor.constraint(equalTo: (mode == .privateTabs ? privateButton : regularButton).centerXAnchor)
        indicatorCenter.isActive = true
    }
    func apply(tabCount: Int, visibleTabCount: Int, hasVisibleTab: Bool) {
        countLabel.text = tabCount > 99 ? "∞" : String(max(0, tabCount))
        regularButton.accessibilityValue = String(tabCount)
        add.accessibilityLabel = FennecTheme.text(currentMode == .privateTabs ? "New private tab" : "New tab")
    }
}

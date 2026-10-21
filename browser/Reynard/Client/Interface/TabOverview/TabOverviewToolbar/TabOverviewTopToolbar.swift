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
    let floatingControls = UIView()
    private let categoryStack = UIStackView()
    private let privateButton = FennecClosureButton(frame: .zero)
    private let regularButton = FennecClosureButton(frame: .zero)
    private let groupsButton = FennecClosureButton(frame: .zero)
    private let indicator = UIView()
    private let overflow = UIButton(type: .system)
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
        privateButton.setImage(UIImage(named: "private.mode.icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        privateButton.imageView?.contentMode = .scaleAspectFit
        privateButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 36, bottom: 12, right: 36)
        privateButton.accessibilityLabel = FennecTheme.text("Private")
        regularButton.setTitle("0", for: .normal)
        regularButton.accessibilityLabel = FennecTheme.text("Tabs")
        groupsButton.setImage(UIImage(systemName: "square.grid.2x2"), for: .normal)
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
        search.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        search.tintColor = FennecTheme.ink
        search.accessibilityLabel = FennecTheme.text("Search tabs")
        search.onTap = { [weak self] in self?.onSearch?() }
        add.translatesAutoresizingMaskIntoConstraints = false
        add.setImage(UIImage(systemName: "plus"), for: .normal)
        add.tintColor = FennecTheme.ink
        add.backgroundColor = FennecTheme.accentContainer
        add.layer.cornerRadius = 16
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
        privateButton.tintColor = mode == .privateTabs ? FennecTheme.ink : .secondaryLabel
        regularButton.setTitleColor(mode == .regularTabs ? FennecTheme.ink : .secondaryLabel, for: .normal)
        privateButton.accessibilityTraits = mode == .privateTabs ? [.button, .selected] : .button
        regularButton.accessibilityTraits = mode == .regularTabs ? [.button, .selected] : .button
        indicatorCenter.isActive = false
        indicatorCenter = indicator.centerXAnchor.constraint(equalTo: (mode == .privateTabs ? privateButton : regularButton).centerXAnchor)
        indicatorCenter.isActive = true
    }
    func apply(tabCount: Int, visibleTabCount: Int, hasVisibleTab: Bool) {
        regularButton.setTitle("▢ \(tabCount)", for: .normal)
        regularButton.accessibilityValue = String(tabCount)
        let clearMenu = TabOverviewClearTabsMenu.make(tabCount: visibleTabCount,
            onClearTabs: { [weak self] in self?.onClearTabs?() },
            onClearTabsOlderThan: { [weak self] age in self?.onClearTabsOlderThan?(age) })
        let done = UIAction(title: FennecTheme.text("Back to browsing"), image: UIImage(systemName: "arrow.backward"), attributes: hasVisibleTab ? [] : .disabled) { [weak self] _ in self?.onDone?() }
        if #available(iOS 14.0, *) {
            overflow.menu = UIMenu(children: [clearMenu, done])
            overflow.showsMenuAsPrimaryAction = true
        }
        add.accessibilityLabel = FennecTheme.text(currentMode == .privateTabs ? "New private tab" : "New tab")
    }
}

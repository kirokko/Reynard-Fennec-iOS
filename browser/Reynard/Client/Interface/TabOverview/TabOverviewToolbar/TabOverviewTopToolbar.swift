// Fennec-style tab categories and floating actions. GPL-3.0.
import UIKit

final class TabOverviewTopToolbar: UIView {
    var onClearTabs: (() -> Void)?
    var onClearTabsOlderThan: ((TabOverviewClearTabsMenu.Age) -> Void)?
    var onAddTab: (() -> Void)?
    var onDone: (() -> Void)?
    var onTabModeChange: ((TabOverview.Mode) -> Void)?
    let floatingControls = UIView()
    private let categoryStack = UIStackView()
    private let privateButton = FennecClosureButton(frame: .zero)
    private let regularButton = FennecClosureButton(frame: .zero)
    private let indicator = UIView()
    private let overflow = UIButton(type: .system)
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
        for button in [privateButton, regularButton] {
            categoryStack.addArrangedSubview(button)
            button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        privateButton.setTitle(FennecTheme.text("Private"), for: .normal)
        regularButton.setTitle(FennecTheme.text("Tabs"), for: .normal)
        privateButton.onTap = { [weak self] in self?.onTabModeChange?(.privateTabs) }
        regularButton.onTap = { [weak self] in self?.onTabModeChange?(.regularTabs) }
        addSubview(categoryStack)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.backgroundColor = FennecTheme.accent
        indicator.layer.cornerRadius = 2
        addSubview(indicator)
        indicatorCenter = indicator.centerXAnchor.constraint(equalTo: regularButton.centerXAnchor)
        NSLayoutConstraint.activate([
            categoryStack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            categoryStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            categoryStack.topAnchor.constraint(equalTo: topAnchor),
            categoryStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 28),
            indicator.heightAnchor.constraint(equalToConstant: 4),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor), indicatorCenter,
        ])
        floatingControls.translatesAutoresizingMaskIntoConstraints = false
        overflow.translatesAutoresizingMaskIntoConstraints = false
        overflow.setImage(FennecTheme.overflowImage, for: .normal)
        overflow.tintColor = .label
        overflow.backgroundColor = FennecTheme.container
        overflow.layer.cornerRadius = 28
        overflow.accessibilityLabel = FennecTheme.text("Menu")
        add.translatesAutoresizingMaskIntoConstraints = false
        add.setTitle("＋  " + FennecTheme.text("New tab"), for: .normal)
        add.setTitleColor(FennecTheme.accent, for: .normal)
        add.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        add.titleLabel?.adjustsFontForContentSizeCategory = true
        add.backgroundColor = FennecTheme.accentContainer
        add.layer.cornerRadius = 20
        add.onTap = { [weak self] in self?.onAddTab?() }
        floatingControls.addSubview(overflow)
        floatingControls.addSubview(add)
        NSLayoutConstraint.activate([
            overflow.leadingAnchor.constraint(equalTo: floatingControls.leadingAnchor),
            overflow.bottomAnchor.constraint(equalTo: floatingControls.bottomAnchor),
            overflow.widthAnchor.constraint(equalToConstant: 56), overflow.heightAnchor.constraint(equalToConstant: 56),
            add.trailingAnchor.constraint(equalTo: floatingControls.trailingAnchor),
            add.bottomAnchor.constraint(equalTo: floatingControls.bottomAnchor),
            add.leadingAnchor.constraint(greaterThanOrEqualTo: overflow.trailingAnchor, constant: 16),
            add.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            add.widthAnchor.constraint(greaterThanOrEqualToConstant: 144),
            add.topAnchor.constraint(greaterThanOrEqualTo: floatingControls.topAnchor),
        ])
        setMode(.regularTabs)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func setMode(_ mode: TabOverview.Mode) {
        currentMode = mode
        privateButton.setTitleColor(mode == .privateTabs ? FennecTheme.accent : .secondaryLabel, for: .normal)
        regularButton.setTitleColor(mode == .regularTabs ? FennecTheme.accent : .secondaryLabel, for: .normal)
        privateButton.accessibilityTraits = mode == .privateTabs ? [.button, .selected] : .button
        regularButton.accessibilityTraits = mode == .regularTabs ? [.button, .selected] : .button
        indicatorCenter.isActive = false
        indicatorCenter = indicator.centerXAnchor.constraint(equalTo: (mode == .privateTabs ? privateButton : regularButton).centerXAnchor)
        indicatorCenter.isActive = true
    }
    func apply(tabCount: Int, visibleTabCount: Int, hasVisibleTab: Bool) {
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

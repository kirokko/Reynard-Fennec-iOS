// Fennec-inspired single-row toolbar. Original Reynard API retained. GPL-3.0.
import UIKit

final class TopToolbar: UIView {
    enum LayoutState { case hidden, standard, compact }
    var onSidebar: (() -> Void)?
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onLibrary: (() -> Void)?
    var onDownloads: (() -> Void)?
    var onShare: (() -> Void)?
    var onNewTab: (() -> Void)?
    var onTabOverview: (() -> Void)?

    private let contentView = UIView()
    private let backgroundView = UIView()
    private let controls = FennecToolbarControls()
    private lazy var sidebarButton = ToolbarButton(buttonType: .sidebar, target: self, action: #selector(sidebar))
    private let buttonMenus = ToolbarButtonMenus()
    private var heightConstraint: NSLayoutConstraint!
    private var contentTopConstraint: NSLayoutConstraint!
    private var backgroundBottomConstraint: NSLayoutConstraint!
    private var addressConstraints: [NSLayoutConstraint] = []
    private var addressTrailing: NSLayoutConstraint?
    private var addressLeading: NSLayoutConstraint?
    private var showsSidebar = false
    private var editing = false

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = FennecTheme.surface
        for child in [backgroundView, contentView] {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }
        contentView.addSubview(sidebarButton)
        contentView.addSubview(controls)
        heightConstraint = heightAnchor.constraint(equalToConstant: 56)
        contentTopConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
        backgroundBottomConstraint = backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([
            heightConstraint, contentTopConstraint, backgroundBottomConstraint,
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 56),
            controls.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            controls.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sidebarButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            sidebarButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            sidebarButton.widthAnchor.constraint(equalToConstant: 44),
            sidebarButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        controls.onNewTab = { [weak self] in self?.onNewTab?() }
        controls.onTabs = { [weak self] in self?.onTabOverview?() }
        controls.onMenu = { [weak self] in self?.onLibrary?() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func attachAddressBar(_ addressBar: AddressBar) {
        if addressBar.superview !== contentView {
            addressBar.removeFromSuperview()
            contentView.addSubview(addressBar)
        }
        if addressConstraints.isEmpty {
            let leading = addressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)
            let trailing = addressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -96)
            addressLeading = leading
            addressTrailing = trailing
            addressConstraints = [leading, trailing,
                addressBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                addressBar.heightAnchor.constraint(equalToConstant: 44)]
        }
        NSLayoutConstraint.activate(addressConstraints)
        updateInsets()
    }

    func detachAddressBar() { NSLayoutConstraint.deactivate(addressConstraints) }
    func sharePopoverSourceView() -> UIView { controls.menuButton }
    func extendBackground(to bottomAnchor: NSLayoutYAxisAnchor) {
        backgroundBottomConstraint.isActive = false
        backgroundBottomConstraint = backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        backgroundBottomConstraint.isActive = true
    }
    func setBackgroundCollapseOffset(_ offset: CGFloat) { backgroundBottomConstraint.constant = -offset }
    func apply(state: LayoutState, topInset: CGFloat, interfaceIdiom: UIUserInterfaceIdiom, sidebarButtonVisible: Bool) {
        contentTopConstraint.constant = topInset
        heightConstraint.constant = topInset + 56
        isHidden = state == .hidden
        showsSidebar = interfaceIdiom == .pad && sidebarButtonVisible
        sidebarButton.isHidden = !showsSidebar
        updateInsets()
    }
    func setEditing(_ editing: Bool) {
        self.editing = editing
        controls.isHidden = editing
        updateInsets()
    }
    private func updateInsets() {
        addressLeading?.constant = showsSidebar ? 56 : 8
        addressTrailing?.constant = editing ? -8 : -96
    }
    func setContentAlpha(_ alpha: CGFloat) { contentView.alpha = alpha }
    func setTabCount(_ count: Int) { controls.setTabCount(count) }
    func updateNavigation(canGoBack: Bool, canGoForward: Bool, canShare: Bool) {}
    // Navigation controls live in the main menu, not a second toolbar row.
    func configureNavigationMenus(itemsProvider: @escaping (ToolbarButtonMenus.NavigationDirection) -> [NavigationHistoryStore.HistoryItem], onSelect: @escaping (ToolbarButtonMenus.NavigationDirection, Int) -> Void) {}
    func configureRecentlyClosedTabsMenu(isAvailable: @escaping () -> Bool, itemsProvider: @escaping () -> [TabManagementStore.RecentlyClosedTabSnapshot], onSelect: @escaping (UUID) -> Void) {
        buttonMenus.installRecentlyClosedTabsMenu(on: controls.newTabButton, isAvailable: isAvailable, itemsProvider: itemsProvider, onSelect: onSelect)
    }
    func configureLibraryMenus(onSelect: @escaping (LibrarySection) -> Void) {
        buttonMenus.installLibraryMenus(on: [sidebarButton, controls.menuButton], onSelect: onSelect)
    }
    func configureTabOverviewMenus(tabCountProvider: @escaping () -> Int, onCloseAllTabs: @escaping () -> Void, onCloseTab: @escaping () -> Void, onNewPrivateTab: @escaping () -> Void, onNewTab: @escaping () -> Void) {
        buttonMenus.installTabOverviewMenus(on: [controls.tabButton], tabCountProvider: tabCountProvider, onCloseAllTabs: onCloseAllTabs, onCloseTab: onCloseTab, onNewPrivateTab: onNewPrivateTab, onNewTab: onNewTab)
    }
    func updateDownload(_ summary: DownloadStoreSummary) { controls.updateDownload(summary) }
    func setMenuButtonIndicatesUpdate(_ hasUpdate: Bool) {}
    func syncSidebarButton(splitViewController: UISplitViewController?) {
        sidebarButton.setImage(splitViewController?.displayModeButtonItem.image ?? UIImage(named: "reynard.sidebar.left"), for: .normal)
        sidebarButton.accessibilityLabel = splitViewController?.displayModeButtonItem.accessibilityLabel
    }
    func sidebarButtonFrame(in view: UIView) -> CGRect { sidebarButton.convert(sidebarButton.bounds, to: view) }
    func setSidebarButtonTransition(alpha: CGFloat, hidden: Bool) { sidebarButton.alpha = alpha; sidebarButton.isHidden = hidden }
    @objc private func sidebar() { onSidebar?() }
}

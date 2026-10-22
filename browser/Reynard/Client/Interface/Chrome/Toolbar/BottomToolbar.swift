// Fennec-inspired bottom toolbar; same actions as the top toolbar. GPL-3.0.
import UIKit

final class BottomToolbar: UIView {
    enum LayoutState { case hidden, collapsed, standard, compact }
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onShare: (() -> Void)?
    var onLibrary: (() -> Void)?
    var onDownloads: (() -> Void)?
    var onNewTab: (() -> Void)?
    var onTabOverview: (() -> Void)?

    // The complete bar (row + bottom inset + background) moves as ONE plate.
    private let contentView = UIView()
    private let backgroundView = UIView()
    private let controls = FennecToolbarControls()
    private let buttonMenus = ToolbarButtonMenus()
    private var topConstraint: NSLayoutConstraint!
    private var contentHeight: NSLayoutConstraint!
    private var addressConstraints: [NSLayoutConstraint] = []
    private var addressTrailing: NSLayoutConstraint?
    private weak var addressBar: AddressBar?

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = FennecTheme.surface
        for child in [backgroundView, contentView] {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }
        contentView.addSubview(controls)
        contentHeight = contentView.heightAnchor.constraint(equalToConstant: 56)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            contentHeight,
            controls.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            controls.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        controls.onNewTab = { [weak self] in self?.onNewTab?() }
        controls.onTabs = { [weak self] in self?.onTabOverview?() }
        controls.onMenu = { [weak self] in self?.onLibrary?() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self || hit === backgroundView || hit === contentView ? nil : hit
    }
    func configureTopAnchor(to safeAreaBottomAnchor: NSLayoutYAxisAnchor) {
        topConstraint = topAnchor.constraint(equalTo: safeAreaBottomAnchor, constant: -56)
        topConstraint.isActive = true
    }
    func attachAddressBar(_ addressBar: AddressBar) {
        self.addressBar = addressBar
        if addressBar.superview !== contentView {
            addressBar.removeFromSuperview()
            contentView.addSubview(addressBar)
        }
        if addressConstraints.isEmpty {
            let trailing = addressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -140)
            addressTrailing = trailing
            addressConstraints = [trailing,
                addressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
                addressBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                addressBar.heightAnchor.constraint(equalToConstant: 44)]
        }
        NSLayoutConstraint.activate(addressConstraints)
    }
    func detachAddressBar() { NSLayoutConstraint.deactivate(addressConstraints); addressBar = nil }
    func hitTestAddressBar(at point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled, contentView.alpha > 0.01,
              let addressBar else { return nil }
        return addressBar.hitTest(addressBar.convert(point, from: self), with: event)
    }
    func sharePopoverSourceView() -> UIView { controls.menuButton }
    func apply(state: LayoutState, hidesButtons: Bool) {
        // In top-bar mode there is no second bottom navigation row.
        let visible = state == .standard
        topConstraint.constant = visible ? -56 : 0
        contentHeight.constant = visible ? 56 : 0
        isHidden = !visible
        setEditing(hidesButtons)
    }
    func setEditing(_ editing: Bool) {
        controls.isHidden = editing
        addressTrailing?.constant = editing ? -8 : -140
    }
    func setAddressBarDockOffset(_ offset: CGFloat) {
        // Keyboard notifications can be delivered inside an active Core
        // Animation transaction. Cancel any old presentation transform as well
        // as disabling UIView animations, so the old docked bar cannot linger.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.performWithoutAnimation {
            contentView.layer.removeAllAnimations()
            backgroundView.layer.removeAllAnimations()
            contentView.transform = CGAffineTransform(translationX: 0, y: offset)
            backgroundView.transform = CGAffineTransform(translationX: 0, y: offset)
            layoutIfNeeded()
        }
        CATransaction.commit()
    }
    func setScrollTranslation(_ offset: CGFloat) {
        // No clipping seam, separate bottom fade or second-phase motion.
        transform = CGAffineTransform(translationX: 0, y: offset)
    }
    func setContentAlpha(_ alpha: CGFloat) { contentView.alpha = alpha }
    func setTabCount(_ count: Int) { controls.setTabCount(count) }
    func setPrivateBrowsing(_ value: Bool) { controls.setPrivateBrowsing(value) }
    func updateNavigation(canGoBack: Bool, canGoForward: Bool, canShare: Bool) {}
    func configureNavigationMenus(itemsProvider: @escaping (ToolbarButtonMenus.NavigationDirection) -> [NavigationHistoryStore.HistoryItem], onSelect: @escaping (ToolbarButtonMenus.NavigationDirection, Int) -> Void) {}
    func configureLibraryMenus(onSelect: @escaping (LibrarySection) -> Void) {
        buttonMenus.installLibraryMenus(on: [controls.menuButton], onSelect: onSelect)
    }
    func configureRecentlyClosedTabsMenu(isAvailable: @escaping () -> Bool, itemsProvider: @escaping () -> [TabManagementStore.RecentlyClosedTabSnapshot], onSelect: @escaping (UUID) -> Void) {
        buttonMenus.installRecentlyClosedTabsMenu(on: controls.newTabButton, isAvailable: isAvailable, itemsProvider: itemsProvider, onSelect: onSelect)
    }
    func configureTabOverviewMenus(tabCountProvider: @escaping () -> Int, onCloseAllTabs: @escaping () -> Void, onCloseTab: @escaping () -> Void, onNewPrivateTab: @escaping () -> Void, onNewTab: @escaping () -> Void) {
        buttonMenus.installTabOverviewMenus(on: [controls.tabButton], tabCountProvider: tabCountProvider, onCloseAllTabs: onCloseAllTabs, onCloseTab: onCloseTab, onNewPrivateTab: onNewPrivateTab, onNewTab: onNewTab)
    }
    func updateDownload(_ summary: DownloadStoreSummary) { controls.updateDownload(summary) }
    func setMenuButtonIndicatesUpdate(_ hasUpdate: Bool) {}
}

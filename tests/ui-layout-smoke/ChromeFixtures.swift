// Real chrome/rotation/progress UI around engine-free address/menu doubles.
// Not a Gecko, physical sensor, system keyboard, or orientation-lock test.
import UIKit

final class AddressBar: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = FennecTheme.container
        layer.cornerRadius = 22
        let shield = UIImageView(image: FennecTheme.siteProtectionImage)
        shield.translatesAutoresizingMaskIntoConstraints = false
        shield.tintColor = FennecTheme.ink
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = FennecTheme.ink
        label.lineBreakMode = .byTruncatingTail
        label.text = FennecAddressDisplay.text("https://example.invalid/search?q=toolbar", fullAddress: false)
        addSubview(shield)
        addSubview(label)
        NSLayoutConstraint.activate([
            shield.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            shield.centerYAnchor.constraint(equalTo: centerYAnchor),
            shield.widthAnchor.constraint(equalToConstant: 24),
            shield.heightAnchor.constraint(equalToConstant: 24),
            label.leadingAnchor.constraint(equalTo: shield.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
enum NavigationHistoryStore { struct HistoryItem {} }
enum TabManagementStore { struct RecentlyClosedTabSnapshot {} }
final class ToolbarButtonMenus {
    enum NavigationDirection { case back, forward }
    func installLibraryMenus(on: [UIButton], onSelect: @escaping (LibrarySection) -> Void) {}
    func installRecentlyClosedTabsMenu(on: UIButton, isAvailable: @escaping () -> Bool, itemsProvider: @escaping () -> [TabManagementStore.RecentlyClosedTabSnapshot], onSelect: @escaping (UUID) -> Void) {}
    func installTabOverviewMenus(on: [UIButton], tabCountProvider: @escaping () -> Int, onCloseAllTabs: @escaping () -> Void, onCloseTab: @escaping () -> Void, onNewPrivateTab: @escaping () -> Void, onNewTab: @escaping () -> Void) {}
}

func checkFennecChrome() -> UIView {
    var captured: UIView!
    for width in [320.0, 393, 430, 844, 1024] {
        let canvas = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 164))
        canvas.backgroundColor = FennecTheme.surface
        let top = TopToolbar()
        let bottom = BottomToolbar()
        canvas.addSubview(top)
        canvas.addSubview(bottom)
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: canvas.topAnchor),
            top.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            top.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
            bottom.bottomAnchor.constraint(equalTo: canvas.bottomAnchor),
            bottom.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
        ])
        bottom.configureTopAnchor(to: canvas.bottomAnchor)
        let topAddress = AddressBar(), bottomAddress = AddressBar()
        top.attachAddressBar(topAddress)
        bottom.attachAddressBar(bottomAddress)
        top.apply(state: .standard, topInset: 0, interfaceIdiom: .phone, sidebarButtonVisible: false)
        bottom.apply(state: .standard, hidesButtons: false)
        top.setTabCount(12)
        bottom.setTabCount(12)
        canvas.layoutIfNeeded()
        precondition(topAddress.bounds.width >= 172 && bottomAddress.bounds.width >= 172)
        func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap { descendants($0) } }
        let controls = descendants(canvas).compactMap { $0 as? FennecToolbarControls }
        precondition(controls.count == 2)
        for control in controls {
            precondition(control.arrangedSubviews.count == 3 && control.bounds.width == 132)
            precondition(!control.hasAmbiguousLayout)
            for target in control.arrangedSubviews {
                precondition(target.bounds.width == 44 && target.bounds.height == 44)
                precondition(target.frame.minX >= 0 && target.frame.maxX <= 132)
            }
        }
        var additions = 0
        top.onNewTab = { additions += 1 }
        bottom.onNewTab = { additions += 1 }
        for control in controls { control.newTabButton.sendActions(for: .touchUpInside) }
        precondition(additions == 2, "Both plus buttons must reach real toolbar callbacks")
        top.setEditing(true)
        bottom.setEditing(true)
        // This canvas is deliberately off-window. Explicitly flush its layout
        // tree; unlike an on-screen hierarchy it has no scheduled frame pass.
        canvas.setNeedsLayout()
        canvas.layoutIfNeeded()
        top.layoutIfNeeded()
        bottom.layoutIfNeeded()
        precondition(controls.allSatisfy { $0.isHidden })
        let expectedWidth = width - 16
        let topWidth = topAddress.bounds.width, bottomWidth = bottomAddress.bounds.width
        FileHandle.standardError.write(Data(("Editing width \(width): expected=\(expectedWidth), top=\(topWidth), bottom=\(bottomWidth)\n").utf8))
        precondition(abs(topWidth - expectedWidth) < 0.5 && abs(bottomWidth - expectedWidth) < 0.5,
                     "Editing must reclaim the controls' space within pixel rounding")
        top.setEditing(false)
        bottom.setEditing(false)
        canvas.setNeedsLayout()
        canvas.layoutIfNeeded()
        top.layoutIfNeeded()
        bottom.layoutIfNeeded()
        if width == 393 { captured = canvas }
    }
    return captured
}

func checkFullscreenRotationAndRefresh() {
    var state = FennecFullscreenRotationState()
    state.toggle()
    precondition(state.mode == .inactive)
    state.enter()
    precondition(state.mode == .portrait && state.mask == .portrait)
    precondition(!state.updateGravity(x: 0.9, y: 0.1))
    precondition(!state.updateGravity(x: 0.9, y: 0.1))
    precondition(state.orientation == .portrait, "Physical rotation cannot bypass the button")
    state.toggle()
    precondition(state.mode == .landscape && state.orientation == .landscapeLeft)
    precondition(!state.updateGravity(x: -0.9, y: 0))
    precondition(state.updateGravity(x: -0.9, y: 0))
    precondition(state.orientation == .landscapeRight && state.mask == .landscapeRight)
    precondition(!state.updateGravity(x: 0.1, y: -0.95))
    precondition(!state.updateGravity(x: .nan, y: 0))
    precondition(state.orientation == .landscapeRight, "Portrait/flat/invalid samples must not flip landscape")
    state.toggle()
    precondition(state.orientation == .portrait)
    state.exit()
    precondition(!state.updateGravity(x: 1, y: 0) && state.mode == .inactive)
    state.enter()
    precondition(state.orientation == .portrait, "Every new fullscreen begins portrait")

    let host = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    let rotation = FennecFullscreenRotationController()
    rotation.install(in: host)
    var requests: [UIInterfaceOrientation] = []
    rotation.onRequestOrientation = { requests.append($0) }
    rotation.enter()
    host.layoutIfNeeded()
    precondition(!rotation.button.isHidden && rotation.button.bounds.size == CGSize(width: 44, height: 44))
    rotation.button.sendActions(for: .touchUpInside)
    precondition(requests == [.portrait, .landscapeRight])
    rotation.exit()
    precondition(rotation.button.isHidden && rotation.state.mode == .inactive)
    rotation.button.sendActions(for: .touchUpInside)
    precondition(requests.count == 2, "Stale full-screen controls must be inactive")

    let indicator = FennecRefreshIndicator(frame: .zero)
    precondition(indicator.intrinsicContentSize == CGSize(width: 40, height: 40))
    indicator.setPullProgress(0.5)
    indicator.startAnimating()
    indicator.startAnimating() // Idempotent; one explicit animation only.
    precondition(indicator.isAnimating)
    let arrow = indicator.subviews.first!
    precondition(arrow.layer.animationKeys() == ["refresh.spin"])
    indicator.stopAnimating()
    precondition(!indicator.isAnimating && (arrow.layer.animationKeys() ?? []).isEmpty && arrow.transform == .identity)
}

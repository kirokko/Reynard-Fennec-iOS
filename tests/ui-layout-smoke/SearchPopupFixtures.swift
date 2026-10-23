// Real anchored popup UI and geometry; actions/store/engine boundary are doubles.
import UIKit

func checkSearchPopup() -> UIView {
    func checkpoint(_ name: String) { FileHandle.standardError.write(Data(("POPUP: " + name + "\n").utf8)) }
    let names = ["DuckDuckGo", "DuckDuckGo (Lite)", "DuckDuckGo (HTML)"]
    let icons = ["FennecSearch-duckDuckGo", "FennecSearch-duckDuckGo", "FennecSearch-duckDuckGo"]
    for icon in Set(icons) { precondition(UIImage(named: icon) != nil, "Missing provider icon: \(icon)") }
    let items = zip(names, icons).map { FennecSearchPopupItem(title: $0.0, image: UIImage(named: $0.1), action: {}) }
    let sections = [items,
        [FennecSearchPopupItem(title: "Bookmarks", image: UIImage(named: "FennecBookmarkTray"), action: {}),
         FennecSearchPopupItem(title: "Tabs", image: UIImage(named: "FennecTabTray"), action: {}),
         FennecSearchPopupItem(title: "History", image: UIImage(named: "FennecHistory"), action: {})],
        [FennecSearchPopupItem(title: "Search settings", image: UIImage(named: "FennecSearchSettings"), action: {})]]
    func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap(descendants) }
    var sample: UIView!
    for width in [320.0, 393, 430, 844, 1024] {
        for bottom in [false, true] {
            let height: CGFloat = width > 500 ? 393 : 852
            let bounds = CGRect(x: 0, y: 0, width: width, height: height)
            let anchor = CGRect(x: 12, y: bottom ? height - 78 : 60, width: 40, height: 44)
            let safe = UIEdgeInsets(top: 54, left: 0, bottom: 34, right: 0)
            let frame = FennecSearchPopup.panelFrame(bounds: bounds, safe: safe, anchor: anchor, contentHeight: 538)
            precondition(frame.width < width * 0.8, "Picker must be a narrow popup, never a full-width sheet")
            precondition(frame.minX >= 8 && frame.maxX <= width - 8)
            precondition(frame.minY >= safe.top + 8 && frame.maxY <= height - safe.bottom - 8)
            checkpoint("viewport \(width), bottom=\(bottom), create")
            let source = UIView(frame: anchor)
            let popup = FennecSearchPopup(sourceView: source, groups: sections)
            popup.loadViewIfNeeded()
            checkpoint("loaded")
            popup.view.frame = bounds
            popup.view.backgroundColor = FennecTheme.surface // synthetic page illustration only
            popup.view.setNeedsLayout()
            checkpoint("layout begin")
            popup.view.layoutIfNeeded()
            checkpoint("layout end")
            let panel = descendants(popup.view).first { $0.accessibilityIdentifier == "search.providerPopup" }!
            precondition(panel.bounds.width > 0 && panel.bounds.width < width * 0.8)
            let stableFrame = panel.frame
            popup.view.setNeedsLayout()
            popup.view.layoutIfNeeded()
            precondition(panel.frame == stableFrame, "Popup must converge after wrapping labels")
            let labels = descendants(popup.view).compactMap { ($0 as? UILabel)?.text }
            precondition(names.allSatisfy { labels.contains($0) })
            let titleOrder = labels.filter { names.contains($0) }
            precondition(titleOrder == names)
            if width == 393 && bottom { sample = popup.view }
        }
    }
    for asset in ["FennecTabOutline", "FennecPrivateTabBadge", "FennecPrivateBadge", "FennecBookmarkTray", "FennecTabTray", "FennecHistory", "FennecSearchSettings"] {
        precondition(UIImage(named: asset) != nil, "Actual actool asset missing: \(asset)")
    }
    // Test the actual access-gate UI, not Face ID success on a synthetic device.
    for width in [320.0, 393, 430, 844, 1024] {
        checkpoint("private lock \(width)")
        let lock = FennecPrivateLockViewController()
        var unlockRequests = 0
        var normalRequests = 0
        lock.onUnlock = { unlockRequests += 1 }
        lock.onRegular = { normalRequests += 1 }
        lock.loadViewIfNeeded()
        lock.view.frame = CGRect(x: 0, y: 0, width: width, height: width > 500 ? 393 : 852)
        lock.view.layoutIfNeeded()
        precondition(lock.view.accessibilityViewIsModal)
        let buttons = descendants(lock.view).compactMap { $0 as? UIButton }
        precondition(buttons.count == 2)
        for button in buttons {
            precondition(button.bounds.height >= 44)
            precondition(lock.view.bounds.contains(button.convert(button.bounds, to: lock.view)))
            button.sendActions(for: .touchUpInside)
        }
        precondition(unlockRequests == 1 && normalRequests == 1)
        lock.showFailure()
        lock.view.layoutIfNeeded()
        precondition(descendants(lock.view).compactMap { ($0 as? UILabel)?.text }.contains(FennecTheme.text("Private tabs remain locked. Try again or return to normal browsing.")))
        lock.setLocked(false)
        lock.setLocked(true)
    }
    return sample
}

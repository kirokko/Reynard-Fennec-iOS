// Real anchored popup UI and geometry; actions/store/engine boundary are doubles.
import UIKit

func checkSearchPopup() -> UIView {
    let names = ["DuckDuckGo", "cn.bing.com", "DuckDuckGo (Lite)", "DuckDuckGo (HTML)"]
    let items = names.map { FennecSearchPopupItem(title: $0, image: UIImage(named: "FennecSearch-duckDuckGo"), action: {}) }
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
            let source = UIView(frame: anchor)
            let popup = FennecSearchPopup(sourceView: source, groups: sections)
            popup.loadViewIfNeeded()
            popup.view.frame = bounds
            popup.view.backgroundColor = FennecTheme.surface // synthetic page illustration only
            popup.view.setNeedsLayout()
            popup.view.layoutIfNeeded()
            let panel = descendants(popup.view).first { $0.accessibilityIdentifier == "search.providerPopup" }!
            precondition(panel.bounds.width > 0 && panel.bounds.width < width * 0.8)
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
    // The real diagnostic must be reachable/interactive without changing a
    // browser layer or requiring JIT/remote debugging. No security PASS asserted.
    let probe = FennecCaptureProbeViewController()
    probe.loadViewIfNeeded()
    probe.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
    probe.view.layoutIfNeeded()
    let modes = descendants(probe.view).compactMap { $0 as? UISegmentedControl }.first!
    for mode in [0, 1, 2, 0] {
        modes.selectedSegmentIndex = mode
        modes.sendActions(for: .valueChanged)
        probe.view.layoutIfNeeded()
    }
    precondition(descendants(probe.view).contains { $0 is FennecSecureCanvasExperiment })
    return sample
}

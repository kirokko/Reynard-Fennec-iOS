// Engine-free doubles around the REAL TabOverviewPresentation controller.
import UIKit

enum LibrarySection { case bookmarks, history, downloads, settings }
struct SettingsSectionText { var headerTitle: String?; var footerTitle: String?; init(headerTitle: String? = nil, footerTitle: String? = nil) { self.headerTitle = headerTitle; self.footerTitle = footerTitle } }
enum TabMode { case regular, `private` }
struct BrowserLayout { enum ChromeMode { case phone, pad }; var chromeMode: ChromeMode = .phone }
enum BrowserChromeMode { case phone, compact, pad }
final class ContentView: UIView {
    var onHistorySwipeBegan: (() -> Void)?
    var onHistorySwipeEnded: (() -> Void)?
    var onScrollInteractionBegan: (() -> Void)?
    var onScrollInteractionEnded: (() -> Void)?
    var onVerticalScroll: ((CGFloat, CGFloat) -> Void)?
    var bottomOffset: CGFloat = 0
    func resetScrollTracking() {}
    func setToolbarLimits(maxHeight: CGFloat, minHeight: CGFloat, contentTopInset: CGFloat, contentBottomInset: CGFloat, webContentBottomOffset: CGFloat) {}
    func applyToolbarOffsets(top: CGFloat, bottom: CGFloat, resizesPage: Bool, refresh: Bool) { bottomOffset = bottom }
    func setTransitionTransform(_ transform: CGAffineTransform) { self.transform = transform }
    func setTransitionHidden(_ hidden: Bool) { isHidden = hidden }
}
final class BrowserChrome: UIView {
    var onToolbarExpansionRequested: (() -> Void)?
    var bottomOffset: CGFloat = 0
    func minimizedToolbarHeight(for mode: BrowserChromeMode) -> CGFloat { mode == .phone ? 34 : 24 }
    func topToolbarTransitionFrame(in view: UIView) -> CGRect { CGRect(x: 0, y: 0, width: 393, height: 56) }
    func bottomToolbarTransitionFrame(in view: UIView) -> CGRect { CGRect(x: 0, y: 0, width: 393, height: 90) }
    func setToolbarTransition(topOffset: CGFloat, bottomOffset: CGFloat, tabBarCollapseOffset: CGFloat, collapseProgress: CGFloat, textCenterProgress: CGFloat, isBottomToolbarCollapsed: Bool, animatesContent: Bool) { self.bottomOffset = bottomOffset }
    func setChromeTransition(topAlpha: CGFloat, bottomAlpha: CGFloat, bottomTranslationY: CGFloat) {}
}
final class TabBar: UIView {
    enum Visibility { case hidden, visible }
    var visibility = Visibility.hidden
    func setCollapseOffset(_ offset: CGFloat) {}
    func updateLayout() {}
}
protocol TabOverviewDataSource: AnyObject {
    var regularTabs: [Tab] { get }; var privateTabs: [Tab] { get }
    var selectedMode: TabMode { get }; var selectedIndex: Int { get }
    func selectTab(at index: Int, mode: TabMode)
    func captureThumbnail(forTabAt index: Int, mode: TabMode, completion: ((UIImage?) -> Void)?)
}
protocol TabOverviewPresentationContext: AnyObject {
    var containerView: UIView { get }; var contentView: ContentView { get }
    var browserChrome: BrowserChrome { get }; var tabBar: TabBar { get }; var browserLayout: BrowserLayout { get }
    func setSearchFocused(_ focused: Bool, animated: Bool); func endEditing()
    func updateLayout(animated: Bool, duration: TimeInterval)
    func prepareTabOverviewPresentation(); func tabOverviewDidFinishDismissal()
}
final class FixtureCollection {
    let allCollectionViews: [UICollectionView] = []
    func setPresentationVerticalOffset(_ offset: CGFloat) { precondition(offset == 0) }
    func restoreActiveTabCardCloseSwipeIfNeeded() {}
    func applyPresentationTransforms() {}
}
final class TabOverview: UIView {
    enum Mode { case regularTabs, privateTabs }
    weak var dataSource: TabOverviewDataSource?
    weak var presentationContext: TabOverviewPresentationContext?
    let collection = FixtureCollection()
    var previewAspectRatio: CGFloat = 1.2
    func setMode(_ mode: Mode, animated: Bool) { precondition(!animated) }
    func reloadTabs() {}
    func setActiveToolbarAlpha(_ alpha: CGFloat) { precondition(alpha == 1) }
}
final class FixtureTrayHost: TabOverviewDataSource, TabOverviewPresentationContext {
    var regularTabs = [Tab(), Tab()]; var privateTabs = [Tab()]
    var selectedMode = TabMode.regular; var selectedIndex = 0
    let containerView = UIView(); let contentView = ContentView(); let browserChrome = BrowserChrome(); let tabBar = TabBar()
    var browserLayout = BrowserLayout()
    var dismissals = 0
    var thumbnailCallback: ((UIImage?) -> Void)?
    func selectTab(at index: Int, mode: TabMode) { selectedIndex = index; selectedMode = mode }
    func captureThumbnail(forTabAt index: Int, mode: TabMode, completion: ((UIImage?) -> Void)?) { thumbnailCallback = completion }
    func setSearchFocused(_ focused: Bool, animated: Bool) { precondition(!animated) }
    func endEditing() {}
    func updateLayout(animated: Bool, duration: TimeInterval) { precondition(!animated && duration == 0) }
    func prepareTabOverviewPresentation() {}
    func tabOverviewDidFinishDismissal() { dismissals += 1 }
}

func checkInstantTray() {
    let host = FixtureTrayHost()
    let tray = TabOverview(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    host.containerView.addSubview(host.contentView)
    host.containerView.addSubview(tray)
    tray.dataSource = host; tray.presentationContext = host
    let presentation = TabOverviewPresentation(tabOverview: tray)
    UIView.setAnimationsEnabled(true) // Must pass WITHOUT the launch-time flag.
    for _ in 0..<16 {
        presentation.setPresented(true, animated: true)
        precondition(presentation.isPresented && !presentation.isTransitionRunning && !tray.isHidden)
        precondition(host.contentView.transform == .identity)
        let staleCapture = host.thumbnailCallback
        presentation.prepareDismissSelection(to: 1, mode: .regular, previewImage: nil)
        presentation.setPresented(false, animated: true)
        precondition(!presentation.isPresented && tray.isHidden && host.selectedIndex == 1)
        staleCapture?(nil)
        precondition(tray.isHidden, "Late thumbnail must never reopen tray")
        precondition((tray.layer.animationKeys() ?? []).isEmpty)
        precondition((host.contentView.layer.animationKeys() ?? []).isEmpty)
    }
    precondition(host.dismissals == 16)
    UIView.setAnimationsEnabled(false)
}

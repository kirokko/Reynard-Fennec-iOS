// Simulator-only layout host. Compiles the real homepage root/summary/theme/menu.
// Store/engine-backed sections below are fixed-height test doubles, NOT a browser
// integration test. No network, user data, signing credentials or Gecko required.
import UIKit

// Bookmark boundaries/cells are doubled; shortcut controller/layout are real.
struct BookmarkFolderSnapshot { let title = "Folder"; let guid = "fixture-folder" }
enum TabOpenDisposition { case currentTab }
enum HomepageContentMode {
    case embeddedNarrow, embeddedWide, embeddedExpanded, detachedNarrow, detachedWide
    var isDetached: Bool { self == .detachedNarrow || self == .detachedWide }
}
enum HomepageWallpaper { static var image: UIImage? { nil } }
enum Prefs {
    enum AppearanceSettings {
        static let scrollToHideToolbarEnabled = true
        static let showsFullWebsiteAddress = false
    }
    enum SearchSettings {
        static var searchEngine = SearchEngine.duckDuckGo
        static var customSearchTemplate = "https://example.invalid/?q=%s"
    }
    enum JITSettings { static var isJITEnabled = true }
    enum HomepageSettings {
        static var showsContinue = true
        static var showsProtection = true
        static let showsRecommendations = true
        static let showsWallpaper = false
        static let showsFavorites = true
        static let favoriteRowCount = 2
        static let showsFavoritesInPrivateBrowsing = false
        static let showsFrequentlyVisited = true
        static let showsFrequentlyVisitedInPrivateBrowsing = false
        static let showsRecentlyClosedTabs = true
    }
}
extension Notification.Name { static let homepageSettingsDidChange = Notification.Name("fixture.homepageSettings") }

class MockSection: UIViewController {
    init() { super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemGray6
        // Required nonzero contents exercise the former hidden-stack conflict.
        view.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }
    func setContentMode(_ mode: HomepageContentMode) {}
    func setPrivateBrowsing(_ value: Bool) {}
}
class MockRecommendation: MockSection, HomepageRecommendationViewController {
    weak var delegate: HomepageSectionDelegate?
}
typealias PerformanceRecommendationViewController = MockRecommendation
typealias UpdateAvailableViewController = MockRecommendation
typealias DonationRecommendationViewController = MockRecommendation
class FrequentlyVisitedSectionViewController: MockSection { weak var delegate: HomepageSectionDelegate? }
class RecentlyClosedTabsSectionViewController: MockSection { weak var delegate: HomepageSectionDelegate? }

struct DownloadStoreSummary { let aggregateProgress = 0.0; let activeCount = 0 }
final class ToolbarButton: UIButton {
    enum ButtonType { case newTab, tabOverview, library, sidebar }
    init(buttonType: ButtonType, target: AnyObject, action: Selector) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addTarget(target, action: action, for: .touchUpInside)
        if buttonType == .newTab { setImage(UIImage(systemName: "plus"), for: .normal) }
    }
    required init?(coder: NSCoder) { fatalError() }
}
final class Tab {
    let id = UUID()
    var isPrivate = false
    var url: String? = "https://example.invalid/" + String(repeating: "long-path-", count: 30)
    var title = "A real-tab layout fixture with a long title"
    var thumbnail: UIImage?
    var favicon: UIImage?
    let state = State()
    final class State { var selectionOrder = 1 }
}

@main
final class LayoutSmokeDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var root: HomepageRootViewController!
    private var tabs: [Tab] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIView.setAnimationsEnabled(false) // Match the shipped app's policy.
        root = HomepageRootViewController(bookmarkStore: BookmarkStore())
        root.browserTabs = { [weak self] in self?.tabs ?? [] }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = root
        self.window = window
        window.makeKeyAndVisible()
        // A layout runaway prevents this callback and the host's PASS marker.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.exercise() }
        return true
    }

    private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap { descendants($0) }
    }
    private func screenshot(_ view: UIView, name: String) {
        let image = UIGraphicsImageRenderer(bounds: view.bounds).image { context in view.layer.render(in: context.cgContext) }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name + ".png")
        try! image.pngData()!.write(to: url)
    }
    private func exercise() {
        func checkpoint(_ name: String) { FileHandle.standardError.write(Data(("CHECK: " + name + "\n").utf8)) }
        checkpoint("marked-text c -> cn and capture policy")
        checkInputAndPrivacy()
        window?.makeKeyAndVisible()
        checkpoint("anchored provider popup and original tab/private assets")
        screenshot(checkSearchPopup(), name: "search-provider-popup")
        checkpoint("real shortcuts before More")
        checkInitialShortcuts()
        checkpoint("no-JIT")
        checkNoJITController()
        checkpoint("fullscreen rotation and refresh")
        checkFullscreenRotationAndRefresh()
        checkpoint("first-entry count color and address-only display")
        checkCountColorAndAddressDisplay()
        checkpoint("top/bottom chrome and real scroll controller")
        checkToolbarScrollController()
        checkRealAddressBar()
        screenshot(checkFennecChrome(), name: "chrome-controls")
        screenshot(scrollChromeSample(), name: "chrome-scroll-states")
        checkpoint("download filters and homepage")
        checkDownloadFilters()
        checkInstantTray()
        let thumbnail = UIGraphicsImageRenderer(size: CGSize(width: 393, height: 1800)).image { context in
            UIColor.systemGray4.setFill(); context.fill(CGRect(x: 0, y: 0, width: 393, height: 1800))
        }
        let widths: [CGFloat] = [320, 393, 430, 844, 1024]
        for step in 0..<24 {
            tabs = step.isMultiple(of: 2) ? [] : [Tab()]
            tabs.first?.thumbnail = thumbnail
            root.view.frame = CGRect(x: 0, y: 0, width: widths[step % widths.count], height: 852)
            root.refreshBrowserSummary()
            root.setContentMode(step.isMultiple(of: 3) ? .detachedNarrow : .embeddedNarrow)
            root.view.layoutIfNeeded()
            if let summary = descendants(root.view).compactMap({ $0 as? FennecHomepageSummaryView }).first {
                precondition(summary.arrangedSubviews.count == (tabs.isEmpty ? 1 : 2), "Continue subtree must detach, not collapse a required height")
                let frame = summary.convert(summary.bounds, to: root.view)
                precondition(frame.minX >= 15.5 && frame.maxX <= root.view.bounds.width - 15.5, "Homepage must stay inside phone viewport")
                if let card = descendants(summary).first(where: { $0.accessibilityIdentifier == "homepage.resume" }) {
                    precondition(card.bounds.height >= 88 && card.bounds.height < 180, "Tall thumbnail must not stretch Continue card")
                }
            }
            if let more = descendants(root.view).compactMap({ $0 as? FennecClosureButton }).first(where: { $0.title(for: .normal) == "More" }) {
                more.onTap?()
                root.view.layoutIfNeeded()
                more.onTap?()
                root.view.layoutIfNeeded()
            }
        }
        precondition(!HomepageSection.allCases.contains(.frequentlyVisited))
        precondition(!root.children.contains { $0 is FrequentlyVisitedSectionViewController }, "No frequent-site controller/query on the homepage")
        for showProtection in [false, true] {
            for showContinue in [false, true] {
                Prefs.HomepageSettings.showsProtection = showProtection
                Prefs.HomepageSettings.showsContinue = showContinue
                tabs = [Tab()]
                root.refreshBrowserSummary()
                root.view.layoutIfNeeded()
                let summary = descendants(root.view).compactMap { $0 as? FennecHomepageSummaryView }.first!
                precondition(summary.arrangedSubviews.count == (showProtection ? 1 : 0) + (showContinue ? 1 : 0))
            }
        }
        // Restore the real window geometry after wide synthetic layout cases.
        root.view.frame = window!.bounds
        root.setContentMode(.embeddedNarrow)
        root.setPrivateBrowsing(true)
        root.view.layoutIfNeeded()
        precondition(root.overrideUserInterfaceStyle == .dark)
        var returnedToNormal = 0
        root.onPrivateTab = { returnedToNormal += 1 }
        let returnButton = descendants(root.view).compactMap { $0 as? FennecClosureButton }
            .first { $0.accessibilityIdentifier == "homepage.returnToNormal" }!
        precondition(returnButton.bounds.width >= 44 && returnButton.bounds.height >= 44)
        let returnFrame = returnButton.convert(returnButton.bounds, to: root.view)
        precondition(returnFrame.minY >= root.view.safeAreaInsets.top, "Private mode switch must stay below status bar")
        returnButton.sendActions(for: .touchUpInside)
        precondition(returnedToNormal == 1)
        precondition(descendants(root.view).contains { $0.accessibilityIdentifier == "homepage.private" })
        precondition(!descendants(root.view).compactMap { $0 as? UILabel }.contains { $0.text == "ieynec" })
        precondition(!descendants(root.view).compactMap { $0 as? UIButton }.contains { $0.title(for: .normal) == "More" })
        for label in descendants(root.view).compactMap({ $0 as? UILabel }) where !label.isHidden {
            let frame = label.convert(label.bounds, to: root.view)
            precondition(frame.minX >= 0 && frame.maxX <= root.view.bounds.width + 0.5, "Private copy must fit the physical phone viewport")
        }
        screenshot(window!, name: "private-homepage-layout")
        waitForScreenCapture("private") { [self] in
            root.setPrivateBrowsing(false)
            root.view.layoutIfNeeded()
            screenshot(window!, name: "homepage-layout")
            waitForScreenCapture("home") { [self] in
                let sample = realAddressBarScreen(bounds: window!.bounds)
                window!.addSubview(sample)
                window!.layoutIfNeeded()
                sample.layoutIfNeeded()
                waitForScreenCapture("addressbar") { [self] in
                    sample.removeFromSuperview()
                    checkCategories()
                    checkNavigation()
                }
            }
        }
    }

    private func checkDownloadFilters() {
        let entries: [BookmarkSortOrder.Values] = [
            (Date(timeIntervalSince1970: 3), "Beta", "https://b.invalid"),
            (Date(timeIntervalSince1970: 1), "Zulu", "https://a.invalid"),
            (Date(timeIntervalSince1970: 2), "alpha", "https://c.invalid"),
        ]
        let sorts: [(BookmarkSortOrder, [String])] = [
            (.date_added, ["Beta", "alpha", "Zulu"]),
            (.date_added_oldest, ["Zulu", "alpha", "Beta"]),
            (.name, ["alpha", "Beta", "Zulu"]),
            (.name_descending, ["Zulu", "Beta", "alpha"]),
            (.address, ["Zulu", "Beta", "alpha"]),
        ]
        for (order, expected) in sorts {
            precondition(entries.sorted { order.precedes($0, $1) }.map { $0.title } == expected)
        }
        precondition(BookmarkSortOrder(rawValue: "date_added") == .date_added)
        precondition(!BookmarkSortOrder.none.precedes(entries[0], entries[1]))
        let cases: [(String, String?, Bool)] = [
            ("photo.JPG", nil, true), ("photo.avif", "application/octet-stream", true),
            ("unnamed", " IMAGE/PNG ; charset=binary", true), ("photo.heic", nil, true),
            ("vector.svg", "image/svg+xml", true), ("file.zip", nil, false),
            ("video.mp4", "video/mp4", false), ("fake.jpg", "text/html", false),
            ("document.pdf", "application/pdf", false), ("unknown", nil, false),
        ]
        for (name, mime, image) in cases {
            precondition(FennecDownloadFilter.all.matches(fileName: name, mimeType: mime))
            precondition(FennecDownloadFilter.images.matches(fileName: name, mimeType: mime) == image)
            precondition(FennecDownloadFilter.other.matches(fileName: name, mimeType: mime) != image)
        }
        let chips = FennecDownloadFilterView(frame: CGRect(x: 0, y: 0, width: 288, height: 56))
        var changes = 0
        chips.onSelect = { _ in changes += 1 }
        chips.layoutIfNeeded()
        for button in chips.arrangedSubviews.compactMap({ $0 as? UIButton }) {
            precondition(button.frame.minX >= 0 && button.frame.maxX <= 288)
            precondition(button.bounds.height >= 44)
        }
        chips.select(.images)
        chips.select(.images)
        precondition(chips.selected == .images && changes == 1)
        chips.select(.other)
        precondition(changes == 2)
        precondition(chips.arrangedSubviews.compactMap { $0 as? UIButton }.filter { $0.accessibilityTraits.contains(.selected) }.count == 1)
        screenshot(chips, name: "download-categories")
    }

    private func checkCategories() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 180))
        container.backgroundColor = FennecTheme.surface
        let toolbar = TabOverviewTopToolbar(frame: .zero)
        container.addSubview(toolbar)
        container.addSubview(toolbar.floatingControls)
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: container.leadingAnchor), toolbar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: container.topAnchor), toolbar.heightAnchor.constraint(equalToConstant: 64),
            toolbar.floatingControls.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            toolbar.floatingControls.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            toolbar.floatingControls.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            toolbar.floatingControls.heightAnchor.constraint(equalToConstant: 56),
        ])
        toolbar.apply(tabCount: 2, visibleTabCount: 2, hasVisibleTab: true)
        container.layoutIfNeeded()
        let labels = descendants(toolbar).compactMap { $0 as? UILabel }
        precondition(labels.contains { $0.text == "2" && $0.bounds.width == 26 && $0.bounds.height == 20 })
        let privateButton = descendants(toolbar).compactMap { $0 as? UIButton }.first { $0.accessibilityLabel == "Private" }!
        precondition(privateButton.image(for: .normal)?.size == CGSize(width: 26, height: 26))
        screenshot(container, name: "tab-categories")
        toolbar.setMode(.privateTabs)
        precondition(toolbar.overrideUserInterfaceStyle == .dark)
        precondition(toolbar.floatingControls.overrideUserInterfaceStyle == .dark)
        toolbar.setMode(.regularTabs)
        precondition(toolbar.overrideUserInterfaceStyle == .unspecified)
    }

    private func activate(_ item: UIBarButtonItem) {
        precondition(UIApplication.shared.sendAction(item.action!, to: item.target, from: item, for: nil))
    }
    private func checkNavigation() {
        let suite = "local.ieynec.LayoutSmoke.groups"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = TabGroupStore(defaults: defaults)
        let regular = Tab(), privateTab = Tab()
        privateTab.isPrivate = true
        let page = FennecTabGroupsViewController(tabs: { [regular, privateTab] }, store: store) { _ in }
        var dismissCount = 0
        let navigation = ContentModalNavigationController(rootViewController: page) { dismissCount += 1 }
        navigation.modalPresentationStyle = .fullScreen
        root.present(navigation, animated: false) { [self] in
            navigation.view.layoutIfNeeded()
            precondition(page.navigationItem.leftBarButtonItem?.accessibilityIdentifier == "contentPage.close")
            screenshot(window!, name: "groups-empty-with-exit")
            activate(page.navigationItem.rightBarButtonItem!)
            let editor = navigation.topViewController as! UITableViewController
            editor.view.layoutIfNeeded()
            precondition(editor.tableView.numberOfRows(inSection: 1) == 1, "Private tabs must not enter group editor")
            let field = descendants(editor.view).compactMap { $0 as? UITextField }.first!
            field.text = "Fixture group"
            field.sendActions(for: .editingChanged)
            precondition(editor.navigationItem.rightBarButtonItem?.isEnabled == false)
            editor.tableView.delegate?.tableView?(editor.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
            precondition(editor.navigationItem.rightBarButtonItem?.isEnabled == true)
            activate(editor.navigationItem.rightBarButtonItem!)
            precondition(navigation.topViewController === page && store.groups.count == 1)
            precondition(store.groups[0].tabIDs == [regular.id])
            page.tableView(page.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
            precondition(navigation.topViewController is FennecOpenTabsController)
            _ = navigation.popViewController(animated: true)
            precondition(navigation.topViewController === page)
            navigation.view.layoutIfNeeded()
            screenshot(window!, name: "groups-saved-with-exit")
            waitForScreenCapture("groups") { [self] in
                activate(page.navigationItem.leftBarButtonItem!)
                verifyDismissal(count: { dismissCount })
            }
        }
    }
    private func waitForScreenCapture(_ stage: String, completion: @escaping () -> Void) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try! Data().write(to: directory.appendingPathComponent(stage + "-ready"))
        func poll(_ remaining: Int) {
            if FileManager.default.fileExists(atPath: directory.appendingPathComponent(stage + "-captured").path) { completion(); return }
            precondition(remaining > 0, "Host did not capture actual Simulator screen")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { poll(remaining - 1) }
        }
        // Cold CoreSimulator screenshot/launch IPC can take tens of seconds
        // on shared runners; the app stays responsive while the host catches up.
        poll(1200)
    }
    private func verifyDismissal(count: @escaping () -> Int, remaining: Int = 40) {
        if root.presentedViewController == nil && count() == 1 {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("layout-pass.txt")
            try! "PASS: viewport widths 320/393/430/844/1024, tall thumbnails, all Continue/protection toggle combinations, real private homepage without normal wordmark/More, no-JIT controller migration/child reporting; real group editor save/pop/root dismissal; instant tray even with UIKit animations enabled and late captures. Engine/store homepage sections remain test doubles.\n".write(to: url, atomically: true, encoding: .utf8)
            return
        }
        precondition(remaining > 0, "Root back must dismiss: presented=\(String(describing: root.presentedViewController)), callbacks=\(count())")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in verifyDismissal(count: count, remaining: remaining - 1) }
    }
}

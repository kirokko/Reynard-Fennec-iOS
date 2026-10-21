// Simulator-only layout host. Compiles the real homepage root/summary/theme/menu.
// Store/engine-backed sections below are fixed-height test doubles, NOT a browser
// integration test. No network, user data, signing credentials or Gecko required.
import UIKit

final class BookmarkStore {}
struct BookmarkFolderSnapshot { let title = "Folder" }
enum TabOpenDisposition { case currentTab }
enum HomepageContentMode {
    case embeddedNarrow, embeddedWide, embeddedExpanded, detachedNarrow, detachedWide
    var isDetached: Bool { self == .detachedNarrow || self == .detachedWide }
}
enum HomepageWallpaper { static var image: UIImage? { nil } }
enum Prefs {
    enum HomepageSettings {
        static let showsWallpaper = false
        static let showsFavorites = true
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
typealias PrivateBrowsingSectionViewController = MockSection
class FrequentlyVisitedSectionViewController: MockSection { weak var delegate: HomepageSectionDelegate? }
class RecentlyClosedTabsSectionViewController: MockSection { weak var delegate: HomepageSectionDelegate? }
protocol FavoritesSectionViewControllerDelegate: HomepageSectionDelegate {
    func favoritesSectionViewController(_ controller: FavoritesSectionViewController, didSelectFolder folder: BookmarkFolderSnapshot)
}
class FavoritesSectionViewController: MockSection {
    weak var delegate: FavoritesSectionViewControllerDelegate?
    init(bookmarkStore: BookmarkStore, folder: BookmarkFolderSnapshot?, showsSectionTitle: Bool) { super.init() }
    required init?(coder: NSCoder) { fatalError() }
}

struct DownloadStoreSummary { let aggregateProgress = 0.0; let activeCount = 0 }
final class ToolbarButton: UIButton {
    enum ButtonType { case newTab, tabOverview, library }
    init(buttonType: ButtonType, target: AnyObject, action: Selector) {
        super.init(frame: .zero)
        addTarget(target, action: action, for: .touchUpInside)
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
    private func exercise() {
        for step in 0..<24 {
            tabs = step.isMultiple(of: 2) ? [] : [Tab()]
            root.refreshBrowserSummary()
            root.setContentMode(step.isMultiple(of: 3) ? .detachedNarrow : .embeddedNarrow)
            root.view.layoutIfNeeded()
            if let summary = descendants(root.view).compactMap({ $0 as? FennecHomepageSummaryView }).first {
                precondition(summary.arrangedSubviews.count == (tabs.isEmpty ? 1 : 2), "Continue subtree must detach, not collapse a required height")
            }
            if let more = descendants(root.view).compactMap({ $0 as? FennecClosureButton }).first(where: { $0.title(for: .normal) == "More" }) {
                more.onTap?()
                root.view.layoutIfNeeded()
                more.onTap?()
                root.view.layoutIfNeeded()
            }
        }
        root.setPrivateBrowsing(true)
        root.view.layoutIfNeeded()
        root.setPrivateBrowsing(false)
        root.view.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("layout-pass.txt")
            try! "PASS: first frame, empty/populated Continue, repeated More expansion and privacy relayout; mocked store/engine sections only\n".write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// Instant native tab-tray presentation. No browser-owned zoom, spring,
// snapshot crossfade or delayed transition, regardless of UIKit's global flag.
import UIKit

final class TabOverviewPresentation {
    private enum UX {
        static let cardCollectionItemSpacing: CGFloat = 16
        static let phoneCardTargetWidth: CGFloat = 170
        static let padCardTargetWidth: CGFloat = 250
        static let minimumTabCardColumnCount = 2
    }
    enum State { case dismissed, presenting, presented, dismissing }
    private unowned let tabOverview: TabOverview
    private var dataSource: TabOverviewDataSource {
        guard let source = tabOverview.dataSource else { preconditionFailure("TabOverview requires a data source") }
        return source
    }
    private var context: TabOverviewPresentationContext {
        guard let context = tabOverview.presentationContext else { preconditionFailure("TabOverview requires a presentation context") }
        return context
    }
    private var pendingSelectionTabIndex: Int?
    private var pendingSelectionTabMode: TabMode?
    private var presentationToken = 0
    private(set) var state: State = .dismissed
    var isPresented: Bool { state == .presented }
    var isTransitionRunning: Bool { false }

    init(tabOverview: TabOverview) { self.tabOverview = tabOverview }

    func cardSize(in collectionView: UICollectionView) -> CGSize {
        let insets = collectionView.adjustedContentInset
        let availableWidth = max(0, collectionView.bounds.width - insets.left - insets.right)
        let targetWidth = context.browserLayout.chromeMode == .phone ? UX.phoneCardTargetWidth : UX.padCardTargetWidth
        let columns = max(UX.minimumTabCardColumnCount, Int((availableWidth + UX.cardCollectionItemSpacing) / (targetWidth + UX.cardCollectionItemSpacing)))
        let width = max(0, floor((availableWidth - CGFloat(columns - 1) * UX.cardCollectionItemSpacing) / CGFloat(columns)))
        return CGSize(width: width, height: floor(width * min(1.25, max(1, tabOverview.previewAspectRatio)) + 44))
    }

    func refreshForCurrentOrientation() {
        guard isPresented else { return }
        UIView.performWithoutAnimation {
            for collection in tabOverview.collection.allCollectionViews {
                collection.collectionViewLayout.invalidateLayout()
                collection.reloadData()
                collection.layoutIfNeeded()
            }
            tabOverview.collection.restoreActiveTabCardCloseSwipeIfNeeded()
            tabOverview.collection.applyPresentationTransforms()
        }
    }

    func prepareDismissSelection(to index: Int, mode: TabMode, previewImage: UIImage?) {
        pendingSelectionTabIndex = index
        pendingSelectionTabMode = mode
    }

    // `animated` is retained for existing callers, but deliberately ignored.
    func setPresented(_ visible: Bool, animated: Bool) {
        guard visible != isPresented else { return }
        presentationToken += 1
        let token = presentationToken
        UIView.performWithoutAnimation {
            // Do not scale the live page even while the tray covers it. It must
            // retain its real viewport for layout and thumbnail capture.
            context.contentView.setTransitionTransform(.identity)
            context.contentView.setTransitionHidden(false)
            tabOverview.collection.setPresentationVerticalOffset(0)
            tabOverview.alpha = 1
            tabOverview.setActiveToolbarAlpha(1)
            if visible {
                pendingSelectionTabIndex = nil
                pendingSelectionTabMode = nil
                tabOverview.setMode(dataSource.selectedMode == .private ? .privateTabs : .regularTabs, animated: false)
                context.prepareTabOverviewPresentation()
                context.endEditing()
                context.setSearchFocused(false, animated: false)
                tabOverview.reloadTabs()
                tabOverview.isHidden = false
                context.containerView.bringSubviewToFront(tabOverview)
                state = .presented
            } else {
                commitPendingTabSelection()
                tabOverview.isHidden = true
                state = .dismissed
            }
            context.browserChrome.setChromeTransition(topAlpha: 1, bottomAlpha: visible ? 0 : 1, bottomTranslationY: 0)
            context.updateLayout(animated: false, duration: 0)
            context.tabBar.updateLayout()
            if !visible { context.tabOverviewDidFinishDismissal() }
        }
        guard visible else { return }
        // Thumbnail work must never gate showing the tray or a subsequent exit.
        dataSource.captureThumbnail(forTabAt: dataSource.selectedIndex, mode: dataSource.selectedMode) { [weak self] _ in
            guard let self, self.presentationToken == token, self.isPresented else { return }
            UIView.performWithoutAnimation { self.tabOverview.reloadTabs() }
        }
    }

    // Existing scrolling delegate hook. There is no transition to finish.
    func finishPresentationForScrolling(in collectionView: UICollectionView) {}

    private func commitPendingTabSelection() {
        defer { pendingSelectionTabIndex = nil; pendingSelectionTabMode = nil }
        guard let target = pendingSelectionTabIndex, let mode = pendingSelectionTabMode else { return }
        let tabs = mode == .private ? dataSource.privateTabs : dataSource.regularTabs
        guard tabs.indices.contains(target) else { return }
        dataSource.selectTab(at: target, mode: mode)
    }
}

// Main menu actions reuse Reynard's original engine/coordinator operations. GPL-3.0.
import UIKit

extension BrowserViewController {
    func presentFennecMenu() {
        guard presentedViewController == nil else { return }
        toolbarController.reset()
        dismissAddressBarEditingAndOverlays()
        let tab = tabManager.selectedTab
        let value = tab?.url ?? ""
        let isHome = value.isEmpty || value.lowercased().hasPrefix("about:blank")
        let url = tab.flatMap { tabManager.shareableURL(for: $0) }
        let bar = browserChrome.addressBar
        let item: (String, String, @escaping () -> Void) -> FennecMenuItem = { title, symbol, action in
            FennecMenuItem(title: FennecTheme.text(title), symbol: symbol, action: action)
        }
        var groups: [FennecMenuViewController.Group] = []
        if !isHome && Prefs.AppearanceSettings.addressBarPosition == .top {
            groups.append(.navigation(fennecNavigationItems()))
        }
        var extensions = addressBarAddonItems(bar).map { entry in
            FennecMenuItem(title: entry.menuItem.title, symbol: "puzzlepiece.extension", action: { [weak self] in
                guard let self else { return }
                self.addressBar(self.browserChrome.addressBar, didSelectAddon: entry.menuItem)
            })
        }
        extensions.append(item("Manage extensions", "gearshape") { [weak self] in
            self?.presentContentModal(AddonsPreferencesViewController())
        })
        let extensionItem = FennecMenuItem(title: FennecTheme.text("Extensions"), symbol: "puzzlepiece.extension", children: extensions)
        if !isHome {
            var more: [FennecMenuItem] = []
            if tab?.state.readerMode.isReaderable == true || tab?.state.readerMode.isActive == true {
                more.append(item("Reader", "doc.text") { [weak self] in
                    guard let self else { return }
                    self.addressBarDidRequestReader(self.browserChrome.addressBar)
                })
            }
            more.append(item("Page zoom", "textformat.size") { [weak self] in
                guard let self else { return }
                self.addressBarDidRequestPageZoom(self.browserChrome.addressBar)
            })
            more.append(item("Add to shortcuts", "pin") { [weak self] in self?.presentBookmarkEditor(addToFavorites: true) })
            more.append(item("Site settings", "shield") { [weak self] in
                guard let self else { return }
                self.addressBarDidRequestWebsiteSettings(self.browserChrome.addressBar)
            })
            more.append(item("Print", "printer") { [weak self] in
                guard let tab = self?.tabManager.selectedTab else { return }
                PagePrintActivity(session: tab.session, jobName: tab.title).perform()
            })
            more.append(item("Hide toolbar", "arrow.down.right.and.arrow.up.left") { [weak self] in
                self?.toolbarController.collapseUntilReset()
            })
            let isBookmarked = url.map { BookmarkStore.shared.bookmark(savedFor: $0) != nil } ?? false
            let isDesktop = tab.flatMap { tab in tab.url.flatMap { sessionManager.isDesktopMode(for: $0, tabID: tab.id) } } ?? false
            groups.append(.rows([
                item(isBookmarked ? "Edit bookmark" : "Bookmark this page", "bookmark") { [weak self] in self?.presentBookmarkEditor(addToFavorites: false) },
                item("Find in page", "magnifyingglass") { [weak self] in
                    guard let self else { return }
                    self.addressBarDidRequestFindInPage(self.browserChrome.addressBar)
                },
                FennecMenuItem(title: FennecTheme.text("Desktop site"), symbol: "desktopcomputer", badge: FennecTheme.text(isDesktop ? "On" : "Off"), action: { [weak self] in
                    guard let self else { return }
                    self.addressBarDidRequestWebsiteModeChange(self.browserChrome.addressBar)
                }),
                extensionItem,
                FennecMenuItem(title: FennecTheme.text("More"), symbol: "ellipsis", children: more),
            ]))
        } else {
            groups.append(.rows([extensionItem]))
        }
        groups.append(.tiles([
            item("Bookmarks", "bookmark") { [weak self] in self?.presentLibrary(initialSection: .bookmarks) },
            item("History", "clock") { [weak self] in self?.presentLibrary(initialSection: .history) },
            item("Downloads", "arrow.down.circle") { [weak self] in self?.presentLibrary(initialSection: .downloads) },
        ]))
        var settings: [FennecMenuItem] = []
        if isHome {
            settings.append(item("Customize homepage", "house") { [weak self] in self?.presentContentModal(HomepagePreferencesViewController()) })
        }
        settings.append(item("Settings", "gearshape") { [weak self] in self?.presentLibrary(initialSection: .settings) })
        groups.append(.rows(settings))
        if !isHome && Prefs.AppearanceSettings.addressBarPosition == .bottom {
            groups.append(.navigation(fennecNavigationItems()))
        }
        present(FennecMenuViewController(groups: groups), animated: true)
    }

    private func fennecNavigationItems() -> [FennecMenuItem] {
        let loading = tabManager.selectedTab?.state.loadingState.isLoading == true
        return [
            FennecMenuItem(title: FennecTheme.text("Back"), symbol: "arrow.backward", enabled: tabManager.canGoBack,
                action: { [weak self] in self?.browserChrome.onBack?() },
                longPressAction: { [weak self] in self?.presentFennecNavigationHistory(.back) }),
            FennecMenuItem(title: FennecTheme.text("Forward"), symbol: "arrow.forward", enabled: tabManager.selectedTab?.state.navigationState.canGoForward == true,
                action: { [weak self] in self?.browserChrome.onForward?() },
                longPressAction: { [weak self] in self?.presentFennecNavigationHistory(.forward) }),
            FennecMenuItem(title: FennecTheme.text("Share"), symbol: "square.and.arrow.up", enabled: tabManager.selectedTab.flatMap { tabManager.shareableURL(for: $0) } != nil,
                action: { [weak self] in self?.browserChrome.onShare?() }),
            FennecMenuItem(title: FennecTheme.text(loading ? "Stop" : "Refresh"), symbol: loading ? "xmark" : "arrow.clockwise",
                action: { [weak self] in
                    guard let self else { return }
                    self.addressBarDidRequestReloadOrStop(self.browserChrome.addressBar)
                }, longPressAction: { [weak self] in
                    guard let self else { return }
                    self.addressBarDidRequestHardReload(self.browserChrome.addressBar)
                }),
        ]
    }

    private func presentFennecNavigationHistory(_ direction: ToolbarButtonMenus.NavigationDirection) {
        guard let tab = tabManager.selectedTab else { return }
        let snapshot = tabManager.navigationHistory(for: tab)
        let history: [NavigationHistoryStore.HistoryItem]
        switch direction { case .back: history = snapshot.backHistory; case .forward: history = snapshot.forwardHistory }
        let items = history.enumerated().map { index, entry in
            FennecMenuItem(title: entry.title.isEmpty ? entry.url : entry.title, symbol: "clock", action: { [weak self] in
                guard let self else { return }
                self.toolbarController.reset(preserveManualCollapse: true)
                self.prepareThumbnailForNavigation()
                switch direction { case .back: self.tabManager.goBack(to: index); case .forward: self.tabManager.goForward(to: index) }
            })
        }
        guard !items.isEmpty else { return }
        present(FennecMenuViewController(groups: [.rows(items)]), animated: true)
    }
}

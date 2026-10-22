//
//  BrowserViewController+TabPresentation.swift
//  Reynard
//
//  Created by Minh Ton on 16/6/26.
//

import UIKit

extension BrowserViewController: TabBarDataSource, TabOverviewDataSource, TabOverviewDelegate, TabOverviewPresentationContext {
    // MARK: - Shared Tab Data
    
    var tabs: [Tab] {
        return tabManager.activeTabs
    }
    
    var selectedTabID: UUID? {
        return tabManager.selectedTab?.id
    }
    
    var selectedMode: TabMode {
        return tabManager.selectedTabMode
    }
    
    func selectTab(at index: Int, mode: TabMode) {
        browserChrome.dismissActionBar(animated: false)
        toolbarController.reset()
        if mode == tabManager.selectedTabMode,
           index != tabManager.selectedTabIndex {
            if tabOverview.isPresented || tabOverview.isTransitionRunning {
                tabManager.selectTab(at: index, mode: mode)
                return
            }
            
            // Cache the outgoing preview, but never delay selection on a
            // homepage snapshot callback (or let an old callback select a tab).
            captureThumbnail(forTabAt: tabManager.selectedTabIndex, mode: tabManager.selectedTabMode)
            tabManager.selectTab(at: index, mode: mode)
            return
        }
        tabManager.selectTab(at: index, mode: mode)
    }
    
    func closeTab(at index: Int, mode: TabMode) {
        toolbarController.reset()
        let isTabOverviewActive = tabOverview.isPresented || tabOverview.isTransitionRunning
        if isTabOverviewActive,
           tabOverview.mode == .regularTabs,
           mode == .regular,
           tabManager.regularTabs.count == 1 {
            tabOverview.prepareNextTabChangesWithoutAnimation()
            tabManager.removeTab(at: index, mode: mode, behavior: .none)
            tabOverview.prepareNextTabChangesWithoutAnimation()
            createTabFromOverview(mode: .regular)
            return
        }
        
        let behavior: TabRemovalBehavior = isTabOverviewActive ? .none : .recent
        tabManager.removeTab(at: index, mode: mode, behavior: behavior)
    }
    
    func moveTab(from sourceIndex: Int, to destinationIndex: Int, mode: TabMode) {
        toolbarController.reset()
        tabManager.moveTab(from: sourceIndex, to: destinationIndex, mode: mode)
    }
    
    // MARK: - TabOverviewDataSource
    
    var regularTabs: [Tab] {
        return tabManager.regularTabs
    }
    
    var privateTabs: [Tab] {
        return tabManager.privateTabs
    }
    
    var selectedIndex: Int {
        return tabManager.selectedTabIndex
    }
    
    // MARK: - TabOverviewDelegate
    
    func tabOverviewDidRequestClearTabs(_ tabOverview: TabOverview) {
        clearTabsForCurrentOverviewMode()
    }
    
    func tabOverviewDidRequestClearTabsOlderThan(_ tabOverview: TabOverview, age: TabOverviewClearTabsMenu.Age) {
        clearTabsOlderThan(age)
    }
    
    func tabOverviewDidRequestNewTab(_ tabOverview: TabOverview) {
        createNewTab()
    }
    
    func tabOverviewDidRequestDone(_ tabOverview: TabOverview) {
        dismissTabOverviewSelectingMostRecentTabIfNeeded()
    }
    
    func tabOverviewDidRequestDismiss(_ tabOverview: TabOverview, animated: Bool) {
        setTabOverviewVisible(false, animated: animated)
    }
    
    func tabOverviewDidRequestClearPendingTabExpansion(_ tabOverview: TabOverview) {
        tabBar.setPendingExpansion(at: nil)
    }
    
    // MARK: - TabOverviewPresentationContext
    
    var containerView: UIView {
        return view
    }
    
    func setSearchFocused(_ focused: Bool, animated: Bool) {
        searchOverlayCoordinator.setFocused(focused, animated: animated)
    }
    
    func endEditing() {
        view.endEditing(true)
    }
    
    func updateLayout(animated: Bool, duration: TimeInterval) {
        updateBrowserLayout(animated: animated, duration: duration)
    }
    
    func prepareTabOverviewPresentation() {
        homepageOverlayCoordinator.updatePresentation(animated: false)
        view.layoutIfNeeded()
    }
    
    func tabOverviewDidFinishDismissal() {
        toolbarController.unlock(for: .tabOverview)
        requestHomepageAddressBarFocus()
        requestContentKeyboardFocus()
    }
    
    func setTabOverviewVisible(_ visible: Bool, animated: Bool) {
        if visible {
            toolbarController.lock(for: .tabOverview)
            if browserChrome.performAfterTransition({ [weak self] in
                self?.setTabOverviewVisible(true, animated: animated)
            }) {
                return
            }
            
            browserChrome.dismissActionBar(animated: false)
            dismissAddressBarEditingAndOverlays()
            contentView.resetFocusedInputRelocation()
            homepageOverlayCoordinator.tabOverviewWillPresent()
            searchOverlayCoordinator.tabOverviewWillPresent()
        }
        tabOverview.setPresented(visible, animated: false)
        if !visible {
            homepageOverlayCoordinator.updatePresentation(animated: false)
        }
    }
    
    // MARK: - Tab Overview Actions

    func presentFennecTrayMenu() {
        guard presentedViewController == nil else { return }
        let isPrivate = tabOverview.mode == .privateTabs
        let tabs = isPrivate ? tabManager.privateTabs : tabManager.regularTabs
        var items: [FennecMenuItem] = []
        if !isPrivate {
            let hasClosed = !TabManagementStore.shared.recentlyClosedTabs(limit: 1).isEmpty
            items.append(FennecMenuItem(title: FennecTheme.text("Recently closed tabs"), symbol: "clock.arrow.circlepath", enabled: hasClosed, action: { [weak self] in
                self?.presentRecentlyClosedTrayMenu()
            }))
        }
        items.append(FennecMenuItem(title: FennecTheme.text("Tab settings"), symbol: "gearshape", action: { [weak self] in
            self?.presentContentModal(FennecSettingsListController(title: "Tabs", entries: [
                ("New tab", { NewTabPreferencesViewController() }),
                ("Open links in new tabs", { OpenLinksInNewTabsPreferencesViewController() }),
            ]))
        }))
        items.append(FennecMenuItem(title: FennecTheme.text("Close all tabs"), symbol: "trash", enabled: !tabs.isEmpty, action: { [weak self] in
            self?.tabOverview.topToolbar.onClearTabs?()
        }))
        let ageItems = TabOverviewClearTabsMenu.Age.allCases.map { age in
            FennecMenuItem(title: age.title, symbol: "clock", enabled: !tabs.isEmpty, action: { [weak self] in
                self?.tabOverview.topToolbar.onClearTabsOlderThan?(age)
            })
        }
        items.append(FennecMenuItem(title: FennecTheme.text("More"), symbol: "ellipsis", children: ageItems))
        items.append(FennecMenuItem(title: FennecTheme.text("Back to browsing"), symbol: "arrow.backward", enabled: !tabs.isEmpty, action: { [weak self] in
            self?.tabOverview.topToolbar.onDone?()
        }))
        let menu = FennecMenuViewController(groups: [.rows(items)])
        menu.overrideUserInterfaceStyle = isPrivate ? .dark : .unspecified
        present(menu, animated: false)
    }

    func presentRecentlyClosedTrayMenu() {
        guard tabOverview.mode == .regularTabs else { return }
        let entries = TabManagementStore.shared.recentlyClosedTabs(limit: Prefs.HomepageSettings.recentlyClosedTabLimit)
        let items = entries.map { entry in
            FennecMenuItem(title: entry.title.isEmpty ? NSLocalizedString("Untitled", comment: "") : entry.title, symbol: "clock", action: { [weak self] in
                guard let self, self.tabManager.restoreRecentlyClosedTab(id: entry.id) else { return }
                self.tabOverview.prepareDismissSelectionForCurrentTab()
                self.setTabOverviewVisible(false, animated: false)
            })
        }
        guard !items.isEmpty else { return }
        present(FennecMenuViewController(groups: [.rows(items)]), animated: false)
    }

    func presentTabGroups() {
        let page = FennecTabGroupsViewController(tabs: { [weak self] in self?.tabManager.regularTabs ?? [] }) { [weak self] id in
            self?.selectTabFromTrayPage(id: id, mode: .regular)
        }
        presentContentModal(page)
    }

    func presentTabSearch() {
        let mode = tabOverview.mode.tabMode
        let page = FennecOpenTabsController(tabs: { [weak self] in
            guard let self else { return [] }
            return mode == .private ? self.tabManager.privateTabs : self.tabManager.regularTabs
        }) { [weak self] id in self?.selectTabFromTrayPage(id: id, mode: mode) }
        presentContentModal(page)
    }

    private func selectTabFromTrayPage(id: UUID, mode: TabMode) {
        dismiss(animated: false) { [weak self] in
            guard let self else { return }
            let tabs = mode == .private ? self.tabManager.privateTabs : self.tabManager.regularTabs
            guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
            self.tabOverview.prepareDismissSelection(to: index, mode: mode, previewImage: tabs[index].thumbnail)
            self.setTabOverviewVisible(false, animated: false)
        }
    }
    
    private func dismissTabOverviewSelectingMostRecentTabIfNeeded() {
        if tabOverview.isPresented {
            let mode = tabOverview.mode.tabMode
            let tabs = mode == .private ? tabManager.privateTabs : tabManager.regularTabs
            guard !tabs.isEmpty else {
                return
            }
            
            if tabManager.selectedTabMode != mode,
               let tabIndex = tabs.indices.max(by: {
                   tabs[$0].state.selectionOrder < tabs[$1].state.selectionOrder
               }) {
                tabManager.selectTab(at: tabIndex, mode: mode)
            }
            scrollTabOverviewToTab(at: tabManager.selectedTabIndex)
            tabOverview.prepareDismissSelectionForCurrentTab()
        }
        setTabOverviewVisible(false, animated: true)
    }
    
    func scrollTabOverviewToTab(at index: Int) {
        guard let itemIndex = tabOverview.itemIndex(forTabAt: index) else {
            return
        }
        
        let collectionView = tabOverview.currentCollectionView()
        collectionView.scrollToItem(
            at: IndexPath(item: itemIndex, section: 0),
            at: .centeredVertically,
            animated: false
        )
        collectionView.layoutIfNeeded()
    }
    
    private func clearTabsForCurrentOverviewMode() {
        tabBar.setPendingExpansion(at: nil)
        
        guard tabOverview.isPresented else {
            tabManager.removeAllTabs(mode: nil)
            return
        }
        
        let mode = tabOverview.mode.tabMode
        guard mode == .regular else {
            tabManager.removeAllTabs(mode: mode)
            return
        }
        
        if !tabManager.regularTabs.isEmpty {
            tabOverview.prepareNextTabChangesWithoutAnimation()
        }
        tabManager.removeAllTabs(mode: .regular)
        tabOverview.prepareNextTabChangesWithoutAnimation()
        createTabFromOverview(mode: .regular)
    }
    
    private func clearTabsOlderThan(_ age: TabOverviewClearTabsMenu.Age) {
        guard let cutoffDate = age.cutoffDate() else {
            return
        }
        
        tabBar.setPendingExpansion(at: nil)
        let mode = tabOverview.mode.tabMode
        let tabs = mode == .private ? tabManager.privateTabs : tabManager.regularTabs
        let oldTabIDs = TabManagementStore.shared.tabIDs(olderThan: cutoffDate, isPrivate: mode == .private)
        let oldTabIndices = tabs.indices.filter { oldTabIDs.contains(tabs[$0].id) }
        guard !oldTabIndices.isEmpty else {
            return
        }
        
        if oldTabIndices.count == tabs.count {
            clearTabsForCurrentOverviewMode()
            return
        }
        
        oldTabIndices.reversed().forEach { index in
            tabManager.removeTab(at: index, mode: mode, behavior: .none)
        }
    }
    
    func createTabFromOverview(mode: TabMode) {
        homepageOverlayCoordinator.prepareHomepageForNewTab(mode: mode)
        let createdIndex = tabManager.createTab(
            selecting: true,
            target: .end,
            mode: mode
        )
        
        switch Prefs.NewTabSettings.newTabDisplayOption {
        case .homepage, .blankPage:
            let createdTabs = mode == .private ? tabManager.privateTabs : tabManager.regularTabs
            let createdTabID = createdTabs[createdIndex].id
            
            captureThumbnail(forTabAt: createdIndex, mode: mode) { [weak self] previewImage in
                guard let self,
                      (mode == .private ? self.tabManager.privateTabs : self.tabManager.regularTabs)[safe: createdIndex]?.id == createdTabID else {
                    return
                }
                
                self.tabOverview.prepareDismissSelection(to: createdIndex, mode: mode, previewImage: previewImage)
                self.scrollTabOverviewToTab(at: createdIndex)
                self.tabBar.setPendingExpansion(at: createdIndex)
                self.setTabOverviewVisible(false, animated: true)
            }
        case .customURL:
            applyNewTabDisplayOption(toTabAt: createdIndex)
            tabOverview.prepareDismissSelection(to: createdIndex, mode: mode, previewImage: nil)
            scrollTabOverviewToTab(at: createdIndex)
            tabBar.setPendingExpansion(at: createdIndex)
            setTabOverviewVisible(false, animated: true)
        }
    }
}

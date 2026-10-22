//
//  HomepageRootViewController.swift
//  Reynard
//
//  Created by Minh Ton on 21/6/26.
//

import UIKit

protocol HomepageRootViewControllerDelegate: AnyObject {
    func homepageRootViewController(_ controller: HomepageRootViewController, didRequestOpenURL url: URL, disposition: TabOpenDisposition)
    func homepageRootViewController(
        _ controller: HomepageRootViewController,
        didRequestShareURL url: URL,
        sourceView: UIView
    )
    func homepageRootViewController(_ controller: HomepageRootViewController, didRequestHideFromSuggestions siteID: Int64)
    func homepageRootViewController(_ controller: HomepageRootViewController, didSelectRecentlyClosedTab id: UUID)
    func homepageRootViewControllerDidSelectFolder(_ folder: BookmarkFolderSnapshot)
    func homepageRootViewControllerDidSelectSettings(_ controller: HomepageRootViewController)
    func homepageRootViewControllerDidStartScrolling()
}

protocol HomepageRecommendationViewController: UIViewController {
    func setContentMode(_ contentMode: HomepageContentMode)
    func setPrivateBrowsing(_ isPrivateBrowsing: Bool)
}

final class HomepageRootViewController: UIViewController {
    private enum UX {
        static let topInset: CGFloat = 24
        static let folderTopInset: CGFloat = 20
        static let horizontalInset: CGFloat = 16
        static let bottomInset: CGFloat = 24
        static let embeddedMaximumWidth: CGFloat = 800
        static let detachedMaximumWidth: CGFloat = 700
    }
    
    weak var delegate: HomepageRootViewControllerDelegate?
    
    private let privateBackground = FennecPrivateBackgroundView(frame: .zero)
    private let bookmarkStore: BookmarkStore
    private let folder: BookmarkFolderSnapshot?
    private let sections: [HomepageSection]
    private var isPrivateBrowsing: Bool
    private var contentMode: HomepageContentMode = .embeddedNarrow
    private var visibleContentInsets: UIEdgeInsets = .zero
    private var sectionViewControllers: [HomepageSection: UIViewController] = [:]
    private var sectionStackWidthConstraint: NSLayoutConstraint?
    private var showsMoreHomepageContent = false
    var browserTabs: () -> [Tab] = { [] }
    var blockedTrackerCount: () -> Int = { 0 }
    var onResumeTab: ((UUID) -> Void)?
    var onPrivateTab: (() -> Void)?
    var onProtection: (() -> Void)?
    private var summaryView: FennecHomepageSummaryView?

    func refreshBrowserSummary() {
        guard isViewLoaded, !isPrivateBrowsing else { return }
        summaryView?.refresh(
            tabs: Prefs.HomepageSettings.showsContinue ? browserTabs() : [],
            blockedCount: Prefs.HomepageSettings.showsProtection ? blockedTrackerCount() : 0
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshBrowserSummary()
    }
    
    private let wallpaperImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        scrollView.keyboardDismissMode = .none
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let sectionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    init(
        bookmarkStore: BookmarkStore,
        folder: BookmarkFolderSnapshot? = nil,
        sections: [HomepageSection] = HomepageSection.allCases,
        isPrivateBrowsing: Bool = false
    ) {
        self.bookmarkStore = bookmarkStore
        self.folder = folder
        self.sections = sections
        self.isPrivateBrowsing = isPrivateBrowsing
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = folder?.title
        observeHomepageSettings()
        configureScrollView()
        configureHierarchy()
        configureConstraints()
        configureSections()
    }
    
    // MARK: - Public API
    
    func setContentMode(_ contentMode: HomepageContentMode) {
        guard self.contentMode != contentMode else {
            return
        }
        
        self.contentMode = contentMode
        recommendationViewControllers.forEach { viewController in
            viewController.setContentMode(contentMode)
        }
        privateBrowsingSectionViewController?.setContentMode(contentMode)
        favoritesSectionViewController?.setContentMode(contentMode)
        frequentlyVisitedSectionViewController?.setContentMode(contentMode)
        recentlyClosedTabsSectionViewController?.setContentMode(contentMode)
        if isViewLoaded {
            updateWallpaper()
            updateScrollInsets()
        }
        updateSectionStackWidth()
    }
    
    func setPrivateBrowsing(_ isPrivateBrowsing: Bool) {
        guard self.isPrivateBrowsing != isPrivateBrowsing else {
            return
        }
        
        self.isPrivateBrowsing = isPrivateBrowsing
        guard isViewLoaded else {
            return
        }
        
        if folder == nil {
            reloadSections()
            return
        }
        
        recommendationViewControllers.forEach { viewController in
            viewController.setPrivateBrowsing(isPrivateBrowsing)
        }
        privateBrowsingSectionViewController?.setPrivateBrowsing(isPrivateBrowsing)
    }
    
    func setVisibleContentInsets(_ visibleContentInsets: UIEdgeInsets) {
        guard self.visibleContentInsets != visibleContentInsets else {
            return
        }
        
        self.visibleContentInsets = visibleContentInsets
        guard isViewLoaded else {
            return
        }
        updateScrollInsets()
    }
    
    // MARK: - Configuration
    
    private func configureScrollView() {
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        updateScrollInsets()
    }
    
    private func updateScrollInsets() {
        let isAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top
        let effectiveVisibleContentInsets = contentMode.isDetached ? .zero : visibleContentInsets
        let contentInset = UIEdgeInsets(
            top: effectiveVisibleContentInsets.top + (folder == nil ? UX.topInset : UX.folderTopInset),
            left: 0,
            bottom: effectiveVisibleContentInsets.bottom + UX.bottomInset,
            right: 0
        )
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        if isAtTop {
            scrollView.contentOffset.y = -contentInset.top
        }
    }
    
    private func configureHierarchy() {
        privateBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(privateBackground)
        NSLayoutConstraint.activate([
            privateBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            privateBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            privateBackground.topAnchor.constraint(equalTo: view.topAnchor),
            privateBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        view.addSubview(wallpaperImageView)
        view.addSubview(scrollView)
        scrollView.addSubview(sectionStackView)
        sectionStackView.accessibilityIdentifier = "homepage.sections"
        updateWallpaper()
    }
    
    private func configureConstraints() {
        // Resolve width in Auto Layout, not by rewriting a required width from
        // viewDidLayoutSubviews. The old 1pt initial width was incompatible with
        // the new card's contents and risked repeated first-frame invalidation.
        let widthConstraint = sectionStackView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.embeddedMaximumWidth)
        let preferredWidth = sectionStackView.widthAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(UX.horizontalInset * 2))
        preferredWidth.priority = UILayoutPriority(999)
        sectionStackWidthConstraint = widthConstraint
        
        NSLayoutConstraint.activate([
            wallpaperImageView.topAnchor.constraint(equalTo: view.topAnchor),
            wallpaperImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wallpaperImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            sectionStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            sectionStackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            sectionStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            widthConstraint, preferredWidth,
            sectionStackView.widthAnchor.constraint(lessThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(UX.horizontalInset * 2)),
        ])
    }
    
    private func appendSection(_ section: HomepageSection, to stack: UIStackView) {
        let controller = makeSectionViewController(for: section)
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(controller.view)
        controller.didMove(toParent: self)
        sectionViewControllers[section] = controller
    }

    private func configureSections() {
        sectionStackView.arrangedSubviews.forEach { sectionStackView.removeArrangedSubview($0); $0.removeFromSuperview() }
        summaryView = nil
        sectionStackView.spacing = 28
        overrideUserInterfaceStyle = isPrivateBrowsing ? .dark : .unspecified
        privateBackground.isHidden = !isPrivateBrowsing
        view.backgroundColor = isPrivateBrowsing ? FennecTheme.privateSurface : FennecTheme.surface
        let extras = UIStackView()
        extras.axis = .vertical
        extras.spacing = 16
        // A collapsed stack must be detached, not hidden with a required 0pt
        // UISV-hiding constraint against fixed-height child sections.
        let extraSections = displayedSections.filter {
            folder == nil && ($0 == .recentlyClosedTabs || $0 == .recommendation(.donation))
        }
        if folder == nil && !isPrivateBrowsing {
            let header = UIView()
            let brand = UILabel()
            brand.text = "ieynec"
            brand.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: .systemFont(ofSize: 24, weight: .semibold))
            brand.adjustsFontForContentSizeCategory = true
            brand.adjustsFontSizeToFitWidth = true
            brand.minimumScaleFactor = 0.5
            brand.textColor = FennecTheme.ink
            let logo = UIImageView(image: UIImage(named: "ieynec-logo"))
            logo.contentMode = .scaleAspectFit
            logo.widthAnchor.constraint(equalToConstant: 40).isActive = true
            logo.heightAnchor.constraint(equalToConstant: 40).isActive = true
            let wordmark = UIStackView(arrangedSubviews: [logo, brand])
            wordmark.axis = .horizontal
            wordmark.alignment = .center
            wordmark.spacing = 12
            wordmark.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(wordmark)
            let privacy = FennecClosureButton(frame: .zero)
            privacy.translatesAutoresizingMaskIntoConstraints = false
            privacy.setImage(FennecTheme.privateBrowsingImage, for: .normal)
            privacy.imageView?.contentMode = .scaleAspectFit
            privacy.tintColor = FennecTheme.ink
            privacy.accessibilityLabel = FennecTheme.text("New private tab")
            privacy.onTap = { [weak self] in self?.onPrivateTab?() }
            privacy.isHidden = isPrivateBrowsing
            header.addSubview(privacy)
            NSLayoutConstraint.activate([
                header.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
                wordmark.centerXAnchor.constraint(equalTo: header.centerXAnchor),
                wordmark.centerYAnchor.constraint(equalTo: header.centerYAnchor, constant: 12),
                wordmark.leadingAnchor.constraint(greaterThanOrEqualTo: header.leadingAnchor),
                wordmark.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor),
                wordmark.topAnchor.constraint(greaterThanOrEqualTo: header.topAnchor, constant: 44),
                wordmark.bottomAnchor.constraint(lessThanOrEqualTo: header.bottomAnchor, constant: -12),
                privacy.topAnchor.constraint(equalTo: header.topAnchor),
                privacy.trailingAnchor.constraint(equalTo: header.trailingAnchor),
                privacy.widthAnchor.constraint(equalToConstant: 44),
                privacy.heightAnchor.constraint(equalToConstant: 44),
            ])
            sectionStackView.addArrangedSubview(header)
        }
        if folder == nil && isPrivateBrowsing {
            // Match Android's persistent top-right mode switch, including the
            // empty private homepage. Never require opening the tab tray to exit.
            let header = UIView()
            let normal = FennecClosureButton(frame: .zero)
            normal.translatesAutoresizingMaskIntoConstraints = false
            normal.setImage(FennecTheme.privateBrowsingImage, for: .normal)
            normal.tintColor = FennecTheme.privateSurface
            normal.backgroundColor = UIColor(white: 0.96, alpha: 1)
            normal.layer.cornerRadius = 22
            normal.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            normal.imageView?.contentMode = .scaleAspectFit
            normal.accessibilityLabel = FennecTheme.text("Normal tabs")
            normal.accessibilityIdentifier = "homepage.returnToNormal"
            normal.onTap = { [weak self] in self?.onPrivateTab?() }
            header.addSubview(normal)
            NSLayoutConstraint.activate([
                header.heightAnchor.constraint(equalToConstant: 44),
                normal.topAnchor.constraint(equalTo: header.topAnchor),
                normal.trailingAnchor.constraint(equalTo: header.trailingAnchor),
                normal.widthAnchor.constraint(equalToConstant: 44),
                normal.heightAnchor.constraint(equalToConstant: 44),
            ])
            sectionStackView.addArrangedSubview(header)
        }
        for section in displayedSections where !extraSections.contains(section) {
            appendSection(section, to: sectionStackView)
        }
        if folder == nil && !isPrivateBrowsing {
            let summary = FennecHomepageSummaryView(frame: .zero)
            summary.onResume = { [weak self] id in self?.onResumeTab?(id) }
            summary.onProtection = { [weak self] in self?.onProtection?() }
            summaryView = summary
            sectionStackView.addArrangedSubview(summary)
            refreshBrowserSummary()
        }
        if !extraSections.isEmpty {
            let more = FennecClosureButton(frame: .zero)
            more.contentHorizontalAlignment = .leading
            more.setTitle(FennecTheme.text("More"), for: .normal)
            more.setTitleColor(FennecTheme.accent, for: .normal)
            more.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            more.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            more.accessibilityValue = FennecTheme.text(showsMoreHomepageContent ? "Expanded" : "Collapsed")
            more.onTap = { [weak self, weak more] in
                guard let self else { return }
                self.showsMoreHomepageContent.toggle()
                if self.showsMoreHomepageContent {
                    if extras.arrangedSubviews.isEmpty {
                        for section in extraSections { self.appendSection(section, to: extras) }
                    }
                    self.sectionStackView.addArrangedSubview(extras)
                } else {
                    self.sectionStackView.removeArrangedSubview(extras)
                    extras.removeFromSuperview()
                }
                more?.accessibilityValue = FennecTheme.text(self.showsMoreHomepageContent ? "Expanded" : "Collapsed")
            }
            sectionStackView.addArrangedSubview(more)
            if showsMoreHomepageContent {
                for section in extraSections { appendSection(section, to: extras) }
                sectionStackView.addArrangedSubview(extras)
            }
        }
    }
    
    private func reloadSections() {
        sectionViewControllers.values.forEach { viewController in
            viewController.willMove(toParent: nil)
            sectionStackView.removeArrangedSubview(viewController.view)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
        sectionViewControllers.removeAll(keepingCapacity: true)
        configureSections()
        updateSectionStackWidth()
    }
    
    private func makeSectionViewController(for section: HomepageSection) -> UIViewController {
        switch section {
        case .recommendation(.performance):
            let viewController = PerformanceRecommendationViewController()
            viewController.delegate = self
            viewController.setContentMode(contentMode)
            viewController.setPrivateBrowsing(isPrivateBrowsing)
            return viewController
            
        case .recommendation(.updateAvailable):
            let viewController = UpdateAvailableViewController()
            viewController.delegate = self
            viewController.setContentMode(contentMode)
            viewController.setPrivateBrowsing(isPrivateBrowsing)
            return viewController
            
        case .recommendation(.donation):
            let viewController = DonationRecommendationViewController()
            viewController.delegate = self
            viewController.setContentMode(contentMode)
            viewController.setPrivateBrowsing(isPrivateBrowsing)
            return viewController
            
        case .privateBrowsing:
            let viewController = PrivateBrowsingSectionViewController()
            viewController.onLearnMore = { [weak self] in
                guard let self, let url = URL(string: "https://support.mozilla.org/kb/common-myths-about-private-browsing") else { return }
                self.delegate?.homepageRootViewController(self, didRequestOpenURL: url, disposition: .currentTab)
            }
            viewController.setContentMode(contentMode)
            viewController.setPrivateBrowsing(isPrivateBrowsing)
            return viewController
            
        case .favorites:
            let viewController = FavoritesSectionViewController(
                bookmarkStore: bookmarkStore,
                folder: folder,
                showsSectionTitle: folder == nil
            )
            viewController.delegate = self
            viewController.setContentMode(contentMode)
            return viewController
            
        case .frequentlyVisited:
            let viewController = FrequentlyVisitedSectionViewController()
            viewController.delegate = self
            viewController.setContentMode(contentMode)
            return viewController
            
        case .recentlyClosedTabs:
            let viewController = RecentlyClosedTabsSectionViewController()
            viewController.delegate = self
            viewController.setContentMode(contentMode)
            return viewController
        }
    }
    
    // MARK: - Layout
    
    private func updateSectionStackWidth() {
        let maximumWidth = contentMode.isDetached ? UX.detachedMaximumWidth : UX.embeddedMaximumWidth
        guard sectionStackWidthConstraint?.constant != maximumWidth else { return }
        sectionStackWidthConstraint?.constant = maximumWidth
    }
    
    private func updateWallpaper() {
        guard Prefs.HomepageSettings.showsWallpaper,
              !contentMode.isDetached else {
            wallpaperImageView.image = nil
            return
        }
        wallpaperImageView.image = HomepageWallpaper.image
    }
    
    // MARK: - Helpers
    
    private var recommendationViewControllers: [HomepageRecommendationViewController] {
        return sectionViewControllers.compactMap { section, viewController in
            guard case .recommendation = section else {
                return nil
            }
            
            return viewController as? HomepageRecommendationViewController
        }
    }
    
    private var privateBrowsingSectionViewController: PrivateBrowsingSectionViewController? {
        return sectionViewControllers[.privateBrowsing] as? PrivateBrowsingSectionViewController
    }
    
    private var favoritesSectionViewController: FavoritesSectionViewController? {
        return sectionViewControllers[.favorites] as? FavoritesSectionViewController
    }
    
    private var frequentlyVisitedSectionViewController: FrequentlyVisitedSectionViewController? {
        return sectionViewControllers[.frequentlyVisited] as? FrequentlyVisitedSectionViewController
    }
    
    private var recentlyClosedTabsSectionViewController: RecentlyClosedTabsSectionViewController? {
        return sectionViewControllers[.recentlyClosedTabs] as? RecentlyClosedTabsSectionViewController
    }
    
    private var displayedSections: [HomepageSection] {
        guard folder == nil else {
            return sections
        }
        
        return sections.filter { section in
            switch section {
            case .recommendation(.performance), .recommendation(.updateAvailable):
                // No JIT feature or application update feed.
                return false
            case .recommendation(.donation):
                return !isPrivateBrowsing && Prefs.HomepageSettings.showsRecommendations
            case .privateBrowsing:
                return isPrivateBrowsing
            case .favorites:
                return Prefs.HomepageSettings.showsFavorites &&
                (!isPrivateBrowsing || Prefs.HomepageSettings.showsFavoritesInPrivateBrowsing)
            case .frequentlyVisited:
                // Removed from both normal/private homepages, including upgrades
                // with an old true preference. History storage is untouched.
                return false
            case .recentlyClosedTabs:
                return Prefs.HomepageSettings.showsRecentlyClosedTabs && !isPrivateBrowsing
            default:
                return true
            }
        }
    }
    
    private func observeHomepageSettings() {
        guard folder == nil else {
            return
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(homepageSettingsDidChange),
            name: .homepageSettingsDidChange,
            object: nil
        )
    }
    
    @objc private func homepageSettingsDidChange() {
        updateWallpaper()
        reloadSections()
    }
    
}

extension HomepageRootViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.homepageRootViewControllerDidStartScrolling()
    }
}

extension HomepageRootViewController: HomepageSectionDelegate {
    func homepageSection(_ viewController: UIViewController, didRequestOpenURL url: URL, disposition: TabOpenDisposition) {
        delegate?.homepageRootViewController(self, didRequestOpenURL: url, disposition: disposition)
    }
    
    func homepageSection(
        _ viewController: UIViewController,
        didRequestShareURL url: URL,
        sourceView: UIView
    ) {
        delegate?.homepageRootViewController(
            self,
            didRequestShareURL: url,
            sourceView: sourceView
        )
    }
    
    func homepageSection(_ viewController: UIViewController, didRequestHideFromSuggestions siteID: Int64) {
        delegate?.homepageRootViewController(self, didRequestHideFromSuggestions: siteID)
    }
    
    func homepageSection(_ viewController: UIViewController, didSelectRecentlyClosedTab id: UUID) {
        delegate?.homepageRootViewController(self, didSelectRecentlyClosedTab: id)
    }
    
    func homepageSectionDidSelectSettings(_ viewController: UIViewController) {
        delegate?.homepageRootViewControllerDidSelectSettings(self)
    }
}

extension HomepageRootViewController: FavoritesSectionViewControllerDelegate {
    func favoritesSectionViewController(_ controller: FavoritesSectionViewController, didSelectFolder folder: BookmarkFolderSnapshot) {
        delegate?.homepageRootViewControllerDidSelectFolder(folder)
    }
}

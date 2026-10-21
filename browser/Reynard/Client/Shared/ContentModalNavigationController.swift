//
//  ContentModalNavigationController.swift
//  Reynard
//
//  Created by Minh Ton on 30/7/26.
//

import UIKit

final class ContentModalNavigationController: UINavigationController, UINavigationControllerDelegate {
    private let onDismissed: () -> Void
    private var didNotifyDismissal = false
    var librarySection: LibrarySection?
    
    init(rootViewController: UIViewController, onDismissed: @escaping () -> Void) {
        self.onDismissed = onDismissed
        super.init(rootViewController: rootViewController)
        delegate = self
        installRootExit(on: rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = FennecTheme.surface
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: FennecTheme.ink, .font: UIFont.preferredFont(forTextStyle: .title2)]
        appearance.setBackIndicatorImage(UIImage(systemName: "arrow.backward"), transitionMaskImage: UIImage(systemName: "arrow.backward"))
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = FennecTheme.ink
        if let root = viewControllers.first { installRootExit(on: root) }
    }

    private func installRootExit(on controller: UIViewController) {
        let exit = UIBarButtonItem(image: UIImage(systemName: "arrow.backward"), style: .plain, target: self, action: #selector(closePage))
        exit.tintColor = FennecTheme.ink
        exit.accessibilityLabel = FennecTheme.text("Back to browsing")
        exit.accessibilityIdentifier = "contentPage.close"
        controller.navigationItem.leftBarButtonItem = exit
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setNavigationBarHidden(false, animated: false)
        if viewController === viewControllers.first { installRootExit(on: viewController) }
        for item in (viewController.navigationItem.leftBarButtonItems ?? []) + (viewController.navigationItem.rightBarButtonItems ?? []) {
            item.tintColor = FennecTheme.ink
        }
    }

    private func notifyDismissal() {
        guard !didNotifyDismissal else { return }
        didNotifyDismissal = true
        onDismissed()
    }

    @objc private func closePage() {
        // UIKit still has transition lifecycle bookkeeping with animated:false.
        // Honor rapid back taps during a push/pop instead of dropping dismissal.
        if let coordinator = transitionCoordinator,
           coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
               DispatchQueue.main.async { self?.closePage() }
           }) { return }
        dismiss(animated: false) { [weak self] in self?.notifyDismissal() }
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: false)
    }
    override func popViewController(animated: Bool) -> UIViewController? {
        super.popViewController(animated: false)
    }
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        super.popToRootViewController(animated: false)
    }
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        super.popToViewController(viewController, animated: false)
    }
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isBeingDismissed else {
            return
        }
        notifyDismissal()
    }
}

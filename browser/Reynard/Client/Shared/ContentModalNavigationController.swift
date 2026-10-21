//
//  ContentModalNavigationController.swift
//  Reynard
//
//  Created by Minh Ton on 30/7/26.
//

import UIKit

final class ContentModalNavigationController: UINavigationController {
    private let onDismissed: () -> Void
    var librarySection: LibrarySection?
    
    init(rootViewController: UIViewController, onDismissed: @escaping () -> Void) {
        self.onDismissed = onDismissed
        super.init(rootViewController: rootViewController)
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
        viewControllers.first?.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.backward"), style: .plain, target: self, action: #selector(closePage))
    }

    @objc private func closePage() { dismiss(animated: false) }

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
        onDismissed()
    }
}

//
//  ContentModalNavigationController.swift
//  Reynard
//
//  Created by Minh Ton on 30/7/26.
//

import UIKit

final class ContentModalNavigationController: UINavigationController {
    private let onDismissed: () -> Void
    
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
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label, .font: UIFont.preferredFont(forTextStyle: .title2)]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = FennecTheme.accent
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isBeingDismissed else {
            return
        }
        onDismissed()
    }
}

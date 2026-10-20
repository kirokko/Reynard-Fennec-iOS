//
//  AdvancedSettingsSection.swift
//  Reynard
//
//  Created by Minh Ton on 8/9/26.
//

import UIKit

// Kept intact behind Advanced > Reynard-specific so no engine controls are lost.
struct ReynardSpecificSettingsSection {
    enum Row: CaseIterable {
        case developer
        case compatibility
        case browsing
    }
    
    var rowCount: Int {
        return Row.allCases.count
    }
    
    func cell(at index: Int) -> UITableViewCell {
        guard Row.allCases.indices.contains(index) else {
            return UITableViewCell()
        }
        
        switch Row.allCases[index] {
        case .developer:
            return SettingsViewUtils.disclosureCell(title: NSLocalizedString("Developer", comment: ""))
        case .compatibility:
            return SettingsViewUtils.disclosureCell(title: NSLocalizedString("Compatibility", comment: ""))
        case .browsing:
            return SettingsViewUtils.disclosureCell(title: NSLocalizedString("Browsing", comment: ""))
        }
    }
    
    func selectRow(at index: Int, from viewController: UIViewController) {
        guard Row.allCases.indices.contains(index) else {
            return
        }
        
        switch Row.allCases[index] {
        case .developer:
            let destination = DeveloperPreferencesViewController()
            viewController.navigationController?.pushViewController(destination, animated: true)
        case .compatibility:
            let destination = CompatibilityPreferencesViewController()
            viewController.navigationController?.pushViewController(destination, animated: true)
        case .browsing:
            viewController.navigationController?.pushViewController(BrowsingPreferencesViewController(), animated: true)
        }
    }
}

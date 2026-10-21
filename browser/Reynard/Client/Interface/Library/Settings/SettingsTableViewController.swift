//
//  SettingsTableViewController.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    private enum UX {
        static let sectionHeaderTopPadding: CGFloat = 0
    }
    
    override init(style: UITableView.Style) {
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionText(for: section).headerTitle
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sectionText(for: section).footerTitle
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = FennecTheme.surface
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.textColor = FennecTheme.ink
        cell.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = FennecTheme.accent
        header.textLabel?.font = .preferredFont(forTextStyle: .headline)
        header.contentView.backgroundColor = FennecTheme.surface
    }

    func sectionText(for section: Int) -> SettingsSectionText {
        return SettingsSectionText()
    }
    
    private func configureTableView() {
        view.tintColor = FennecTheme.accent
        tableView.backgroundColor = FennecTheme.surface
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.alwaysBounceVertical = true
        tableView.keyboardDismissMode = .interactive
        if #available(iOS 14.0, *) {
            tableView.selectionFollowsFocus = false
        }
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = UX.sectionHeaderTopPadding
        }
    }
}

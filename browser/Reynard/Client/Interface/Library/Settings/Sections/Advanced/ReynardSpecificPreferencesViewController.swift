// Modifications for the Reynard/Fennec iOS project. Licensed under GPL-3.0.
import UIKit

struct AdvancedSettingsSection {
    var rowCount: Int { 1 }

    func cell(at index: Int) -> UITableViewCell {
        guard index == 0 else { return UITableViewCell() }
        return SettingsViewUtils.disclosureCell(title: FennecTheme.text("Reynard-specific"))
    }

    func selectRow(at index: Int, from viewController: UIViewController) {
        guard index == 0 else { return }
        viewController.navigationController?.pushViewController(
            ReynardSpecificPreferencesViewController(), animated: true
        )
    }
}

/// A separate home for controls with no Android Fennec counterpart.
/// The original section still owns navigation to compatibility and developer pages.
final class ReynardSpecificPreferencesViewController: SettingsTableViewController {
    private let section = ReynardSpecificSettingsSection()

    init() {
        super.init(style: .plain)
        title = FennecTheme.text("Reynard-specific")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.section.rowCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        section.cell(at: indexPath.row)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        section.selectRow(at: indexPath.row, from: self)
    }
}

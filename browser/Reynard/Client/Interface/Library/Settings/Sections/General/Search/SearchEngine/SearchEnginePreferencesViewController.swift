// GPL-3.0. The owner's four providers, in the same order as the toolbar picker.
import UIKit

final class SearchEnginePreferencesViewController: SettingsTableViewController {
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Search Engine", comment: "")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? SearchEngine.pickerEngines.count : 0
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard SearchEngine.pickerEngines.indices.contains(indexPath.row) else { return UITableViewCell() }
        let engine = SearchEngine.pickerEngines[indexPath.row]
        let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = engine.displayName
        cell.imageView?.image = UIImage(named: engine.iconAssetName)?.withRenderingMode(.alwaysOriginal)
        cell.accessoryType = Prefs.SearchSettings.searchEngine == engine ? .checkmark : .none
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: false) }
        guard SearchEngine.pickerEngines.indices.contains(indexPath.row) else { return }
        Prefs.SearchSettings.searchEngine = SearchEngine.pickerEngines[indexPath.row]
        tableView.reloadData()
    }
    override func sectionText(for section: Int) -> SettingsSectionText {
        SettingsSectionText(headerTitle: NSLocalizedString("Search Engine", comment: ""))
    }
}

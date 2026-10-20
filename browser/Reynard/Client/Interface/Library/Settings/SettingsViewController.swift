// Settings order follows Fennec 158; unsupported Android-only entries are omitted.
// Reynard-specific controls remain available under Advanced and iOS / JIT. GPL-3.0.
import UIKit

final class SettingsViewController: SettingsTableViewController {
    private enum Section: CaseIterable { case general, privacy, advanced, jit, about }
    private let jitSection = JITSettingsSection()
    private let privacySection = PrivacySettingsSection()
    private let externalLinksSwitch = UISwitch()
    private var sections: [Section] {
        Section.allCases.filter { $0 != .jit || !getEntitlementValue("com.apple.private.security.no-sandbox") }
    }
    private let generalTitles = ["Search", "Tabs", "Homepage", "Customize", "Accessibility", "Language"]
    private let advancedTitles = ["Extensions", "Open links in apps", "Reynard-specific"]

    init() {
        super.init(style: .plain)
        title = FennecTheme.text("Settings")
        jitSection.attach(to: self)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        externalLinksSwitch.addTarget(self, action: #selector(externalLinksChanged), for: .valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshJIT), name: .jitlessModeDidActivate, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        jitSection.refreshDisplayedState()
        externalLinksSwitch.isOn = Prefs.BrowsingSettings.openLinksInExternalApps
        tableView.reloadData()
    }
    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .general: return generalTitles.count
        case .privacy: return privacySection.rowCount
        case .advanced: return advancedTitles.count
        case .jit: return jitSection.rowCount
        case .about: return 1
        }
    }
    override func sectionText(for section: Int) -> SettingsSectionText {
        let key: String
        switch sections[section] {
        case .general: key = "General"
        case .privacy: key = "Privacy and security"
        case .advanced: key = "Advanced"
        case .jit: key = "iOS / JIT"
        case .about: key = "About"
        }
        return SettingsSectionText(headerTitle: FennecTheme.text(key))
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .general: return cell(generalTitles[indexPath.row])
        case .privacy: return privacySection.cell(at: indexPath.row)
        case .advanced:
            let result = cell(advancedTitles[indexPath.row])
            if indexPath.row == 1 { result.accessoryView = externalLinksSwitch; result.selectionStyle = .none }
            return result
        case .jit: return jitSection.cell(at: indexPath.row, tintColor: FennecTheme.accent)
        case .about: return cell("About Reynard Fennec")
        }
    }
    private func cell(_ key: String) -> UITableViewCell {
        let result = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
        result.textLabel?.text = FennecTheme.text(key)
        return result
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        switch sections[indexPath.section] {
        case .general:
            let page: UIViewController
            switch indexPath.row {
            case 0: page = SearchPreferencesViewController()
            case 1: page = FennecSettingsListController(title: "Tabs", entries: [
                ("New tab", { NewTabPreferencesViewController() }),
                ("Open links in new tabs", { OpenLinksInNewTabsPreferencesViewController() }),
            ])
            case 2: page = HomepagePreferencesViewController()
            case 3: page = AppearancePreferencesViewController()
            case 4: page = FennecSettingsListController(title: "Accessibility", entries: [
                ("Page zoom", { PageZoomPreferencesViewController() }),
                ("Reader", { ReaderPreferencesViewController() }),
            ])
            default: page = LanguagesPreferencesViewController()
            }
            navigationController?.pushViewController(page, animated: true)
        case .privacy: privacySection.selectRow(at: indexPath.row, from: self)
        case .advanced:
            switch indexPath.row {
            case 0: navigationController?.pushViewController(AddonsPreferencesViewController(), animated: true)
            case 2: navigationController?.pushViewController(ReynardSpecificPreferencesViewController(), animated: true)
            default: break
            }
        case .jit: jitSection.selectRow(at: indexPath.row, from: self)
        case .about: navigationController?.pushViewController(FennecAboutViewController(), animated: true)
        }
    }
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        sections[section] == .jit ? jitSection.footerView() : nil
    }
    @objc private func externalLinksChanged() { Prefs.BrowsingSettings.openLinksInExternalApps = externalLinksSwitch.isOn }
    @objc private func refreshJIT() { jitSection.refreshDisplayedState(); tableView.reloadData() }
}

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        jitSection.savePairingFile(from: url)
    }
}

final class FennecSettingsListController: SettingsTableViewController {
    private let entries: [(String, () -> UIViewController)]
    init(title: String, entries: [(String, () -> UIViewController)]) {
        self.entries = entries
        super.init(style: .plain)
        self.title = FennecTheme.text(title)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { entries.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        SettingsViewUtils.disclosureCell(title: FennecTheme.text(entries[indexPath.row].0))
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(entries[indexPath.row].1(), animated: true)
    }
}

final class FennecAboutViewController: SettingsTableViewController {
    private let section = AboutSettingsSection()
    init() {
        super.init(style: .plain)
        title = FennecTheme.text("About Reynard Fennec")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { self.section.rowCount }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = section.cell(at: indexPath.row)
        if section.isAppVersionRow(at: indexPath.row) {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(reveal(_:)))
            gesture.numberOfTapsRequired = 10
            result.addGestureRecognizer(gesture)
        }
        return result
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        section.selectRow(at: indexPath.row, from: self)
    }
    override func sectionText(for section: Int) -> SettingsSectionText {
        SettingsSectionText(footerTitle: FennecTheme.text("Manual updates only. This is an unofficial Reynard fork, not a Mozilla product."))
    }
    @objc private func reveal(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended, section.revealExperimentalFeatures() { tableView.reloadData() }
    }
}

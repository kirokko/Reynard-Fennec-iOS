// Local native groups for ieynec. Uses existing regular tabs, never bookmarks.
// GPL-3.0.
import UIKit

final class FennecTabGroupsViewController: SettingsTableViewController {
    private let tabs: () -> [Tab]
    private let onSelect: (UUID) -> Void
    private let store: TabGroupStore

    init(tabs: @escaping () -> [Tab], store: TabGroupStore = .shared, onSelect: @escaping (UUID) -> Void) {
        self.tabs = tabs
        self.store = store
        self.onSelect = onSelect
        super.init(style: .plain)
        title = FennecTheme.text("Tab groups")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createGroup))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateEmptyState()
    }
    private func updateEmptyState() {
        guard store.groups.isEmpty else { tableView.backgroundView = nil; return }
        let background = UIView()
        let message = UILabel()
        message.translatesAutoresizingMaskIntoConstraints = false
        message.text = FennecTheme.text("Select open tabs to create a group. Groups are stored only on this device.")
        message.numberOfLines = 0
        message.textAlignment = .center
        message.textColor = .secondaryLabel
        message.font = .preferredFont(forTextStyle: .body)
        message.adjustsFontForContentSizeCategory = true
        background.addSubview(message)
        NSLayoutConstraint.activate([
            message.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 24),
            message.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -24),
            message.centerYAnchor.constraint(equalTo: background.centerYAnchor),
        ])
        tableView.backgroundView = background
    }
    @objc private func createGroup() {
        navigationController?.pushViewController(FennecTabGroupEditor(tabs: tabs, store: store, group: nil), animated: false)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { store.groups.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = store.groups[indexPath.row]
        let liveIDs = Set(tabs().filter { !$0.isPrivate }.map(\.id))
        let cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = group.name
        cell.detailTextLabel?.text = String(format: FennecTheme.text("%d open tabs"), group.tabIDs.filter { liveIDs.contains($0) }.count)
        cell.imageView?.image = UIImage(systemName: "square.grid.2x2")
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = FennecOpenTabsController(tabs: { [tabs] in tabs().filter { !$0.isPrivate } }, onSelect: onSelect)
        controller.groupID = store.groups[indexPath.row].id
        controller.store = store
        navigationController?.pushViewController(controller, animated: false)
    }
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let id = store.groups[indexPath.row].id
        let action = UIContextualAction(style: .destructive, title: FennecTheme.text("Ungroup")) { [weak self] _, _, done in
            self?.store.remove(id: id)
            self?.tableView.reloadData()
            self?.updateEmptyState()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}

final class FennecOpenTabsController: SettingsTableViewController, UISearchResultsUpdating {
    var groupID: UUID?
    var store = TabGroupStore.shared
    private let tabs: () -> [Tab]
    private let onSelect: (UUID) -> Void
    private let search = UISearchController(searchResultsController: nil)
    private var shown: [Tab] = []

    init(tabs: @escaping () -> [Tab], onSelect: @escaping (UUID) -> Void) {
        self.tabs = tabs
        self.onSelect = onSelect
        super.init(style: .plain)
        title = FennecTheme.text("Search tabs")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        if groupID != nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: FennecTheme.text("Edit group"), style: .plain, target: self, action: #selector(editGroup))
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }
    func updateSearchResults(for searchController: UISearchController) { refresh() }
    private func refresh() {
        let group = store.groups.first { $0.id == groupID }
        if groupID != nil { title = group?.name ?? FennecTheme.text("Tab groups") }
        let query = (search.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        shown = tabs().filter { tab in
            let inGroup = groupID == nil || (!tab.isPrivate && group?.tabIDs.contains(tab.id) == true)
            return inGroup && (query.isEmpty || tab.title.localizedCaseInsensitiveContains(query) || (tab.url ?? "").localizedCaseInsensitiveContains(query))
        }
        tableView.reloadData()
    }
    @objc private func editGroup() {
        guard let group = store.groups.first(where: { $0.id == groupID }) else { return }
        navigationController?.pushViewController(FennecTabGroupEditor(tabs: tabs, store: store, group: group), animated: false)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { shown.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tab = shown[indexPath.row]
        let cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = tab.title.isEmpty ? NSLocalizedString("Homepage", comment: "") : tab.title
        cell.detailTextLabel?.text = tab.url
        cell.imageView?.image = tab.favicon ?? UIImage(systemName: "globe")
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = shown[indexPath.row].id
        search.isActive = false
        onSelect(id)
    }
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let groupID else { return nil }
        let tabID = shown[indexPath.row].id
        let action = UIContextualAction(style: .normal, title: FennecTheme.text("Remove from group")) { [weak self] _, _, done in
            self?.store.removeTab(tabID, from: groupID)
            self?.refresh()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}

private final class FennecTabGroupEditor: SettingsTableViewController {
    private let tabs: () -> [Tab]
    private let store: TabGroupStore
    private let group: LocalTabGroup?
    private let nameField = UITextField()
    private var selected = Set<UUID>()
    private var eligible: [Tab] = []

    init(tabs: @escaping () -> [Tab], store: TabGroupStore, group: LocalTabGroup?) {
        self.tabs = tabs
        self.store = store
        self.group = group
        selected = Set(group?.tabIDs ?? [])
        super.init(style: .plain)
        title = FennecTheme.text(group == nil ? "New group" : "Edit group")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        eligible = tabs().filter { !$0.isPrivate }
        nameField.text = group?.name
        nameField.placeholder = FennecTheme.text("Group name")
        nameField.accessibilityLabel = FennecTheme.text("Group name")
        nameField.font = .preferredFont(forTextStyle: .body)
        nameField.adjustsFontForContentSizeCategory = true
        nameField.clearButtonMode = .whileEditing
        nameField.addTarget(self, action: #selector(updateSaveButton), for: .editingChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveGroup))
        updateSaveButton()
    }
    @objc private func updateSaveButton() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        navigationItem.rightBarButtonItem?.isEnabled = !name.isEmpty && !selected.intersection(Set(eligible.map(\.id))).isEmpty
    }
    @objc private func saveGroup() {
        // Revalidate live membership at save time: private/closed tabs cannot leak
        // into persistent groups even if the tab model changed during editing.
        let ids = tabs().filter { !$0.isPrivate && selected.contains($0.id) }.map(\.id)
        guard !ids.isEmpty else { return }
        if let group { store.update(id: group.id, name: nameField.text ?? "", regularTabIDs: ids) }
        else { store.create(name: nameField.text ?? "", regularTabIDs: ids) }
        navigationController?.popViewController(animated: false)
    }
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? 1 : eligible.count }
    override func sectionText(for section: Int) -> SettingsSectionText {
        SettingsSectionText(headerTitle: FennecTheme.text(section == 0 ? "Group name" : "Select tabs"))
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: nil)
        if indexPath.section == 0 {
            nameField.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(nameField)
            NSLayoutConstraint.activate([
                nameField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                nameField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                nameField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                nameField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            ])
            cell.selectionStyle = .none
        } else {
            let tab = eligible[indexPath.row]
            cell.textLabel?.text = tab.title.isEmpty ? NSLocalizedString("Homepage", comment: "") : tab.title
            cell.detailTextLabel?.text = tab.url
            cell.accessoryType = selected.contains(tab.id) ? .checkmark : .none
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        let id = eligible[indexPath.row].id
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        tableView.cellForRow(at: indexPath)?.accessoryType = selected.contains(id) ? .checkmark : .none
        tableView.deselectRow(at: indexPath, animated: false)
        updateSaveButton()
    }
}

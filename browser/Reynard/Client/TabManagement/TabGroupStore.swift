// Native local groups reference existing regular-tab UUIDs; no sessions or URLs
// are duplicated. Group deletion does not close tabs. GPL-3.0.
import Foundation

struct LocalTabGroup: Codable, Equatable {
    let id: UUID
    var name: String
    var tabIDs: [UUID]
}

final class TabGroupStore {
    static let shared = TabGroupStore()
    private let defaults: UserDefaults
    private let key = "ieynec.localTabGroups.v1"
    private(set) var groups: [LocalTabGroup]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        groups = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([LocalTabGroup].self, from: $0) } ?? []
    }

    @discardableResult
    func create(name: String, regularTabIDs: [UUID]) -> UUID? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ids = unique(regularTabIDs)
        guard !name.isEmpty, !ids.isEmpty else { return nil }
        let id = UUID()
        moveOutOfOtherGroups(ids, except: id)
        groups.append(LocalTabGroup(id: id, name: name, tabIDs: ids))
        save()
        return id
    }

    func update(id: UUID, name: String, regularTabIDs: [UUID]) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let index = groups.firstIndex(where: { $0.id == id }) else { return }
        let ids = unique(regularTabIDs)
        moveOutOfOtherGroups(ids, except: id)
        groups[index].name = name
        groups[index].tabIDs = ids
        save()
    }

    func remove(id: UUID) {
        groups.removeAll { $0.id == id }
        save()
    }

    func removeTab(_ tabID: UUID, from groupID: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[index].tabIDs.removeAll { $0 == tabID }
        save()
    }

    private func moveOutOfOtherGroups(_ ids: [UUID], except id: UUID) {
        let selected = Set(ids)
        for index in groups.indices where groups[index].id != id {
            groups[index].tabIDs.removeAll { selected.contains($0) }
        }
    }
    private func unique(_ ids: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        return ids.filter { seen.insert($0).inserted }
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(groups) else { return }
        defaults.set(data, forKey: key)
    }
}

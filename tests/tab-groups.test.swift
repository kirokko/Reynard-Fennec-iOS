import Foundation

@main
struct TabGroupStoreTests {
    static func main() {
        let suite = "ieynec.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = TabGroupStore(defaults: defaults)
        let a = UUID(), b = UUID(), c = UUID()
        precondition(store.groups.isEmpty)
        precondition(store.create(name: "   ", regularTabIDs: [a]) == nil)
        precondition(store.create(name: "Empty", regularTabIDs: []) == nil)
        let first = store.create(name: "  Research  ", regularTabIDs: [a, a, b])!
        precondition(store.groups[0].name == "Research")
        precondition(store.groups[0].tabIDs == [a, b])
        let second = store.create(name: "Reading", regularTabIDs: [b, c])!
        precondition(store.groups[0].tabIDs == [a], "membership must not duplicate a tab across groups")
        store.update(id: first, name: "Renamed", regularTabIDs: [a, c])
        precondition(store.groups[0].name == "Renamed")
        precondition(store.groups[1].tabIDs == [b])
        let restored = TabGroupStore(defaults: defaults)
        precondition(restored.groups == store.groups, "UUID membership must survive relaunch")
        store.removeTab(c, from: first)
        precondition(store.groups[0].tabIDs == [a])
        store.remove(id: second)
        precondition(store.groups.count == 1)
        store.update(id: first, name: " ", regularTabIDs: [])
        precondition(store.groups[0].tabIDs == [a], "invalid edits must not overwrite membership")
        store.remove(id: first)
        precondition(TabGroupStore(defaults: defaults).groups.isEmpty)
        defaults.set(Data("bad json".utf8), forKey: "ieynec.localTabGroups.v1")
        precondition(TabGroupStore(defaults: defaults).groups.isEmpty)
        print("PASS: local tab-group validation, deduplication, membership moves, rename, persistence, removal and corrupt-data handling")
    }
}

// Preserve existing raw preference values; add Fennec's reverse sort choices.
// GPL-3.0.
import Foundation

enum BookmarkSortOrder: String {
    case none
    case date_added
    case date_added_oldest
    case name
    case name_descending
    case address

    typealias Values = (dateAdded: Date, title: String, address: String)
    func precedes(_ lhs: Values, _ rhs: Values) -> Bool {
        switch self {
        case .none: return false // Caller retains custom order, no sorting.
        case .date_added, .date_added_oldest:
            if lhs.dateAdded == rhs.dateAdded {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return self == .date_added ? lhs.dateAdded > rhs.dateAdded : lhs.dateAdded < rhs.dateAdded
        case .name:
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        case .name_descending:
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedDescending
        case .address:
            return lhs.address.localizedCaseInsensitiveCompare(rhs.address) == .orderedAscending
        }
    }
}

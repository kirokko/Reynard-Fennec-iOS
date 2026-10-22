// Address-only display, as in the pinned Android toolbar; never append page title.
// This does not alter the editable/submitted URL or website navigation. GPL-3.0.
import Foundation

enum FennecAddressDisplay {
    static func text(_ value: String, fullAddress: Bool) -> String {
        var address = value
        if var components = URLComponents(string: value),
           let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme) {
            components.user = nil
            components.password = nil
            address = components.string ?? value
        }
        guard !fullAddress else { return address }
        for scheme in ["https://", "http://"] where address.lowercased().hasPrefix(scheme) {
            return String(address.dropFirst(scheme.count))
        }
        return address
    }
}

// Manual-maintenance fork: intentionally no application update feed. GPL-3.0.
// Keep the original API so engine/UI integrations remain source-compatible.
import Foundation

final class BrowserUpdates: NSObject {
    static let shared = BrowserUpdates()
    let hasUpdate = false
    let latestVersion = ""
    let sourceData: Data? = nil
    var cachedReleaseNotes: NSAttributedString?

    private override init() {
        super.init()
        // Do not contact the upstream feed or delete manually downloaded IPAs.
        // Updating this app and adopting upstream changes are owner actions.
    }
}

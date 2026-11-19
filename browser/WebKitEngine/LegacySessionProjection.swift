// GPL-3.0. Read-only conversion of the GeckoSessionState JSON documented by
// browser/GeckoView/Session/GeckoSessionState.swift. Never writes legacy stores.
import Foundation
import CoreFoundation

struct LegacySessionProjection: Encodable, Equatable {
    struct Entry: Encodable, Equatable {
        let url: URL
        let title: String?
    }
    enum ProjectionError: Error { case privateSession, invalidJSON, invalidHistory, invalidIndex, unsupportedURL(Int) }
    let schemaVersion: Int
    let sourceEngine: String
    let entries: [Entry]
    let selectedIndex: Int
    // Native WKBackForwardList items cannot be created from Gecko entries via
    // public API. The existing NavigationHistoryStore must own restored back/
    // forward transitions. This is NOT a native WK session-state restoration.
    var current: Entry { entries[selectedIndex] }

    init(serializedGeckoState: Data, isPrivate: Bool) throws {
        guard !isPrivate else { throw ProjectionError.privateSession }
        guard let payload = try? JSONSerialization.jsonObject(with: serializedGeckoState) as? [String: Any] else {
            throw ProjectionError.invalidJSON
        }
        guard let history = payload["history"] as? [String: Any],
              let rawEntries = history["entries"] as? [[String: Any]], !rawEntries.isEmpty else {
            throw ProjectionError.invalidHistory
        }
        guard let number = history["index"] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite, number.doubleValue.rounded() == number.doubleValue,
              number.doubleValue >= 1, number.doubleValue <= Double(rawEntries.count) else {
            throw ProjectionError.invalidIndex
        }
        entries = try rawEntries.enumerated().map { index, entry in
            guard let string = entry["url"] as? String, let url = URL(string: string),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  url.host?.isEmpty == false, url.user == nil, url.password == nil else {
                // Never silently drop an entry and shift the selected index, or
                // execute an old javascript:/moz-extension:/file: URL on upgrade.
                throw ProjectionError.unsupportedURL(index)
            }
            return Entry(url: url, title: entry["title"] as? String)
        }
        selectedIndex = number.intValue - 1
        schemaVersion = 1
        sourceEngine = "gecko"
        // Deliberately omit principals, docshell UUIDs, form/password contents,
        // POST bodies, scroll blobs and opaque engine state. Keep originals.
    }
}

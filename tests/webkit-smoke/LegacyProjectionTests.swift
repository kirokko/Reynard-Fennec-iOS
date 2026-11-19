// GPL-3.0. Synthetic data only; never opens the owner's browser profile.
import Foundation

enum LegacyProjectionTests {
    enum Failure: Error { case expectedRejection, invalidProjection }
    static func run() throws -> [String] {
        let original = Data(#"{"history":{"index":2,"entries":[{"url":"https://example.com/a","title":"A"},{"url":"https://example.com/b","title":"B","triggeringPrincipal_base64":"opaque-gecko-data"}]},"formdata":{"password":"never-copy"}}"#.utf8)
        let projection = try LegacySessionProjection(serializedGeckoState: original, isPrivate: false)
        guard projection.selectedIndex == 1, projection.entries.count == 2,
              projection.current.url.absoluteString == "https://example.com/b" else { throw Failure.invalidProjection }
        let encoded = String(decoding: try JSONEncoder().encode(projection), as: UTF8.self)
        guard !encoded.contains("never-copy"), !encoded.contains("opaque-gecko-data") else { throw Failure.invalidProjection }
        var results = ["legacy history/index projected without Gecko principals or form secrets"]
        func rejects(_ data: Data, isPrivate: Bool = false) throws {
            do {
                _ = try LegacySessionProjection(serializedGeckoState: data, isPrivate: isPrivate)
            } catch is LegacySessionProjection.ProjectionError { return }
            throw Failure.expectedRejection
        }
        try rejects(original, isPrivate: true)
        results.append("private Gecko state rejected for persistent migration")
        for index in ["0", "-1", "3", "true", "1.5", "null", "\"1\""] {
            try rejects(Data("{\"history\":{\"index\":\(index),\"entries\":[{\"url\":\"https://example.com\"}]}}".utf8))
        }
        results.append("invalid/boolean/fractional legacy indices rejected")
        for url in ["javascript:alert(1)", "moz-extension://old/options.html", "file:///private/data", "about:config", "https://user:secret@example.com", "https:///"] {
            let data = try JSONSerialization.data(withJSONObject: ["history": ["index": 1, "entries": [["url": url]]]])
            try rejects(data)
        }
        results.append("unsafe legacy URL schemes and credentials rejected without index shifts")
        try rejects(Data("not-json".utf8))
        try rejects(Data("{}".utf8))
        results.append("malformed legacy data rejected; source bytes untouched")
        return results
    }
}

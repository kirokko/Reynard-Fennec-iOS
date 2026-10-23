// GPL-3.0. Deliberately scoped: do not disable all CSS/JS animation or YouTube.
import Foundation

enum FennecMediaPolicy {
    static func blocksAutomaticMedia(on host: String) -> Bool {
        let host = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return host == "apple.com" || host.hasSuffix(".apple.com")
    }
}

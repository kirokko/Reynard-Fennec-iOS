// GPL-3.0. Never persist this state: every process launch requires authentication.
import Foundation

struct FennecPrivateAccessState {
    private(set) var isUnlocked = false

    func needsAuthentication(isSensitive: Bool) -> Bool {
        isSensitive && !isUnlocked
    }

    mutating func authenticationFinished(success: Bool) {
        if success { isUnlocked = true }
    }
}

import Foundation

@main
struct PrivateAccessMediaTests {
    static func main() {
        var access = FennecPrivateAccessState()
        precondition(!access.needsAuthentication(isSensitive: false))
        precondition(access.needsAuthentication(isSensitive: true))
        access.authenticationFinished(success: false)
        precondition(access.needsAuthentication(isSensitive: true))
        access.authenticationFinished(success: true)
        precondition(!access.needsAuthentication(isSensitive: true))
        precondition(!access.needsAuthentication(isSensitive: false))
        // A fresh process/state never inherits the earlier successful unlock.
        precondition(FennecPrivateAccessState().needsAuthentication(isSensitive: true))
        for host in ["apple.com", "www.apple.com", "APPLE.COM", "support.apple.com", "www.apple.com."] {
            precondition(FennecMediaPolicy.blocksAutomaticMedia(on: host), host)
        }
        for host in ["m.youtube.com", "youtube.com", "example.org", "apple.com.evil.test", "notapple.com", "", "apple.com@evil.test"] {
            precondition(!FennecMediaPolicy.blocksAutomaticMedia(on: host), host)
        }
        print("Private access state and scoped Apple autoplay policy passed")
    }
}

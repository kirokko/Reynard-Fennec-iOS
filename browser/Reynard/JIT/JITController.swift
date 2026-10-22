// ieynec intentionally runs Gecko without JIT. GPL-3.0.
// Keep the engine's child-process status handshake: removing this observer can
// leave Gecko waiting for a JIT decision. No pairing, DDI, VPN or debugger work.
import Foundation
import Darwin

final class JITController {
    static let shared = JITController()
    let isJITLessModeActive = true
    private var didStart = false
    private init() {}

    func start() {
        guard !didStart else { return }
        didStart = true
        // Migrate an existing installation without deleting private user files.
        Prefs.JITSettings.isJITEnabled = false
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleChildProcessNotification(_:)),
            name: .geckoRuntimeChildProcessDidStart, object: nil
        )
    }

    func childProcessDidStart(pid: Int32, processType: String) {
        guard pid > 0 else { return }
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let runtime = JITRuntimeInfo(
            hasTXMSupport: hasTXMSupport() ? 1 : 0,
            deviceOSVersion: DeviceOSVersion(
                majorVersion: Int32(version.majorVersion),
                minorVersion: Int32(version.minorVersion),
                patchVersion: Int32(version.patchVersion)
            )
        )
        ReportJITStatusForChild(pid, false, runtime)
    }

    // Hardware information is still passed to Gecko; it is not JIT permission.
    private func hasTXMSupport() -> Bool {
        var info = utsname()
        uname(&info)
        let hardware = withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        if #available(iOS 27.0, *) {
            return hardware != "iPad8,11" && hardware != "iPad8,12"
        }
        if #available(iOS 26.0, *) {
            let isPad = hardware.hasPrefix("iPad")
            let prefix = isPad ? "iPad" : "iPhone"
            let parts = hardware.dropFirst(prefix.count).split(separator: ",")
            guard parts.count == 2, let major = Int(parts[0]), let minor = Int(parts[1]) else { return false }
            return major > 14 || (major == 14 && minor >= (isPad ? 5 : 2))
        }
        return false
    }

    @objc private func handleChildProcessNotification(_ notification: Notification) {
        guard let info = notification.userInfo,
              let pid = info["pid"] as? NSNumber,
              let type = info["processType"] as? String else { return }
        childProcessDidStart(pid: pid.int32Value, processType: type)
    }
}

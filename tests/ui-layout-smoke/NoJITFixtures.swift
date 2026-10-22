// Engine boundary doubles for exercising the real no-JIT controller.
// This verifies status reporting and preference migration, NOT Gecko execution.
import Foundation

struct DeviceOSVersion {
    let majorVersion: Int32
    let minorVersion: Int32
    let patchVersion: Int32
}
struct JITRuntimeInfo {
    let hasTXMSupport: Int32
    let deviceOSVersion: DeviceOSVersion
}
private var reports: [(Int32, Bool)] = []
func ReportJITStatusForChild(_ pid: Int32, _ enabled: Bool, _ runtime: JITRuntimeInfo) {
    precondition(runtime.deviceOSVersion.majorVersion > 0)
    reports.append((pid, enabled))
}
extension Notification.Name {
    static let geckoRuntimeChildProcessDidStart = Notification.Name("fixture.childStarted")
}
func checkNoJITController() {
    Prefs.JITSettings.isJITEnabled = true // Simulate an older installed version.
    let controller = JITController.shared
    controller.start()
    controller.start() // Must not duplicate notification observers.
    precondition(!Prefs.JITSettings.isJITEnabled)
    precondition(controller.isJITLessModeActive)
    controller.childProcessDidStart(pid: 0, processType: "tab")
    precondition(reports.isEmpty)
    for (pid, kind) in [(Int32(101), "tab"), (Int32(102), "socket"), (Int32(103), "tab")] {
        NotificationCenter.default.post(name: .geckoRuntimeChildProcessDidStart, object: nil, userInfo: ["pid": NSNumber(value: pid), "processType": kind])
    }
    precondition(reports.map { $0.0 } == [101, 102, 103])
    precondition(reports.allSatisfy { !$0.1 }, "No child may be told JIT is enabled")
}

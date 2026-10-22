// Synthetic probe only: no Gecko, websites, owner media or stored browser data.
import UIKit

@main final class CaptureProbeApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let host = FennecSecureCanvasExperiment()
    private let label = UILabel()
    private let target = UIView()
    private let button = UIButton(type: .system)
    private let field = UITextField()
    private var taps = 0
    private var reports: [[String: Any]] = []
    private var timer: Timer?
    private var stageIndex = 0
    private let stages = ["normal", "protected", "layer-flag", "restored"]
    private var directory: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBlue
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = controller
        window.makeKeyAndVisible()
        label.frame = CGRect(x: 20, y: 75, width: window.bounds.width - 40, height: 70)
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        controller.view.addSubview(label)
        host.frame = CGRect(x: 16, y: 155, width: window.bounds.width - 32, height: window.bounds.height - 230)
        controller.view.addSubview(host)
        host.content.backgroundColor = .white
        target.backgroundColor = .red
        target.accessibilityIdentifier = "synthetic.redTarget"
        host.content.addSubview(target)
        button.setTitle("Synthetic interactive button", for: .normal)
        button.addTarget(self, action: #selector(tap), for: .touchUpInside)
        host.content.addSubview(button)
        field.borderStyle = .roundedRect
        field.placeholder = "Synthetic editable input"
        field.text = "probe input"
        host.content.addSubview(field)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.presentStage() }
        return true
    }

    @objc private func tap() { taps += 1 }

    private func presentStage() {
        let stage = stages[stageIndex]
        label.text = "EXPERIMENT ONLY — \(stage)\nBlue is outside protection; red is inside."
        let found = host.setProtected(stage == "protected")
        let flagAvailable = host.setExperimentalLayerFlag(stage == "layer-flag")
        host.layoutIfNeeded()
        let bounds = host.content.bounds
        target.frame = CGRect(x: 20, y: 100, width: max(0, bounds.width - 40), height: 140)
        button.frame = CGRect(x: 12, y: 260, width: max(0, bounds.width - 24), height: 44)
        field.frame = CGRect(x: 16, y: 20, width: max(0, bounds.width - 32), height: 44)
        let point = button.convert(CGPoint(x: button.bounds.midX, y: button.bounds.midY), to: host)
        let hit = host.hitTest(point, with: nil)
        let interactive = hit === button || hit?.isDescendant(of: button) == true
        if interactive { button.sendActions(for: .touchUpInside) }
        let report: [String: Any] = [
            "stage": stage, "layerFlagSetterAvailable": flagAvailable, "canvasFound": found, "canvasClass": host.discoveredCanvasName,
            "contentFrame": NSCoder.string(for: host.content.frame),
            "targetWindowFrame": NSCoder.string(for: target.convert(target.bounds, to: window)),
            "hitTestReachedButton": interactive, "tapCount": taps,
            "fieldText": field.text ?? "", "scale": UIScreen.main.scale,
            "warning": "Undocumented canvas behavior; no Gecko or device acceptance",
        ]
        reports.append(report)
        print(report)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let image = UIGraphicsImageRenderer(bounds: self.window!.bounds).image { context in
                self.window!.layer.render(in: context.cgContext)
            }
            try! image.pngData()!.write(to: self.directory.appendingPathComponent("\(stage)-layer.png"))
            try! Data().write(to: self.directory.appendingPathComponent("\(stage)-ready"))
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in self?.checkCapture() }
        }
    }

    private func checkCapture() {
        let stage = stages[stageIndex]
        guard FileManager.default.fileExists(atPath: directory.appendingPathComponent("\(stage)-captured").path) else { return }
        timer?.invalidate()
        timer = nil
        stageIndex += 1
        if stageIndex < stages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.presentStage() }
        } else {
            try! JSONSerialization.data(withJSONObject: reports, options: [.prettyPrinted, .sortedKeys])
                .write(to: directory.appendingPathComponent("report.json"))
            try! Data().write(to: directory.appendingPathComponent("probe-done"))
        }
    }
}

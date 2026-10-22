// Fennec-style refresh disc overlays the page; it never translates web content.
// Its progress/spinner is an explicit requested motion exception. GPL-3.0.
import UIKit

final class FennecRefreshIndicator: UIView {
    private let arrow = UIImageView(image: UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold)))
    var color: UIColor = .label { didSet { arrow.tintColor = color } }
    private(set) var isAnimating = false
    override var intrinsicContentSize: CGSize { CGSize(width: 40, height: 40) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = FennecTheme.card
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 3
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.contentMode = .scaleAspectFit
        addSubview(arrow)
        NSLayoutConstraint.activate([
            arrow.centerXAnchor.constraint(equalTo: centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 24),
            arrow.heightAnchor.constraint(equalToConstant: 24),
        ])
        accessibilityLabel = FennecTheme.text("Refresh")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func setPullProgress(_ progress: CGFloat) {
        guard !isAnimating else { return }
        arrow.transform = CGAffineTransform(rotationAngle: min(1, max(0, progress)) * .pi * 1.5)
    }
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = Double.pi * 2
        spin.duration = 0.8
        spin.repeatCount = .infinity
        arrow.layer.add(spin, forKey: "refresh.spin")
    }
    func stopAnimating() {
        isAnimating = false
        arrow.layer.removeAnimation(forKey: "refresh.spin")
        arrow.transform = .identity
    }
}

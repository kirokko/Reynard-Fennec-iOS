// Actual AddressBar, AddressBarButton, dismiss button, field and menu compile
// unchanged into this host. Only engine/store/search-result/gesture boundaries
// below are doubles. The previous hand-drawn AddressBar double missed .fill.
import UIKit

struct ReaderModeState { var isActive = false; var isReaderable = false }
struct AddonMenuItem { let title: String }
struct UserDataSearchResult { let title: String; let url: URL }
protocol AddressBarGestureDelegate: AnyObject {}
final class AddressBarGestures {
    init(addressBar: AddressBar, delegate: AddressBarGestureDelegate) {}
    func configure() {}
    func resetHorizontalTransition() {}
    func performAfterTransition(_ completion: @escaping () -> Void) -> Bool { false }
    func animateAutomaticTabTransition(to tab: Tab, returning: Bool, completion: @escaping () -> Void) { completion() }
}
extension BookmarkStore {
    func bookmark(savedFor url: URL) -> BookmarkSnapshot? { nil }
    func isSavedInFavorites(_ url: URL) -> Bool { false }
}
extension Notification.Name {
    static let showFullWebsiteAddressDidChange = Notification.Name("fixture.showFullWebsiteAddress")
}

private func addressDescendants(_ view: UIView) -> [UIView] {
    [view] + view.subviews.flatMap(addressDescendants)
}

func checkRealAddressBar() {
    for width in [320.0, 393, 430, 844, 1024] {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let canvas = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 164))
            canvas.overrideUserInterfaceStyle = style
            let toolbar = BottomToolbar()
            canvas.addSubview(toolbar)
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
                toolbar.bottomAnchor.constraint(equalTo: canvas.bottomAnchor),
            ])
            toolbar.configureTopAnchor(to: canvas.bottomAnchor)
            let bar = AddressBar()
            toolbar.attachAddressBar(bar)
            bar.updateLayout(position: .bottom, chromeMode: .phone)
            bar.setText(nil)
            toolbar.apply(state: .standard, hidesButtons: false)
            canvas.layoutIfNeeded()
            bar.layoutIfNeeded()
            let button = bar.addressBarButton
            button.layoutIfNeeded()
            let field = addressDescendants(bar).compactMap { $0 as? AddressBarTextField }.first!
            precondition(bar.bounds.height == 44)
            precondition(button.bounds.size == CGSize(width: 48, height: 36))
            precondition(button.contentHorizontalAlignment == .center && button.contentVerticalAlignment == .center)
            precondition(button.image(for: .normal)?.size == CGSize(width: 48, height: 36))
            precondition(button.imageView!.bounds.size == CGSize(width: 48, height: 36), "Provider artwork must not undergo a second .fill scaling")
            precondition(abs(button.frame.minX - 4) < 0.5)
            precondition(field.font?.pointSize == 16)
            precondition(field.placeholder == AddressBar.placeholderText)
            let hint = field.attributedPlaceholder!.attribute(.foregroundColor, at: 0, effectiveRange: nil) as! UIColor
            precondition(hint.resolvedColor(with: field.traitCollection).isEqual(FennecTheme.searchHint.resolvedColor(with: field.traitCollection)))
            let fieldFrame = field.convert(field.bounds, to: bar)
            let buttonFrame = button.convert(button.bounds, to: bar)
            precondition(fieldFrame.minX >= buttonFrame.maxX + 7.5)
            precondition(fieldFrame.width > 40 && fieldFrame.maxX <= bar.bounds.width)
            for engine in SearchEngine.pickerEngines {
                bar.selectSearchEngine(engine)
                bar.layoutIfNeeded()
                button.layoutIfNeeded()
                precondition(button.imageView!.bounds.size == CGSize(width: 48, height: 36))
            }
            bar.setText("https://example.invalid/page", showsBarMenu: true)
            bar.layoutIfNeeded()
            precondition(button.backgroundColor == .clear && button.bounds.width == 24)
            precondition(button.contentHorizontalAlignment == .fill)
            bar.setText(nil)
            bar.setEditingState(.focused)
            bar.layoutIfNeeded()
            precondition(button.contentHorizontalAlignment == .center)
            bar.setEditingState(.inactive)
            bar.setText(nil)
            bar.layoutIfNeeded()
            precondition(button.bounds.size == CGSize(width: 48, height: 36))
            FileHandle.standardError.write(Data(("REAL ADDRESS: \(width) style=\(style.rawValue), 44pt bar / 48x36 pill / unscaled artwork / 16pt readable hint PASS\n").utf8))
        }
    }
}

/// Installed in the live UIWindow for a real simctl compositor screenshot.
func realAddressBarScreen(bounds: CGRect) -> UIView {
    let canvas = UIView(frame: bounds)
    canvas.backgroundColor = FennecTheme.surface
    let toolbar = BottomToolbar()
    canvas.addSubview(toolbar)
    NSLayoutConstraint.activate([
        toolbar.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
        toolbar.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
        toolbar.bottomAnchor.constraint(equalTo: canvas.bottomAnchor),
    ])
    toolbar.configureTopAnchor(to: canvas.safeAreaLayoutGuide.bottomAnchor)
    let bar = AddressBar()
    bar.updateLayout(position: .bottom, chromeMode: .phone)
    bar.setText(nil)
    toolbar.attachAddressBar(bar)
    toolbar.setTabCount(2)
    toolbar.apply(state: .standard, hidesButtons: false)
    return canvas
}

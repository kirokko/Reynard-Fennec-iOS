// Real toolbar/count label. Check first inherited trait attachment, not just a
// manually repeated setMode call that would mask the first-entry border bug.
import UIKit

func checkCountColorAndAddressDisplay() {
    func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap { descendants($0) } }
    let host = UIViewController()
    host.overrideUserInterfaceStyle = .dark
    let toolbar = TabOverviewTopToolbar()
    toolbar.setMode(.regularTabs) // before it has the host's inherited traits
    toolbar.apply(tabCount: 1, visibleTabCount: 1, hasVisibleTab: true)
    host.view.addSubview(toolbar)
    NSLayoutConstraint.activate([
        toolbar.topAnchor.constraint(equalTo: host.view.topAnchor),
        toolbar.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
        toolbar.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
        toolbar.heightAnchor.constraint(equalToConstant: 64),
    ])
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
    window.rootViewController = host
    window.isHidden = false
    defer { window.isHidden = true }
    let count = descendants(toolbar).compactMap { $0 as? FennecTabCountLabel }.first!
    for style in [UIUserInterfaceStyle.dark, .light, .dark, .light] {
        host.overrideUserInterfaceStyle = style
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        toolbar.layoutIfNeeded()
        count.layoutIfNeeded()
        let expected = FennecTheme.ink.resolvedColor(with: count.traitCollection).cgColor
        precondition(count.layer.borderColor == expected, "First attachment/trait update must match the selected text")
        let first = count.layer.borderColor
        toolbar.setMode(.regularTabs)
        precondition(count.layer.borderColor == first, "Second tap must not change the icon outline")
    }
    precondition(FennecTheme.siteProtectionImage != nil, "Compile/load the actual pinned shield asset")
    for (source, full, expected) in [
        ("https://example.invalid/search?q=abc", false, "example.invalid/search?q=abc"),
        ("http://example.invalid/a", false, "example.invalid/a"),
        ("https://example.invalid/a", true, "https://example.invalid/a"),
        ("https://user:secret@example.invalid/a", false, "example.invalid/a"),
        ("about:blank", false, "about:blank"),
        ("a plain search", false, "a plain search"),
    ] {
        precondition(FennecAddressDisplay.text(source, fullAddress: full) == expected)
    }
}

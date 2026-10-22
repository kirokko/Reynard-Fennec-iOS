// Real ToolbarController + real BottomToolbar, with engine/chrome boundaries doubled.
// No claim of actual Gecko/APZ timing, OS inset or touch integration acceptance.
import UIKit

func checkToolbarScrollController() {
    let root = UIView(), chrome = BrowserChrome(), content = ContentView(), tabs = TabBar()
    let controller = ToolbarController(browserChrome: chrome, tabBar: tabs, contentView: content, rootView: root)
    controller.updateLayout(chromeMode: .phone, isToolbarEnabled: true, extendsContentBehindToolbar: false)
    func pump(_ duration: TimeInterval) { RunLoop.main.run(until: Date().addingTimeInterval(duration)) }
    func expect(_ offset: CGFloat) {
        precondition(abs(chrome.bottomOffset - offset) < 0.01, "Scroll offset \(chrome.bottomOffset), expected \(offset)")
        precondition(abs(content.bottomOffset - offset) < 0.01, "Engine content must track chrome")
    }
    content.onScrollInteractionBegan?()
    content.onVerticalScroll?(20, 100)
    expect(20) // direct, same callback; no display-link lag or 0.8 multiplier
    pump(0.18)
    expect(20) // stationary finger must never trigger a timer snap
    content.onVerticalScroll?(-7, 93)
    expect(13) // direction reversal is immediate
    content.onScrollInteractionEnded?()
    pump(0.22)
    expect(0) // less than half -> expand
    content.onScrollInteractionBegan?()
    content.onVerticalScroll?(28, 121)
    content.onScrollInteractionEnded?()
    pump(0.22)
    expect(56) // exactly half -> collapse, no tiny-URL remainder
    content.onScrollInteractionBegan?()
    content.onVerticalScroll?(-12, 109)
    expect(44)
    content.onVerticalScroll?(-1000, 0)
    expect(0) // top and overscroll clamp
    content.onVerticalScroll?(1000, 1000)
    expect(56)
    content.onScrollInteractionEnded?()
    content.onScrollInteractionBegan?()
    content.onVerticalScroll?(-36, 964)
    content.onScrollInteractionEnded?()
    pump(0.04) // interrupt a live settle, not just its endpoints
    let visible = chrome.bottomOffset
    content.onScrollInteractionBegan?()
    content.onVerticalScroll?(4, 968)
    expect(visible + 4)
    controller.lock(for: .addressBarEditing)
    expect(0)
    content.onVerticalScroll?(50, 1018)
    expect(0)
    content.onScrollInteractionEnded?()
    pump(0.25)
    expect(0) // no stale snap after focus/search/keyboard/tray locks
    controller.unlock(for: .addressBarEditing)
    for _ in 0..<16 {
        content.onScrollInteractionBegan?()
        content.onVerticalScroll?(40, 100)
        controller.reset(animated: false)
        content.onScrollInteractionEnded?()
        expect(0)
    }
    pump(0.2)
    expect(0)
}

func scrollChromeSample() -> UIView {
    let canvas = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 270))
    canvas.backgroundColor = .systemYellow // makes leftover opaque row backgrounds obvious
    for (index, offset) in [CGFloat(0), 28, 56].enumerated() {
        let band = UIView()
        band.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(band)
        let bottom = BottomToolbar(), address = AddressBar()
        band.addSubview(bottom)
        let safeBottom = UILayoutGuide()
        band.addLayoutGuide(safeBottom)
        NSLayoutConstraint.activate([
            band.topAnchor.constraint(equalTo: canvas.topAnchor, constant: CGFloat(index) * 90),
            band.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            band.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
            band.heightAnchor.constraint(equalToConstant: 90),
            safeBottom.bottomAnchor.constraint(equalTo: band.bottomAnchor, constant: -34),
            safeBottom.topAnchor.constraint(equalTo: band.topAnchor),
            safeBottom.leadingAnchor.constraint(equalTo: band.leadingAnchor),
            safeBottom.trailingAnchor.constraint(equalTo: band.trailingAnchor),
            bottom.bottomAnchor.constraint(equalTo: band.bottomAnchor),
            bottom.leadingAnchor.constraint(equalTo: band.leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: band.trailingAnchor),
        ])
        bottom.configureTopAnchor(to: safeBottom.bottomAnchor)
        bottom.attachAddressBar(address)
        bottom.apply(state: .standard, hidesButtons: false)
        bottom.setTabCount(3)
        canvas.layoutIfNeeded()
        let original = address.convert(address.bounds, to: band)
        bottom.setScrollTranslation(offset)
        let shifted = address.convert(address.bounds, to: band)
        precondition(shifted.size == original.size && shifted.minY == original.minY + offset)
        if offset == 56 {
            for y in stride(from: CGFloat(0), to: 90, by: 4) {
                precondition(bottom.hitTest(CGPoint(x: 40, y: y), with: nil) == nil, "Hidden row must not intercept webpage/home-indicator touches")
            }
        }
    }
    return canvas
}

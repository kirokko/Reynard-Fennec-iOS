# Search input and privacy follow-up (after build #21)

## Search picker

The search field now has the selected provider icon and chevron, with a real
per-search provider picker. The saved default is not changed. The currently
supported providers are Google's existing bundled favicon, Yahoo, Bing, Brave,
DuckDuckGo, Ecosia, Startpage, and a configured valid custom template. We do not
claim every provider visible in Android's screenshot is implemented. Bookmarks,
tabs, history, and search settings route to existing local browser controllers.
The picker uses the existing motion-free ieynec menu, not Android's native menu.

The six additional 64x64 PNGs are site favicons obtained from the public
`https://icons.duckduckgo.com/ip3/{domain}.ico` endpoints, converted locally with
ffmpeg, without sending browsing history or private user media. Domains:
`search.yahoo.com`, `bing.com`, `search.brave.com`, `duckduckgo.com`, `ecosia.org`,
`startpage.com`. They identify their respective providers only. Provider names
and logos remain their owners' trademarks; no affiliation/endorsement is implied.
They are not Mozilla MPL icon paths and are not claimed as original GPL artwork.
No runtime favicon-service request is made by the search picker.

## Input fixes

Clear synthetic completion presentation before UIKit creates a marked-text run.
Do not offer asynchronous autocomplete while marked text exists or replace that
run with the focus-preview replacement shortcut. This addresses the c -> cn
invisible input observed with a Chinese candidate keyboard. The UIKit fixture
uses the real AddressBarTextField and explicit setMarkedText/unmarkText calls;
it is not a full Chinese keyboard or actual AddressBar/Gecko integration test.

Keyboard docking now cancels stale presentation-layer transforms inside a
no-actions transaction, and losing search focus resets docking even without a
keyboard-hide notification. Physical keyboard transitions still need device
validation. These changes do not disable system keyboard animations.

## Privacy

The private homepage has a 44pt top-right return-to-normal button. It returns to
the regular tab that opened the private homepage, when still available, otherwise
the first remaining regular tab, or creates one when none exist. It does not
close private tabs or delete user data.

A scene-bound black UIWindow covers private browsing / private tray content when
UIKit reports screen capture/mirroring, and while the scene is inactive (app
switcher protection). The overlay does not become the key window. Normal mode
remains usable during capture. Because this uses public APIs, private content is
also covered on the device while recording; stop recording to use it again.
Capture notifications are asynchronous and this is not an absolute zero-frame
leak guarantee, nor an audio-recording prevention feature.

**Ordinary screenshots are NOT blocked.** iOS has no public Android FLAG_SECURE
counterpart for arbitrary UIKit/Gecko content. Screenshot notifications occur
after capture; no private secure-layer reparenting or false promise is used.
External-camera filming cannot be blocked on either platform. Private browsing
isolates browsing state; it does not make the user anonymous to websites/network.

Tests: source integration checks, real marked-text lifecycle, the private
homepage's real button action, and capture-policy truth table. Actual capture
notification/window behavior and the full browser remain device acceptance
items until separately verified. The current delivered IPA remains #21 until a
new full build, package verification and explicit delivery are complete.

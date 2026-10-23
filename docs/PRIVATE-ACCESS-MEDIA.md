# Private access and media follow-up

This supersedes the four-engine / radial-background / capture-diagnostic UI in
SEARCH-PRIVATE-FOLLOWUP.md. The engine, SDK, technical identifiers, no-JIT
handshake, App Extensions, and existing user data remain unchanged.

## Presentation

- Search picker/settings: DuckDuckGo, DuckDuckGo (Lite), DuckDuckGo (HTML).
  The legacy Bing enum/endpoints remain decodable, but are not selectable.
  Existing unsupported defaults resolve to DuckDuckGo without deleting bookmarks,
  history or custom templates.
- Homepage search entry: short localized Search prompt, 48 x 36 rounded provider
  capsule with icon and chevron, inset 4pt inside the address capsule. Keep the
  independent new-tab button, tab counter and menu.
- Private homepage: solid private purple, no radial gradient/glow. Keep the real
  Mozilla mask assets, return-to-normal button and help link.
- No address-bar speaker indicator/control. Restored tabs default to browser-
  unmuted; website-player mute/volume remains the website's responsibility.

## Private access lock

- A fresh process has no authenticated private-access state. Private pages and
  the private tray require system identity verification before access, including
  when restoring directly into private mode. Normal browsing remains available.
- Face ID / Touch ID uses LocalAuthentication.deviceOwnerAuthentication, with
  Apple's system device-passcode fallback. No biometric data or app PIN is read
  or stored. If system authentication is unavailable, private access stays locked;
  returning to normal browsing does not delete the private tabs.
- Authentication occurs on the unlock button. Failure/cancel leaves the gate
  visible and permits retry. Success is kept only in process memory, shared by
  browser hosts. Restarting requires verification again; this change does not
  require fresh authentication on every ordinary background/foreground cycle.
- A separate opaque, modal-accessibility, key window gates private pages,
  address/title and tray previews, without reparenting Gecko. Gate installation
  precedes the first visible browser frame, including the iPad sidebar child.
  The underlying keyboard is dismissed; initial private keyboard focus is blocked.
- The existing inactive/app-switcher privacy cover remains. Active unlocked
  private browsing is displayed normally during screenshots/recordings. There is
  no capture-state observer, capture exclusion, or active recording black screen.
- Capture experiments are historical, unreachable from settings, and no longer
  exercised by the normal UIKit fixture. No new capture experiment is run.

This is a UI access gate, NOT encrypted private-tab storage, metadata migration,
secure deletion or a completed private-persistence audit. Existing private title /
URL database storage is not silently changed. It does not promise that an engine
session cannot perform network activity underneath the gate.

## Product demos / autoplay

The requested direction is less automatic product-demo playback, not adding
animations. Apple product demos are commonly muted HTML video rather than GIFs.
For apple.com and its subdomains, the existing Gecko permission path now returns
`blockAll` for autoplay, including muted video, in normal and private sessions.
This is applied both when restoring site permissions and in permission callbacks.
Explicit player gestures remain available. YouTube and other hosts keep their
existing permission behavior; website-player sound is not forced or rewritten.

No global CSS/JS animation disable, synthetic Safari UA, engine upgrade or native
SDK rebuild is introduced. Genuine GIFs, canvas/JS animation or scroll-driven
product effects are not covered by an autoplay permission. A concrete product URL
and physical Gecko test are required before claiming every observed demo is stopped
or rendering matches Safari.

## Verification boundaries

- Node source-policy/localization regressions and shell syntax run locally.
- Real Foundation tests cover new-launch/retry/success access state and exact
  Apple/subdomain matching versus YouTube and lookalike hosts.
- UIKit fixture checks actual lock controls, failure text, normal-return/unlock
  actions and layout at five widths, alongside the three-engine popup. It does
  not simulate a successful physical Face ID verification.
- The normal SideStore workflow must compile/archive the actual app and verify
  its exact-commit IPA. Physical cold-launch/Face ID/cancel/fallback, private tray,
  keyboard/accessibility, YouTube sound and Apple media still require device tests.

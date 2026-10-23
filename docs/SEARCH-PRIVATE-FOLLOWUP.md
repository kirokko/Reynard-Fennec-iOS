# Follow-up after #22: anchored popup, private UI, capture feasibility

> Historical scope: the later three-engine list, solid background, private access
> lock and retirement of the capture diagnostic are documented in
> [PRIVATE-ACCESS-MEDIA.md](PRIVATE-ACCESS-MEDIA.md), which takes precedence.

## Requested UI changes

- Replace the reused full-width bottom menu with a narrow, transparent-outside,
  source-anchored popup. Provider group, bookmark/tab/history group, then a
  separated search-settings row. No drag handle, bottom-sheet adaptation or
  browser-owned animation. Use real routes, not fake search-source statistics.
- Exactly four providers, shared by picker/settings, in this order: DuckDuckGo,
  cn.bing.com, DuckDuckGo (Lite), DuckDuckGo (HTML). They use distinct real HTTPS
  endpoints. Legacy raw preference values remain decodable; a removed default
  resolves to DuckDuckGo without deleting the stored custom template. The
  one-off picker does not overwrite a supported saved default.
- Use Mozilla's actual curved tab outline instead of a rounded-rectangle layer
  border. Private browsing adds the original circled-mask badge. This change is
  for browser chrome; the tray category selection remains a separate control.
- Private home uses a mask-style selected mode button (not a white fox square),
  a purple radial surface, original circular private badge and an actual Mozilla
  help link. No fabricated global tracker statistics or Sync controls are added.
  Geometry/colors are iOS adaptations, not a claim of pixel-identical rendering.

## Reference code (fixed tag, no engine upgrade)

All Mozilla references remain `FIREFOX-ANDROID_158_0_RELEASE`:

- `mobile/android/fenix/app/src/main/java/org/mozilla/fenix/HomeActivity.kt`,
  `createBrowsingModeManager` / `updateSecureWindowFlags`: Android calls
  `window.addFlags(FLAG_SECURE)` in private mode, clears it otherwise.
- `.../ext/Fragment.kt`, `SecureFragment.kt`: secure-screen lifecycle behavior.
- `.../home/ui/PrivateBrowsingDescription.kt`: circular mask, title, description,
  clickable/underlined learn-more action. We retain truthful ieynec-specific copy.
- `mobile/android/android-components/components/ui/tabcounter/src/main/java/mozilla/components/ui/tabcounter/TabCounter.kt`:
  original tab drawable, one/two-digit sizing and private badge.
- `mobile/android/android-components/components/ui/icons/src/main/res/drawable/`:
  `mozac_ic_tab_24.xml`, `mozac_ic_bookmark_tray_24.xml`, `mozac_ic_tab_tray_24.xml`,
  `mozac_ic_history_24.xml`, `mozac_ic_settings_24.xml`,
  `mozac_ic_private_mode_circle_fill_72.xml`,
  `mozac_ic_private_mode_circle_fill_stroke_20.xml`.
  Original vector paths are unchanged. SVG wrappers/fills adapted; each asset
  retains MPL-2.0 attribution. `tools/Import-FennecReferenceIcons.mjs` converts
  locally downloaded XML files reproducibly. Bing favicon updated from public
  `https://cn.bing.com/sa/simg/favicon-trans-bg-blue-mg.ico` (provider trademark).

## Capture experiment: do not confuse tests running with protection working

The owner wants the local phone to remain usable while only captured private
pixels disappear. #22's recording-triggered local black cover is rejected and
removed from active-scene behavior. The inactive-scene/app-switcher cover remains.
**Without a separately proven secure-rendering mechanism, active private pages
are not screenshot/recording protected.**

Inspecting the engine confirms `GeckoView` embeds a real native engine UIView;
Gecko iOS patches use IOSurface/Core Animation composition. Sideloading does not
itself grant system capture exclusion. The Android window flag cannot simply be
translated into Swift or inserted into Gecko CSS.

An isolated, synthetic-only UIKit probe tests hosting arbitrary controls below
UITextField's secure canvas. It does not reassign CALayers or wrap live Gecko.
The internal canvas is undocumented for this purpose. The probe exports normal,
protected and restored screenshots, layer renders, a simulator recording and
hit-test reports. First attempt was a Swift CGRect diagnostic compile failure,
not a capture result. The corrected run
https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39793493042
completed: canvas found, stable layout and three button hit tests, but the red
synthetic target remained in the protected screenshot. This is **no evidence of
capture protection**; simulator behavior also cannot settle actual-device behavior.

A follow-up additionally probes the unsupported CALayer `disableUpdateMask`
setter, only if the selector exists. Run
https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39797126595
completed all four stages: normal, secure canvas, layer flag, restored. The setter
existed, geometry/input/hit tests were stable, but the synthetic red target still
appeared in the layer-flag system screenshot too. This is not protection success. This private mechanism is not a supported
API, entitlement, or verified guarantee. It operates only on synthetic diagnostic
content, never live browser layers. The standalone workflow is manually dispatched,
outputs no IPA and uses no user websites, media or Gecko. The same diagnostic is
accessible via Settings > Advanced > Reynard-specific > Developer > Capture
protection experiment. It works without enabling remote debugging or JIT.

Device test: modes 0/1/2 mean normal/secure canvas/layer flag. The red button must
remain visible and count taps locally, while system screenshot and recording
must lose it. If local content also vanishes, or captures retain it, the required
behavior has NOT passed. The test explicitly says it does not protect browser
tabs. Only after device evidence should a guarded Gecko integration be attempted.
Modal controllers, keyboard, fullscreen video, accessibility, mode reversal and
render-process surfaces require independent integration checks.

## Functional privacy audit remains distinct from visual matching

Current iOS history delegate excludes private visits and returns no visited
statuses; closed private sessions are discarded without ordinary history.
However `TabManagementStore.persistTabs` still stores private titles/URLs in the
local tab database (not full private session serialization). This is a real audit
item, not fixed by masks or screenshot flags. No migration deleting old private
metadata/session state is performed in this UI follow-up; changing restoration
and purging existing local metadata must be handled explicitly, with tests and
clear data-preservation boundaries. Do not describe complete Android private-mode
parity, secure erasure or anonymity as already achieved.

## Validation boundary

New source policies, actual provider-format Foundation cases and real popup/
private UI fixtures are added. Popup screenshots use synthetic data/actions;
Gecko/browser routes and a physical Chinese keyboard are not automated by them.
Full [#26](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39915365500)
succeeded in 21m05s, original SDK cache hit. Production revision
`2a770d3de36a892cafe14d04c10f3af0ae278059`, package `2a770d3`,
106,810,928 bytes, SHA-256
`550BE4C46C5AE4AB7AB1820364056890E222A7A2E9FE9BBF9D9B989617840D46`.
All three actual plists retain original identifiers, 0.18.0 and minimum OS 13.0.
#26 is now current; hash-verified #22 plus origin is retained under rollback.

35 Node source/localization tests, actual SearchEngine/URLUtils Foundation cases,
original tab groups, all Swift parsing, expanded real UIKit fixtures and full
packaging passed. Six isolated Windows downloader tests passed. Actual private
phone fixture, popup and chrome exports were inspected. A synthetic screenshot
was initially missing Bing only because its reduced fixture catalog omitted that
asset; this did not affect the production asset catalog. Fixture-only revision
`1b59cff` adds/asserts it. The resulting UI-only
[#27](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39916776905)
also passed and its corrected screenshot was inspected; it does not change #26's
browser source or create a new IPA.

Earlier #23 and #24 reached a real popup layout hang, not a Gecko compile failure:
320pt wrapped labels caused repeated estimated/fitted height changes. Checkpoints
and a sampled host stack confirmed this. The layout now establishes width only
when changed and assigns only changed final frames. Repeated-layout stability
regression passed across all five widths and both anchor positions. #25 passed
UIKit but was deliberately cancelled before packaging to include the status-bar
safe-area fix found during screenshot review. No intermediate IPA was promoted.

Browser integration, physical IME/capture and actual installed-package acceptance
remain separate device work. Existing deprecation/fixture warnings remain. No
engine/SDK baseline, identifiers, user-data deletion or JIT change was introduced.
All workflows are manual; no recurring or after-conversation tasks are scheduled.

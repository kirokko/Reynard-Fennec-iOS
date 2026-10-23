# Search input and privacy: current #26

## Verified package

Full [#26](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39915365500)
succeeded in 21m05s with the original cached Gecko SDK. App source
`2a770d3de36a892cafe14d04c10f3af0ae278059`, package build `2a770d3`.
106,810,928 bytes; SHA-256
`550BE4C46C5AE4AB7AB1820364056890E222A7A2E9FE9BBF9D9B989617840D46`.
Downloaded and independently hashed; all three actual plists checked. Current
local IPA is #26; #22 and its origin are retained, original hash verified, under
`IPA/rollback/ieynec-no-jit-build22.ipa`. Older rollbacks are unchanged.

## Search popup and providers

The icon/chevron now opens a narrow source-anchored popup, not the rejected full
bottom menu. Four engines, top to bottom: **DuckDuckGo → cn.bing.com → DuckDuckGo
(Lite) → DuckDuckGo (HTML)**. Picker and settings share that list and use actual
distinct HTTPS query templates. The supported saved default is not overwritten
by one-off selection. Older provider raw values still decode; removed choices
resolve to DuckDuckGo without deleting custom-template preference data. New
installs default to DuckDuckGo. Bookmarks, tabs, history and search settings route
to existing browser controllers. Local icon assets make no runtime favicon-service
request. Provider marks remain their owners' trademarks, not original GPL art.
See [reference/provenance and experiment details](SEARCH-PRIVATE-FOLLOWUP.md).

Narrow-phone wrapped labels originally caused estimated/measured popup heights
to oscillate indefinitely. Checkpoint logs and an actual host stack identified
this; measurement width is now established only when changed, final frames are
assigned only when different, and repeated layout must converge. Five widths,
top/bottom anchors and the real standalone diagnostic mode transitions pass.
A later fixture-only change includes the real Bing icon in its reduced asset
catalog; full application assets were already present in #26. UI-only
[#27](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39916776905)
passed and its corrected screenshot was inspected. It produces no new IPA.

## Retained #22 input fixes

Clear synthetic completion before UIKit creates marked text; no asynchronous
completion or focus-preview replacement during a marked run. The real
AddressBarTextField fixture explicitly performs setMarkedText(c/cn)/unmarkText.
This is not a full Chinese keyboard or AddressBar/Gecko end-to-end test.

Keyboard docking cancels stale layer transforms in a disabled-actions transaction;
losing search focus resets docking without requiring a keyboard-hide notification.
Physical keyboard transitions still need device validation. These changes do not
disable the system keyboard's own animation.

## Private UI and state boundaries

Private home now has the original circular mask, adapted purple radial background,
a mask-style 44pt top-right return-to-normal button and an actual Mozilla help
link. Insets use the larger of browser-content and device-safe insets, not their
sum: the return switch must stay clear of the status bar. It returns to the
previous regular tab UUID when still available, otherwise a remaining/new regular
tab. It does not close private tabs or delete user data. Toolbar count uses the
original Android curved-tab vector and a private badge. These are adaptations,
not pixel-identical Android controls.

**Private title/URL persistence is an unresolved audit item.** History callbacks
exclude private visits, but the local tab database still stores their metadata.
This release does not purge existing private data or change restoration behavior.
No claim of complete Android isolation, secure erasure or anonymity is made.

## Capture behavior: #22 local blackout is removed

The scene-bound non-key black UIWindow is now an **inactive-scene/app-switcher
cover only**. Recording an active private page no longer blackens the actual
phone UI. This is not an alternative form of recording protection.

**Ordinary screenshots and active private recordings are NOT proven protected.**
Android's actual implementation uses FLAG_SECURE. iOS exposes no public equivalent
for arbitrary UIKit/Gecko content. Sideloading and Gecko alone do not supply that
capability; they are not reasons to skip experiments either.

Two isolated UIKit probes were actually compiled/run: secure UITextField canvas
hosting and an unsupported CALayer flag. Simulator screenshots retained the
synthetic red target in both cases. Canvas discovery, stable geometry, hit tests,
setter availability and a workflow success do NOT mean capture exclusion passed.
Developer settings offers a clearly labeled synthetic-only diagnostic for device
modes 0/1/2. It never wraps live browser/Gecko content or claims privacy is enabled.
Local UI must remain visible/interactive while system screenshots/recording lose
the target; otherwise the owner's requirement has not passed. Fullscreen video,
keyboard, modal windows and native engine surfaces need separate integration work.

35 source/localization policies, actual provider/URL Foundation tests, original
tab-group tests, Swift parsing, expanded UIKit and full App packaging passed.
Six Windows downloader tests passed again. Actual private-homephone fixture and
popup/chrome exports were inspected. Storage/engine doubles, old lifecycle/region
and deprecated-API warnings remain. These are not complete Gecko or physical
phone acceptance results. No JIT, engine/SDK/identifier change or data deletion.

# UI reference provenance

This is an independent UIKit implementation of selected Android Fennec layout patterns, not an Android binary conversion, Compose port, or official Mozilla distribution. The user-facing name is now ieynec, with user-supplied fox artwork replacing the upstream app icon. Existing author and copyright notices are retained; this is not an official Mozilla/Fennec distribution.

## Screenshot review and version recheck (2026-10-21)

The F-Droid package page and fdroiddata metadata were fetched again with user authorization. The suggested ARM64 release is still **158.0.0 / 1580020**, with the same metadata build commit and Mozilla tag listed below. The Reynard/Gecko baseline is unchanged.

User-provided screenshots were reviewed locally in `Downloads/Telegram Desktop` (not copied into this public repository because they contain browsing data):

- Photos 1–5: installed first-build UI, including homepage, regular/private tabs, private homepage and homepage menu.
- Photo 6: target Fennec homepage: centered logo/wordmark, private shortcut, smaller circular shortcut tiles, Show all, tracker summary and vertical Continue card.
- Photos 7 and 12: target normal tabs and inactive-tab section; white cards, outlined selected card, search/overflow pill and compact plus button.
- Photo 8: black image except OS status/navigation bars; no browser private-page layout can be inferred from it.
- Photos 9–10: tab groups and synced tabs. These are functional features, not merely cosmetic tabs; the fork does not currently implement them.
- Photo 11: homepage menu: drag handle, white surfaces, History before Bookmarks, grouped rows. Unsupported account/password entries remain omitted under the existing agreement.
- Photo 13: target settings typography and spacing. Unsupported features remain omitted, as does the default-browser entry by explicit request.

The existing first-build homepage is visibly not equivalent to photo 6: oversized leading brand, rounded-square shortcuts and horizontal frequent-site cards. The second-pass implementation now reworks those layouts: centered logo/wordmark, compact circular shortcuts, bottom Show all, genuine open-tab Continue card, grouped white menu surfaces, independent full-screen library pages and outlined tab cards. UIKit animations are disabled, with explicit nonanimated tray/toolbar paths. Device comparison is still required; source changes do not prove screenshot parity.

The owner deferred inactive-tab archiving / automatic closing and authorized proceeding with the remaining work. Native local tab groups are now implemented using persistent regular-tab UUID membership, with create/rename/member editing/ungroup/switch actions. Groups do not copy sessions or bookmark folders, and private tabs are excluded from persistence. The groups management page is an independent UIKit implementation, not a claim of exact Fennec group-screen parity. Existing per-session tracker counts are not presented as a persistent all-browser total. Continue uses a genuine open tab, never relabeled history.

The supplied 1024px PNG is used for the app icon, flattened onto white into RGB so the app icon has no alpha channel. iOS applies the home-screen corner mask. Dedicated upstream dark/tinted icons were removed so those appearances cannot fall back to the old Reynard artwork. The matching supplied SVG is archived in `docs/artwork/ieynec.svg` for future rendering. Original input files in Downloads were not modified. Artwork provenance: supplied and selected by the user; no additional third-party license grant is asserted here.

## Pinned references

- F-Droid package: https://f-droid.org/packages/org.mozilla.fennec_fdroid/
- Selected recommended version: **158.0.0**, ARM64 code **1580020**.
- F-Droid metadata build commit: `3b36d79f5e6e43779a0b661a34bc6b1ec30c8bcd`.
- Mozilla tag listed by that metadata: **FIREFOX-ANDROID_158_0_RELEASE**.
- Source root: https://github.com/mozilla-firefox/firefox/tree/FIREFOX-ANDROID_158_0_RELEASE/mobile/android/fenix

Files consulted (relative to the Fenix root):

- `app/src/main/res/xml/preferences.xml`: settings category and entry ordering. Runtime flags and F-Droid patches can hide entries in this file; presence in XML is not proof that it appears in the F-Droid build.
- `app/src/main/java/org/mozilla/fenix/utils/Settings.kt`: configurable top/bottom and expanded-toolbar behavior. This fork implements single-row top/bottom presentation, not every expanded-toolbar variant.
- `app/src/main/java/org/mozilla/fenix/components/menu/compose/MainMenu.kt`: page tools, expandable extension/More rows, library tiles, settings, and navigation placement.
- `app/src/main/java/org/mozilla/fenix/components/menu/compose/MenuNavigation.kt`: back, forward, share, reload/stop ordering and long-press behavior.
- `app/src/main/java/org/mozilla/fenix/components/menu/compose/MoreSettingsSubmenu.kt`: page actions, shortcuts, reader, print.

F-Droid page screenshots inspected:

- https://f-droid.org/repo/org.mozilla.fennec_fdroid/en-US/phoneScreenshots/1.png
- https://f-droid.org/repo/org.mozilla.fennec_fdroid/en-US/phoneScreenshots/2.png
- https://f-droid.org/repo/org.mozilla.fennec_fdroid/en-US/phoneScreenshots/3.png

The screenshots are not vendored and may change independently of a release. They show a top address bar with new-tab/tab-count/overflow controls, top tab categories with floating new-tab/overflow buttons, and extension management. Exact parity must be evaluated on-device against the selected F-Droid version; typography, system chrome, safe areas and unsupported features differ on iOS.

The reference Mozilla source files carry MPL-2.0 notices. This fork does not copy their Kotlin implementation. The applicable Reynard licenses remain in the repository root; consult the referenced source if reusing code from it in future work.

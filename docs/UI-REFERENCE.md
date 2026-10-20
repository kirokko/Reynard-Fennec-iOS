# UI reference provenance

This is an independent UIKit implementation of selected Android Fennec layout patterns, not an Android binary conversion, Compose port, or official Mozilla distribution. The upstream Reynard icon and existing copyright notices are retained; no claim is made to Mozilla/Fennec branding.

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

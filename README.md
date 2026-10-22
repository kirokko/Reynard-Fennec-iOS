# ieynec — experimental Fennec-style iOS browser

**Unofficial** Fennec-inspired UI on [Reynard Browser](https://github.com/minh-ton/reynard-browser), retaining its Gecko engine and iOS integration. This is not a Mozilla product or an official Fennec iOS release.

开发记录与需求：**[PROJECT.zh-CN.md](PROJECT.zh-CN.md)**。原项目说明和作者致谢：**[docs/UPSTREAM_README.md](docs/UPSTREAM_README.md)**。

## Status / 当前状态

**Latest verified package: [build #21](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39755850470)**, App revision `6ce67d68482ebf1f4e940135153fc0310deda603` / build `6ce67d6` (30m04s, cached Gecko SDK). Current local `Downloads\ieynec-项目\IPA\current\ieynec-no-jit.ipa`, 106,731,181 bytes; SHA-256 `EF9E93FD6303CBDF880DDA72FEA4577616D762CBC83C4070984F824FACFA003F`. Main App and both extension plists checked. Selected count outlines refresh at first attachment/trait/layout, without a second tap; the old Reynard private-tray intro factory/background is removed, leaving one Fennec explanation. The entire bottom plate now translates top-to-bottom as one piece, including its OS inset, with identical visual/Gecko offsets and no separate clipping/fade phase. Address display uses the pinned Android shield, URL rather than domain/title composite, and reference-sized text/controls. Twenty-five source checks, Foundation groups, Swift parsing, expanded UIKit, full App packaging and six downloader tests passed; component images inspected. **Complete Gecko/APZ motion, first-entry tray and private-tray cleanup still require actual-device acceptance.** No JIT, SDK/engine, identifiers or stored-data change. [Details](docs/VIDEO-REVIEW.md).

**Previous delivered package: [build #20](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39740615453)**, App revision `c670ded36f1cc911059db42004d252f646307999` / build `c670ded` (successful attempt 2: 28m04s, cached Gecko SDK). `Downloads\ieynec-项目\IPA\rollback\ieynec-no-jit-build20.ipa`, 106,727,821 bytes; SHA-256 `1480011DFAD406118EB8DF5E19ACB9B287ECBA4F378B904659B13998C6796DC8`. Main App and both extension plists checked. Collapsed bottom chrome now releases the home-indicator area to webpage content instead of retaining an opaque empty strip. Shortcuts size from the section's resolved width on the first layout, without requiring a More tap. The fixture now compiles the real favorites controller and collection layout against bookmark/cell doubles; six cells appear under explicitly zero initial collection bounds. Twenty-three source/localization checks, Foundation groups, Swift parsing, expanded UIKit, full App packaging and six Windows downloader tests passed. Actual fixture screenshots inspected. First attempt timed out during Simulator preparation; rerunning the same source passed. Device confirmation of full Gecko bottom-area rendering, fixed website footers and initial shortcuts remains necessary. No JIT/engine/SDK or stored-data change. [Details](docs/VIDEO-REVIEW.md).

**Previous delivered package: [build #19](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39733757293)**, App revision `bba987627c85912aa9eac240d8e6928a5c7ae946` (26m48s, cached Gecko SDK). `Downloads\ieynec-项目\IPA\rollback\ieynec-no-jit-build19.ipa`, 106,729,811 bytes; SHA-256 `82F110EF40A7CC9FCBF4B95A9C086BD6ACA17B86C8C73AE31A0B5F208A202AE4`. Main App and both extension plists checked (build `bba9876`, original identifiers, minimum OS 13.0). New device feedback prompted a dimensional light-gray icon surface instead of a flat white plate, removal of frequent sites and its settings entry, and a one-time upgrade default enabling real shortcuts. The bottom phone toolbar now slides as a complete row at 1:1 scroll distance, retaining only the OS inset: no shrinking URL strip or early button fade. Endpoint settling uses the pinned Android 150ms decelerator; stationary-touch interruption, reversal, locks and hidden-row hit testing have regressions. Twenty-two source/localization checks, Foundation groups, Swift parsing, expanded UIKit fixture, full App packaging and six Windows downloader tests passed. Actual fixture screenshots inspected. **Installed icon appearance and complete Gecko/APZ scroll parity still require device acceptance**; system keyboard-animation suppression remains unresolved. No JIT, engine/SDK or data-storage change. [Details](docs/VIDEO-REVIEW.md).

**Previous delivered package: [build #17](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39725171193)**, App revision `12dec95dc2612e23063dacff8881de71138b9bec` (24m32s, cached Gecko SDK). `Downloads\ieynec-项目\IPA\rollback\ieynec-no-jit-build17.ipa`, 106,640,271 bytes; SHA-256 `67DD4CC8A841EE952EF788D5255B0A7C4CCF0CD5977454E6563CA7EC55DE77CC`. Main App and both extension plists checked. Annotated-image fixes restore the real toolbar plus, use the original pinned Android private-mask vector (MPL-2.0), refine tray controls and reframe the opaque app icon. Phone fullscreen starts portrait, with a lower-left button for gravity-selected landscape; system portrait-lock compatibility is **not device-verified**. Refresh overlays a progress disc instead of translating the page. Only reference-specific phone address-bar scroll/settling and refresh progress are motion exceptions. App-owned focus/input relocation is nonanimated; disabling the **system keyboard's own** animation is still unresolved. Nineteen source/localization checks, Foundation tests, Swift parsing, real-asset expanded UIKit fixture and full App packaging passed. Final category/private images inspected. [Details and acceptance limits](docs/VIDEO-REVIEW.md).

**Previous no-JIT baseline (#11, retained for rollback):** at the owner's request JIT has been removed from settings and runtime enablement. Existing enabled preferences are ignored/migrated; Gecko receives explicit no-JIT child-process status. No LocalDevVPN, pairing file or DDI is needed for browsing with this source revision. Private-mode layout, tray menu, homepage switches, Traditional Chinese and address-focus/keyboard docking have been revised after a local video review. See [review, remaining differences and performance limits](docs/VIDEO-REVIEW.md). The full [build #11](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39712078402) succeeded at App revision `98d694d34a4319ec3b0e4c0bc7d9f93285bcdc24` (28m23s). Archived package: `Downloads\ieynec-项目\IPA\rollback\ieynec-no-jit-build11.ipa`, SHA-256 `9C68D4F63649F692C21F62F8FAE55D378417B712381AF46C049749D3AB94D5FD`. Expanded UIKit checks passed, including real download chips/classification and bookmark comparator directions; actual private/groups compositor images were inspected. No SideStore/device acceptance or measured performance gain is claimed. Build #7 below is historical, still contains JIT, and is retained under `IPA\rollback`.

**Historical build notes (not the current package):** Development build, not a verified release. First-build run [#2](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39544125387) completed successfully and was installed on the owner's iPhone. Their screenshots showed substantial layout differences. The second-pass source now uses the name **ieynec**, the supplied icon, a reworked homepage/menu/tab tray and motion-free presentation. This revision passed its own complete [build #3](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39589249099) at source commit `685b36afe334a7dc7c9b8a35931979e38786a4e8`, including the local tab-group persistence test. The owner installed that IPA and reported an all-white startup. Their local device log confirms a scene-create watchdog termination while UIKit was laying out the first frame, not a verified JIT failure. **Build #3 is not recommended for use.** Build #4 restored visible UI in the owner's subsequent screenshots, but exposed viewport/card sizing, tab-category icon and missing-exit issues. **The current UI-fix candidate is [build #7](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39603345135), App source `39a3adf`: `Downloads\ieynec-ui-fix.ipa`.** It removes the old animated tab-tray presentation implementation and hardens sizing, icons and navigation exits. Expanded UIKit regression tests and [a separate actual Simulator screen review](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39608419357) passed. Test hosts use real native UI/presentation code with mocked store/engine sections and context, not a full Gecko/SideStore/JIT integration test. Complete device confirmation remains pending. No pixel-perfect parity or complete functional acceptance is claimed.

- Functional baseline: Reynard **0.18.0 alpha**, commit `860bb6f4d0ff2b5d45f7dbe48eca8f39ee88a4fa`.
- UI reference: F-Droid Fennec **158.0.0 / 1580020**, Mozilla source tag `FIREFOX-ANDROID_158_0_RELEASE` and F-Droid screenshots.
- Intended device: iPhone 17 / iOS 26.6 / SideStore.
- **Manual maintenance only.** No app update feed, scheduled build, automatic upstream merge, or automatic app replacement. Gecko and the owner-modified UI stay pinned until the owner chooses to update them. This also means upstream security fixes are **not** adopted automatically.
- Existing Firefox add-on update behavior is separate from application updates and has not been removed.

## Interface changes

- Single-row, opaque top/bottom browser toolbar: address pill → real new-tab plus → tab count → vertical overflow. Tray creation and long-press recent-tab recovery remain available.
- Top bar by default; bottom position remains configurable.
- Main menu: page bookmark, find, desktop mode, extension actions, expandable More, library shortcuts, settings. Back/forward/share/reload live in its navigation row. Long-press history navigation and hard reload remain available.
- Privacy/regular tabs use top icon categories, white preview cards with selected outlines, and a floating search/overflow pill and compact plus. Native local groups reference existing regular-tab UUIDs; grouping, renaming, membership editing and ungrouping do not duplicate sessions or turn bookmarks into tabs. No inactive-tab archiving/auto-close or fake Sync tab is added.
- Settings are ordered around Fennec's General, Privacy and security, Advanced, and About categories. Existing non-JIT engine controls remain under Advanced → Reynard-specific. No iOS / JIT section is exposed.
- Centered icon/wordmark, compact circular shortcuts with Show all below, and a vertical Continue card linked to a real open regular tab. Recently closed/donation sections remain under More; frequent sites and its settings entry have been removed without deleting history. Shortcuts default on, including a one-time upgrade migration, and can still be disabled manually afterward. The protection chip opens real tracking settings, without fabricating a persistent global count. Continue/protection cards have real visibility switches; obsolete application update controls are removed.
- Phone settings/bookmarks/history/downloads open as independent full-screen pages, not a bottom library tab bar inside a sheet. Data and actions remain connected to their original stores.
- App-owned UIKit transitions are disabled, including tab overview, search focus and keyboard-driven layout. Explicit reference exceptions are the phone address bar following/settling after page scroll and refresh progress. Web CSS/JS and OS-owned animations are separate; system keyboard-animation suppression remains unresolved.
- Material-inspired light/dark colors and Simplified/Traditional Chinese strings for new UI.

System file pickers, sharing, printing, permissions and similar OS-owned dialogs remain native iOS UI. Original deeper preference/extension management pages are restyled, not a port of Android Compose or GeckoView-Android. Further screen-by-screen parity work and device QA remain necessary.

Entries with no Reynard implementation (Mozilla account/Sync, native password/card management, Collections, etc.) are omitted, not replaced by nonfunctional switches. No default-browser setting is provided.

## Cloud build (no Mac required)

The public repository exposes **Build SideStore IPA (manual)** under Actions. Start it manually on the branch you want to build. It invokes the adapted upstream macOS/Xcode build, which:

1. Checks source policy, string catalogs and Swift syntax.
2. Checks out the pinned engine and support-library submodules and applies Reynard patches.
3. Compiles Gecko and the iOS app, or restores a matching, self-contained cached Gecko SDK.
4. Uploads the standard IPA as the **Reynard-Fennec-SideStore** artifact. Inside the artifact the filename is **Reynard.ipa**.

The first engine build can take hours. The engine SDK is cached **before** Swift app compilation, so fixing a UI compilation error should not necessarily require rebuilding Gecko. Cache availability is not guaranteed. Only standard GitHub-hosted runners are requested, not paid larger runners. Repository/account limits can still prevent jobs from starting.

No Apple ID, pairing record, development certificate or signing private key is needed by this workflow. SideStore performs the final development signing. A successfully packaged IPA still requires real-device testing.

### Download a completed build on Windows

With GitHub CLI installed and authenticated, run this from the project folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Download-IPA.ps1
```

It selects the most recent successful manual run with an unexpired SideStore IPA artifact (skipping UI-only checks), downloads it to `Downloads\ieynec-latest.ipa` without overwriting the first-pass rollback file, checks that app extensions are present, and writes the commit/build URL/SHA-256 beside it. If no successful build exists, it fails explicitly. It does not start a build or update an installed app.

For the current no-JIT candidate specifically (UI-only workflow runs have no IPA):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Download-IPA.ps1 -RunId 39755850470 -Destination "$env:USERPROFILE\Downloads\ieynec-项目\IPA\current\ieynec-no-jit.ipa"
```

The default legacy filename remains compatible with existing shortcuts; the explicit destination above preserves the first-build IPA for rollback.

For one already-started run, `tools/Watch-Build.ps1 -RunId <id>` can wait for at most seven hours and download **only that run** if it succeeds. It writes a status file in Downloads and then exits. It is not an updater, scheduled task, or build retry service; it does not monitor later releases.

Source ZIP snapshots omit the engine/support submodule contents; the pinned references remain in Git and the cloud workflow obtains them from upstream. Do not mistake a source ZIP for an IPA.

## Installing with SideStore

- Follow Reynard's [installation requirements](docs/UPSTREAM_README.md#installation).
- Keep **App Extensions** when SideStore asks. The browser cannot function correctly without them.
- This fork retains the upstream bundle identifiers to avoid untested changes to the engine/helper integration. Under the same SideStore signing identity it may replace the original Reynard rather than install alongside it. Back up important browser data first. Do not uninstall an existing browser just to test this build unless you accept losing its data.
- Application display name: **ieynec**. Repository, build artifact and internal executable names remain compatible with the original download workflow; an artifact containing `Reynard.ipa` is expected.
- Current source runs Gecko **without JIT** by owner request. No VPN or pairing setup is needed for ordinary browsing. This does not promise Safari-level JavaScript performance. Historical IPA #7 and earlier still have the upstream JIT feature; a source change does not modify an installed App.
- Do **not** commit pairing records or account credentials to this public repository.

## Local checks

With Node.js 20+:

```sh
node --test tests/*.test.mjs
```

On macOS with Xcode:

```sh
find browser -name '*.swift' -print0 | xargs -0 xcrun swiftc -frontend -parse
xcrun swiftc browser/Reynard/Client/TabManagement/TabGroupStore.swift tests/tab-groups.test.swift -o /tmp/ieynec-tab-group-tests
/tmp/ieynec-tab-group-tests
```

On Windows, the downloader also has six isolated mock-artifact tests (success, failed run, missing extensions, no successful run, skipping a successful UI-only run, and rejecting UI-only results):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\download-ipa.test.ps1
```

These are source/syntax/download-tool checks, not browser UI, integration or runtime tests. Full build prerequisites are in the upstream README.

## Adopting a newer Reynard manually

Work on a separate branch, preserve the current version, and review upstream diffs rather than overwriting this fork with upstream main. For example, in a new clone of **this** repository:

```sh
git remote add upstream https://github.com/minh-ton/reynard-browser.git
git fetch upstream tag <new-release-tag>
git switch -c review-upstream-update
git diff 0.18.0..<new-release-tag> -- browser patches engine tools
```

Integrate only the chosen changes, review API/engine compatibility, update the documented baseline if appropriate, run checks, and manually trigger a build. Engine changes invalidate the SDK cache through patch/build/version/submodule/toolchain hashes. Do not ship a newly adopted feature until its entry point and settings location have been reviewed against the chosen UI design.

## License and credits

Reynard is by **Minh Ton** and contributors. Retain the original copyright notices, acknowledgements and licenses when distributing modified versions.

- App source and this fork's modifications: **GNU GPL v3**, see [LICENSE](LICENSE).
- Gecko patches: **Mozilla Public License 2.0**, see [LICENSE.firefox](LICENSE.firefox).
- Android Fennec/Firefox source is used as a design/behavior reference. Android sources and logos are not represented as original work of this fork. See [UI reference notes](docs/UI-REFERENCE.md).

When distributing an IPA, make its corresponding source revision, engine references, patches and build instructions available in accordance with the applicable licenses.

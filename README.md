# ieynec — experimental Fennec-style iOS browser

**Unofficial** Fennec-inspired UI on [Reynard Browser](https://github.com/minh-ton/reynard-browser), retaining its Gecko engine and iOS integration. This is not a Mozilla product or an official Fennec iOS release.

开发记录与需求：**[PROJECT.zh-CN.md](PROJECT.zh-CN.md)**。原项目说明和作者致谢：**[docs/UPSTREAM_README.md](docs/UPSTREAM_README.md)**。

## Status / 当前状态

Development build, not a verified release. First-build run [#2](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39544125387) completed successfully and was installed on the owner's iPhone. Their screenshots showed substantial layout differences. The second-pass source now uses the name **ieynec**, the supplied icon, a reworked homepage/menu/tab tray and motion-free presentation. This revision passed its own complete [build #3](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39589249099) at source commit `685b36afe334a7dc7c9b8a35931979e38786a4e8`, including the local tab-group persistence test. The owner installed that IPA and reported an all-white startup. Their local device log confirms a scene-create watchdog termination while UIKit was laying out the first frame, not a verified JIT failure. **Build #3 is not recommended for use.** Build #4 restored visible UI in the owner's subsequent screenshots, but exposed viewport/card sizing, tab-category icon and missing-exit issues. **The current UI-fix candidate is [build #7](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39603345135), App source `39a3adf`: `Downloads\ieynec-ui-fix.ipa`.** It removes the old animated tab-tray presentation implementation and hardens sizing, icons and navigation exits. Expanded UIKit regression tests and [a separate actual Simulator screen review](https://github.com/kirokko/Reynard-Fennec-iOS/actions/runs/39608419357) passed. Test hosts use real native UI/presentation code with mocked store/engine sections and context, not a full Gecko/SideStore/JIT integration test. Complete device confirmation remains pending. No pixel-perfect parity or complete functional acceptance is claimed.

- Functional baseline: Reynard **0.18.0 alpha**, commit `860bb6f4d0ff2b5d45f7dbe48eca8f39ee88a4fa`.
- UI reference: F-Droid Fennec **158.0.0 / 1580020**, Mozilla source tag `FIREFOX-ANDROID_158_0_RELEASE` and F-Droid screenshots.
- Intended device: iPhone 17 / iOS 26.6 / SideStore.
- **Manual maintenance only.** No app update feed, scheduled build, automatic upstream merge, or automatic app replacement. Gecko and the owner-modified UI stay pinned until the owner chooses to update them. This also means upstream security fixes are **not** adopted automatically.
- Existing Firefox add-on update behavior is separate from application updates and has not been removed.

## Interface changes

- Single-row, opaque top/bottom browser toolbar: address pill → tab count → vertical overflow. New-tab creation and recent-tab recovery remain in the tab tray and long-press menus.
- Top bar by default; bottom position remains configurable.
- Main menu: page bookmark, find, desktop mode, extension actions, expandable More, library shortcuts, settings. Back/forward/share/reload live in its navigation row. Long-press history navigation and hard reload remain available.
- Privacy/regular tabs use top icon categories, white preview cards with selected outlines, and a floating search/overflow pill and compact plus. Native local groups reference existing regular-tab UUIDs; grouping, renaming, membership editing and ungrouping do not duplicate sessions or turn bookmarks into tabs. No inactive-tab archiving/auto-close or fake Sync tab is added.
- Settings are ordered around Fennec's General, Privacy and security, Advanced, and About categories. Existing engine controls remain under Advanced → Reynard-specific, with iOS / JIT separately available.
- Centered icon/wordmark, compact circular shortcuts with Show all below, and a vertical Continue card linked to a real open regular tab. Existing frequent sites/recently closed/donation sections remain under More. The protection chip opens real tracking settings, without fabricating a persistent global count. JIT advice is in settings; upstream application update prompts are suppressed.
- Phone settings/bookmarks/history/downloads open as independent full-screen pages, not a bottom library tab bar inside a sheet. Data and actions remain connected to their original stores.
- App-owned UIKit animations are disabled; tab overview transitions and toolbar display-link interpolation bypass animated paths. Direct scrolling/dragging, web CSS/JS animations and OS-owned UI are not disabled.
- Material-inspired light/dark colors and Simplified Chinese strings for new UI.

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

For the latest UI-fix candidate specifically (UI-only workflow runs have no IPA):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Download-IPA.ps1 -RunId 39603345135 -Destination "$env:USERPROFILE\Downloads\ieynec-ui-fix.ipa"
```

The default legacy filename remains compatible with existing shortcuts; the explicit destination above preserves the first-build IPA for rollback.

For one already-started run, `tools/Watch-Build.ps1 -RunId <id>` can wait for at most seven hours and download **only that run** if it succeeds. It writes a status file in Downloads and then exits. It is not an updater, scheduled task, or build retry service; it does not monitor later releases.

Source ZIP snapshots omit the engine/support submodule contents; the pinned references remain in Git and the cloud workflow obtains them from upstream. Do not mistake a source ZIP for an IPA.

## Installing with SideStore

- Follow Reynard's [installation requirements](docs/UPSTREAM_README.md#installation).
- Keep **App Extensions** when SideStore asks. The browser cannot function correctly without them.
- This fork retains the upstream bundle identifiers to avoid untested changes to the engine/helper integration. Under the same SideStore signing identity it may replace the original Reynard rather than install alongside it. Back up important browser data first. Do not uninstall an existing browser just to test this build unless you accept losing its data.
- Application display name: **ieynec**. Repository, build artifact and internal executable names remain compatible with the original download workflow; an artifact containing `Reynard.ipa` is expected.
- Pairing-based JIT is already integrated into the browser: it does **not** require a separately sideloaded StikDebug for this browser. JIT still needs the pairing record, supported device/OS, required DDI and a loopback VPN. The upstream guide currently requires Wi-Fi and LocalDevVPN (installed from the App Store, not a SideStore slot). Use the retained iOS / JIT settings and the upstream [manual JIT guide](https://github.com/minh-ton/reynard-browser/wiki/Manually-Enabling-JIT). This does not provide JIT to other LiveContainer apps.
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

On Windows, the downloader also has four isolated mock-artifact tests (success, failed run, missing extensions, and no successful run):

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

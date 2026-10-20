# Reynard Fennec — experimental iOS fork

**Unofficial** Fennec-inspired UI on [Reynard Browser](https://github.com/minh-ton/reynard-browser), retaining its Gecko engine and iOS integration. This is not a Mozilla product or an official Fennec iOS release.

开发记录与需求：**[PROJECT.zh-CN.md](PROJECT.zh-CN.md)**。原项目说明和作者致谢：**[docs/UPSTREAM_README.md](docs/UPSTREAM_README.md)**。

## Status / 当前状态

Development build, not a verified release. Interface changes are implemented in source, but full iOS compilation and device acceptance must succeed before an IPA can be considered usable. No claim of pixel-perfect parity with Android is made without device screenshots and comparison.

- Functional baseline: Reynard **0.18.0 alpha**, commit `860bb6f4d0ff2b5d45f7dbe48eca8f39ee88a4fa`.
- UI reference: F-Droid Fennec **158.0.0 / 1580020**, Mozilla source tag `FIREFOX-ANDROID_158_0_RELEASE` and F-Droid screenshots.
- Intended device: iPhone 17 / iOS 26.6 / SideStore.
- **Manual maintenance only.** No app update feed, scheduled build, automatic upstream merge, or automatic app replacement. Gecko and the owner-modified UI stay pinned until the owner chooses to update them. This also means upstream security fixes are **not** adopted automatically.
- Existing Firefox add-on update behavior is separate from application updates and has not been removed.

## Interface changes

- Single-row, opaque top/bottom browser toolbar: address pill → new tab → tab count → vertical overflow.
- Top bar by default; bottom position remains configurable.
- Main menu: page bookmark, find, desktop mode, extension actions, expandable More, library shortcuts, settings. Back/forward/share/reload live in its navigation row. Long-press history navigation and hard reload remain available.
- Privacy/regular tabs use top categories, a two-column card grid on phones, title/close controls above previews, and floating overflow/new-tab actions. There is no fake Sync tab.
- Settings are ordered around Fennec's General, Privacy and security, Advanced, and About categories. Existing engine controls remain under Advanced → Reynard-specific, with iOS / JIT separately available.
- Existing shortcuts and browsing sections remain on the homepage; extra Reynard content is under More. JIT advice is in settings; upstream application update prompts are suppressed.
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

## Installing with SideStore

- Follow Reynard's [installation requirements](docs/UPSTREAM_README.md#installation).
- Keep **App Extensions** when SideStore asks. The browser cannot function correctly without them.
- This fork retains the upstream bundle identifiers to avoid untested changes to the engine/helper integration. Under the same SideStore signing identity it may replace the original Reynard rather than install alongside it. Back up important browser data first. Do not uninstall an existing browser just to test this build unless you accept losing its data.
- Application display name: **Reynard Fennec**.
- JIT is not enabled merely by installing the IPA. Use the retained iOS / JIT settings and the upstream [manual JIT guide](https://github.com/minh-ton/reynard-browser/wiki/Manually-Enabling-JIT).
- Do **not** commit pairing records or account credentials to this public repository.

## Local checks

With Node.js 20+:

```sh
node --test tests/*.test.mjs
```

On macOS with Xcode:

```sh
find browser -name '*.swift' -print0 | xargs -0 xcrun swiftc -frontend -parse
```

These are source/syntax checks, not UI, integration or runtime tests. Full build prerequisites are in the upstream README.

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

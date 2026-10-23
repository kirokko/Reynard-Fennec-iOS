# Agent build/delivery rules

Goal: shortest reliable edit-to-downloadable **current-commit SideStore IPA**.
These rules do not authorize background jobs after the conversation ends.

## Normal feature/UI changes

1. Make and locally test the requested change. Preserve Gecko, Firefox/App
   Extensions, identifiers, user data, no-JIT and existing motion policy.
2. Commit/push the exact requested branch. Capture `git rev-parse HEAD`.
3. Use the existing workflow once (do not additionally launch unrelated UIKit-only
   or capture experiment workflows):
   ```sh
   gh workflow run build-sidestore.yml --repo kirokko/Reynard-Fennec-iOS \
     --ref fennec-ios -f test_strategy=auto
   ```
   Use the actual development ref when working on an authorized isolated branch.
   Resolve the dispatched run by its ref, exact head SHA and dispatch time, not
   simply the newest successful run. Record its run ID immediately.
4. `auto` always runs Node policies/localizations, real Foundation tests and Swift
   parsing. It reuses UIKit only for the exact same source/test/toolchain key;
   changed browser/test inputs run the existing simulator suite automatically.
   Use `test_strategy=full` for forced complete revalidation. `light` deliberately
   omits Simulator checks and is only appropriate for an explicitly scoped task,
   not as a silent default for UI changes. `ui_checks_only=true` still executes
   full UIKit checks but produces NO IPA.
5. Native SDK and idevice binary caches are exact-input and integrity checked.
   DerivedData is only an incremental compiler aid; source bytes govern timestamp
   restoration. Always create a new archive and IPA. Do not return a cached IPA.
6. Wait for **this run** to succeed. Verify `headSha` equals the intended commit;
   download the `Reynard-Fennec-SideStore` artifact from this run ID. It contains
   `Reynard.ipa` plus `Reynard.ipa.provenance.json` (full commit, SHA-256, three
   checked plist build IDs). Hash the downloaded IPA and compare provenance.
   Existing `tools/Download-IPA.ps1 -RunId <id> -Destination <staging-path>` is
   compatible. Never omit RunId when delivering a requested modification.
7. Provide the exact run/artifact download link, commit and IPA hash. If promoting
   local `IPA/current`, first verify/archive the previous IPA and its origin.
   SideStore overwrite; retain ALL App Extensions; do not uninstall/clear data.
8. On failure show the failing step and actual logs/run URL. A previous successful
   run is a rollback only, not the result of the new modification. Fix the cause
   before rerunning; do not blindly trigger additional workflows.

## Build-system validation

- Modify workflows on an isolated branch first. Keep all three existing workflows
  and all reusable normal/nightly/TrollStore/jailbroken inputs and artifacts.
- `rebuild_native=true` is a deliberately slow recovery/test path: no binary
  Gecko/idevice restore; it must run the real source preparation/build. Dependency
  download caches/sccache may still assist. It is not a daily Agent default.
- Measure both cold/new and warm caches; distinguish SDK migration, binary cache
  misses, compatible Xcode snapshot reuse and UIKit reuse. Do not label a native
  source build or an unchanged-source repeat as a representative UI-edit speed.
- Keep exact commit/product verification before artifact upload. Caching failures
  must not suppress compiler/test failures or authorize stale product reuse.

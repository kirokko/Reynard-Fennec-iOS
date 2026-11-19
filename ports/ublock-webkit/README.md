# Unofficial full uBlock Origin → WebKit port experiment

**Research prototype, not an official uBO build, not uBO Lite, not a production
browser/IPA, and not full Firefox API compatibility.** GPL-3.0-or-later overlay;
upstream remains Copyright Raymond Hill and contributors, GPL-3.0-or-later.
Upstream `LICENSE.txt`, attribution and original assets remain in the staged
package; the single explicit API-binding patch is recorded in `patches.json`
and provenance hashes. Source modifications invalidate Mozilla's signature:
the staging tool removes `META-INF` and records this explicitly.

## What actually runs

1. Download the pinned official **full Firefox XPI** described in
   `tests/webkit-smoke/ublock-package.json`. Verify SHA-256 before extraction.
2. Keep upstream content scripts, popup/dashboard HTML/CSS and engine assets
   byte-for-byte, except for the declared shared `vapi-common.js` forwarding
   patch preserving WebKit's native API receiver (`getURL`). No fake API is
   added. Modify the manifest explicitly for a non-persistent iOS research
   background, add this overlay, and verify original/modified source hashes.
3. In a dedicated module Worker, run **the converter included in the full uBO
   package**, `js/static-dnr-filtering.js`, using its original parser/compiler.
   It shares upstream code with other uBO projects; this does not download,
   install or rename a Lite build. This conversion path is declarative and has
   limitations; using full source alone does NOT recreate Firefox capabilities.
4. Install candidate rules through the public native
   `browser.declarativeNetRequest.updateDynamicRules`. Read back the set and
   roll back if it differs. Never first erase the old rules in a separate call.
5. Start the original `js/start.js`, seed a tiny local test filter list through
   original storage keys, and separately observe its readiness, original
   cosmetic/scriptlet behavior, and original `popup-fenix.html` rendering.
   Missing browser APIs are NOT replaced with fake success/no-op objects.
6. Listen to original `user-filters` storage changes and recompile/replace the
   native rule set. Other uBO settings are NOT wired to native filtering yet.

The native host is `tests/webkit-smoke/UBlockPortProbe.m`; it uses a fresh,
disposable extension identity/store context and a localhost server, no Gecko,
private API, VPN, JIT entitlement, or external filtering proxy.

## Honest feature boundary

This is a **user-filter static network backend prototype**. It is not yet the
backend for all of uBO's normal lists or controls. In particular:

- Original popup power/whitelist switches, dynamic firewall/URL rules, list
  selection/update, and accurate per-tab network logs are **not synchronized**
  with DNR. Do not expose the prototype as a working end-user blocker.
- HTML response filtering and Firefox request-time arbitrary decisions remain
  unavailable through this backend. No fake `webRequestBlocking` API is added.
- Scriptlets/cosmetics are delegated to original upstream code; native test
  results, not retained HTML files, determine whether they work.
- `nonNetwork` records every cosmetic/scriptlet/HTML/response-header input
  and its disposition. Upstream `_error` conversion failures remain in the
  report. Native rejection is an explicit transaction failure, not silent
  dropping of a bad rule. Semantic equivalence is not claimed for untested DNR
  features or regex dialects, even when a rule parses.
- Upstream merges/splits network rules; candidate counts are NOT percentages
  of compatible original filters and NOT one-to-one coverage statistics.
- The bundled `assets/ublock/filters.min.txt` audit is conversion-only; those
  candidates are **not** installed or accepted as real-site compatibility.
- Background suspension/recovery, private browsing, data migration, arbitrary
  XPI installation, full uBO UI interactions and SideStore remain unverified.
- Probe bootstrap deliberately seeds a synthetic profile at startup; never
  attach it to a user's real extension data or ship it as an installer.

## Reproduce

Windows compiler integration test (requires installed Python launcher and Node
with ES-module syntax detection, e.g. Node24/26):

```
py -3 tools/ublock/prepare.py path/to/pinned-upstream.xpi path/to/NEW-stage
node tools/ublock/test-compiler.mjs path/to/NEW-stage path/to/existing-results
```

The preparation command refuses an existing stage, wrong hash, unsafe archive
paths, symlinks, duplicate entries, and oversized extraction. This is specifically
for one pinned known package, NOT a general secure user-XPI installer.

macOS CI (no local Xcode required):

```
gh workflow run build-sidestore.yml --ref port/full-ubo-webkit -f ublock_port_checks_only=true
```

Artifacts include source provenance, all conversion findings, native errors,
network outcomes, server log, rule-update/atomic-rejection findings, original
popup snapshot when available, and a verdict which **always** says
`fullUBlockOriginVerified: false`. A green prerequisite gate never means complete
uBO/browser/SideStore acceptance.

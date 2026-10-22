# Local video review: Android Fennec vs ieynec

## Scope and privacy

Reviewed three owner-provided videos locally: Android screen recording (~105s), iOS screen recording (~69s), and a filmed Android private-mode demonstration (~41s). Regular sampling was expanded to 0.5s steps around navigation/search and 1–2s steps in visible library/settings sections. These are sampled frames, not an automated touch or timing trace. Videos, extracted frames, device details and browsing contents are not committed.

The Android screen recording is mostly black before ~44s because private-mode capture is blocked. Do not infer an empty/black UI from it. Use the filmed private-mode demonstration instead. The iOS recording does not visibly exercise every search/keyboard path; the owner's additional report about address-bar motion is a separate input, investigated in source.

## Confirmed differences and this revision

| Area | Reference / observed difference | Work in this revision |
|---|---|---|
| Private homepage | Filmed Android shows a dark private surface, mask badge, concise explanation. iOS showed normal ieynec wordmark, light background and More. | Dedicated dark private surface, badge and explanation; normal wordmark/donation More excluded. Private favorites/frequent-site preferences remain respected. |
| Empty private tray | Android displays private-mode guidance; iOS had no corresponding explanation. | Add private-only empty state, hidden as soon as private tabs exist. |
| Tray overflow | Android filmed menu exposes recently closed, tab settings and close-all. iOS showed a native submenu dominated by Back to browsing. | Nonanimated app-owned menu connected to real recently-closed/settings/close operations. Existing age-based closing and return action retained as additional entries. No inactive-tab archive added. |
| Private chrome | Android private browsing retains dark controls even with a light normal homepage. | Scope dark style to private homepage, tray, floating controls and browser chrome; restore inherited appearance in normal mode. This is not a claim that every child popover is covered. |
| Homepage branding | iOS wordmark is larger than Android reference. | Reduce normal wordmark from 30pt to 24pt and preferred header height from 116pt to 96pt; retain dynamic type and viewport constraints. |
| Homepage settings | Android shows wallpaper, homepage content and opening-screen controls. iOS still exposed an application-update switch with no active feed. | Reorder sections, remove dead update switch; add real persisted Continue/protection-card switches. Keep original useful extra content controls and wallpaper picker. |
| Mixed-language UI | iOS menu/settings headings remained English amid Traditional Chinese system UI. | Complete Traditional Chinese entries in the new Fennec string catalog. Third-party extension names are not renamed. |
| Address focus / keyboard | Owner reports upward Reynard-style chrome motion. | Explicitly disable animated search presentation/dismissal and dismiss-button paths; wrap keyboard-driven chrome docking/layout in performWithoutAnimation. System keyboard still owns its own animation. The address field must still relocate above the keyboard rather than become obscured. |
| Automatic new-tab transition | Source retained a translated-content animation. | Replace automatic animation with immediate completion; direct finger gestures remain available. |
| JIT | Owner explicitly withdrew the requirement to retain JIT. | Remove settings entry, ignore old enabled preference, and replace runtime controller with no-JIT child-status handshake. No DDI/pairing/debugger/VPN/audio workflow is started. Retain legacy upstream source files for now, unreachable from normal settings/startup; no private user files deleted. |

## Differences not honestly solved by copying the video

- Android's bookmarks are organized around that user's own data. ieynec must preserve its existing folders and storage; do not flatten or fabricate bookmarks to match a recording.
- Android download type chips, floating search buttons, detailed history grouping and deeper settings/library layouts are not all reproduced in this revision. They need separate native implementations and regression coverage.
- Android accounts/Sync, password management, default-browser controls and inactive-tab archiving remain intentionally omitted under prior requirements; no dead buttons are added.
- The Android protection dashboard has persistent totals. ieynec only exposes known counts for current regular tabs; no invented weekly/global totals.
- OS keyboard, permissions, photo/file pickers and sharing remain system UI. Web CSS/JS animations are not disabled.
- This is not a pixel-perfect or all-pages parity claim.

## Performance without JIT

Implemented bounded improvements:

- Do not start JIT preflight, pairing tunnel, debugger or background-audio work at launch, including upgrades with the old switch enabled.
- Never wait for an asynchronous homepage preview before switching a tab; late snapshot completion cannot change selection.
- Render reusable private/overflow icons once rather than regenerating image contexts on each refresh.
- Avoid collecting the homepage tracking count when its card is disabled; allow disabling Continue/protection cards and their refresh work.
- Remove remaining automatic new-tab motion and keyboard chrome animation work.

Existing lazy session restoration is already present: restored sessions are created with manual opening and restored when needed. Do not claim this revision newly adds it, or change it without measuring extension/background requirements. No engine revision, SDK cache key, tracking-protection policy or extension behavior changed. No speculative Gecko preferences or weakened security settings.

No percentage speed-up is claimed. Native responsiveness is distinct from JavaScript throughput; these changes cannot replace an unavailable JIT. Device benchmarks must compare the same page/network/cache state and distinguish cold start, first useful content, interaction and tab-switch latency.

## Validation boundaries

Local source checks inspect policies/localization only. The UIKit fixture compiles real homepage root/summary/private page/theme, group navigation and tray presentation; store/engine sections remain doubles. It now also compiles the real no-JIT controller against a fake engine-reporting boundary, checking old-preference migration, observer idempotency and false status reports for child processes. This is not an actual Gecko or SideStore integration test. Full App compilation and new-device acceptance must be reported separately with a build run and revision.

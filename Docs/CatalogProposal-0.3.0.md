# Collection/profile proposal (not published)

Scope: a future edit to Apple-Design-Templates and the owner's profile. This task changes only MacMenuBarCommandKit. No collection/profile publication is implied by the RC release.

## Artifact paths

Use the candidate tag's versions of:

- `Assets/NativeCaptures/0.3.0-rc.1/main-window.partial.png`
- `Assets/NativeCaptures/0.3.0-rc.1/menu-dashboard.partial.png`
- `Assets/NativeCaptures/0.3.0-rc.1/command-palette.partial.png`
- `Assets/NativeCaptures/0.3.0-rc.1/settings.partial.png`
- `Assets/GIFs/rc-native-content-captures.gif`
- `Docs/Evidence/capture-provenance.json`
- `Docs/Validation-0.3.0-rc.1.md`, `Docs/ReleaseNotes-0.3.0-rc.1.md`, `Docs/Migration-0.3.0.md`
- `Integration/Consumer/` and `Tools/prepare_consumer.py`

## Proposed collection card

> MacMenuBarCommandKit — a reusable Swift tools 6.0/macOS 14 command shell with app-owned IDs and handlers, dynamic registry observation, typed outcomes, native menu/palette/Settings surfaces, and a small bounded session inbox/deadline-timer demo. 0.3.0-rc.1 has native fixture evidence and explicit remaining GUI/signed-login gates.

The current Settings content capture contains no Notifications placeholder, but all fallback captures are labelled partial. Wait for the complete WindowServer/native visual gate before replacing a public collection hero with them. Caption the GIF as an assembly of native content-view captures. Caption the menu image as the actual menu view in a native capture host, with system status-item activation checked separately.

| Existing/possible claim | Proposed claim | Reason |
| --- | --- | --- |
| Production-ready / 10/10 | Release candidate with linked results and pending gates | A prepared checklist does not close native conditions |
| Clipboard persistence / archive | Bounded session-only inbox; Clear deletes; session undo | Matches actual lifetime and deletion |
| Start adds protected time | Deadline timer; completed duration grows at finish | Matches clock semantics; no system Focus control |
| Audit trail proves changes | Typed request/timer-event history; samples labelled | Failures and fixtures are not mutation proof |
| GIF records the app | Slideshow assembled from captured native PNGs | Matches renderer behavior |
| Launch at Login fully verified | SMAppService recovery with fake UI/model tests; signed gate separately recorded | Avoids substituting a fake for system approval |

## Proposed short profile entry

> Native macOS command tooling: MacMenuBarCommandKit RC, with a public SPM consumer, dynamic catalog updates, honest outcomes and session inbox/timer demo. See the linked validation record for current evidence and pending native checks.

Future claims should be updated only when the corresponding gate actually passes. Link the exact release/tag and its evidence, not a generic badge or later main commit. Developer pilot, performance and retention claims require their own observed evidence.

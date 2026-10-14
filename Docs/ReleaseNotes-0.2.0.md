# MacMenuBarCommandKit 0.2.0

`0.2.0` makes command routing genuinely extensible while keeping the package small and synchronous.

## Highlights

- App-owned, string-backed `CommandID` values replace the closed sample action enum.
- Handlers can throw and return explicit success or failure summaries.
- Demo IDs, fixtures, clipboard session state, and side effects no longer leak into package defaults.
- The palette supports Up/Down navigation, Return, Escape, and focus restoration.
- Menu and Settings shortcuts are rendered from command metadata.
- Launch at Login reflects current `SMAppService` status instead of a duplicated preference.

This release contains breaking API changes from `0.1.0`. Follow the [0.2.0 migration guide](https://github.com/mikonyaa/MacMenuBarCommandKit/blob/0.2.0/Docs/Migration-0.2.0.md) before updating.

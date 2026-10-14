# Release checklist

A completed checkbox is a pointer to observed evidence, not proof by itself. RC may ship as a prerelease with enumerated external gates; final `0.3.0` must not inherit pending entries as passes. Current facts are in [validation](Validation-0.3.0-rc.1.md).

- [ ] Check applicable AGENTS, clean isolated worktree, HEAD, remote refs and releases; preserve parallel sessions.
- [ ] Log OS/hardware and actual Swift/Xcode/XcodeGen/SwiftLint versions; retain exit codes.
- [ ] `swift test`, `swiftlint lint --strict`, demo build and demo model tests at macOS 14 deployment target.
- [ ] Independent baseline URL exact `0.2.0` resolves/builds; local RC consumer builds and hosted tests run without `@testable`.
- [ ] Full native XCUI and interactive keyboard/focus/menu/VoiceOver outcomes, with skip/pending distinct from success.
- [ ] Own signed Launch at Login status/approval/error/foreground/cleanup evidence.
- [ ] Own fake-clock/private-pasteboard/limits/relaunch tests and short native ticker completion/cancel.
- [ ] `bash -n script/build_and_run.sh`, `zsh -n Scripts/record_showcase.sh`, owned script negative/native fixtures.
- [ ] XcodeGen 2.45.4 generates reference project; second generation is byte-identical; `git diff --check`.
- [ ] Captures record implementation SHA, OS, native mechanism and surface; Settings has no stale Notifications toggle. GIF is described as assembled captures.
- [ ] EN/RU/setup/migration/changelog claims agree; session lifetime and sample removal are explicit.
- [ ] Recheck all applicable gates after final changes. Distinguish native workstation results from CI compatibility/current toolchains and minimum-runtime testing.
- [ ] Before any authorized publication re-read remote main and target refs. Never force push or overwrite another session's ref/release.
- [ ] Publish a fresh bare SemVer prerelease tag only with authority; pin its exact commit. Inspect CI repository/event/ref/SHA and every job/step.
- [ ] Download the exact public source release anonymously; compare source blobs and run a clean consumer. Source-only releases are valid for SPM.
- [ ] Prepare collection/profile edits as a [claims proposal](CatalogProposal-0.3.0.md); publish them only when separately authorized.

Use [native acceptance](NativeAcceptance.md) for test commands and a factual result form. The default CI runs model tests and controlled hosted native consumers. XCUI is an explicit workflow-dispatch option requiring authenticated GUI conditions; green default CI does not close that gate.

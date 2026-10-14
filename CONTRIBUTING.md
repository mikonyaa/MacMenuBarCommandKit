# Contributing

Keep the package local, dependency-light, metadata-driven and MainActor-owned. Handlers and business state belong to the app. Preserve existing initializer/source compatibility and distinguish typed failure, missing metadata and informational summaries.

Run `swift test`, pinned SwiftLint strict lint, the demo build/model tests and an external consumer. [Native acceptance](Docs/NativeAcceptance.md) gives exact commands, isolated fixture resources and result forms. Full native UI, signed-login and VoiceOver evidence must be recorded separately from fake/hosted tests. Default CI does not imply those gates passed.

Regenerate with XcodeGen 2.45.4 twice and compare with the reference project. Update native captures with SHA/OS/provenance when visuals change; the GIF assembler does not record interaction. Keep [release checklist](Docs/ReleaseChecklist.md), migration and EN/RU claims aligned. Do not stop unrelated processes or overwrite another session's work/ref/release.

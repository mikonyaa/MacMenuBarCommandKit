# Contributing

Thanks for improving MacMenuBarCommandKit.

## Before opening a PR

- Keep the template local-first and dependency-light.
- Prefer native macOS SwiftUI behavior over custom chrome.
- Do not add backend, analytics, Firebase, Supabase, or paid dependencies.
- Keep commands metadata-driven and handlers app-owned.

## Verification

Run:

```bash
swift test
xcodebuild -project Examples/CommandKitDemo/CommandKitDemo.xcodeproj -scheme CommandKitDemo -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

Update screenshots or GIFs when visual behavior changes.

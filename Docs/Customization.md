# Customization

## Rename the app

Update:

- `Examples/CommandKitDemo/project.yml`
- `Examples/CommandKitDemo/CommandKitDemo/Info.plist`
- `script/build_and_run.sh`
- README badges and links

Regenerate the Xcode project with `xcodegen generate`.

## Replace demo data

Use your own arrays:

```swift
DashboardStore(
    activities: myActivities,
    metrics: myMetrics
)
```

Keep data local and deterministic while adapting the template. Add networking only after the command surfaces are stable.

## Launch at Login

`LaunchAtLoginService` wraps `SMAppService.mainApp`. In unsigned local debug builds, status and registration can differ from a signed release build. Always verify this in the final distributed app.

## No-Dock accessory mode

The template is Dock-visible by default. For a menu-bar-only app, set the activation policy to `.accessory` intentionally and document that behavior for users. Do not expose a casual runtime toggle unless you also handle activation, window visibility, and user expectations.

## Visual style

Use semantic SwiftUI colors and system materials. Keep custom glass or heavy styling on controls and overlays, not long-form content.

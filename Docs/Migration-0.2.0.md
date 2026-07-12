# Migrating from 0.1.0 to 0.2.0

Version `0.2.0` replaces the closed demo action enum with app-owned command identity. This is a deliberate breaking change while the package remains `0.x`.

## Command identity

Before:

```swift
CommandItem(id: "export", /* ... */, action: .copyStatusReport)
```

After:

```swift
extension CommandID {
    static let export: CommandID = "export.summary"
}

CommandItem(id: .export, /* ... */)
```

Use reverse-DNS or short namespaced strings when commands may come from multiple feature modules.

## Handlers

Before, handlers returned `Void` and the package supplied demo fallbacks. In `0.2.0`, handlers return an explicit result and may throw:

```swift
registry.register(.export) { command in
    try exporter.writeSummary()
    return .success("Exported \(command.title).")
}
```

Missing and throwing handlers produce visible failure summaries. Register every command that can be executed.

## Demo data

`CommandItem.demoCommands`, `ActivityItem.demo`, `MetricCard.demo`, and sample side effects moved to `Examples/CommandKitDemo`. Copy only the fixtures you want; package registries and dashboards now start empty.

## Settings

`AppSettings.launchAtLogin` and `notificationPlaceholderEnabled` were removed. Read Launch at Login from `LaunchAtLoginService.status`; it reflects `SMAppService` instead of a second persisted preference. Add a real notification authorization flow in your app if notifications are part of the product.

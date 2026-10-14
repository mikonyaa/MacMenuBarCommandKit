# Architecture

The package separates command metadata/UI from app-owned behavior. Models retain value semantics and MainActor stores own mutable UI state. There are no external runtime dependencies.

CommandRegistry owns the catalog and synchronous throwing handlers keyed by app-defined CommandID. CommandStore holds query/presentation, internal palette selection, recent known requests and typed latest result. A single lifetime-bound weak Combine subscription forwards catalog publication and reconciles selected IDs using the incoming metadata. The catalog is not copied. Query and replacement preserve a valid ID or choose the first match; execution resolves current metadata rather than trusting an older value.

DashboardStore remains a reusable presentation store. SettingsStore persists only shell preferences, with injectable UserDefaults and default-compatible key prefix. LaunchAtLoginService derives truth from SMAppService. The internal Settings view model supports the existing service initializer and the added controlling-protocol initializer, forwards live service publication and refreshes on foreground; no login enabled flag is saved.

Examples owns demo IDs, fixtures, session inbox, clipboard adapter, clock/deadline timer and bounded UUID/timestamp history. Sample removal leaves real session state. A single owned timer subscription stops at finish/cancel and uses weak callbacks; views do not create repeating tasks. Foreground/wake reconciles a running deadline. Clock events are labelled and do not increment successful command-request counts.

The demo retains WindowGroup, MenuBarExtra(window), native Settings and Commands. Window/Settings actions are installed from the actual view/commands environment through DemoSceneActions. An independent Open Window command is available without command metadata. Launch invokes that own command; existing visible main windows are brought forward. This supports menu navigation when the main content is absent.

The built-in surfaces use native ScrollView; palette ScrollViewReader calls occur only at documented action/onChange boundaries. A small native NSTextField delegate handles key commands that its field editor otherwise consumes. Background modality, selection traits and outcome announcements support accessibility; real focus/VoiceOver/system-menu scenarios still require the native acceptance gate.

## Primary references consulted

- [ObservableObject migration](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [ScrollViewReader](https://developer.apple.com/documentation/swiftui/scrollviewreader)
- [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [WindowGroup/openWindow](https://developer.apple.com/documentation/swiftui/windowgroup)
- [Native text editing delegate](https://developer.apple.com/documentation/appkit/nscontroltexteditingdelegate/control(_:textview:docommandby:))
- [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice), [Login Items Settings](https://developer.apple.com/documentation/servicemanagement/smappservice/opensystemsettingsloginitems())
- [Pasteboard write Bool](https://developer.apple.com/documentation/appkit/nspasteboard/setstring(_:fortype:))
- [Swift PackageDescription](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)

Apple SwiftUI/ServiceManagement documentation was queried through Context7; primary Apple/Swift sources and the installed Apple SDK were used for exact API boundaries. No migration to Observation or minimum-platform increase was needed.

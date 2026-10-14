import AppKit

/// Captures only this app's rendered content view; it never reads the desktop or
/// another application's pixels and does not require changing screen permissions.
@MainActor
enum DemoCapture {
    static let surfaces = ["main-window", "menu-dashboard", "command-palette", "settings"]

    static func write(window: NSWindow, directory: String, surface: String, sourceCommit: String) throws {
        guard surfaces.contains(surface), let view = window.contentView else { return }
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { return }
        let destination = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try png.write(to: destination.appendingPathComponent(surface + ".png"), options: .atomic)
        let metadata: [String: Any] = [
            "sourceCommit": sourceCommit,
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "surface": surface,
            "mechanism": "NSView.cacheDisplay from the running CommandKitDemo native content view; excludes window chrome",
            "presentation": surface == "menu-dashboard" ? "Standalone native host of the actual MenuBarDashboard view" : "Actual app scene",
            "windowTitle": window.title,
            "pixelWidth": bitmap.pixelsWide, "pixelHeight": bitmap.pixelsHigh,
            "pid": ProcessInfo.processInfo.processIdentifier,
            "bundlePath": Bundle.main.bundleURL.path
        ]
        let json = try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: destination.appendingPathComponent(surface + ".json"), options: .atomic)
    }
}

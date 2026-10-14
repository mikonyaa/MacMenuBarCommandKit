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
        let imageURL = destination.appendingPathComponent(surface + ".png")
        // Try a documented window-only capture from the owning app's process.
        // Never request permission, capture the desktop, or select another PID.
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-o", "-l", String(window.windowNumber), imageURL.path]
        capture.standardOutput = Pipe()
        capture.standardError = Pipe()
        try capture.run()
        capture.waitUntilExit()
        let completeWindow = capture.terminationStatus == 0 && FileManager.default.fileExists(atPath: imageURL.path)
        if !completeWindow { try png.write(to: imageURL, options: .atomic) }
        let metadata: [String: Any] = [
            "sourceCommit": sourceCommit,
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "surface": surface,
            "mechanism": completeWindow ? "screencapture -l of the owning app's NSWindow" : "NSView.cacheDisplay (partial layer coverage)",
            "coverage": completeWindow ? "window" : "partial-content-view",
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

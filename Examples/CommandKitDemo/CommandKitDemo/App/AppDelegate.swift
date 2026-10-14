import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Invoke the app's own installed SwiftUI command, whose environment has
        // a real OpenWindowAction even before any main content view appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let menu = NSApp.mainMenu?.items.compactMap(\.submenu).first(where: { $0.item(withTitle: "Open Window") != nil }),
                  let item = menu.item(withTitle: "Open Window") else { return }
            menu.performActionForItem(at: menu.index(of: item))
        }
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--verify-output"), index + 1 < arguments.count,
           let suiteIndex = arguments.firstIndex(of: "--test-suite"), suiteIndex + 1 < arguments.count,
           arguments[suiteIndex + 1].hasPrefix("CommandKitTests.") {
            let diagnostic: [String: Any] = [
                "pid": ProcessInfo.processInfo.processIdentifier,
                "arguments": arguments,
                "mainMenuTitles": NSApp.mainMenu?.items.map(\.title) ?? [],
                "mainMenuItemTitles": NSApp.mainMenu?.items.flatMap { $0.submenu?.items.map(\.title) ?? [] } ?? [],
                "windowTitlesAtLaunch": NSApp.windows.map(\.title)
            ]
            if let data = try? JSONSerialization.data(withJSONObject: diagnostic, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: URL(fileURLWithPath: arguments[index + 1] + ".launch.json"), options: .atomic)
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { true }
}

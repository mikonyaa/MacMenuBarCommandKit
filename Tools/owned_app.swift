import AppKit
import Foundation

// Tooling only. LaunchServices returns the exact new application instance;
// termination is restricted to that PID and both paths, never a process name.
func canonical(_ path: String) -> URL {
    URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL
}

let arguments = CommandLine.arguments
let mode = arguments.count > 1 ? arguments[1] : ""
if mode == "launch", arguments.count >= 4 {
    let bundle = canonical(arguments[2])
    let pidFile = URL(fileURLWithPath: arguments[3])
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true
    configuration.activates = true
    configuration.promptsUserIfNeeded = false
    configuration.arguments = Array(arguments.dropFirst(4))
    NSWorkspace.shared.openApplication(at: bundle, configuration: configuration) { app, error in
        guard let app, app.bundleURL?.resolvingSymlinksInPath().standardizedFileURL == bundle else {
            NSLog("Owned launch failed: %@", error?.localizedDescription ?? "Bundle path mismatch")
            exit(1)
        }
        do {
            try Data("\(app.processIdentifier)\n".utf8).write(to: pidFile, options: .atomic)
            exit(0)
        } catch {
            NSLog("Could not write owned PID: %@", error.localizedDescription)
            app.terminate()
            exit(1)
        }
    }
    RunLoop.main.run()
} else if mode == "stop", arguments.count >= 5, let pid = Int32(arguments[2]) {
    let bundle = canonical(arguments[3])
    let executable = canonical(arguments[4])
    if let app = NSRunningApplication(processIdentifier: pid), !app.isTerminated {
        guard app.bundleURL?.resolvingSymlinksInPath().standardizedFileURL == bundle,
              app.executableURL?.resolvingSymlinksInPath().standardizedFileURL == executable else {
            NSLog("Refusing to stop a PID whose bundle/executable paths differ")
            exit(1)
        }
        app.terminate()
        for _ in 0..<50 where !app.isTerminated {
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }
        if !app.isTerminated { app.forceTerminate() }
    }
    if arguments.count == 6, arguments[5].hasPrefix("CommandKitTests.Verify.") {
        let suite = arguments[5]
        NSPasteboard(name: .init(suite + ".clipboard")).releaseGlobally()
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }
    exit(0)
} else {
    NSLog("usage: owned_app.swift launch <bundle> <pid-file> [args] | stop <pid> <bundle> <executable> [owned-verify-suite]")
    exit(2)
}

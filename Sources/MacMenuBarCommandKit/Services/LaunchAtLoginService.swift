import Foundation
import ServiceManagement

public enum LaunchAtLoginStatus: Equatable, Sendable {
    case enabled
    case disabled
    case requiresApproval
    case unsupported
    case error(String)

    public var title: String {
        switch self {
        case .enabled:
            "Enabled"
        case .disabled:
            "Disabled"
        case .requiresApproval:
            "Requires Approval"
        case .unsupported:
            "Unsupported"
        case .error:
            "Error"
        }
    }
}

@MainActor
public protocol LaunchAtLoginControlling: AnyObject {
    var status: LaunchAtLoginStatus { get }
    var isEnabled: Bool { get }
    func refresh()
    func setEnabled(_ isEnabled: Bool)
}

@MainActor
public final class LaunchAtLoginService: ObservableObject, LaunchAtLoginControlling {
    @Published public private(set) var status: LaunchAtLoginStatus

    public init() {
        status = Self.readStatus()
    }

    public var isEnabled: Bool {
        status == .enabled
    }

    public func refresh() {
        status = Self.readStatus()
    }

    public func setEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refresh()
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    private static func readStatus() -> LaunchAtLoginStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            .enabled
        case .notRegistered:
            .disabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unsupported
        @unknown default:
            .unsupported
        }
    }
}

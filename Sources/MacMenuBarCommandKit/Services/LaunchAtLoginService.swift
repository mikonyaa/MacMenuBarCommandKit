import Combine
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
    func openLoginItemsSettings()
}

public extension LaunchAtLoginControlling {
    // A default keeps existing app-owned conformers source compatible.
    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
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

/// A view adapter that refreshes system truth after actions and foregrounding.
/// Kept internal: consumers inject their existing controlling implementation.
@MainActor
final class LaunchAtLoginViewModel: ObservableObject {
    @Published private(set) var status: LaunchAtLoginStatus
    private let controller: any LaunchAtLoginControlling
    private var liveObservation: AnyCancellable?

    init(controller: any LaunchAtLoginControlling) {
        self.controller = controller
        status = controller.status
        if let service = controller as? LaunchAtLoginService {
            liveObservation = service.$status.dropFirst().sink { [weak self] status in self?.status = status }
        }
    }

    var isEnabled: Bool { status == .enabled }

    func refresh() {
        controller.refresh()
        status = controller.status
    }

    func setEnabled(_ enabled: Bool) {
        controller.setEnabled(enabled)
        status = controller.status
    }

    func openLoginItemsSettings() { controller.openLoginItemsSettings() }
}

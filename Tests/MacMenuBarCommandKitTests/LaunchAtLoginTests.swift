import XCTest
@testable import MacMenuBarCommandKit

@MainActor
final class LaunchAtLoginTests: XCTestCase {
    func testSystemTruthApprovalErrorAndForegroundRefresh() {
        let fake = FakeLoginController()
        let model = LaunchAtLoginViewModel(controller: fake)
        XCTAssertFalse(model.isEnabled)
        fake.nextStatus = .enabled
        model.refresh()
        XCTAssertTrue(model.isEnabled)
        fake.nextStatus = .requiresApproval
        model.setEnabled(true)
        XCTAssertEqual(model.status, .requiresApproval)
        XCTAssertFalse(model.isEnabled)
        model.openLoginItemsSettings()
        XCTAssertEqual(fake.openCount, 1)
        fake.nextStatus = .error("Permission denied")
        model.refresh()
        XCTAssertEqual(model.status, .error("Permission denied"))
        fake.nextStatus = .disabled
        model.refresh()
        XCTAssertEqual(model.status, .disabled)
        XCTAssertEqual(fake.refreshCount, 3)
        fake.nextStatus = .unsupported
        model.refresh()
        XCTAssertEqual(model.status, .unsupported)
    }
}

@MainActor
private final class FakeLoginController: LaunchAtLoginControlling {
    var status: LaunchAtLoginStatus = .disabled
    var nextStatus: LaunchAtLoginStatus = .disabled
    var isEnabled: Bool { status == .enabled }
    var refreshCount = 0
    var openCount = 0
    func refresh() { refreshCount += 1; status = nextStatus }
    func setEnabled(_ isEnabled: Bool) { status = nextStatus }
    func openLoginItemsSettings() { openCount += 1 }
}

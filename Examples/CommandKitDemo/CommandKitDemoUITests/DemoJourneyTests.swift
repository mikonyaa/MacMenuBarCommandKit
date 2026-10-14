import XCTest

final class DemoJourneyTests: XCTestCase {
    @MainActor
    func testHundredCommandKeyboardVisibilityAndExactlyOneReturn() {
        withApp(["--test-command-count", "100", "--test-demo-data-off", "--show-palette"]) { app in
            let search = app.textFields["commandkit.palette.search"]
            XCTAssertTrue(search.waitForExistence(timeout: 10))
            search.click()
            for _ in 0..<99 { search.typeKey(.downArrow, modifierFlags: []) }
            let last = app.buttons["commandkit.palette.row.fixture.command.100"]
            XCTAssertTrue(last.waitForExistence(timeout: 3))
            XCTAssertTrue(last.isHittable, "Keyboard selection must be visible in the viewport")
            XCTAssertTrue(last.isSelected)
            search.typeKey(.return, modifierFlags: [])
            let outcome = app.descendants(matching: .any)["commandkit.latest-result"].firstMatch
            XCTAssertTrue(outcome.waitForExistence(timeout: 3))
            XCTAssertTrue(outcome.label.contains("Executed fixture.command.100"))
            app.typeKey(.return, modifierFlags: [])
            XCTAssertEqual(app.staticTexts["demo.attempt.count"].label, "History records: 1")
        }
    }

    @MainActor
    func testPaletteNoMatchEscapeAndBackgroundIsolation() {
        withApp(["--test-demo-data-off", "--show-palette"]) { app in
            let search = app.textFields["commandkit.palette.search"]
            XCTAssertTrue(search.waitForExistence(timeout: 10))
            XCTAssertFalse(app.buttons["New Note"].exists)
            search.click()
            search.typeText("does-not-match-any-command")
            XCTAssertTrue(app.staticTexts["No commands found"].waitForExistence(timeout: 3))
            search.typeKey(.return, modifierFlags: [])
            XCTAssertTrue(search.exists)
            search.typeKey(.escape, modifierFlags: [])
            XCTAssertFalse(search.waitForExistence(timeout: 1))
            XCTAssertEqual(app.staticTexts["demo.attempt.count"].label, "History records: 0")
        }
    }

    @MainActor
    func testEditorSaveCancelReadCopyClearUndoAndPreferenceRelaunch() {
        withApp(["--test-demo-data-off"]) { app in
            XCTAssertTrue(app.staticTexts["demo.inbox.count"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.staticTexts["demo.inbox.count"].label, "0 / 50 entries")
            app.typeKey("n", modifierFlags: .command)
            let editor = app.textViews["demo.note.editor"]
            XCTAssertTrue(editor.waitForExistence(timeout: 3))
            XCTAssertFalse(app.buttons["demo.note.save"].isEnabled)
            app.buttons["Cancel"].click()
            XCTAssertEqual(app.staticTexts["demo.inbox.count"].label, "0 / 50 entries")
            app.typeKey("n", modifierFlags: .command)
            XCTAssertTrue(editor.waitForExistence(timeout: 3))
            editor.click()
            editor.typeText("Native test note\nSecond line")
            app.buttons["demo.note.save"].click()
            XCTAssertEqual(app.staticTexts["demo.inbox.count"].label, "1 / 50 entries")
            app.staticTexts["Note"].firstMatch.click()
            XCTAssertTrue(app.staticTexts["demo.inbox.content"].label.contains("Second line"))
            app.buttons["Copy Text"].click()
            app.buttons["demo.inbox.clear"].click()
            XCTAssertEqual(app.staticTexts["demo.inbox.count"].label, "0 / 50 entries")
            app.buttons["Undo Clear"].click()
            XCTAssertEqual(app.staticTexts["demo.inbox.count"].label, "1 / 50 entries")
            app.typeKey(",", modifierFlags: .command)
            let toggle = app.checkBoxes["commandkit.settings.demo-data"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 3))
            toggle.click()
            toggle.click()
            app.terminate()
            app.launchArguments.removeAll { $0 == "--test-demo-data-off" }
            app.launch()
            XCTAssertTrue(app.staticTexts["demo.inbox.count"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.staticTexts["demo.inbox.count"].label, "0 / 50 entries", "Preference off survives a fresh app launch")
        }
    }

    @MainActor
    func testShortNativeTimerFinishAndCancel() {
        withApp(["--test-demo-data-off", "--test-timer-seconds", "2"]) { app in
            XCTAssertTrue(app.staticTexts["demo.timer.state"].waitForExistence(timeout: 10))
            app.buttons["demo.timer.start"].click()
            let state = app.descendants(matching: .any)["demo.timer.state"].firstMatch
            XCTAssertTrue(state.label.contains("Running"))
            let finished = NSPredicate(format: "label CONTAINS 'Finished'")
            expectation(for: finished, evaluatedWith: state)
            waitForExpectations(timeout: 5)
            app.buttons["demo.timer.start"].click()
            app.buttons["demo.timer.cancel"].click()
            XCTAssertTrue(state.label.contains("Cancelled"))
        }
    }

    @MainActor
    func testFakeLoginRecoveryShowsDetailsAndApproval() {
        withApp(["--test-login-status", "error"]) { app in
            XCTAssertTrue(app.staticTexts["demo.inbox.count"].waitForExistence(timeout: 10))
            app.typeKey(",", modifierFlags: .command)
            let detail = app.staticTexts["commandkit.login.error"]
            XCTAssertTrue(detail.waitForExistence(timeout: 3))
            XCTAssertTrue(detail.label.contains("Test registration denied"))
            XCTAssertTrue(app.buttons["commandkit.login.retry"].exists)
            capture(app.windows.firstMatch, name: "settings-error")
        }
        withApp(["--test-login-status", "approval"]) { app in
            XCTAssertTrue(app.staticTexts["demo.inbox.count"].waitForExistence(timeout: 10))
            app.typeKey(",", modifierFlags: .command)
            XCTAssertTrue(app.buttons["commandkit.login.approval"].waitForExistence(timeout: 3))
        }
    }

    @MainActor
    func testEscapeRestoresFilterInputAndKeepsBackgroundUnreachable() {
        withApp(["--test-demo-data-off"]) { app in
            XCTAssertTrue(app.buttons["commandkit.dashboard.section.actions"].waitForExistence(timeout: 10))
            app.buttons["commandkit.dashboard.section.actions"].click()
            let previous = app.textFields["commandkit.dashboard.search"]
            XCTAssertTrue(previous.waitForExistence(timeout: 3))
            previous.click()
            app.typeKey("k", modifierFlags: .command)
            XCTAssertTrue(app.textFields["commandkit.palette.search"].waitForExistence(timeout: 3))
            XCTAssertFalse(previous.exists)
            app.typeKey(.escape, modifierFlags: [])
            XCTAssertTrue(previous.waitForExistence(timeout: 3))
            app.typeText("restored")
            XCTAssertEqual(previous.value as? String, "restored", "Native key delivery returns to the previous input")
            XCTAssertEqual(app.staticTexts["demo.attempt.count"].label, "History records: 0")
        }
    }

    @MainActor
    func testMenuStatesOverflowAndRecoveryAfterMainWindowCloses() {
        for state in [[], ["--empty"], ["--error"], ["--loading"]] {
            withApp(state) { app in
                XCTAssertTrue(app.staticTexts["demo.inbox.count"].waitForExistence(timeout: 10))
                app.typeKey("w", modifierFlags: .command)
                let status = app.statusItems["CommandKit"]
                XCTAssertTrue(status.waitForExistence(timeout: 3))
                status.click()
                XCTAssertTrue(app.buttons["commandkit.menu.row.note.new"].waitForExistence(timeout: 3))
                app.buttons["commandkit.menu.more"].click()
                XCTAssertTrue(app.buttons["commandkit.menu.row.status.copy-report"].exists)
                capture(app.windows.firstMatch, name: "menu-dashboard")
                app.buttons["Open Window"].click()
                XCTAssertTrue(app.windows["CommandKit"].waitForExistence(timeout: 3))
                app.typeKey(",", modifierFlags: .command)
                XCTAssertTrue(app.checkBoxes["commandkit.settings.demo-data"].waitForExistence(timeout: 3))
            }
        }
    }

    @MainActor
    func testCaptureCurrentMainPaletteAndSettings() {
        withApp([]) { app in
            XCTAssertTrue(app.staticTexts["demo.inbox.count"].waitForExistence(timeout: 10))
            capture(app.windows["CommandKit"], name: "main-window")
            app.typeKey("k", modifierFlags: .command)
            XCTAssertTrue(app.textFields["commandkit.palette.search"].waitForExistence(timeout: 3))
            capture(app.windows["CommandKit"], name: "command-palette")
            app.typeKey(.escape, modifierFlags: [])
            app.typeKey(",", modifierFlags: .command)
            XCTAssertTrue(app.checkBoxes["commandkit.settings.demo-data"].waitForExistence(timeout: 3))
            capture(app.windows.matching(NSPredicate(format: "label != 'CommandKit'")).firstMatch, name: "settings")
        }
    }

    @MainActor
    private func withApp(_ arguments: [String], body: (XCUIApplication) -> Void) {
        continueAfterFailure = false
        let suite = "CommandKitTests.UI.\(UUID().uuidString)"
        let app = XCUIApplication()
        app.launchArguments = ["--test-suite", suite] + arguments
        app.launch()
        defer {
            app.terminate()
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        body(app)
    }

    @MainActor
    private func capture(_ window: XCUIElement, name: String) {
        let attachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

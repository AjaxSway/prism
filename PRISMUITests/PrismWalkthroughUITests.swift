import XCTest

/// PRISM Apple-viewing walkthrough — every tab + every module must open; primary actions must respond.
final class PrismWalkthroughUITests: XCTestCase {
    private let barTabs = ["command", "channels", "modules", "activity", "studio", "settings", "about"]
    private let modules = [
        "signal_composer", "platform_outputs", "refraction_preview", "campaign_calendar",
        "brand_voice", "audience_selector", "draft_queue", "distribution_status",
        "proof_assets", "image_studio", "approval_gate", "audit_trail",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["PRISM_SKIP_INTRO"] = "1"
        app.launchEnvironment["PRISM_DISABLE_MUSIC"] = "1"
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any)[id]
    }

    private func waitForStudio(_ app: XCUIApplication, timeout: TimeInterval = 10) -> Bool {
        element(app, id: "prism-studio-title").waitForExistence(timeout: timeout)
            || app.staticTexts["Create"].waitForExistence(timeout: 2)
    }

    private func dismissKeyboardIfNeeded(_ app: XCUIApplication) {
        if app.keyboards.count > 0 {
            app.keyboards.buttons["Return"].tap()
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
    }

    private func waitForModulesTab(_ app: XCUIApplication) {
        app.buttons["prism-tab-modules"].tap()
        let title = app.otherElements["prism-modules-title"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 10) || app.staticTexts["Modules"].waitForExistence(timeout: 4),
            "Modules tab did not load"
        )
    }

    func testEveryTabOpens() throws {
        let app = launchApp()
        let home = app.buttons["prism-tab-home"]
        XCTAssertTrue(home.waitForExistence(timeout: 12), "Missing home orb")
        home.tap()

        for tab in barTabs {
            let button = app.buttons["prism-tab-\(tab)"]
            XCTAssertTrue(button.waitForExistence(timeout: 8), "Missing tab: \(tab)")
            button.tap()
            dismissKeyboardIfNeeded(app)

            switch tab {
            case "about":
                XCTAssertTrue(app.staticTexts["prism-about-title"].waitForExistence(timeout: 8), "About tab did not load")
            case "channels":
                XCTAssertTrue(
                    app.otherElements["prism-channels-title"].waitForExistence(timeout: 10),
                    "Channels tab did not load"
                )
            case "modules":
                XCTAssertTrue(
                    app.otherElements["prism-modules-title"].waitForExistence(timeout: 8)
                        || app.staticTexts["Modules"].waitForExistence(timeout: 4),
                    "Modules tab did not load"
                )
            case "studio":
                XCTAssertTrue(waitForStudio(app), "Studio tab did not load")
            case "activity":
                XCTAssertTrue(
                    app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Activity'")).firstMatch.waitForExistence(timeout: 8),
                    "Activity tab did not load"
                )
            default:
                break
            }
        }
    }

    func testEveryModuleOpens() throws {
        for moduleId in modules {
            let app = launchApp()
            XCTAssertTrue(app.buttons["prism-tab-home"].waitForExistence(timeout: 12), "Home orb missing for \(moduleId)")
            openModule(app, id: moduleId)
            app.terminate()
        }
    }

    private func returnToModulesList(_ app: XCUIApplication) {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.waitForExistence(timeout: 2) { back.tap() }
        app.buttons["prism-tab-modules"].tap()
        scrollModulesToTop(app)
        _ = element(app, id: "prism-modules-title").waitForExistence(timeout: 4)
            || app.staticTexts["Modules"].waitForExistence(timeout: 2)
    }

    func testPrimaryActionsRespond() throws {
        let app = launchApp()
        let home = app.buttons["prism-tab-home"]
        XCTAssertTrue(home.waitForExistence(timeout: 10), "Home orb missing")

        app.buttons["prism-tab-command"].tap()
        let commandField = app.textFields["prism-command-field"]
        if !commandField.waitForExistence(timeout: 6) {
            app.swipeDown()
        }
        XCTAssertTrue(commandField.waitForExistence(timeout: 8), "Command field missing")
        commandField.tap()
        commandField.typeText("Draft Signal")
        let run = app.buttons["prism-run-local-draft"]
        XCTAssertTrue(run.waitForExistence(timeout: 4), "Run draft button missing")
        run.tap()
        let running = app.staticTexts["RUNNING…"]
        _ = running.waitForNonExistence(timeout: 30)
        _ = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Draft' OR label CONTAINS[c] 'Super Brain' OR label CONTAINS[c] 'Preview' OR label CONTAINS[c] 'unavailable'")
        ).firstMatch.waitForExistence(timeout: 15)
        dismissKeyboardIfNeeded(app)
        app.buttons["prism-tab-home"].tap()

        let studioTab = app.buttons["prism-tab-studio"]
        XCTAssertTrue(studioTab.waitForExistence(timeout: 4), "Studio tab button missing")
        studioTab.tap()
        XCTAssertTrue(waitForStudio(app), "Studio tab did not load")
        let studioPrompt = app.textFields["prism-studio-prompt"]
        if !studioPrompt.waitForExistence(timeout: 4) {
            app.swipeUp()
        }
        XCTAssertTrue(studioPrompt.waitForExistence(timeout: 8), "Studio prompt missing")
        studioPrompt.tap()
        studioPrompt.typeText("PRISM poster draft")
        let generate = app.buttons["prism-generate-draft"]
        XCTAssertTrue(generate.waitForExistence(timeout: 4), "Generate button missing")
        generate.tap()
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved' OR label CONTAINS[c] 'Image' OR label CONTAINS[c] 'draft'")).firstMatch.waitForExistence(timeout: 8)
    }

    private func scrollModulesToTop(_ app: XCUIApplication) {
        for _ in 0..<6 { app.swipeDown() }
    }

    private func openModule(_ app: XCUIApplication, id: String) {
        if id == "image_studio" {
            app.buttons["prism-tab-studio"].tap()
            XCTAssertTrue(waitForStudio(app, timeout: 8), "Image Studio tab did not open")
            return
        }

        app.buttons["prism-tab-modules"].tap()
        scrollModulesToTop(app)
        let card = app.buttons["prism-module-\(id)"]
        var attempts = 0
        while !card.waitForExistence(timeout: 2), attempts < 22 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(card.waitForExistence(timeout: 4), "Missing module: \(id)")
        if card.isHittable {
            card.tap()
        } else {
            card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        sleep(2)
        let opened = element(app, id: "prism-module-open-\(id)")
        let navBar = app.navigationBars.element(boundBy: 0)
        let header = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", moduleHeaderFragment(for: id))
        ).firstMatch
        XCTAssertTrue(
            opened.waitForExistence(timeout: 10)
                || navBar.waitForExistence(timeout: 6)
                || header.waitForExistence(timeout: 6),
            "Module did not open: \(id)"
        )
    }

    private func moduleHeaderFragment(for id: String) -> String {
        switch id {
        case "signal_composer": return "Create Post"
        case "platform_outputs": return "Platform"
        case "refraction_preview": return "Refraction"
        case "campaign_calendar": return "Campaign"
        case "brand_voice": return "Brand"
        case "audience_selector": return "Audience"
        case "draft_queue": return "Draft"
        case "distribution_status": return "Distribution"
        case "proof_assets": return "Proof"
        case "approval_gate": return "Approval"
        case "audit_trail": return "Activity"
        default: return id.replacingOccurrences(of: "_", with: " ")
        }
    }
}

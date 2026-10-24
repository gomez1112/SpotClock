import XCTest

final class ParkingWorkflowTests: XCTestCase {
    @MainActor
    func testStartExtendAndEndParkingInIsolatedStore() {
        let app = XCUIApplication()
        app.launchArguments = ["--marketing-capture"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Enjoy your time."].waitForExistence(timeout: 10))
        reveal(app.buttons["parking.end"], in: app)
        app.buttons["parking.end"].tap()

        let start = app.buttons["parking.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        let confirm = app.buttons["parking.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["Enjoy your time."].waitForExistence(timeout: 5))

        let extend = app.buttons["Extend parking by 15 minutes"]
        reveal(extend, in: app)
        extend.tap()
        let returnButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Return to your car")).firstMatch
        XCTAssertTrue(returnButton.exists)
        reveal(app.buttons["parking.end"], in: app)
        app.buttons["parking.end"].tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5))
    }

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }
}

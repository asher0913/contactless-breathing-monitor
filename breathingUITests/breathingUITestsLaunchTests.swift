//
//  breathingUITestsLaunchTests.swift
//  breathingUITests
//
//

import XCTest

// Test class for application launch behavior
class breathingUITestsLaunchTests: XCTestCase {

    // Set up the test environment before each test
    override func setUpWithError() throws {
        // Ensure tests run without animations interfering
        continueAfterFailure = false
    }

    // Test that the app launches and displays the tutorial's first page
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the first page of the tutorial appears
        let firstPageText = app.staticTexts["text_1"]
        XCTAssertTrue(firstPageText.waitForExistence(timeout: 5), "First page text should appear within 5 seconds after launch")

        let skipButton = app.buttons["skipButton"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 2), "Skip button should be visible on the first page")

        let firstPageImage = app.images["image_1"]
        XCTAssertTrue(firstPageImage.waitForExistence(timeout: 2), "First page image should be visible")
    }

    // Test the app's launch performance
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            // Measure how long it takes to launch the app
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

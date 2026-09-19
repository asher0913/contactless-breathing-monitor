//
//  breathingUITests.swift
//  breathingUITests
//
//

import XCTest

// UI tests for the breathing app
class breathingUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // Test that the app starts on the tutorial's first page
    func testAppStartsOnPage1() throws {
        let page1Text = app.staticTexts["text_1"]
        XCTAssertTrue(page1Text.waitForExistence(timeout: 2), "App should start on page 1 with correct text")

        let skipButton = app.buttons["skipButton"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 2), "Skip button should be visible on page 1")

        let page1Image = app.images["image_1"]
        XCTAssertTrue(page1Image.waitForExistence(timeout: 2), "Page 1 image should be visible")
    }

    // Test swipe up to navigate to the next page
    func testSwipeUpToNextPage() throws {
        let page1Text = app.staticTexts["text_1"]
        XCTAssertTrue(page1Text.waitForExistence(timeout: 2), "Should start on page 1")

        app.swipeUp() // Perform an upward swipe

        let page2Text = app.staticTexts["text_2"]
        XCTAssertTrue(page2Text.waitForExistence(timeout: 2), "Should transition to page 2 after swipe up")
    }

    // Test swipe down to return to the previous page from a middle page
    func testSwipeDownToPreviousPage() throws {
        app.swipeUp() // Move to page 2
        let page2Text = app.staticTexts["text_2"]
        XCTAssertTrue(page2Text.waitForExistence(timeout: 2), "Should be on page 2 after swipe up")

        app.swipeDown() // Move back to page 1

        let page1Text = app.staticTexts["text_1"]
        XCTAssertTrue(page1Text.waitForExistence(timeout: 2), "Should return to page 1 after swipe down")
    }

    // Test swipe down on the last page returns to the previous page
    func testSwipeDownOnLastPageReturnsToPrevious() throws {
        // Navigate to the last page (page 4)
        for _ in 1...3 {
            app.swipeUp()
            sleep(1) // Wait for animation
        }

        let lastPageText = app.staticTexts["text_4"]
        XCTAssertTrue(lastPageText.waitForExistence(timeout: 2), "Should be on the last page (page 4)")

        app.swipeDown() // Swipe down from the last page

        let previousPageText = app.staticTexts["text_3"]
        XCTAssertTrue(previousPageText.waitForExistence(timeout: 2), "Should return to page 3 after swiping down from the last page")
    }

    // Test clicking the skip button navigates to TestView
    func testSkipButtonNavigation() throws {
        let skipButton = app.buttons["skipButton"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 2), "Skip button should be visible on page 1")

        skipButton.tap()

        let testViewText = app.staticTexts["⚠️ Ensure shoulders visible"] // Adjust based on TestView content
        XCTAssertTrue(testViewText.waitForExistence(timeout: 3), "Should navigate to TestView after tapping skip")
    }

    // Test navigating to TestView using the start button on the last page
    func testStartButtonNavigation() throws {
        // Navigate to the last page (page 4)
        for _ in 1...4 {
            app.swipeUp()
            sleep(1) // Wait for animation
        }

        let lastPageText = app.staticTexts["text_5"]
        XCTAssertTrue(lastPageText.waitForExistence(timeout: 2), "Should be on the last page (page 4)")

        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start button should be visible on the last page")

        startButton.tap()

        let testViewText = app.staticTexts["⚠️ Ensure shoulders visible"] // Adjust based on TestView content
        XCTAssertTrue(testViewText.waitForExistence(timeout: 3), "Should navigate to TestView after tapping start")
    }
}

//
//  Puzzle_SolverUITests.swift
//  Puzzle SolverUITests
//
//  Created by Aditi Abrol on 30/1/24.
//

import XCTest

final class Puzzle_SolverUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.otherElements["splash-screen"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.otherElements["main-content"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.otherElements["splash-screen"].exists)
    }

    func testDarkAppearanceSelectionPersistsAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-HasCompletedOnboarding", "YES"]
        app.launch()
        openSettings(in: app)

        let dark = app.buttons["appearance-dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 2))
        dark.tap()
        XCTAssertEqual(dark.value as? String, "Selected")

        app.terminate()
        app.launch()
        openSettings(in: app)
        XCTAssertEqual(app.buttons["appearance-dark"].value as? String, "Selected")

        app.buttons["appearance-system"].tap()
        XCTAssertEqual(app.buttons["appearance-system"].value as? String, "Selected")
    }

    func testSudokuProductionFlowIsManualEntryOnly() throws {
        let app = XCUIApplication()
        app.launch()

        openSudoku(in: app)

        XCTAssertTrue(app.otherElements["sudoku-manual-input"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Validate"].exists)
        XCTAssertTrue(app.buttons["Solve Sudoku"].exists)
        XCTAssertFalse(app.buttons["Scan Sudoku"].exists)
        XCTAssertFalse(app.buttons["Choose Photo"].exists)
        XCTAssertFalse(app.buttons["Camera"].exists)
    }

    func testSudokuCellSelectionKeypadInputAndValidationFeedback() throws {
        let app = XCUIApplication()
        app.launch()
        openSudoku(in: app)

        let firstCell = app.buttons["sudoku-cell-1-1"]
        XCTAssertTrue(firstCell.waitForExistence(timeout: 2))
        firstCell.tap()

        let sevenKey = app.buttons["sudoku-key-7"]
        if !sevenKey.isHittable { app.swipeUp() }
        XCTAssertTrue(sevenKey.isHittable)
        sevenKey.tap()

        let secondCell = app.buttons["sudoku-cell-1-2"]
        if !secondCell.isHittable { app.swipeDown() }
        secondCell.tap()
        if !sevenKey.isHittable { app.swipeUp() }
        sevenKey.tap()

        XCTAssertTrue(firstCell.label.contains("value 7"))
        XCTAssertTrue(firstCell.label.contains("invalid conflict"))
        XCTAssertTrue(app.otherElements["sudoku-validation-summary"].exists)
    }

    func testSudokuRemainsUsableWithAccessibilityText() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"]
        app.launch()
        openSudoku(in: app)

        XCTAssertTrue(app.buttons["sudoku-cell-9-9"].waitForExistence(timeout: 2))
        let delete = app.buttons["sudoku-delete"]
        if !delete.isHittable { app.swipeUp() }
        XCTAssertTrue(delete.isHittable)
        XCTAssertTrue(app.buttons["Solve Sudoku"].exists)
    }

    private func openSudoku(in app: XCUIApplication) {
        XCTAssertTrue(app.otherElements["main-content"].waitForExistence(timeout: 3))
        if app.buttons["Skip"].exists { app.buttons["Skip"].tap() }

        let logicPuzzles = app.staticTexts["Logic Puzzles"].firstMatch
        XCTAssertTrue(logicPuzzles.waitForExistence(timeout: 2))
        logicPuzzles.tap()

        let sudoku = app.staticTexts["Sudoku"].firstMatch
        XCTAssertTrue(sudoku.waitForExistence(timeout: 2))
        sudoku.tap()
        XCTAssertTrue(app.otherElements["sudoku-manual-input"].waitForExistence(timeout: 2))
    }

    private func openSettings(in app: XCUIApplication) {
        XCTAssertTrue(app.otherElements["main-content"].waitForExistence(timeout: 3))
        let settings = app.staticTexts["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 2))
        settings.tap()
        XCTAssertTrue(app.buttons["appearance-system"].waitForExistence(timeout: 2))
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

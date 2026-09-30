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

    func testSudokuProductionFlowIsManualEntryOnly() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.otherElements["main-content"].waitForExistence(timeout: 3))
        if app.buttons["Skip"].exists {
            app.buttons["Skip"].tap()
        }

        let logicPuzzles = app.staticTexts["Logic Puzzles"].firstMatch
        XCTAssertTrue(logicPuzzles.waitForExistence(timeout: 2))
        logicPuzzles.tap()

        let sudoku = app.staticTexts["Sudoku"].firstMatch
        XCTAssertTrue(sudoku.waitForExistence(timeout: 2))
        sudoku.tap()

        XCTAssertTrue(app.otherElements["sudoku-manual-input"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Validate"].exists)
        XCTAssertTrue(app.buttons["Solve Sudoku"].exists)
        XCTAssertFalse(app.buttons["Scan Sudoku"].exists)
        XCTAssertFalse(app.buttons["Choose Photo"].exists)
        XCTAssertFalse(app.buttons["Camera"].exists)
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

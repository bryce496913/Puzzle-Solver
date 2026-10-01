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

    func testPhotoScanCardIsActiveAndOpensDedicatedImporter() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-HasCompletedOnboarding", "YES"]
        app.launch()
        let logic = app.staticTexts["Logic Puzzles"].firstMatch
        XCTAssertTrue(logic.waitForExistence(timeout: 3))
        logic.tap()

        let scan = app.staticTexts["Sudoku Photo Scan"].firstMatch
        XCTAssertTrue(scan.waitForExistence(timeout: 2))
        scan.tap()
        XCTAssertTrue(app.otherElements["sudoku-photo-scan-import"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Take Photo"].exists)
        XCTAssertTrue(app.buttons["Choose from Photo Library"].exists)
        XCTAssertTrue(app.buttons["Manual fallback"].exists)
        XCTAssertFalse(app.staticTexts["Coming Soon"].exists)
    }

    func testBundledPhotoImportReviewCanBeEditedAndSolved() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestSudokuPhotoScanFixture")
        app.launch()
        let reviewCell = app.buttons["sudoku-scan-cell-1-1"]
        XCTAssertTrue(reviewCell.waitForExistence(timeout: 3))
        reviewCell.tap()
        let five = app.buttons["sudoku-key-5"]
        if !five.isHittable { app.swipeUp() }
        five.tap()
        XCTAssertTrue(reviewCell.label.contains("detected 5"))
        let use = app.buttons["Use This Puzzle"]
        if !use.isHittable { app.swipeUp() }
        XCTAssertTrue(use.isEnabled)
        use.tap()
        XCTAssertTrue(app.otherElements["sudoku-result"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Coming Soon"].exists)
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

    func testScanReviewSelectsAndCorrectsLowConfidenceAndConflictCells() throws {
        let app = launchScanReview()
        let conflict = app.buttons["sudoku-scan-cell-1-2"]
        XCTAssertTrue(conflict.waitForExistence(timeout: 2))
        XCTAssertTrue(conflict.label.localizedCaseInsensitiveContains("conflict"))
        conflict.tap()
        XCTAssertTrue(conflict.label.localizedCaseInsensitiveContains("selected"))
        let seven = app.buttons["sudoku-key-7"]
        if !seven.isHittable { app.swipeUp() }
        seven.tap()
        XCTAssertTrue(conflict.label.contains("detected 7"))
        XCTAssertFalse(conflict.label.localizedCaseInsensitiveContains("conflict"))

        let lowConfidence = app.buttons["sudoku-scan-cell-4-7"]
        if !lowConfidence.isHittable { app.swipeDown() }
        lowConfidence.tap()
        XCTAssertTrue(lowConfidence.label.contains("low confidence"))
        let four = app.buttons["sudoku-key-4"]
        if !four.isHittable { app.swipeUp() }
        four.tap()
        XCTAssertTrue(lowConfidence.label.contains("detected 4"))
        XCTAssertFalse(lowConfidence.label.contains("low confidence"))
    }

    func testScanReviewExposesMinimumWarningAndVoiceOverSemantics() throws {
        let app = launchScanReview()
        XCTAssertTrue(app.staticTexts["sudoku-scan-status"].label.contains("Not enough clues were recognized"))
        let uncertainBlank = app.buttons["sudoku-scan-cell-5-5"]
        XCTAssertTrue(uncertainBlank.label.contains("Row 5"))
        XCTAssertTrue(uncertainBlank.label.contains("column 5"))
        XCTAssertTrue(uncertainBlank.label.contains("blank"))
        XCTAssertTrue(uncertainBlank.label.contains("low confidence"))
        XCTAssertFalse(app.buttons["Use This Puzzle"].isEnabled)
    }

    func testScanReviewFitsSmallScreenWithLargeDynamicType() throws {
        let app = launchScanReview(contentSize: "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge")
        let lastCell = app.buttons["sudoku-scan-cell-9-9"]
        XCTAssertTrue(lastCell.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(lastCell.frame.width, 30)
        XCTAssertLessThanOrEqual(lastCell.frame.maxX, app.windows.firstMatch.frame.maxX + 1)
        XCTAssertTrue(app.buttons["sudoku-key-1"].exists)
    }

    private func launchScanReview(contentSize: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-UITestSudokuScanReview")
        if let contentSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize] }
        app.launch()
        return app
    }

    func testOpenThreeByThreeGuidedAndAdvancedEntryWithLockedCenters() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-HasCompletedOnboarding", "YES"]
        app.launch()

        let twisty = app.staticTexts["Twisty Puzzles"].firstMatch
        XCTAssertTrue(twisty.waitForExistence(timeout: 3))
        twisty.tap()
        let cube = app.staticTexts["3×3 Rubik’s Cube"].firstMatch
        XCTAssertTrue(cube.waitForExistence(timeout: 2))
        cube.tap()

        XCTAssertTrue(app.buttons["Start Entering Up Face"].waitForExistence(timeout: 2))
        app.buttons["Start Entering Up Face"].tap()
        let center = app.buttons["cube-locked-center-U"]
        XCTAssertTrue(center.waitForExistence(timeout: 2))
        XCTAssertFalse(center.isEnabled)
        XCTAssertTrue(app.staticTexts["Enter the Up face"].exists)

        app.buttons["Advanced net input"].tap()
        XCTAssertTrue(app.staticTexts["Back (viewed from behind)"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.otherElements["cube-validation-summary"].exists)
        XCTAssertTrue(app.buttons["cube-locked-center-B"].exists)
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

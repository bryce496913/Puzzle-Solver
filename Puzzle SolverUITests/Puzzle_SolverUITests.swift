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

    func testKillerSudokuCreateEditDeleteUndoAndReset() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-HasCompletedOnboarding", "YES"]
        app.launch()
        openKillerSudoku(in: app)

        app.buttons["killer-cell-1-1"].tap()
        app.buttons["killer-cell-1-2"].tap()
        let target = app.textFields["killer-target"]
        target.tap(); target.typeText("8")
        app.buttons["killer-save-cage"].tap()
        XCTAssertTrue(app.staticTexts["killer-validation-summary"].label.contains("79 cells"))

        // Tapping a covered cell selects its whole cage for editing rather than
        // allowing overlap. Save a new total, then delete and restore with Undo.
        app.buttons["killer-cell-1-1"].tap()
        target.tap(); target.clearAndEnterText("9")
        app.buttons["killer-save-cage"].tap()
        app.buttons["killer-cell-1-1"].tap()
        app.buttons["killer-delete-cage"].tap()
        XCTAssertTrue(app.staticTexts["killer-validation-summary"].label.contains("81 cells"))
        app.buttons["killer-undo"].tap()
        XCTAssertTrue(app.staticTexts["killer-validation-summary"].label.contains("79 cells"))
        app.buttons["killer-reset"].tap()
        XCTAssertTrue(app.staticTexts["killer-validation-summary"].label.contains("81 cells"))
        XCTAssertFalse(app.buttons["killer-solve"].isEnabled)
    }

    func testKillerSudokuExampleEnablesSolveAndDisplaysCagesWithSolution() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-HasCompletedOnboarding", "YES"]
        app.launch()
        openKillerSudoku(in: app)

        app.buttons["killer-example"].tap()
        XCTAssertTrue(app.staticTexts["killer-validation-summary"].label.contains("Ready to solve"))
        let solve = app.buttons["killer-solve"]
        XCTAssertTrue(solve.isEnabled)
        solve.tap()
        XCTAssertTrue(app.otherElements["killer-sudoku-result"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Solved"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["killer-cell-1-1"].label.contains("total 12"))
        XCTAssertTrue(app.buttons["killer-cell-1-1"].label.contains("value 5"))
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

    // MARK: - V1 release gate

    func testV1Sliding3x3HappyPath() { verifySliding(size: 3) }
    func testV1Sliding4x4HappyPath() { verifySliding(size: 4) }
    func testV1Sliding5x5BoundedHappyPath() { verifySliding(size: 5) }

    func testV1Cube2x2KnownStateReachesVerifiedResult() { verifyCube(named: "2×2 Cube") }
    func testV1Cube3x3KnownStateReachesVerifiedResult() { verifyCube(named: "3×3 Rubik’s Cube") }

    func testV1ManualSudokuUniquePuzzleSolves() {
        let app = launchAtMainMenu()
        openMode("Sudoku", category: "Logic Puzzles", in: app)
        tap(app.buttons["Example"], in: app)
        tap(app.buttons["Solve Sudoku"], in: app)
        XCTAssertTrue(app.otherElements["sudoku-result"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Solved"].waitForExistence(timeout: 8))
    }

    func testV1SudokuPhotoBundledFixtureSolves() {
        let app = XCUIApplication()
        app.launchArguments += ["-HasCompletedOnboarding", "YES", "-UITestSudokuPhotoScanFixture"]
        app.launch()
        let use = app.buttons["Use This Puzzle"]
        tap(use, in: app)
        XCTAssertTrue(app.otherElements["sudoku-result"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Solved"].waitForExistence(timeout: 8))
    }

    func testV1KillerSudokuBundledExampleSolves() {
        let app = launchAtMainMenu()
        openMode("Killer Sudoku", category: "Logic Puzzles", in: app)
        tap(app.buttons["killer-example"], in: app)
        tap(app.buttons["killer-solve"], in: app)
        XCTAssertTrue(app.otherElements["killer-sudoku-result"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Solved"].waitForExistence(timeout: 10))
    }

    func testV1RushHourBundledExampleSolves() {
        let app = launchAtMainMenu()
        openMode("Rush Hour", category: "Mechanical Puzzles", in: app)
        tap(app.buttons["Load Example"], in: app)
        tap(app.buttons["Solve Rush Hour"], in: app)
        XCTAssertTrue(app.otherElements["rush-hour-result"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'moves'")).firstMatch.exists)
    }

    func testV1MainMenuAndComingSoonRoutingContract() {
        let app = launchAtMainMenu()
        XCTAssertTrue(app.otherElements["main-content"].exists)
        tap(app.staticTexts["Coming Soon"].firstMatch, in: app)
        XCTAssertTrue(app.staticTexts["Pyraminx"].waitForExistence(timeout: 3))
        app.staticTexts["Pyraminx"].tap()
        XCTAssertTrue(app.staticTexts["Pyraminx"].exists, "Coming Soon cards must remain informational")
        XCTAssertFalse(app.buttons["cube-solve"].exists)
        XCTAssertFalse(app.otherElements["sudoku-manual-input"].exists)
        XCTAssertFalse(app.otherElements["rush-hour-result"].exists)
    }

    private func verifySliding(size: Int) {
        let app = launchAtMainMenu()
        openMode("\(size)×\(size) Sliding Puzzle", category: "Sliding Puzzles", in: app)
        tap(app.buttons["Load Example"], in: app)
        tap(app.buttons["Solve \(size)×\(size) Puzzle"], in: app)
        XCTAssertTrue(app.otherElements["sliding-solver-result"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Solved"].waitForExistence(timeout: 12))
    }

    private func verifyCube(named name: String) {
        let app = launchAtMainMenu()
        openMode(name, category: "Twisty Puzzles", in: app)
        tap(app.buttons["Advanced net input"], in: app)
        tap(app.buttons["cube-solve"], in: app)
        XCTAssertTrue(app.otherElements["cube-solver-result"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Already solved."].waitForExistence(timeout: 8))
    }

    private func launchAtMainMenu() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-HasCompletedOnboarding", "YES"]
        app.launch()
        XCTAssertTrue(app.otherElements["main-content"].waitForExistence(timeout: 4))
        return app
    }

    private func openMode(_ mode: String, category: String, in app: XCUIApplication) {
        tap(app.staticTexts[category].firstMatch, in: app)
        let card = app.staticTexts[mode].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3), "Missing active production card: \(mode)")
        tap(card, in: app)
        XCTAssertFalse(app.staticTexts["Planned for a future update"].exists, "\(mode) routed to AppPlaceholderScreen")
    }

    private func tap(_ element: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 4), "Element does not exist", file: file, line: line)
        for _ in 0..<6 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable, "Element is not hittable", file: file, line: line)
        element.tap()
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

    private func openKillerSudoku(in app: XCUIApplication) {
        XCTAssertTrue(app.otherElements["main-content"].waitForExistence(timeout: 3))
        app.staticTexts["Logic Puzzles"].firstMatch.tap()
        let killer = app.staticTexts["Killer Sudoku"].firstMatch
        XCTAssertTrue(killer.waitForExistence(timeout: 2))
        killer.tap()
        XCTAssertTrue(app.otherElements["killer-sudoku-input"].waitForExistence(timeout: 2))
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

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (value as? String)?.count ?? 3))
        typeText(text)
    }
}

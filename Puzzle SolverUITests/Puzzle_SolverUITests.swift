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

    func testPhotoScanIsOnlyAnInformationalComingSoonCard() {
        let app = launchAtMainMenu()
        tap(app.staticTexts["Logic Puzzles"].firstMatch, in: app)
        XCTAssertFalse(app.staticTexts["Sudoku Photo Scan"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.staticTexts["Coming Soon"].firstMatch, in: app)
        let scan = app.staticTexts["Sudoku Photo Scan"].firstMatch
        for _ in 0..<6 where !scan.exists || !scan.isHittable { app.swipeUp() }
        tap(scan, in: app)
        XCTAssertFalse(app.buttons["Take Photo"].exists)
        XCTAssertFalse(app.buttons["Choose from Photo Library"].exists)
        XCTAssertFalse(app.otherElements["sudoku-photo-scan-import"].exists)
    }

    func testManualSudokuResetAndReentryClearTheBoard() {
        let app = launchAtMainMenu()
        openSudoku(in: app)
        tap(app.buttons["Example"], in: app)
        tap(app.buttons["Reset"], in: app)
        XCTAssertTrue(app.buttons["sudoku-cell-1-1"].label.contains("empty"))
        XCTAssertFalse(app.buttons["Solve Sudoku"].isEnabled)
        app.navigationBars.buttons.firstMatch.tap()
        tap(app.staticTexts["Sudoku"].firstMatch, in: app)
        XCTAssertTrue(app.buttons["sudoku-cell-1-1"].label.contains("empty"))
        XCTAssertFalse(app.buttons["Solve Sudoku"].isEnabled)
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

    // Run both tests on compact, standard, and large iPhone destinations.
    func testAdvancedCube2x2NetAlignment() { verifyAdvancedCubeNet(size: 2) }
    func testAdvancedCube3x3NetAlignment() { verifyAdvancedCubeNet(size: 3) }

    private func verifyAdvancedCubeNet(size: Int) {
        let app = launchAtMainMenu()
        openMode(size == 2 ? "2×2 Cube" : "3×3 Rubik’s Cube", category: "Twisty Puzzles", in: app)
        tap(app.buttons["Advanced net input"], in: app)
        let net = app.otherElements["cube-net"]
        revealInputControl(net, in: app)

        let storageFaces = ["U", "R", "F", "D", "L", "B"]
        let names = ["Up", "Right", "Front", "Down", "Left", "Back"]
        let perFace = size * size
        for (faceIndex, code) in storageFaces.enumerated() {
            let label = app.staticTexts["cube-net-label-\(code)"]
            XCTAssertTrue(label.exists)
            XCTAssertTrue(app.frame.contains(label.frame), "Face label is clipped")
            XCTAssertGreaterThanOrEqual(label.frame.minX, app.frame.minX + 29)
            XCTAssertLessThanOrEqual(label.frame.maxX, app.frame.maxX - 29)
            for cell in 0..<perFace {
                let center = size == 3 && cell == 4
                let key = app.buttons[center ? "cube-locked-center-\(code)" : "cube-sticker-\(faceIndex * perFace + cell)"]
                XCTAssertTrue(key.exists)
                XCTAssertTrue(app.frame.contains(key.frame), "Sticker is clipped")
                XCTAssertGreaterThanOrEqual(key.frame.minX, app.frame.minX + 29)
                XCTAssertLessThanOrEqual(key.frame.maxX, app.frame.maxX - 29)
                XCTAssertEqual(key.frame.width, key.frame.height, accuracy: 1)
                XCTAssertEqual(key.isEnabled, !center)
                XCTAssertEqual(key.label, center ? "Locked \(names[faceIndex]) center" : "\(names[faceIndex]) sticker row \(cell / size + 1) column \(cell % size + 1)")
            }
        }
        XCTAssertEqual(app.staticTexts["cube-net-label-B"].label, "Back (viewed from behind)")

        func firstSticker(_ face: Int) -> CGRect { app.buttons["cube-sticker-\(face * perFace)"].frame }
        func faceCenter(_ face: Int) -> CGFloat {
            let first = firstSticker(face)
            let last = app.buttons["cube-sticker-\(face * perFace + perFace - 1)"].frame
            return (first.minX + last.maxX) / 2
        }
        let sideFaces = [4, 2, 1, 5] // L, F, R, B in view order; storage remains U, R, F, D, L, B.
        let front = firstSticker(2)
        for face in sideFaces {
            XCTAssertEqual(firstSticker(face).minY, front.minY, accuracy: 1)
            XCTAssertEqual(firstSticker(face).width, front.width, accuracy: 1)
        }
        let gaps = zip(sideFaces, sideFaces.dropFirst()).map { left, right in
            firstSticker(right).minX - app.buttons["cube-sticker-\(left * perFace + size - 1)"].frame.maxX
        }
        for gap in gaps {
            XCTAssertGreaterThan(gap, 0)
            XCTAssertEqual(gap, gaps[0], accuracy: 1)
        }
        XCTAssertEqual(faceCenter(0), faceCenter(2), accuracy: 1)
        XCTAssertEqual(faceCenter(3), faceCenter(2), accuracy: 1)
        XCTAssertLessThan(firstSticker(0).maxY, front.minY)
        XCTAssertGreaterThan(firstSticker(3).minY, front.maxY)

        // Every first sticker keeps its physical storage index and face label.
        for face in storageFaces.indices {
            let sticker = app.buttons["cube-sticker-\(face * perFace)"]
            sticker.tap()
            XCTAssertEqual(sticker.value as? String, "Selected")
        }
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

    // Run these on compact, standard, and large iPhone simulator destinations.
    func testCompactSliding3x3Picker() { verifyCompactSlidingPicker(size: 3) }
    func testCompactSliding4x4Picker() { verifyCompactSlidingPicker(size: 4) }
    func testCompactSliding5x5Picker() { verifyCompactSlidingPicker(size: 5) }

    private func verifyCompactSlidingPicker(size: Int) {
        let app = launchAtMainMenu()
        openMode("\(size)×\(size) Sliding Puzzle", category: "Sliding Puzzles", in: app)
        let keys = (1..<(size * size)).map { app.buttons["sliding-key-\($0)"] }
            + [app.buttons["sliding-key-blank"]]
        for key in keys {
            revealInputControl(key, in: app)
            XCTAssertTrue(key.isEnabled)
            XCTAssertGreaterThanOrEqual(key.frame.width, 44)
            XCTAssertGreaterThanOrEqual(key.frame.height, 44)
            XCTAssertLessThanOrEqual(key.frame.height, 64, "Picker controls should remain compact at default text size")
            if size == 5 && app.frame.width >= 375 {
                // A normal-width phone must fit at least five controls per row.
                let fiveColumnWidth = (app.frame.width - 60 - 4 * 6) / 5
                XCTAssertLessThanOrEqual(key.frame.width, fiveColumnWidth + 1)
            }
            // Horizontal bounds include the screen padding and the card's 14pt inset.
            XCTAssertGreaterThanOrEqual(key.frame.minX, app.frame.minX + 30 - 1)
            XCTAssertLessThanOrEqual(key.frame.maxX, app.frame.maxX - 30 + 1)
            XCTAssertTrue(app.frame.contains(key.frame), "Picker control is clipped")
        }

        let one = app.buttons["sliding-key-1"]
        revealInputControl(one, in: app)
        one.tap()
        XCTAssertFalse(one.isEnabled)
        XCTAssertEqual(one.label, "Tile 1, already used")
        let firstCell = app.buttons["sliding-cell-1-1"]
        revealInputControl(firstCell, in: app)
        XCTAssertEqual(firstCell.label, "Tile 1")
        let secondCell = app.buttons["sliding-cell-1-2"]
        XCTAssertEqual(secondCell.value as? String, "Selected")

        let blank = app.buttons["sliding-key-blank"]
        revealInputControl(blank, in: app)
        blank.tap()
        XCTAssertFalse(blank.isEnabled)
        revealInputControl(secondCell, in: app)
        XCTAssertEqual(secondCell.label, "Blank tile")

        let reset = app.buttons["Reset"]
        revealInputControl(reset, in: app)
        reset.tap()
        for key in keys {
            revealInputControl(key, in: app)
            XCTAssertTrue(key.isEnabled, "Reset must restore tile availability")
        }
        revealInputControl(firstCell, in: app)
        XCTAssertEqual(firstCell.label, "Empty tile")
        XCTAssertEqual(firstCell.value as? String, "Selected")
    }

    private func revealInputControl(_ element: XCUIElement, in app: XCUIApplication) {
        // Lazy grid cells may not exist until scrolled into view. Start at the top
        // so this helper also works when returning from the picker to the board.
        for _ in 0..<8 {
            if element.exists && element.isHittable && app.frame.contains(element.frame) { return }
            app.swipeDown()
        }
        for _ in 0..<10 {
            if element.exists && element.isHittable && app.frame.contains(element.frame) { return }
            app.swipeUp()
        }
        XCTFail("Input control was not fully visible: \(element.identifier)")
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
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
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

import XCTest
@testable import Puzzle_Solver

final class KillerSudokuProductionUITests: XCTestCase {
    func testBundledExampleHasCompleteValidCageCoverageAndNoGivenDigits() {
        let board = KillerSudokuBoard.example
        let report = KillerSudokuValidator.report(for: board)

        XCTAssertTrue(report.canSolve)
        XCTAssertEqual(board.cages.flatMap(\.cells).count, 81)
        XCTAssertTrue(board.cells.flatMap { $0 }.allSatisfy { $0.value == nil })
        XCTAssertTrue(board.cages.contains { $0.cells.count > 1 })
        XCTAssertNotEqual(KillerSudokuValidator.validate(board), .invalid)
    }

    func testCoverageReportExplainsIncompleteImpossibleAndOverlappingCages() {
        let cell = LogicGridCoordinate(row: 0, column: 0)
        var board = KillerSudokuBoard.placeholder
        XCTAssertEqual(KillerSudokuValidator.report(for: board).uncoveredCells.count, 81)
        XCTAssertEqual(KillerSudokuValidator.report(for: board).message, "81 cells still need cages.")

        board.cages = [KillerSudokuCage(targetSum: 20, cells: [cell])]
        XCTAssertEqual(KillerSudokuValidator.report(for: board).invalidCageIndices, [0])
        XCTAssertTrue(KillerSudokuValidator.report(for: board).message.contains("impossible total"))

        board.cages.append(KillerSudokuCage(targetSum: 1, cells: [cell]))
        XCTAssertEqual(KillerSudokuValidator.report(for: board).overlappingCells, [cell])
        XCTAssertEqual(KillerSudokuValidator.report(for: board).message, "These cells already belong to another cage.")
    }
}

final class StabilizationTests: XCTestCase {
    func testV1AppearanceChoicesOnlyAdvertiseSupportedModes() {
        XCTAssertEqual(AppAppearanceOption.allCases, [.system, .dark])
        XCTAssertNil(AppAppearanceOption.system.colorScheme, "System must inherit the device color scheme")
        XCTAssertEqual(AppAppearanceOption.dark.colorScheme, .dark)
    }

    func testPersistedAppearanceResolvesAcrossRelaunchesAndLegacyValues() {
        XCTAssertEqual(AppAppearanceOption.resolve(AppAppearanceOption.dark.rawValue), .dark)
        XCTAssertEqual(AppAppearanceOption.resolve(AppAppearanceOption.system.rawValue), .system)
        XCTAssertEqual(AppAppearanceOption.resolve("light"), .system)
        XCTAssertEqual(AppAppearanceOption.resolve("unexpected-value"), .system)
    }

    @MainActor
    func testLaunchStateStartsAtSplashAndCompletesExactlyOnce() {
        let state = LaunchStateController()
        XCTAssertEqual(state.phase, .splash)
        XCTAssertTrue(state.completeSplash())
        XCTAssertEqual(state.phase, .main)
        XCTAssertFalse(state.completeSplash())
    }

    @MainActor
    func testFreshLaunchStateIsDeterministic() {
        let first = LaunchStateController()
        first.completeSplash()
        let relaunched = LaunchStateController()
        XCTAssertEqual(relaunched.phase, .splash)
    }

    func testSudokuFixtureHasValidStructureAndCanSolve() {
        let board = SudokuBoard(values: SudokuFixtureBoards.printedPuzzle)
        XCTAssertEqual(board.cells.count, 9)
        XCTAssertTrue(board.cells.allSatisfy { $0.count == 9 })
        XCTAssertTrue(SudokuValidator.validate(board).canSolve)
    }

    func testScanMappingRejectsOutOfRangeCoordinates() {
        let cells = [
            SudokuDetectedCell(row: 0, column: 0, recognizedValue: 5, confidence: 0.99),
            SudokuDetectedCell(row: 9, column: 0, recognizedValue: 7, confidence: 0.99),
            SudokuDetectedCell(row: 0, column: -1, recognizedValue: 8, confidence: 0.99)
        ]
        let board = SudokuScanResult(cells: cells).board
        XCTAssertEqual(board.filledCount, 1)
        XCTAssertEqual(board.cells[0][0].value, 5)
    }

    func testOCRAcceptsOnlySingleDigitsOneThroughNine() {
        XCTAssertEqual(SudokuCellOCRService.recognizedDigit(from: " 9 "), 9)
        ["", "0", "10", "A", ".", "1x"].forEach { XCTAssertNil(SudokuCellOCRService.recognizedDigit(from: $0)) }
    }

    func testEverySupportedTwoByTwoMoveRoundTripsAndHasOrderFour() {
        for move in TwoByTwoMoveEngine.legalMoves {
            let moved = TwoByTwoMoveEngine.apply(move.notation, to: .solved2x2)
            XCTAssertEqual(TwoByTwoMoveEngine.apply(move.inverse.notation, to: moved), .solved2x2, move.notation)
        }
        for face in ["U", "R", "F"] {
            XCTAssertEqual(TwoByTwoMoveEngine.apply(Array(repeating: face, count: 4), to: .solved2x2), .solved2x2)
            XCTAssertEqual(TwoByTwoMoveEngine.apply(["\(face)2", "\(face)2"], to: .solved2x2), .solved2x2)
            XCTAssertEqual(TwoByTwoMoveEngine.apply(["\(face)'", face], to: .solved2x2), .solved2x2)
        }
    }

    func testCorrectedRightAndFrontStickerPermutations() {
        assertPermutation(
            move: "R",
            cycles: [[4, 6, 7, 5], [1, 9, 13, 22], [3, 11, 15, 20]]
        )
        assertPermutation(
            move: "F",
            cycles: [[8, 9, 11, 10], [2, 4, 13, 19], [3, 6, 12, 17]]
        )
    }

    func testEverySupportedTwoByTwoMoveConservesUniqueStickers() {
        let labelled = CubeState(puzzle: .twoByTwo, stickers: (0..<24).map(String.init))
        for move in TwoByTwoMoveEngine.legalMoves {
            let moved = TwoByTwoMoveEngine.apply(move.notation, to: labelled)
            XCTAssertEqual(moved.stickers.count, 24, move.notation)
            XCTAssertEqual(Set(moved.stickers), Set(labelled.stickers), move.notation)
            XCTAssertEqual(moved.stickers.sorted(), labelled.stickers.sorted(), move.notation)
        }
    }

    func testKnownRightAndFrontOneMoveStatesSolveAndReplay() throws {
        // These are the row-by-row U, R, F, D, L, B sticker states produced by
        // one physical clockwise turn from the canonical solved state.
        let cases: [(move: String, stickers: [String])] = [
            ("R", ["U", "B", "U", "B", "R", "R", "R", "R", "F", "U", "F", "U", "D", "F", "D", "F", "L", "L", "L", "L", "D", "B", "D", "B"]),
            ("F", ["U", "U", "L", "L", "U", "R", "U", "R", "F", "F", "F", "F", "R", "R", "D", "D", "L", "D", "L", "D", "B", "B", "B", "B"])
        ]

        for testCase in cases {
            let initial = CubeState(puzzle: .twoByTwo, stickers: testCase.stickers)
            XCTAssertFalse(initial.isSolved, testCase.move)

            let result = Cube2x2Solver().solve(
                initial,
                options: CubeSolveOptions(timeout: 2, maxDepth: 1, maxNodes: 1_000, includeStepStates: true)
            )
            XCTAssertEqual(result.status, .success, testCase.move)
            XCTAssertEqual(result.moves.count, 1, testCase.move)

            let parsed = try TwistyMoveNotation.parse(
                result.moves.joined(separator: " "),
                spec: TwistyPuzzleKind.twoByTwo.notation
            ).get()
            let replayed = TwoByTwoMoveEngine.apply(parsed.map(\.notation), to: initial)
            XCTAssertEqual(replayed, .solved2x2, testCase.move)
            XCTAssertTrue(replayed.isSolvedByFace, testCase.move)
        }
    }

    func testAllNormalTwistyFixturesReplaySolverOutputToSolved() throws {
        let solver = Cube2x2Solver()
        for fixture in TwistySolverFixture.normalSuite {
            let moves = try TwistyMoveNotation.parse(fixture.scramble, spec: TwistyPuzzleKind.twoByTwo.notation).get()
            let initial = TwoByTwoMoveEngine.apply(moves.map(\.notation), to: .solved2x2)
            XCTAssertEqual(initial.isSolved, fixture.expectedSolved, fixture.name)
            let result = solver.solve(initial, options: CubeSolveOptions(timeout: 3, maxDepth: 8, maxNodes: 100_000, includeStepStates: true))
            XCTAssertTrue(result.status == .success || result.status == .alreadySolved, "\(fixture.name): \(String(describing: result.failureReason))")
            XCTAssertEqual(TwoByTwoMoveEngine.apply(result.moves, to: initial), .solved2x2, fixture.name)
            if let maximum = fixture.maximumSolutionLength { XCTAssertLessThanOrEqual(result.moves.count, maximum, fixture.name) }
        }
    }

    func testTwistySolverIsDeterministicForRepresentativeFixture() throws {
        let fixture = TwistySolverFixture.short[3]
        let moves = try TwistyMoveNotation.parse(fixture.scramble, spec: TwistyPuzzleKind.twoByTwo.notation).get()
        let initial = TwoByTwoMoveEngine.apply(moves.map(\.notation), to: .solved2x2)
        let options = CubeSolveOptions(timeout: 3, maxDepth: 8, maxNodes: 100_000, includeStepStates: false)
        XCTAssertEqual(Cube2x2Solver().solve(initial, options: options).moves, Cube2x2Solver().solve(initial, options: options).moves)
    }

    func testInvalidTwistyStatesAreRejectedBeforeSearch() {
        let wrongCount = CubeState(puzzle: .twoByTwo, stickers: Array(repeating: "U", count: 23))
        let wrongColors = CubeState(puzzle: .twoByTwo, stickers: Array(repeating: "U", count: 24))
        for state in [wrongCount, wrongColors] {
            let result = Cube2x2Solver().solve(state, options: .default)
            XCTAssertEqual(result.status, .invalidInput)
            XCTAssertEqual(result.nodesExplored, 0)
        }
    }

    func testPhysicalCornerValidationAcceptsSolvedMovesAndScrambles() {
        let legalStates = [
            CubeState.solved2x2,
            TwoByTwoMoveEngine.apply("R", to: .solved2x2),
            TwoByTwoMoveEngine.apply(["U", "R", "F"], to: .solved2x2),
            TwoByTwoMoveEngine.apply(["F2", "U", "R2", "F'"], to: .solved2x2),
            TwoByTwoMoveEngine.apply(["R", "U", "R'", "U'", "F2"], to: .solved2x2)
        ]

        for state in legalStates {
            guard case .success(let cubies) = TwoByTwoCubieConverter.validate(state) else {
                return XCTFail("Production moves must always produce a valid physical cubie state")
            }
            XCTAssertEqual(cubies.corners.count, 8)
            XCTAssertEqual(cubies.corners.reduce(0) { $0 + $1.orientation } % 3, 0)
        }
    }

    func testPhysicalCornerValidationRejectsDuplicateAndMissingReplacement() {
        var stickers = CubeState.solved2x2.stickers
        // Exchanging R and L stickers turns URF/ULB into duplicate UFL/UBR
        // identities, so the original two cubies are simultaneously missing.
        stickers.swapAt(4, 16)
        let state = CubeState(puzzle: .twoByTwo, stickers: stickers)

        assertInvalidPhysicalState(state)
    }

    func testPhysicalCornerValidationRejectsImpossibleColorCombination() {
        var stickers = CubeState.solved2x2.stickers
        stickers.swapAt(4, 14) // Produces a corner containing both U and D.

        assertInvalidPhysicalState(CubeState(puzzle: .twoByTwo, stickers: stickers))
    }

    func testPhysicalCornerValidationRejectsOneTwistedCornerBeforeSearch() {
        var stickers = CubeState.solved2x2.stickers
        let corner = TwoByTwoCornerPosition.upRightFront.stickerIndices
        let old = stickers
        stickers[corner[0]] = old[corner[2]]
        stickers[corner[1]] = old[corner[0]]
        stickers[corner[2]] = old[corner[1]]
        let state = CubeState(puzzle: .twoByTwo, stickers: stickers)

        assertInvalidPhysicalState(state)
        let result = Cube2x2Solver().solve(state, options: .default)
        XCTAssertEqual(result.status, .invalidInput)
        XCTAssertEqual(result.nodesExplored, 0)
    }

    func testPhysicalCornerValidationRejectsStickerAndColorCounts() {
        let short = CubeState(puzzle: .twoByTwo, stickers: Array(CubeState.solved2x2.stickers.dropLast()))
        var wrongColors = CubeState.solved2x2.stickers
        wrongColors[0] = "R"

        assertInvalidPhysicalState(short)
        assertInvalidPhysicalState(CubeState(puzzle: .twoByTwo, stickers: wrongColors))
    }

    func testInvalidAndNormalizedScrambleFormatting() {
        let spec = TwistyPuzzleKind.twoByTwo.notation
        for invalid in ["X", "r", "R3", "Rw", "R,U", "R!!"] {
            XCTAssertThrowsError(try TwistyMoveNotation.parse(invalid, spec: spec).get(), invalid)
        }
        XCTAssertEqual(try TwistyMoveNotation.parse("  R   U’  ", spec: spec).get().map(\.notation), ["R", "U'"])
        XCTAssertEqual(try TwistyMoveNotation.parse("", spec: spec).get(), [])
    }

    func testTwistySearchLimitsReturnCleanly() {
        let initial = TwoByTwoMoveEngine.apply("R", to: .solved2x2)
        let timedOut = Cube2x2Solver().solve(initial, options: CubeSolveOptions(timeout: 0, maxDepth: 8, maxNodes: 100_000, includeStepStates: false))
        XCTAssertEqual(timedOut.status, .timeout)
        let nodeLimited = Cube2x2Solver().solve(initial, options: CubeSolveOptions(timeout: 2, maxDepth: 8, maxNodes: 0, includeStepStates: false))
        XCTAssertEqual(nodeLimited.status, .failure)
    }

    private func assertPermutation(move: String, cycles: [[Int]], file: StaticString = #filePath, line: UInt = #line) {
        let labelled = CubeState(puzzle: .twoByTwo, stickers: (0..<24).map(String.init))
        let moved = TwoByTwoMoveEngine.apply(move, to: labelled)
        let affected = Set(cycles.flatMap { $0 })

        for cycle in cycles {
            for index in cycle.indices {
                XCTAssertEqual(
                    moved.stickers[cycle[(index + 1) % cycle.count]],
                    labelled.stickers[cycle[index]],
                    "\(move): cycle must move each sticker to the next listed position",
                    file: file,
                    line: line
                )
            }
        }
        for index in labelled.stickers.indices where !affected.contains(index) {
            XCTAssertEqual(moved.stickers[index], labelled.stickers[index], "\(move): unaffected sticker \(index)", file: file, line: line)
        }
    }


    private func assertInvalidPhysicalState(_ state: CubeState, file: StaticString = #filePath, line: UInt = #line) {
        guard case .failure = TwoByTwoCubieConverter.validate(state) else {
            return XCTFail("Expected a physically invalid 2×2 state", file: file, line: line)
        }
    }
}

// MARK: - Real Sudoku photo pipeline fixtures

final class SudokuPhotoScanEndToEndTests: XCTestCase {
    private struct ExpectedBoard: Decodable {
        let board: [[Int?]]
        let digitState: String
        let blankState: String
    }

    private struct SuccessfulFixture {
        let image: String
        let expectation: String
        let scale: CGFloat
    }

    func testPhotoScanPermissionPurposeStringsAreSpecific() throws {
        let info = try XCTUnwrap(Bundle.main.infoDictionary)
        XCTAssertEqual(
            info["NSCameraUsageDescription"] as? String,
            "Photograph a Sudoku puzzle for on-device recognition."
        )
        XCTAssertEqual(
            info["NSPhotoLibraryUsageDescription"] as? String,
            "Choose a Sudoku image for on-device recognition."
        )
        XCTAssertNil(info["NSPhotoLibraryAddUsageDescription"])
    }

    /// These cases deliberately invoke the default coordinator: image decoding,
    /// orientation normalization, rectangle detection, perspective correction,
    /// 900px rendering, segmentation, Vision OCR, and review-state mapping all run.
    func testRepositoryFixturesProduceAllExpected81Cells() async throws {
        let fixtures = [
            SuccessfulFixture(image: "clean-printed", expectation: "clean-printed", scale: 1),
            SuccessfulFixture(image: "slightly-rotated", expectation: "slightly-rotated", scale: 1),
            SuccessfulFixture(image: "perspective-skewed", expectation: "perspective-skewed", scale: 1),
            SuccessfulFixture(image: "low-contrast", expectation: "low-contrast", scale: 1),
            SuccessfulFixture(image: "surrounding-text", expectation: "surrounding-text", scale: 1),
            SuccessfulFixture(image: "clean-printed", expectation: "scale-1", scale: 1),
            SuccessfulFixture(image: "clean-printed", expectation: "scale-2", scale: 2),
            SuccessfulFixture(image: "clean-printed", expectation: "scale-3", scale: 3),
            SuccessfulFixture(image: "difficult-printed-digits", expectation: "difficult-printed-digits", scale: 1)
        ]

        for fixture in fixtures {
            let source = try fixtureImage(named: fixture.image, scale: fixture.scale)
            var states: [SudokuScanState] = []
            let result = try await SudokuScanCoordinator().process(image: source) { states.append($0) }
            let expected = try expectedBoard(named: fixture.expectation)

            XCTAssertEqual(result.cells.count, 81, fixture.expectation)
            XCTAssertEqual(result.cells.map(\.recognizedValue), expected.board.flatMap { $0 }, fixture.expectation)
            XCTAssertEqual(
                result.cells.map(\.reviewState),
                expected.board.flatMap { $0 }.map { $0 == nil ? .blank : .highConfidence },
                "Review mapping differs for \(fixture.expectation) (expected states: \(expected.digitState)/\(expected.blankState))"
            )
            XCTAssertEqual(states, [.loadingImage, .detectingBoard, .correctingPerspective, .readingCells, .validating])
        }
    }

    func testFailureRasterFixturesHaveExplicitOutcomes() async throws {
        await assertFailure("no-grid", equals: .boardCouldNotBeDetected)
        await assertFailure("cropped-incomplete", equals: .boardCouldNotBeDetected)
        await assertFailure("insufficient-clues", equals: .ocrCouldNotReadEnoughNumbers)
        await assertFailure("unrecoverable-perspective", equals: .boardCouldNotBeDetected)
    }

    func testInjectedOCRFailureIsPropagatedAfterRealImageStages() async throws {
        let image = try fixtureImage(named: "clean-printed")
        let expected = SudokuImageImportError.processingFailure("Injected OCR outage")
        let coordinator = SudokuScanCoordinator(ocr: { _ in throw expected })

        do {
            _ = try await coordinator.process(image: image) { _ in }
            XCTFail("Expected injected OCR failure")
        } catch let error as SudokuImageImportError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func assertFailure(_ fixture: String, equals expected: SudokuImageImportError) async {
        do {
            _ = try await SudokuScanCoordinator().process(image: try fixtureImage(named: fixture)) { _ in }
            XCTFail("\(fixture) unexpectedly scanned")
        } catch let error as SudokuImageImportError {
            XCTAssertEqual(error, expected, fixture)
        } catch {
            XCTFail("\(fixture): unexpected error \(error)")
        }
    }

    private func fixtureImage(named name: String, scale: CGFloat = 1) throws -> UIImage {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "svg", subdirectory: "SudokuImages"))
        let decoded = try XCTUnwrap(UIImage(data: Data(contentsOf: url)))
        let pixels = try XCTUnwrap(decoded.cgImage, "Fixture must decode to raster pixels")
        return UIImage(cgImage: pixels, scale: scale, orientation: .up)
    }

    private func expectedBoard(named name: String) throws -> ExpectedBoard {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "\(name).expected", withExtension: "json", subdirectory: "SudokuImages"))
        let expected = try JSONDecoder().decode(ExpectedBoard.self, from: Data(contentsOf: url))
        XCTAssertEqual(expected.board.count, 9)
        XCTAssertTrue(expected.board.allSatisfy { $0.count == 9 })
        return expected
    }
}

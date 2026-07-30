import XCTest
@testable import Puzzle_Solver

final class StabilizationTests: XCTestCase {
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
}

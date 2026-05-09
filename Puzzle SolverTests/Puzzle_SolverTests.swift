//
//  Puzzle_SolverTests.swift
//  Puzzle SolverTests
//
//  Created by Aditi Abrol on 30/1/24.
//

import XCTest
@testable import Puzzle_Solver

final class Puzzle_SolverTests: XCTestCase {
    // MARK: - 3×3 sliding puzzle

    func testSolvedThreeByThreeSlidingPuzzleReturnsSolvedWithoutMoves() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding3x3Solved)

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.moves, [])
    }

    func testOneMoveThreeByThreeSlidingPuzzleSolves() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding3x3OneMove)

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.moves.count, 1)
    }

    func testMediumThreeByThreeSlidingPuzzleSolves() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding3x3Medium)

        XCTAssertEqual(result.state, .solved)
        XCTAssertFalse(result.moves.isEmpty)
    }

    func testInvalidThreeByThreeSlidingPuzzleReturnsInvalid() throws {
        let invalid = SlidingPuzzleBoard(size: 3, tiles: [1, 1, 2, 3, 4, 5, 6, 7, 0])
        let result = SlidingPuzzleSolver().solve(invalid)

        XCTAssertEqual(result.state, .invalid)
    }

    func testUnsolvableThreeByThreeSlidingPuzzleReturnsUnsolvable() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding3x3Unsolvable)

        XCTAssertEqual(result.state, .unsolvable)
    }

    func testThreeByThreeSlidingPuzzleUsesSuccessfulOrderedPath() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding3x3OneMove)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.path.first, PuzzlePresets.sliding3x3OneMove)
        XCTAssertEqual(result.path.last, PuzzlePresets.sliding3x3Solved)
        XCTAssertEqual(result.steps.count, result.path.count)
    }

    func testThreeByThreeSlidingPuzzleDoesNotReturnFailurePath() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding3x3Unsolvable)

        XCTAssertFalse(result.succeeded)
        XCTAssertTrue(result.moves.isEmpty)
        XCTAssertTrue(result.path.isEmpty)
        XCTAssertTrue(result.steps.isEmpty)
    }

    func testThreeByThreeSlidingPuzzleTimeoutIsBounded() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding3x3Medium, options: SlidingPuzzleSolveOptions(timeout: 0, maxNodes: 100_000))

        XCTAssertEqual(result.state, .timedOut)
    }

    // MARK: - 4×4 sliding puzzle solver coverage

    func testSolvedFourByFourSlidingPuzzleReturnsSolvedWithoutMoves() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding4x4Solved)

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.moves, [])
    }

    func testOneMoveFourByFourSlidingPuzzleSolves() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding4x4OneMove)

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.moves.count, 1)
    }

    func testMediumFourByFourSlidingPuzzleSolves() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding4x4Medium)

        XCTAssertEqual(result.state, .solved)
        XCTAssertFalse(result.moves.isEmpty)
    }

    func testFourByFourSlidingPuzzleUsesIDAStarPath() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding4x4OneMove)

        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.path.first, PuzzlePresets.sliding4x4OneMove)
        XCTAssertEqual(result.path.last, PuzzlePresets.sliding4x4Solved)
        XCTAssertEqual(result.moves, [SlidingPuzzleMove.right.rawValue])
    }

    func testInvalidFourByFourSlidingPuzzleReturnsInvalid() throws {
        let invalid = SlidingPuzzleBoard(size: 4, tiles: Array(repeating: 0, count: 16))
        let result = SlidingPuzzleSolver().solve(invalid)

        XCTAssertEqual(result.state, .invalid)
    }

    func testFourByFourSlidingPuzzleTimeoutIsBounded() throws {
        let result = SlidingPuzzleSolver().solve(PuzzlePresets.sliding4x4Medium, options: SlidingPuzzleSolveOptions(timeout: 0, maxNodes: 100_000))

        XCTAssertEqual(result.state, .timedOut)
    }

    // MARK: - 2×2 cube solver coverage

    func testSolvedTwoByTwoReturnsSuccessWithoutMoves() throws {
        let solver = Cube2x2Solver()

        let result = solver.solve(.solved2x2, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 100, includeStepStates: true))

        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.moveCount, 0)
        XCTAssertTrue(result.steps.isEmpty)
    }

    func testOneMoveTwoByTwoSolves() throws {
        let solver = Cube2x2Solver()
        let scrambled = makeTwoByTwoState(after: ["U"])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 2, maxDepth: 4, maxNodes: 10_000, includeStepStates: true))

        XCTAssertEqual(result.status, .success)
        XCTAssertFalse(result.moves.isEmpty)
    }

    func testMediumTwoByTwoScrambleSolves() throws {
        let solver = Cube2x2Solver()
        let scrambled = makeTwoByTwoState(after: ["U", "R", "F"])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 3, maxDepth: 8, maxNodes: 50_000, includeStepStates: false))

        XCTAssertEqual(result.status, .success)
        XCTAssertFalse(result.moves.isEmpty)
    }

    func testInvalidTwoByTwoReturnsInvalidInput() throws {
        let solver = Cube2x2Solver()
        let invalidState = CubeState(puzzle: .twoByTwo, stickers: ["U"])

        let result = solver.solve(invalidState, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 100, includeStepStates: true))

        XCTAssertEqual(result.status, .invalidInput)
        XCTAssertEqual(result.moveCount, 0)
    }

    func testTwoByTwoTimeoutIsBounded() throws {
        let solver = Cube2x2Solver()
        let scrambled = makeTwoByTwoState(after: ["U", "R", "F"])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 0, maxDepth: 8, maxNodes: 50_000, includeStepStates: false))

        XCTAssertEqual(result.status, .timeout)
    }

    // MARK: - 3×3 cube solver coverage

    func testSolvedThreeByThreeReturnsSuccessWithoutMoves() throws {
        let solver = Cube3x3Solver()

        let result = solver.solve(.solved3x3, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 100, includeStepStates: true))

        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.moveCount, 0)
        XCTAssertTrue(result.steps.isEmpty)
    }

    func testSingleRThreeByThreeReturnsInverseOrEquivalent() throws {
        let solver = Cube3x3Solver()
        let scrambled = makeThreeByThreeState(after: [.R])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 2, maxDepth: 4, maxNodes: 20_000, includeStepStates: true))

        XCTAssertEqual(result.status, .success)
        XCTAssertFalse(result.moves.isEmpty)
        XCTAssertTrue(result.steps.isEmpty)
        XCTAssertTrue(solves(scrambled, moves: result.moves))
    }

    func testSimpleThreeByThreeScrambleSolves() throws {
        let solver = Cube3x3Solver()
        let scrambled = makeThreeByThreeState(after: [.R, .U, .Ri, .Ui])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 5, maxDepth: 8, maxNodes: 250_000, includeStepStates: false))

        XCTAssertEqual(result.status, .success)
        XCTAssertTrue(solves(scrambled, moves: result.moves))
    }

    func testInvalidThreeByThreeColorCountFailsBeforeSolving() throws {
        let solver = Cube3x3Solver()
        var stickers = CubeState.solved3x3.stickers
        stickers[0] = "R"
        let invalid = CubeState(puzzle: .threeByThree, stickers: stickers)

        let result = solver.solve(invalid, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 100, includeStepStates: false))

        XCTAssertEqual(result.status, .invalidInput)
        XCTAssertEqual(result.nodesExplored, 0)
    }

    func testThreeByThreeSafetyOptionsKeepSearchBounded() throws {
        let solver = Cube3x3Solver()
        let scrambled = makeThreeByThreeState(after: [.R, .U, .Ri, .Ui])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 0, maxDepth: 8, maxNodes: 1, includeStepStates: false))

        XCTAssertTrue([CubeSolveStatus.success, .timeout, .failure].contains(result.status))
        XCTAssertLessThan(result.elapsedTime, 2)
    }

    // MARK: - Larger active cube placeholders

    func testFourByFourCubeReportsUnavailableInsteadOfHanging() throws {
        let solver = Cube4x4Solver()
        let state = CubeState(puzzle: .fourByFour, stickers: Array(repeating: "U", count: 96))

        let result = solver.solve(state, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 1, includeStepStates: false))

        XCTAssertEqual(result.status, .solverUnavailable)
    }

    func testInvalidFourByFourCubeReturnsInvalidInput() throws {
        let solver = Cube4x4Solver()
        let result = solver.solve(CubeState(puzzle: .fourByFour, stickers: []), options: .default)

        XCTAssertEqual(result.status, .invalidInput)
    }


    // MARK: - Shared twisty architecture

    func testTwistyMoveNotationParsesAndFormatsReusableMoves() throws {
        let parsed = try TwistyMoveNotation.parse("U R' F2", allowedFaces: Set(["U", "R", "F"])).get()

        XCTAssertEqual(parsed.map(\.notation), ["U", "R'", "F2"])
        XCTAssertEqual(TwistyMoveNotation.format(parsed), "U R' F2")
        XCTAssertEqual(parsed[1].inverse.notation, "R")
    }

    func testTwistyMoveNotationRejectsUnsupportedFaces() throws {
        let parsed = TwistyMoveNotation.parse("B", allowedFaces: Set(["U", "R", "F"]))

        XCTAssertThrowsError(try parsed.get())
    }

    func testSolvedPyraminxAndSkewbReturnSuccess() throws {
        let pyraminx = PyraminxSolver().solve(.solvedPyraminx, options: .default)
        let skewb = SkewbSolver().solve(.solvedSkewb, options: .default)

        XCTAssertEqual(pyraminx.status, .success)
        XCTAssertEqual(skewb.status, .success)
        XCTAssertEqual(pyraminx.moveCount, 0)
        XCTAssertEqual(skewb.moveCount, 0)
    }

    func testPyraminxAndSkewbScramblesSolveWithSharedResults() throws {
        let pyraminxMoves = try TwistyMoveNotation.parse("U R L'", spec: TwistyPuzzleKind.pyraminx.notation).get()
        let pyraminxState = PyraminxMoveEngine.apply(pyraminxMoves, to: .solvedPyraminx)
        let pyraminx = PyraminxSolver().solve(pyraminxState, options: CubeSolveOptions(timeout: 2, maxDepth: 8, maxNodes: 50_000, includeStepStates: true))

        let skewbMoves = try TwistyMoveNotation.parse("R U B'", spec: TwistyPuzzleKind.skewb.notation).get()
        let skewbState = SkewbMoveEngine.apply(skewbMoves, to: .solvedSkewb)
        let skewb = SkewbSolver().solve(skewbState, options: CubeSolveOptions(timeout: 2, maxDepth: 8, maxNodes: 50_000, includeStepStates: true))

        XCTAssertEqual(pyraminx.status, .success)
        XCTAssertEqual(skewb.status, .success)
        XCTAssertEqual(PyraminxMoveEngine.apply(try TwistyMoveNotation.parse(pyraminx.formattedMoves, spec: TwistyPuzzleKind.pyraminx.notation).get(), to: pyraminxState), .solvedPyraminx)
        XCTAssertEqual(SkewbMoveEngine.apply(try TwistyMoveNotation.parse(skewb.formattedMoves, spec: TwistyPuzzleKind.skewb.notation).get(), to: skewbState), .solvedSkewb)
    }

    func testMegaminxAndSquareOnePlaceholdersReturnUnavailable() throws {
        let megaminx = MegaminxSolver().solve(.solvedMegaminx, options: .default)
        let squareOne = SquareOneSolver().solve(.solvedSquareOne, options: .default)

        XCTAssertEqual(megaminx.status, .solverUnavailable)
        XCTAssertEqual(squareOne.status, .solverUnavailable)
    }

    func testDiagnosticsListsTwistyArchitectures() throws {
        XCTAssertTrue(PuzzleModeRegistry.diagnostics.contains { $0.name == "2×2 Cube" && $0.enabled && $0.solverAvailable })
        XCTAssertTrue(PuzzleModeRegistry.diagnostics.contains { $0.name == "Pyraminx" && $0.enabled && $0.solverAvailable })
        XCTAssertTrue(PuzzleModeRegistry.diagnostics.contains { $0.name == "Skewb" && $0.enabled && $0.solverAvailable })
        XCTAssertTrue(PuzzleModeRegistry.diagnostics.contains { $0.name == "Megaminx" && $0.enabled && !$0.solverAvailable })
        XCTAssertTrue(PuzzleModeRegistry.diagnostics.contains { $0.name == "Square-1" && $0.enabled && !$0.solverAvailable })
    }

    // MARK: - Shared state and diagnostics

    func testSolveStateContainsEveryRequiredState() throws {
        XCTAssertEqual(Set(SolveState.allCases.map(\.rawValue)), ["idle", "validating", "solving", "solved", "invalid", "unsolvable", "timedOut", "failed", "unsupported"])
    }

    func testDiagnosticsListsEnabledSlidingPuzzleMode() throws {
        XCTAssertTrue(PuzzleModeRegistry.diagnostics.contains { $0.name == "3×3 Sliding Puzzle" && $0.enabled && $0.solverAvailable })
    }

    func testDiagnosticsListsEnabledFourByFourSlidingPuzzleMode() throws {
        XCTAssertTrue(PuzzleModeRegistry.diagnostics.contains { $0.name == "4×4 Sliding Puzzle" && $0.enabled && $0.solverAvailable })
    }

    // MARK: - Helpers

    private func makeThreeByThreeState(after moves: [Cube3x3Move]) -> CubeState {
        let stickers = moves.reduce(CubeState.solved3x3.stickers) { stickers, move in
            Cube3x3MoveTables.shared.apply(move, to: stickers)
        }
        return CubeState(puzzle: .threeByThree, stickers: stickers)
    }

    private func solves(_ state: CubeState, moves: [String]) -> Bool {
        let finalStickers = moves.reduce(state.stickers) { stickers, moveName in
            guard let move = Cube3x3Move(rawValue: moveName) else { return stickers }
            return Cube3x3MoveTables.shared.apply(move, to: stickers)
        }
        return finalStickers == CubeState.solved3x3.stickers
    }

    private func makeTwoByTwoState(after moves: [String]) -> CubeState {
        moves.reduce(CubeState.solved2x2) { state, move in
            applyTwoByTwo(move, to: state)
        }
    }

    private func applyTwoByTwo(_ move: String, to state: CubeState) -> CubeState {
        let turns: Int
        switch move.last {
        case "'": turns = 3
        case "2": turns = 2
        default: turns = 1
        }

        var result = state
        for _ in 0..<turns {
            switch move.first {
            case "U": result = quarterTurn(result, cycles: [[0, 2, 3, 1], [8, 4, 20, 16], [9, 5, 21, 17]])
            case "R": result = quarterTurn(result, cycles: [[4, 6, 7, 5], [1, 9, 13, 23], [3, 11, 15, 21]])
            case "F": result = quarterTurn(result, cycles: [[8, 10, 11, 9], [2, 16, 13, 7], [3, 18, 12, 5]])
            default: break
            }
        }
        return result
    }

    private func quarterTurn(_ state: CubeState, cycles: [[Int]]) -> CubeState {
        var stickers = state.stickers
        let old = stickers
        for cycle in cycles {
            for index in 0..<cycle.count {
                stickers[cycle[(index + 1) % cycle.count]] = old[cycle[index]]
            }
        }
        return CubeState(puzzle: state.puzzle, stickers: stickers)
    }
    // MARK: - Logic puzzle architecture

    func testSudokuValidatorAcceptsExamplePuzzle() throws {
        let result = SudokuValidator.validate(.example)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.canSolve)
    }

    func testSudokuValidatorFindsDuplicateRowValues() throws {
        let board = SudokuBoard(values: [
            [1, 1, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil, nil]
        ])

        let result = SudokuValidator.validate(board)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(SudokuValidator.conflictingCoordinates(in: board).contains(LogicGridCoordinate(row: 0, column: 0)))
        XCTAssertTrue(SudokuValidator.conflictingCoordinates(in: board).contains(LogicGridCoordinate(row: 0, column: 1)))
    }

    func testSudokuSolverSolvesExamplePuzzle() throws {
        let result = SudokuSolver().solve(.example, options: SudokuSolveOptions(maxNodes: 100_000, timeout: 2))

        XCTAssertEqual(result.state, .solved)
        XCTAssertNotNil(result.solvedBoard)
        XCTAssertTrue(result.solvedBoard?.isComplete ?? false)
        XCTAssertTrue(SudokuValidator.validate(result.solvedBoard ?? .empty).isValid)
    }

    func testLogicPuzzleCatalogKeepsPlaceholdersSeparateFromPlayableSudoku() throws {
        let sudoku = try XCTUnwrap(LogicPuzzleCatalog.descriptors.first { $0.kind == .sudoku })
        let placeholders = LogicPuzzleCatalog.descriptors.filter { $0.kind != .sudoku }

        XCTAssertTrue(sudoku.enabled)
        XCTAssertTrue(sudoku.solverAvailable)
        XCTAssertTrue(placeholders.allSatisfy { !$0.enabled && !$0.solverAvailable })
    }

}

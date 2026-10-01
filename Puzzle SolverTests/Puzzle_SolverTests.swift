//
//  Puzzle_SolverTests.swift
//  Puzzle SolverTests
//
//  Created by Aditi Abrol on 30/1/24.
//

import XCTest
import CoreImage
import UIKit
@testable import Puzzle_Solver

final class Puzzle_SolverTests: XCTestCase {
    private struct CatalogExpectation: Equatable {
        let id: String
        let title: String
        let status: PuzzleAvailability
    }

    private let expectedV1Catalog = [
        CatalogExpectation(id: "sliding-3x3", title: "3×3 Sliding Puzzle", status: .active),
        CatalogExpectation(id: "sliding-4x4", title: "4×4 Sliding Puzzle", status: .active),
        CatalogExpectation(id: "sliding-5x5", title: "5×5 Sliding Puzzle", status: .active),
        CatalogExpectation(id: "cube-2x2", title: "2×2 Cube", status: .active),
        CatalogExpectation(id: "cube-3x3", title: "3×3 Rubik’s Cube", status: .active),
        CatalogExpectation(id: "pyraminx", title: "Pyraminx", status: .comingSoon),
        CatalogExpectation(id: "skewb", title: "Skewb", status: .comingSoon),
        CatalogExpectation(id: "megaminx", title: "Megaminx", status: .comingSoon),
        CatalogExpectation(id: "square-1", title: "Square-1", status: .comingSoon),
        CatalogExpectation(id: "sudoku", title: "Sudoku", status: .active),
        CatalogExpectation(id: "sudoku-photo-scan", title: "Sudoku Photo Scan", status: .active),
        CatalogExpectation(id: "killer-sudoku", title: "Killer Sudoku", status: .active),
        CatalogExpectation(id: "nonogram", title: "Nonogram", status: .comingSoon),
        CatalogExpectation(id: "kakuro", title: "Kakuro", status: .comingSoon),
        CatalogExpectation(id: "slitherlink", title: "Slitherlink", status: .comingSoon),
        CatalogExpectation(id: "rush-hour", title: "Rush Hour", status: .active),
        CatalogExpectation(id: "klotski", title: "Klotski", status: .comingSoon),
        CatalogExpectation(id: "peg-solitaire", title: "Peg Solitaire", status: .comingSoon),
        CatalogExpectation(id: "maze-solver", title: "Maze Solver", status: .comingSoon),
        CatalogExpectation(id: "chess-puzzles", title: "Chess Puzzles", status: .comingSoon),
        CatalogExpectation(id: "jigsaw-solver", title: "Jigsaw Solver", status: .comingSoon)
    ]

    func testV1AvailabilityCatalogMatchesApprovedReleaseSnapshot() {
        let actual = PuzzleAvailabilityCatalog.all.map {
            CatalogExpectation(id: $0.id, title: $0.title, status: $0.status)
        }

        XCTAssertEqual(actual, expectedV1Catalog)
    }

    func testAvailabilityCatalogDescriptorsAreInternallyConsistent() {
        let descriptors = PuzzleAvailabilityCatalog.all

        XCTAssertEqual(Set(descriptors.map(\.id)).count, descriptors.count)
        XCTAssertEqual(Set(descriptors.map(\.title)).count, descriptors.count)
        XCTAssertTrue(descriptors.allSatisfy { !$0.id.isEmpty && !$0.title.isEmpty && !$0.shortDescription.isEmpty && !$0.icon.isEmpty })
        XCTAssertTrue(descriptors.filter { $0.status == .active }.allSatisfy { $0.status.isInteractive })
        XCTAssertTrue(descriptors.filter { $0.status == .comingSoon }.allSatisfy { !$0.status.isInteractive })

        for category in PuzzleCategory.allCases {
            XCTAssertEqual(PuzzleAvailabilityCatalog.activeDescriptors(in: category), descriptors.filter { $0.category == category && $0.status == .active })
            XCTAssertEqual(PuzzleAvailabilityCatalog.comingSoonDescriptors(in: category), descriptors.filter { $0.category == category && $0.status == .comingSoon })
        }
    }

    func testSudokuBoardLayoutFitsCompactAndStandardWidths() {
        for availableWidth in [288.0, 358.0, 398.0] {
            let side = SudokuLayout.boardSide(for: availableWidth)

            XCTAssertLessThanOrEqual(side + SudokuLayout.boardBorderInset * 2, availableWidth)
            XCTAssertEqual(side / 9 * 9, side, accuracy: 0.001)
        }

        XCTAssertEqual(
            SudokuLayout.boardSide(for: 398) / 9,
            43.56,
            accuracy: 0.01,
            "A wider supported iPhone should provide approximately 44-point cell targets."
        )
    }

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

    func testThreeByThreeSlidingPuzzleRejectsHeuristicBeyondMaxDepthWithoutSearch() throws {
        let result = SlidingPuzzleSolver().solve(
            PuzzlePresets.sliding3x3Medium,
            options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 100_000, maxDepth: 3)
        )

        XCTAssertGreaterThan(SlidingPuzzleAnalyzer.manhattan(PuzzlePresets.sliding3x3Medium), 3)
        XCTAssertEqual(result.state, .timedOut)
        XCTAssertEqual(result.failureReason, "Puzzle exceeds the safe search depth.")
        XCTAssertEqual(result.nodesExplored, 0)
    }

    // MARK: - 4×4 sliding puzzle solver coverage


    func testFourByFourGridRoundTripUsesSixteenCells() throws {
        let grid = PuzzlePresets.sliding4x4Medium.toGrid()

        XCTAssertEqual(grid.count, 4)
        XCTAssertTrue(grid.allSatisfy { $0.count == 4 })
        XCTAssertEqual(grid.flatMap { $0 }.count, 16)
        XCTAssertEqual(grid.flatMap { $0 }.compactMap { $0 }.sorted(), Array(1...15))
        XCTAssertNotNil(SlidingPuzzleBoard.fromGrid(grid, size: 4))
    }

    func testFourByFourSlidingPuzzleRejectsWrongSizedGrid() throws {
        let threeByThreeGrid = PuzzlePresets.sliding3x3Medium.toGrid()

        XCTAssertNil(SlidingPuzzleBoard.fromGrid(threeByThreeGrid, size: 4))
    }

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

    func testFourByFourIDAStarHonorsLowerEqualAndHigherHeuristicBounds() throws {
        let board = PuzzlePresets.sliding4x4Medium
        let heuristic = SlidingPuzzleAnalyzer.manhattan(board)
        XCTAssertEqual(heuristic, 2)

        let above = SlidingPuzzleSolver().solve(board, options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 10_000, maxDepth: heuristic + 1))
        XCTAssertEqual(above.state, .solved)
        XCTAssertTrue(above.searchBounds.allSatisfy { $0 <= heuristic + 1 })

        let equal = SlidingPuzzleSolver().solve(board, options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 10_000, maxDepth: heuristic))
        XCTAssertEqual(equal.state, .solved)
        XCTAssertEqual(equal.searchBounds, [heuristic])

        let below = SlidingPuzzleSolver().solve(board, options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 10_000, maxDepth: heuristic - 1))
        XCTAssertEqual(below.state, .timedOut)
        XCTAssertEqual(below.failureReason, "Puzzle exceeds the safe search depth.")
        XCTAssertEqual(below.nodesExplored, 0)
        XCTAssertTrue(below.searchBounds.isEmpty)
    }

    // MARK: - 5×5 sliding puzzle solver coverage

    func testOneMoveFiveByFiveSlidingPuzzleSolves() throws {
        let quick = SlidingPuzzleBoard(size: 5, tiles: Array(1...23) + [0, 24])
        let result = SlidingPuzzleSolver().solve(quick, options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 10_000, maxDepth: 10))

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.moves, [SlidingPuzzleMove.right.rawValue])
        XCTAssertEqual(result.path.first, quick)
        XCTAssertEqual(result.path.last, PuzzlePresets.sliding5x5Solved)
    }

    func testUnsolvableFiveByFiveSlidingPuzzleReturnsUnsolvable() throws {
        let unsolvable = SlidingPuzzleBoard(size: 5, tiles: Array(1...22) + [24, 23, 0])
        let result = SlidingPuzzleSolver().solve(unsolvable, options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 10_000, maxDepth: 10))

        XCTAssertEqual(result.state, .unsolvable)
        XCTAssertEqual(result.nodesExplored, 0)
        XCTAssertTrue(result.searchBounds.isEmpty)
    }

    func testFiveByFiveIDAStarNeverStartsAboveMaxDepth() throws {
        let twoMoves = SlidingPuzzleBoard(size: 5, tiles: Array(1...22) + [0, 23, 24])
        let heuristic = SlidingPuzzleAnalyzer.manhattan(twoMoves)
        XCTAssertEqual(heuristic, 2)

        let capped = SlidingPuzzleSolver().solve(twoMoves, options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 10_000, maxDepth: heuristic))
        XCTAssertEqual(capped.state, .solved)
        XCTAssertEqual(capped.searchBounds, [heuristic])
        XCTAssertTrue(capped.searchBounds.allSatisfy { $0 <= heuristic })

        let rejected = SlidingPuzzleSolver().solve(twoMoves, options: SlidingPuzzleSolveOptions(timeout: 1, maxNodes: 10_000, maxDepth: heuristic - 1))
        XCTAssertEqual(rejected.state, .timedOut)
        XCTAssertEqual(rejected.failureReason, "Puzzle exceeds the safe search depth.")
        XCTAssertEqual(rejected.nodesExplored, 0)
        XCTAssertTrue(rejected.searchBounds.isEmpty)
    }

    // MARK: - Rush Hour mechanical puzzle solver coverage

    func testRushHourExampleSolvesWithOrderedPlayback() throws {
        let result = RushHourSolver().solve(RushHourBoard.example, options: RushHourSolveOptions(timeout: 2, maxStates: 10_000))

        XCTAssertEqual(result.status, .solved)
        XCTAssertGreaterThan(result.moveCount, 0)
        XCTAssertEqual(result.steps.count, result.moveCount + 1)
        XCTAssertEqual(result.steps.first?.stepNumber, 0)
        XCTAssertTrue(result.steps.last?.board.isSolved ?? false)
        XCTAssertTrue(result.steps.dropFirst().allSatisfy { $0.moveLabel.hasPrefix("Move ") })
    }

    func testInvalidRushHourBoardReturnsInvalid() throws {
        let invalid = RushHourBoard(vehicles: [])

        let result = RushHourSolver().solve(invalid, options: RushHourSolveOptions(timeout: 1, maxStates: 100))

        XCTAssertEqual(result.status, .invalid)
        XCTAssertTrue(result.steps.isEmpty)
        XCTAssertEqual(result.message, "Add exactly one red target car.")
    }

    func testRushHourExampleHasConnectedValidVehicles() throws {
        XCTAssertTrue(RushHourBoardValidator.validate(.example))
        XCTAssertEqual(RushHourBoard.example.targetVehicle?.occupiedCells.count, 2)
        XCTAssertTrue(RushHourBoard.example.vehicles.allSatisfy { $0.occupiedCells.count == $0.length })
    }

    func testRushHourRejectsDuplicateVehicleIdentifiers() throws {
        let duplicateIDs = RushHourBoard(vehicles: [
            RushHourVehicle(id: "X", label: "X", orientation: .horizontal, length: 2, row: 2, column: 0, style: .purple, isTarget: true),
            RushHourVehicle(id: "A", label: "A", orientation: .vertical, length: 2, row: 0, column: 0, style: .blue, isTarget: false),
            RushHourVehicle(id: "A", label: "A", orientation: .vertical, length: 2, row: 0, column: 3, style: .teal, isTarget: false)
        ])

        XCTAssertFalse(RushHourBoardValidator.validate(duplicateIDs))
        XCTAssertEqual(RushHourSolver().solve(duplicateIDs).status, .invalid)
    }

    func testRushHourRejectsOverlapAndOutOfBoundsPlacement() throws {
        let target = RushHourVehicle(id: "X", label: "X", orientation: .horizontal, length: 2, row: 2, column: 0, style: .purple, isTarget: true)
        let overlap = RushHourVehicle(id: "A", label: "A", orientation: .vertical, length: 2, row: 1, column: 1, style: .blue, isTarget: false)
        let outside = RushHourVehicle(id: "B", label: "B", orientation: .horizontal, length: 3, row: 5, column: 4, style: .teal, isTarget: false)

        XCTAssertEqual(RushHourBoardValidator.placementIssue(for: RushHourBoard(vehicles: [target, overlap])), "Vehicles cannot overlap.")
        XCTAssertEqual(RushHourBoardValidator.placementIssue(for: RushHourBoard(vehicles: [target, outside])), "That vehicle would extend outside the 6×6 board.")
    }

    func testRushHourRequiresOneHorizontalTarget() throws {
        let verticalTarget = RushHourVehicle(id: "X", label: "X", orientation: .vertical, length: 2, row: 0, column: 0, style: .purple, isTarget: true)
        XCTAssertEqual(RushHourBoard(vehicles: [verticalTarget]).validationIssue, "The red target car must be horizontal.")
    }

    func testRushHourGeneratesAllSlideDistancesAndAppliesMoves() throws {
        let board = RushHourBoard(vehicles: [
            RushHourVehicle(id: "X", label: "X", orientation: .horizontal, length: 2, row: 2, column: 0, style: .purple, isTarget: true)
        ])
        let targetMoves = board.legalMoves().filter { $0.move.vehicleID == "X" }

        XCTAssertEqual(Set(targetMoves.map { $0.move.distance }), Set([1, 2, 3, 4]))
        XCTAssertTrue(targetMoves.contains { $0.board.isSolved && $0.move.label == "Move red car right 4" })
    }

    // MARK: - 2×2 cube solver coverage

    func testSolvedTwoByTwoReturnsAlreadySolvedWithoutMoves() throws {
        let solver = Cube2x2Solver()

        let result = solver.solve(.solved2x2, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 100, includeStepStates: true))

        XCTAssertEqual(result.status, .alreadySolved)
        XCTAssertEqual(result.moveCount, 0)
        XCTAssertTrue(result.moves.isEmpty)
    }

    func testOneMoveTwoByTwoSolves() throws {
        let solver = Cube2x2Solver()
        let scrambled = makeTwoByTwoState(after: ["R"])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 2, maxDepth: 4, maxNodes: 10_000, includeStepStates: true))

        XCTAssertEqual(result.status, .success)
        XCTAssertFalse(result.moves.isEmpty)
    }

    func testShortTwoByTwoScrambleSolves() throws {
        let solver = Cube2x2Solver()
        let scrambled = makeTwoByTwoState(after: ["R", "U"])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 3, maxDepth: 8, maxNodes: 50_000, includeStepStates: false))

        XCTAssertEqual(result.status, .success)
        XCTAssertFalse(result.moves.isEmpty)
        XCTAssertEqual(TwoByTwoMoveEngine.apply(result.moves, to: scrambled), .solved2x2)
    }

    func testInvalidTwoByTwoReturnsInvalidInput() throws {
        let solver = Cube2x2Solver()
        let invalidState = CubeState(puzzle: .twoByTwo, stickers: ["U"])

        let result = solver.solve(invalidState, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 100, includeStepStates: true))

        XCTAssertEqual(result.status, .invalidInput)
        XCTAssertEqual(result.moveCount, 0)
    }

    func testTwistyPuzzleStateReportsSolvedState() throws {
        XCTAssertTrue(CubeState.solved2x2.isSolved)
        XCTAssertTrue(CubeState.solved3x3.isSolved)

        let scrambled = makeTwoByTwoState(after: ["R"])

        XCTAssertFalse(scrambled.isSolved)
    }

    func testTwoByTwoTimeoutIsBounded() throws {
        let solver = Cube2x2Solver()
        let scrambled = makeTwoByTwoState(after: ["U", "R", "F"])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 0, maxDepth: 8, maxNodes: 50_000, includeStepStates: false))

        XCTAssertEqual(result.status, .timeout)
    }

    // MARK: - 3×3 cube solver coverage

    func testSolvedThreeByThreeReturnsAlreadySolvedWithoutMoves() throws {
        let solver = Cube3x3Solver()

        let result = solver.solve(.solved3x3, options: CubeSolveOptions(timeout: 1, maxDepth: 1, maxNodes: 100, includeStepStates: true))

        XCTAssertEqual(result.status, .alreadySolved)
        XCTAssertEqual(result.moveCount, 0)
        XCTAssertTrue(result.moves.isEmpty)
    }

    func testSingleRThreeByThreeReturnsInverseOrEquivalent() throws {
        let solver = Cube3x3Solver()
        let scrambled = makeThreeByThreeState(after: [.R])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 2, maxDepth: 4, maxNodes: 20_000, includeStepStates: true))

        XCTAssertEqual(result.status, .success)
        XCTAssertFalse(result.moves.isEmpty)
        XCTAssertEqual(result.steps.count, result.moves.count + 1)
        XCTAssertTrue(solves(scrambled, moves: result.moves))
        XCTAssertEqual(result.steps.last?.state, .solved3x3)
    }

    func testSimpleThreeByThreeScrambleSolves() throws {
        let solver = Cube3x3Solver()
        let scrambled = makeThreeByThreeState(after: [.R, .U])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 5, maxDepth: 6, maxNodes: 80_000, includeStepStates: false))

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

    func testMissingTwoByTwoStickerFailsBeforeSolving() throws {
        let solver = Cube2x2Solver()
        var stickers = CubeState.solved2x2.stickers
        stickers.removeLast()

        let result = solver.solve(CubeState(puzzle: .twoByTwo, stickers: stickers), options: .default)

        XCTAssertEqual(result.status, .invalidInput)
        XCTAssertEqual(result.nodesExplored, 0)
    }

    func testMissingThreeByThreeStickerFailsBeforeSolving() throws {
        let solver = Cube3x3Solver()
        var stickers = CubeState.solved3x3.stickers
        stickers.removeLast()

        let result = solver.solve(CubeState(puzzle: .threeByThree, stickers: stickers), options: .default)

        XCTAssertEqual(result.status, .invalidInput)
        XCTAssertEqual(result.nodesExplored, 0)
    }

    func testThreeByThreeSafetyOptionsKeepSearchBounded() throws {
        let solver = Cube3x3Solver()
        let scrambled = makeThreeByThreeState(after: [.R, .U])

        let result = solver.solve(scrambled, options: CubeSolveOptions(timeout: 0, maxDepth: 8, maxNodes: 1, includeStepStates: false))

        XCTAssertEqual(result.status, .timeout)
        XCTAssertLessThan(result.elapsedTime, 2)
    }

    func testThreeByThreeProductionWrapperSolvesLongDeterministicScramble() throws {
        let scramble: [Cube3x3Move] = [.U, .D, .Ri, .L2, .F, .Bi, .U2, .R, .D2, .Fi, .L, .B2]
        let start = makeThreeByThreeState(after: scramble)

        let result = Cube3x3Solver().solve(start, options: .threeByThreeProduction)

        XCTAssertEqual(result.status, .success, result.failureReason ?? "")
        XCTAssertTrue(solves(start, moves: result.moves))
        XCTAssertEqual(result.steps.count, result.moves.count + 1)
        XCTAssertEqual(result.steps.first?.state, start)
        XCTAssertEqual(result.steps.last?.state, .solved3x3)
    }

    func testThreeByThreeProductionWrapperReportsNodeLimitDistinctly() throws {
        let start = makeThreeByThreeState(after: [.R, .U])

        let result = Cube3x3Solver().solve(
            start,
            options: CubeSolveOptions(timeout: 30, maxDepth: 30, maxNodes: 1, includeStepStates: false)
        )

        XCTAssertEqual(result.status, .nodeLimitReached)
        XCTAssertEqual(result.nodesExplored, 1)
        XCTAssertTrue(result.moves.isEmpty)
    }

    func testThreeByThreeProductionWrapperReportsTimeoutDistinctly() throws {
        let start = makeThreeByThreeState(after: [.R])

        let result = Cube3x3Solver().solve(
            start,
            options: CubeSolveOptions(timeout: 0, maxDepth: 30, maxNodes: 5_000_000, includeStepStates: false)
        )

        XCTAssertEqual(result.status, .timeout)
        XCTAssertEqual(result.nodesExplored, 0)
        XCTAssertTrue(result.moves.isEmpty)
    }

    func testSharedServiceRoutesThreeByThreeToProductionSolver() throws {
        let start = makeThreeByThreeState(after: [.R])
        let completed = expectation(description: "production 3x3 service completion")

        CubeSolvingService.shared.solve(start) { result in
            XCTAssertEqual(result.status, .success, result.failureReason ?? "")
            XCTAssertEqual(Cube3x3MoveEngine.apply(result.moves, to: start), .solved3x3)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 35)
    }

    // MARK: - Isolated 3×3 two-phase solver regression coverage

    func testKociembaSolvedCubeHasZeroLengthSolutionAndMetrics() throws {
        let result = Cube3x3KociembaSolver().solve(.solved, options: kociembaOptions())

        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.termination, .solved)
        XCTAssertEqual(result.moves, [])
        XCTAssertEqual(result.phaseOneDepth, 0)
        XCTAssertEqual(result.phaseTwoDepth, 0)
        XCTAssertEqual(result.totalSolutionLength, 0)
        XCTAssertEqual(result.nodes, 0)
        XCTAssertGreaterThanOrEqual(result.elapsedSearchTime, 0)
        XCTAssertGreaterThanOrEqual(result.pruningTablePreparationTime, 0)
    }

    func testKociembaSolvesAndIndependentlyReplaysShallowScrambles() throws {
        let scrambles: [[Cube3x3Move]] = [
            [.R], [.U, .F], [.Li, .D2, .B],
            [.F, .Ri, .U2, .L], [.D, .B2, .Ui, .R, .F2]
        ]

        for scramble in scrambles {
            try assertKociembaReplaySolves(scramble, options: kociembaOptions(maxNodes: 1_000_000))
        }
    }

    func testKociembaSolvesAndIndependentlyReplaysMixedScrambles() throws {
        let scrambles: [[Cube3x3Move]] = [
            [.U, .D, .Ri, .L2, .F, .Bi, .U2, .R, .D2, .Fi, .L, .B2],
            [.B, .Fi, .L2, .R, .Di, .U, .F2, .L, .B2, .Ui, .R2, .D]
        ]

        for scramble in scrambles {
            try assertKociembaReplaySolves(scramble, options: kociembaOptions(maxNodes: 5_000_000, timeout: 30))
        }
    }

    func testKociembaCanonicalMoveFilterKeepsExactlyOneOppositeFaceOrder() throws {
        XCTAssertTrue(Cube3x3KociembaSolver.shouldTry(.D, after: "U"))
        XCTAssertFalse(Cube3x3KociembaSolver.shouldTry(.U, after: "D"))
        XCTAssertTrue(Cube3x3KociembaSolver.shouldTry(.R, after: "L"))
        XCTAssertFalse(Cube3x3KociembaSolver.shouldTry(.L, after: "R"))
        XCTAssertTrue(Cube3x3KociembaSolver.shouldTry(.B, after: "F"))
        XCTAssertFalse(Cube3x3KociembaSolver.shouldTry(.F, after: "B"))
        XCTAssertFalse(Cube3x3KociembaSolver.shouldTry(.Ui, after: "U"))
        XCTAssertTrue(Cube3x3KociembaSolver.shouldTry(.R, after: nil))
    }

    func testKociembaHonorsExactNodeLimit() throws {
        let start = cubieState(after: [.R, .U])
        let result = Cube3x3KociembaSolver().solve(start, options: kociembaOptions(maxNodes: 1))

        XCTAssertEqual(result.status, .failure)
        XCTAssertEqual(result.termination, .nodeLimit)
        XCTAssertEqual(result.nodes, 1)
        XCTAssertTrue(result.moves.isEmpty)
    }

    func testKociembaReportsDeterministicZeroTimeout() throws {
        let start = cubieState(after: [.R])
        let result = Cube3x3KociembaSolver().solve(start, options: kociembaOptions(timeout: 0))

        XCTAssertEqual(result.status, .timeout)
        XCTAssertEqual(result.termination, .timeout)
        XCTAssertEqual(result.nodes, 0)
    }

    func testKociembaSmallSufficientAndGenerousLimitsSolve() throws {
        let start = cubieState(after: [.U])
        let small = Cube3x3KociembaSolver().solve(start, options: kociembaOptions(maxNodes: 100))
        let generous = Cube3x3KociembaSolver().solve(start, options: kociembaOptions(maxNodes: 100_000))

        for (result, limit) in [(small, 100), (generous, 100_000)] {
            XCTAssertEqual(result.status, .success)
            XCTAssertLessThanOrEqual(result.nodes, limit)
            let replayed = Cube3x3MoveEngine.apply(result.moves.map(\.rawValue), to: makeThreeByThreeState(after: [.U]))
            XCTAssertEqual(replayed, .solved3x3)
        }
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

    func testTwistyCatalogSeparatesActiveAndComingSoonModes() throws {
        let active = PuzzleAvailabilityCatalog.activeDescriptors(in: .twisty)
        let comingSoon = PuzzleAvailabilityCatalog.comingSoonDescriptors(in: .twisty)

        XCTAssertEqual(active.map(\.id), ["cube-2x2", "cube-3x3"])
        XCTAssertEqual(comingSoon.map(\.id), ["pyraminx", "skewb", "megaminx", "square-1"])
    }

    func testThreeByThreeCubeEntersActiveProductionSolveFlow() throws {
        let twoByTwo = PuzzleAvailabilityCatalog.descriptor(id: "cube-2x2")
        let threeByThree = PuzzleAvailabilityCatalog.descriptor(id: "cube-3x3")
        let activeTwistyIDs = Set(PuzzleAvailabilityCatalog.activeDescriptors(in: .twisty).map(\.id))

        XCTAssertEqual(twoByTwo.status, .active)
        XCTAssertTrue(twoByTwo.status.isInteractive)
        XCTAssertTrue(activeTwistyIDs.contains(twoByTwo.id))

        XCTAssertEqual(threeByThree.status, .active)
        XCTAssertTrue(threeByThree.status.isInteractive)
        XCTAssertTrue(activeTwistyIDs.contains(threeByThree.id))
        XCTAssertFalse(PuzzleAvailabilityCatalog.comingSoonDescriptors(in: .twisty).contains(threeByThree))
    }

    func testThreeByThreePhysicalFailuresUseActionableMessages() throws {
        let cases: [(CubeState, String)] = [
            (Cube3x3PhysicalFixtures.twistedCorner, "Corner orientation is impossible"),
            (Cube3x3PhysicalFixtures.flippedEdge, "One edge appears flipped"),
            (Cube3x3PhysicalFixtures.duplicateMissingCorner, "corner piece"),
            (Cube3x3PhysicalFixtures.duplicateMissingEdge, "edge piece"),
            (Cube3x3PhysicalFixtures.badCenters, "Center colors do not match"),
            (Cube3x3PhysicalFixtures.parityMismatch, "permutation parity is invalid")
        ]

        for (state, expectedText) in cases {
            guard case .failure(let error) = CubeStickerValidator.validate(state) else {
                return XCTFail("Expected invalid physical cube")
            }
            XCTAssertTrue(error.localizedDescription.localizedCaseInsensitiveContains(expectedText), error.localizedDescription)
        }
    }

    func testThreeByThreeEntryToProductionResultReplaysShallowAndMixedCubes() throws {
        let scrambles: [[Cube3x3Move]] = [
            [.R, .U, .Ri, .Ui],
            [.U, .D, .Ri, .L2, .F, .Bi, .U2, .R, .D2, .Fi, .L, .B2]
        ]
        for scramble in scrambles {
            let input = makeThreeByThreeState(after: scramble)
            XCTAssertNoThrow(try CubeStickerValidator.validate(input).get())
            let result = Cube3x3Solver().solve(input, options: .threeByThreeProduction)
            XCTAssertEqual(result.status, .success, result.failureReason ?? "")
            XCTAssertFalse(result.moves.isEmpty)
            XCTAssertEqual(Cube3x3MoveEngine.apply(result.moves, to: input), .solved3x3)
        }
    }
    // MARK: - Shared state and diagnostics

    func testSolveStateContainsEveryRequiredState() throws {
        XCTAssertEqual(Set(SolveState.allCases.map(\.rawValue)), ["idle", "validating", "solving", "solved", "alreadySolved", "invalid", "unsolvable", "multipleSolutions", "noSolution", "timedOut", "failed", "unsupported"])
    }

    func testPuzzleModeRegistryExactlyReflectsAvailabilityCatalog() throws {
        let diagnosticsByName = Dictionary(uniqueKeysWithValues: PuzzleModeRegistry.diagnostics.map { ($0.name, $0) })

        XCTAssertEqual(Set(diagnosticsByName.keys), Set(PuzzleAvailabilityCatalog.all.map(\.title)))
        for descriptor in PuzzleAvailabilityCatalog.all {
            let diagnostic = try XCTUnwrap(diagnosticsByName[descriptor.title])
            XCTAssertEqual(diagnostic.enabled, descriptor.status.isActive)
            XCTAssertEqual(diagnostic.solverAvailable, descriptor.status.isActive)
        }
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

    private func cubieState(after moves: [Cube3x3Move]) -> Cube3x3CubieState {
        try! Cube3x3CubieState.from(stickers: makeThreeByThreeState(after: moves).stickers).get()
    }

    private func kociembaOptions(maxNodes: Int = 2_000_000, timeout: TimeInterval = 15) -> CubeSolveOptions {
        CubeSolveOptions(timeout: timeout, maxDepth: 30, maxNodes: maxNodes, includeStepStates: false)
    }

    private func assertKociembaReplaySolves(
        _ scramble: [Cube3x3Move],
        options: CubeSolveOptions,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let stickerStart = makeThreeByThreeState(after: scramble)
        let cubieStart = try Cube3x3CubieState.from(stickers: stickerStart.stickers).get()
        let result = Cube3x3KociembaSolver().solve(cubieStart, options: options)

        XCTAssertEqual(result.status, .success, result.reason ?? "", file: file, line: line)
        XCTAssertEqual(result.termination, .solved, file: file, line: line)
        XCTAssertEqual(result.totalSolutionLength, result.moves.count, file: file, line: line)
        XCTAssertEqual((result.phaseOneDepth ?? 0) + (result.phaseTwoDepth ?? 0), result.moves.count, file: file, line: line)
        XCTAssertLessThanOrEqual(result.nodes, options.maxNodes, file: file, line: line)

        // Replay through the sticker move engine, independently of cubie-state
        // search transitions and coordinate/pruning logic.
        let replayed = Cube3x3MoveEngine.apply(result.moves.map(\.rawValue), to: stickerStart)
        XCTAssertEqual(replayed, .solved3x3, file: file, line: line)
    }

    private func makeTwoByTwoState(after moves: [String]) -> CubeState {
        TwoByTwoMoveEngine.apply(moves, to: .solved2x2)
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
        XCTAssertEqual(result.solvedBoard?.values(), [
            [5, 3, 4, 6, 7, 8, 9, 1, 2], [6, 7, 2, 1, 9, 5, 3, 4, 8], [1, 9, 8, 3, 4, 2, 5, 6, 7],
            [8, 5, 9, 7, 6, 1, 4, 2, 3], [4, 2, 6, 8, 5, 3, 7, 9, 1], [7, 1, 3, 9, 2, 4, 8, 5, 6],
            [9, 6, 1, 5, 3, 7, 2, 8, 4], [2, 8, 7, 4, 1, 9, 6, 3, 5], [3, 4, 5, 2, 8, 6, 1, 7, 9]
        ])
    }

    func testSudokuSolverRejectsAmbiguousAndEmptyPuzzlesWithoutPresentingABoard() {
        let solvedValues: [[Int?]] = [
            [5, 3, 4, 6, 7, 8, 9, 1, 2], [6, 7, 2, 1, 9, 5, 3, 4, 8], [1, 9, 8, 3, 4, 2, 5, 6, 7],
            [8, 5, 9, 7, 6, 1, 4, 2, 3], [4, 2, 6, 8, 5, 3, 7, 9, 1], [7, 1, 3, 9, 2, 4, 8, 5, 6],
            [9, 6, 1, 5, 3, 7, 2, 8, 4], [2, 8, 7, 4, 1, 9, 6, 3, 5], [3, 4, 5, 2, 8, 6, 1, 7, 9]
        ]
        let ambiguous = [LogicGridCoordinate(row: 0, column: 3), LogicGridCoordinate(row: 0, column: 4), LogicGridCoordinate(row: 3, column: 3), LogicGridCoordinate(row: 3, column: 4)]
            .reduce(SudokuBoard(values: solvedValues)) { $0.settingValue(nil, at: $1) }
        let ambiguousResult = SudokuSolver().solve(ambiguous, options: SudokuSolveOptions(maxNodes: 500_000, timeout: 2))
        let emptyResult = SudokuSolver().solve(.empty, options: SudokuSolveOptions(maxNodes: 500_000, timeout: 2))

        XCTAssertEqual(ambiguousResult.state, .multipleSolutions)
        XCTAssertNil(ambiguousResult.solvedBoard)
        XCTAssertEqual(emptyResult.state, .multipleSolutions)
        XCTAssertNil(emptyResult.solvedBoard)
        XCTAssertFalse(SudokuValidator.validate(.empty).canSolve)
    }

    func testSudokuSolverReportsValidButUnsolvablePuzzle() {
        let board = SudokuBoard.example.settingValue(1, at: LogicGridCoordinate(row: 0, column: 2))
        let result = SudokuSolver().solve(board)

        XCTAssertTrue(SudokuValidator.validate(board).isValid)
        XCTAssertEqual(result.state, .unsolvable)
        XCTAssertNil(result.solvedBoard)
    }

    func testSudokuSolverRecognizesAlreadyCompleteValidBoardAsUnique() throws {
        let solved = try XCTUnwrap(SudokuSolver().solve(.example).solvedBoard)
        let result = SudokuSolver().solve(solved)

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.solvedBoard, solved)
        XCTAssertTrue(result.steps.isEmpty)
    }

    func testSudokuValidatorFindsDuplicateColumnAndBoxValues() {
        let column = SudokuBoard.empty
            .settingValue(2, at: LogicGridCoordinate(row: 0, column: 0))
            .settingValue(2, at: LogicGridCoordinate(row: 3, column: 0))
        let box = SudokuBoard.empty
            .settingValue(4, at: LogicGridCoordinate(row: 0, column: 0))
            .settingValue(4, at: LogicGridCoordinate(row: 1, column: 1))

        XCTAssertTrue(SudokuValidator.validate(column).issues.contains { $0.scope == .column })
        XCTAssertTrue(SudokuValidator.validate(box).issues.contains { $0.scope == .box })
        XCTAssertEqual(SudokuSolver().solve(column).state, .invalid)
        XCTAssertEqual(SudokuSolver().solve(box).state, .invalid)
    }

    func testLogicPuzzleReleaseAvailabilityComesFromV1Catalog() throws {
        let logicDescriptors = PuzzleAvailabilityCatalog.descriptors(in: .logic)

        XCTAssertEqual(logicDescriptors.filter { $0.status == .active }.map(\.id), ["sudoku", "sudoku-photo-scan", "killer-sudoku"])
        XCTAssertEqual(logicDescriptors.filter { $0.status == .comingSoon }.map(\.id), ["nonogram", "kakuro", "slitherlink"])
    }

    func testSudokuPhotoScanUsesActiveDedicatedMenuBehavior() throws {
        let sudoku = PuzzleAvailabilityCatalog.descriptor(id: "sudoku")
        let photoScan = PuzzleAvailabilityCatalog.descriptor(id: "sudoku-photo-scan")

        XCTAssertEqual(sudoku.status, .active)
        XCTAssertTrue(sudoku.status.isInteractive)
        XCTAssertEqual(photoScan.status, .active)
        XCTAssertTrue(photoScan.status.isInteractive)
        XCTAssertTrue(LogicPuzzleMenuView.productionDescriptors.contains(photoScan))
        XCTAssertFalse(PuzzleAvailabilityCatalog.comingSoonDescriptors(in: .logic).contains(photoScan))
    }

    func testOCRImplementationDoesNotAffectProductionSudokuInitialization() {
        let retainedScanResult = SudokuScanResult(cells: [
            SudokuDetectedCell(row: 0, column: 0, recognizedValue: 9, confidence: 0.99)
        ])
        let board = SudokuInputView.initialBoard

        XCTAssertEqual(retainedScanResult.board.value(at: LogicGridCoordinate(row: 0, column: 0)), 9)
        XCTAssertEqual(board, .empty)
        XCTAssertTrue(board.cells.flatMap { $0 }.allSatisfy { $0.value == nil && !$0.isGiven })
        XCTAssertTrue(SudokuValidator.validate(board).isValid)
    }

    func testManualSudokuEntryRemainsEditableAndValidatable() {
        let coordinate = LogicGridCoordinate(row: 0, column: 0)
        let entered = SudokuInputView.initialBoard.settingValue(7, at: coordinate, markGiven: true)

        XCTAssertEqual(entered.value(at: coordinate), 7)
        XCTAssertTrue(entered.cells[coordinate.row][coordinate.column].isGiven)
        XCTAssertTrue(SudokuValidator.validate(entered).canSolve)
    }

    // MARK: - Sudoku photo scan pipeline

    func testSudokuPreprocessingUsesCGImagePixelsAtEveryUIImageScale() throws {
        let cgImage = try XCTUnwrap(makeTestCGImage(width: 90, height: 60))

        for scale in [CGFloat(1), 2, 3] {
            let prepared = try SudokuImagePreprocessor().prepare(UIImage(cgImage: cgImage, scale: scale, orientation: .up))
            XCTAssertEqual(prepared.normalized.scale, 1)
            XCTAssertEqual(prepared.normalized.cgImage?.width, 90)
            XCTAssertEqual(prepared.normalized.cgImage?.height, 60)
        }
    }

    func testNonZeroCoreImageExtentIsNormalizedToOrigin() {
        let shifted = CIImage(color: .white)
            .cropped(to: CGRect(x: 37, y: -12, width: 240, height: 180))
        let normalized = SudokuImageGeometry.zeroOrigin(shifted)

        XCTAssertEqual(normalized.extent.origin.x, 0, accuracy: 0.001)
        XCTAssertEqual(normalized.extent.origin.y, 0, accuracy: 0.001)
        XCTAssertEqual(normalized.extent.size, shifted.extent.size)
    }

    func testVisionNormalizedCoordinatesConvertToUpperLeftPixels() {
        let point = SudokuImageGeometry.pixelPoint(fromVision: CGPoint(x: 0.25, y: 0.75), pixelWidth: 1200, pixelHeight: 900)
        let rect = SudokuImageGeometry.pixelRect(fromVision: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4), pixelWidth: 1200, pixelHeight: 900)

        XCTAssertEqual(point.x, 300, accuracy: 0.001)
        XCTAssertEqual(point.y, 225, accuracy: 0.001)
        XCTAssertEqual(rect, CGRect(x: 120, y: 360, width: 360, height: 360))
    }

    func testNineByNineSegmentationGeometryCoversCanonicalBoard() {
        let rects = SudokuImageGeometry.cellRects(pixelWidth: 900, pixelHeight: 900, paddingRatio: 0)

        XCTAssertEqual(rects.count, 81)
        XCTAssertEqual(rects[0], CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(rects[40], CGRect(x: 400, y: 400, width: 100, height: 100))
        XCTAssertEqual(rects[80], CGRect(x: 800, y: 800, width: 100, height: 100))
    }

    func testResolvedConflictReturnsToStateDerivedFromCurrentConfidence() {
        let cells = [
            SudokuDetectedCell(row: 0, column: 0, recognizedValue: 5, confidence: 0.99, reviewState: .conflict),
            SudokuDetectedCell(row: 0, column: 1, recognizedValue: 6, confidence: 0.70, reviewState: .conflict),
            SudokuDetectedCell(row: 0, column: 2, recognizedValue: nil, confidence: nil, reviewState: .conflict)
        ]

        let reviewed = SudokuScanValidator.markReviewStates(cells)

        XCTAssertEqual(reviewed.map(\.reviewState), [.highConfidence, .needsReview, .blank])
    }

    func testScanRequiresAtLeastSeventeenEnteredClues() {
        XCTAssertEqual(SudokuScanConfiguration.minimumCluesForReview, 17)
        XCTAssertEqual(
            SudokuImageImportError.ocrCouldNotReadEnoughNumbers.localizedDescription,
            "Not enough clues were recognized. Review the image or enter missing digits manually."
        )
    }

    func testUncertainBlankRemainsMarkedForReview() {
        let uncertain = SudokuDetectedCell(
            row: 4, column: 6, recognizedValue: nil, confidence: 0.31,
            sourceType: .detected, reviewState: .blank
        )

        let reviewed = SudokuScanValidator.markReviewStates([uncertain])

        XCTAssertNil(reviewed[0].recognizedValue)
        XCTAssertEqual(reviewed[0].confidence, 0.31)
        XCTAssertEqual(reviewed[0].reviewState, .lowConfidence)
        XCTAssertTrue(reviewed[0].needsReview)
    }

    @MainActor
    func testStartingNewScanCancelsPreviousOperation() async throws {
        let firstCancelled = expectation(description: "first scan cancelled")
        var invocation = 0
        let viewModel = SudokuImageImportViewModel { _, _ in
            invocation += 1
            if invocation == 1 {
                do { try await Task.sleep(nanoseconds: 2_000_000_000) }
                catch { firstCancelled.fulfill(); throw error }
            }
            return SudokuScanResult(cells: [])
        }
        let image = UIImage(cgImage: try XCTUnwrap(makeTestCGImage(width: 10, height: 10)))

        viewModel.process(image)
        await Task.yield()
        viewModel.process(image)
        await fulfillment(of: [firstCancelled], timeout: 1)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.scanState, .readyForReview)
    }

    @MainActor
    func testStaleScanResultCannotOverwriteNewestReviewState() async throws {
        var invocation = 0
        let viewModel = SudokuImageImportViewModel { _, _ in
            invocation += 1
            let current = invocation
            try? await Task.sleep(nanoseconds: current == 1 ? 120_000_000 : 10_000_000)
            return SudokuScanResult(cells: [SudokuDetectedCell(row: 0, column: 0, recognizedValue: current, confidence: 1)])
        }
        let image = UIImage(cgImage: try XCTUnwrap(makeTestCGImage(width: 10, height: 10)))

        viewModel.process(image)
        await Task.yield()
        viewModel.process(image)
        try await Task.sleep(nanoseconds: 180_000_000)

        XCTAssertEqual(viewModel.reviewResult?.cells.first?.recognizedValue, 2)
        XCTAssertFalse(viewModel.isProcessing)
    }

    private func makeTestCGImage(width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }


    // MARK: - Experimental puzzle architecture

    func testGraphSearchFindsShortestPath() throws {
        let result = GraphSearch.breadthFirstSearch(
            from: 0,
            isGoal: { $0 == 3 },
            neighbors: { node in node < 3 ? [(node: node + 1, move: "+1")] : [] }
        )

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.path?.nodes, [0, 1, 2, 3])
        XCTAssertEqual(result.path?.moves, ["+1", "+1", "+1"])
    }

    func testMazeSolverUsesGraphUtilitiesForShortestPath() throws {
        let board = MazeBoard(lines: [
            "S..",
            "##.",
            "G.."
        ])

        let result = MazeSolver().solve(board)

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.moves.count, 6)
        XCTAssertTrue(result.steps.last?.annotations.contains { $0.kind == .path } ?? false)
    }

    func testChessSolverFindsMateInOne() throws {
        let board = try XCTUnwrap(ChessBoard(fen: "7k/8/5KQ1/8/8/8/8/8 w - - 0 1"))
        let result = ChessPuzzleSolver().solveMate(in: 1, board: board)

        XCTAssertEqual(result.state, .solved)
        XCTAssertNotNil(result.bestMove)
    }

    func testJigsawSolverReturnsModularPlaceholder() throws {
        let result = JigsawSolver().solve(.placeholder)

        XCTAssertEqual(result.state, .unsupported)
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.steps.count, 1)
    }

    func testVisualPuzzleSolversRemainComingSoonForV1() throws {
        let visualDescriptors = PuzzleAvailabilityCatalog.descriptors(in: .visual)

        XCTAssertEqual(visualDescriptors.map(\.id), ["maze-solver", "chess-puzzles", "jigsaw-solver"])
        XCTAssertTrue(visualDescriptors.allSatisfy { $0.status == .comingSoon && !$0.status.isInteractive })
    }


    // MARK: - Production stability additions

    func testExamplePuzzlePresetsCoverSolverEngineFamilies() throws {
        let categories = Set(ExamplePuzzlePresets.all.map(\.category))

        XCTAssertTrue(categories.isSuperset(of: ["Sliding", "Twisty", "Logic", "Mechanical", "Experimental"]))
        XCTAssertGreaterThanOrEqual(ExamplePuzzlePresets.all.count, 10)
    }

    func testRushHourTimeoutIsBounded() throws {
        let result = RushHourSolver().solve(RushHourBoard.example, options: RushHourSolveOptions(timeout: 0, maxStates: 10_000))

        XCTAssertEqual(result.status, .timedOut)
        XCTAssertTrue(result.moves.isEmpty)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testSudokuTimeoutIsBounded() throws {
        let result = SudokuSolver().solve(.example, options: SudokuSolveOptions(maxNodes: 100_000, timeout: 0))

        XCTAssertEqual(result.state, .timedOut)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testSudokuNodeLimitIsBounded() throws {
        let result = SudokuSolver().solve(.example, options: SudokuSolveOptions(maxNodes: 0, timeout: 2))

        XCTAssertEqual(result.state, .timedOut)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testGraphSearchTimeoutIsBounded() throws {
        let result = GraphSearch.breadthFirstSearch(
            from: 0,
            isGoal: { $0 == 10 },
            neighbors: { node in [(node: node + 1, move: "+1")] },
            maxNodes: 100_000,
            timeout: 0
        )

        XCTAssertEqual(result.state, .timedOut)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testMazeInvalidInputIsReported() throws {
        let result = MazeSolver().solve(MazeBoard(lines: ["..."]))

        XCTAssertEqual(result.state, .invalid)
        XCTAssertTrue(result.moves.isEmpty)
    }

    func testMazeTimeoutIsBounded() throws {
        let board = MazeBoard(lines: [
            "S..",
            "...",
            "..G"
        ])

        let result = MazeSolver().solve(board, options: MazeSolveOptions(timeout: 0, maxNodes: 100_000))

        XCTAssertEqual(result.state, .timedOut)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testChessBestMoveNodeLimitIsBounded() throws {
        let board = try XCTUnwrap(ChessBoard(fen: "7k/8/5KQ1/8/8/8/8/8 w - - 0 1"))
        let result = ChessPuzzleSolver().solveBestMove(board: board, options: ChessSolveOptions(mateDepth: 1, searchDepth: 3, timeout: 2, maxNodes: 0))

        XCTAssertEqual(result.state, .failed)
        XCTAssertNil(result.bestMove)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testChessMateTimeoutIsBounded() throws {
        let board = try XCTUnwrap(ChessBoard(fen: "7k/8/5KQ1/8/8/8/8/8 w - - 0 1"))
        let result = ChessPuzzleSolver().solveMate(in: 1, board: board, options: ChessSolveOptions(mateDepth: 1, searchDepth: 2, timeout: 0, maxNodes: 100_000))

        XCTAssertEqual(result.state, .timedOut)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testJigsawPlaceholderReturnsImmediatelyWithUnsupportedState() throws {
        let result = JigsawPuzzleSolver().solve(.placeholder, options: JigsawSolveOptions(timeout: 0, maxNodes: 0))

        XCTAssertEqual(result.state, .unsupported)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testComingSoonDescriptorsUseSharedNonInteractiveContract() throws {
        let comingSoon = PuzzleAvailabilityCatalog.all.filter { $0.status == .comingSoon }

        XCTAssertFalse(comingSoon.isEmpty)
        XCTAssertTrue(comingSoon.allSatisfy { !$0.status.isActive && !$0.status.isInteractive })
        XCTAssertEqual(comingSoon, PuzzleCategory.allCases.flatMap { PuzzleAvailabilityCatalog.comingSoonDescriptors(in: $0) })
    }

    func testImplementedSolverEnginesSolveOrReturnBoundedFailureStates() throws {
        let sliding = SlidingPuzzleSolver().solve(PuzzlePresets.sliding4x4Medium, options: SlidingPuzzleSolveOptions(timeout: 3, maxNodes: 120_000, maxDepth: 60))
        let sudoku = SudokuSolver().solve(.example, options: SudokuSolveOptions(maxNodes: 500_000, timeout: 5))
        let rushHour = RushHourSolver().solve(.example, options: RushHourSolveOptions(timeout: 5, maxStates: 100_000))
        let maze = MazeSolver().solve(MazeBoard(lines: ["S..", "##.", "G.."]))
        let chessBoard = try XCTUnwrap(ChessBoard(fen: "7k/8/5KQ1/8/8/8/8/8 w - - 0 1"))
        let chess = ChessPuzzleSolver().solveMate(in: 1, board: chessBoard)

        XCTAssertEqual(sliding.state, .solved)
        XCTAssertEqual(sudoku.state, .solved)
        XCTAssertEqual(rushHour.status, .solved)
        XCTAssertEqual(maze.state, .solved)
        XCTAssertEqual(chess.state, .solved)
    }


    // MARK: - Killer Sudoku production regression coverage

    func testRealKillerSudokuFixturesSolveUniquelyAndReplayEveryConstraint() throws {
        XCTAssertEqual(KillerSudokuFixtures.uniquePuzzles.count, 2)
        for fixture in KillerSudokuFixtures.uniquePuzzles {
            XCTAssertFalse(fixture.provenance.isEmpty, fixture.name)
            XCTAssertGreaterThanOrEqual(fixture.board.cages.count, 40, fixture.name)
            XCTAssertGreaterThanOrEqual(fixture.board.cages.filter { $0.cells.count > 1 }.count, 34, fixture.name)
            XCTAssertTrue(fixture.board.cells.flatMap { $0 }.allSatisfy { $0.value == nil }, fixture.name)

            let result = KillerSudokuSolver().solve(
                fixture.board, options: KillerSudokuSolveOptions(maxNodes: 500_000, timeout: 5)
            )
            XCTAssertEqual(result.state, fixture.expectedOutcome, fixture.name)
            let solved = try XCTUnwrap(result.solvedBoard, fixture.name)
            XCTAssertEqual(solved.cells.map { $0.compactMap(\.value) }, fixture.knownUniqueSolution, fixture.name)
            try assertValidSolvedKillerBoard(solved, fixture: fixture)
        }
    }

    func testKillerSudokuCageValidationRejectsMalformedLayouts() {
        let empty = SudokuBoard.empty
        let complete = rowCages()
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: complete)), .solving)
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: Array(complete.dropLast()))), .invalid)

        var overlap = complete
        overlap[1].cells.append(.init(row: 0, column: 0))
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: overlap)), .invalid)

        var duplicate = complete
        duplicate[0].cells.append(duplicate[0].cells[0])
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: duplicate)), .invalid)

        var emptyCage = complete
        emptyCage.append(KillerSudokuCage(targetSum: 1, cells: []))
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: emptyCage)), .invalid)

        var outOfBounds = complete
        outOfBounds[0].cells[0] = .init(row: -1, column: 0)
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: outOfBounds)), .invalid)

        var impossible = singletonCages(for: empty)
        impossible[0].targetSum = 10
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: impossible)), .invalid)

        let diagonal = KillerSudokuCage(targetSum: 3, cells: [.init(row: 0, column: 0), .init(row: 1, column: 1)])
        let remainder = singletonCages(for: empty).filter { $0.cells[0] != .init(row: 0, column: 0) && $0.cells[0] != .init(row: 1, column: 1) }
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: empty.cells, cages: [diagonal] + remainder)), .invalid)
    }

    func testKillerSudokuRejectsRepeatedGivenDigitInsideCage() {
        var cages = singletonCages(for: SudokuBoard.empty)
        cages.removeFirst(2)
        cages.insert(KillerSudokuCage(targetSum: 10, cells: [.init(row: 0, column: 0), .init(row: 0, column: 1)]), at: 0)
        let cells = SudokuBoard.empty
            .settingValue(5, at: .init(row: 0, column: 0))
            .settingValue(5, at: .init(row: 0, column: 1))
        XCTAssertEqual(KillerSudokuValidator.validate(KillerSudokuBoard(cells: cells.cells, cages: cages)), .invalid)
    }

    func testKillerSudokuCountsUniqueUnsolvableAndMultipleSolutions() {
        let solved = SudokuSolver().solve(.example).solvedBoard!
        XCTAssertEqual(KillerSudokuSolver().solve(KillerSudokuBoard(cells: solved.cells, cages: singletonCages(for: solved))).state, .solved)

        let unsolvable = SudokuBoard.example.settingValue(1, at: .init(row: 0, column: 2))
        XCTAssertEqual(KillerSudokuSolver().solve(KillerSudokuBoard(cells: unsolvable.cells, cages: rowCages())).state, .noSolution)

        let ambiguous = KillerSudokuSolver().solve(KillerSudokuBoard(cells: SudokuBoard.empty.cells, cages: rowCages()), options: .init(maxNodes: 500_000, timeout: 3))
        XCTAssertEqual(ambiguous.state, .multipleSolutions)
        XCTAssertNil(ambiguous.solvedBoard)
    }

    func testKillerSudokuHonorsSearchLimits() {
        let board = KillerSudokuBoard(cells: SudokuBoard.empty.cells, cages: rowCages())
        let limited = KillerSudokuSolver().solve(board, options: .init(maxNodes: 1, timeout: 5))
        XCTAssertEqual(limited.state, .failed)
        XCTAssertLessThanOrEqual(limited.nodesExplored, 1)
        XCTAssertEqual(KillerSudokuSolver().solve(board, options: .init(maxNodes: 500_000, timeout: 0)).state, .timedOut)
    }

    private func rowCages() -> [KillerSudokuCage] {
        (0..<9).map { row in KillerSudokuCage(targetSum: 45, cells: (0..<9).map { .init(row: row, column: $0) }) }
    }

    private func singletonCages(for board: SudokuBoard) -> [KillerSudokuCage] {
        (0..<9).flatMap { row in (0..<9).map { column in
            KillerSudokuCage(targetSum: board.cells[row][column].value ?? ((row * 3 + row / 3 + column) % 9 + 1), cells: [.init(row: row, column: column)])
        } }
    }

    private func assertValidSolvedKillerBoard(_ board: KillerSudokuBoard, fixture: KillerSudokuFixture,
                                              file: StaticString = #filePath, line: UInt = #line) throws {
        let values = try board.cells.map { row in try row.map { try XCTUnwrap($0.value, file: file, line: line) } }
        let digits = Set(1...9)
        for index in 0..<9 {
            XCTAssertEqual(Set(values[index]), digits, "row \(index + 1)", file: file, line: line)
            XCTAssertEqual(Set(values.map { $0[index] }), digits, "column \(index + 1)", file: file, line: line)
        }
        for boxRow in 0..<3 { for boxColumn in 0..<3 {
            let box = (0..<3).flatMap { row in (0..<3).map { column in values[boxRow * 3 + row][boxColumn * 3 + column] } }
            XCTAssertEqual(Set(box), digits, "box \(boxRow + 1),\(boxColumn + 1)", file: file, line: line)
        }}

        XCTAssertEqual(board.cages.count, fixture.definitions.count, file: file, line: line)
        for (index, cage) in board.cages.enumerated() {
            let cageValues = cage.cells.map { values[$0.row][$0.column] }
            XCTAssertEqual(Set(cageValues).count, cageValues.count, "repeated cage digit", file: file, line: line)
            XCTAssertEqual(cageValues.reduce(0, +), cage.targetSum, "wrong cage sum", file: file, line: line)
            let encoded = cage.cells.map { "\($0.row + 1)\($0.column + 1)" }.joined(separator: " ")
            XCTAssertEqual(encoded, fixture.definitions[index].coordinates, "cage coordinates changed", file: file, line: line)
        }
    }

    func testNonogramSimpleCrossSolves() throws {
        let board = NonogramBoard(
            cells: Array(repeating: Array(repeating: .unknown, count: 3), count: 3),
            rowClues: [[1], [3], [1]].map { $0.map { NonogramClueRun(length: $0) } },
            columnClues: [[1], [3], [1]].map { $0.map { NonogramClueRun(length: $0) } }
        )

        let result = NonogramSolver().solve(board, options: NonogramSolveOptions(maxNodes: 100, timeout: 1))

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.solvedBoard?.cells[1], [.filled, .filled, .filled])
    }

    func testKakuroSingleAcrossRunSolves() throws {
        let runCells = [LogicGridCoordinate(row: 0, column: 0), LogicGridCoordinate(row: 0, column: 1)]
        let board = KakuroBoard(cells: [[.value(nil), .value(nil)]], runs: [KakuroRun(sum: 3, direction: .across, cells: runCells)])

        let result = KakuroSolver().solve(board, options: KakuroSolveOptions(maxNodes: 100, timeout: 1))

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(Set(runCells.compactMap { coord -> Int? in
            if case .value(let value) = result.solvedBoard?.cells[coord.row][coord.column] { return value }
            return nil
        }), Set([1, 2]))
    }

    func testSlitherlinkValidatorReturnsUnsupportedSafely() throws {
        let result = SlitherlinkSolver().solve(.placeholder, options: SlitherlinkSolveOptions(timeout: 0, maxNodes: 0))

        XCTAssertEqual(result.state, .unsupported)
        XCTAssertLessThan(result.elapsedTime, 1)
    }

    func testKlotskiAlreadySolvedReturnsSolvedPathOnly() throws {
        let result = KlotskiSolver().solve(.example, options: MechanicalPuzzleSolveOptions(timeout: 1, maxNodes: 100))

        XCTAssertEqual(result.state, .solved)
        XCTAssertTrue(result.moves.isEmpty)
        XCTAssertEqual(result.playbackFrames.count, 1)
    }

    func testPegSolitaireTinyBoardSolvesOneJump() throws {
        let board = PegSolitaireBoard(cells: [[.peg, .peg, .empty]])

        let result = PegSolitaireSolver().solve(board, options: MechanicalPuzzleSolveOptions(timeout: 1, maxNodes: 100))

        XCTAssertEqual(result.state, .solved)
        XCTAssertEqual(result.moves.count, 1)
        XCTAssertEqual(result.playbackFrames.count, 2)
    }

}

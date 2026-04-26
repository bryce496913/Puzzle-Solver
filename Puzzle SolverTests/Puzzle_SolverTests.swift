//
//  Puzzle_SolverTests.swift
//  Puzzle SolverTests
//
//  Created by Bryce Cameron on 30/1/24.
//

import XCTest
@testable import Puzzle_Solver

final class Puzzle_SolverTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCube3x3SolverSolvesShortScramble() async throws {
        let scramble: [Cube3x3Move] = [.r, .u, .fPrime, .l2, .d]
        let scrambled = Cube3x3State.solved.applying(sequence: scramble)

        let result = await Cube3x3Solver().solve(from: scrambled)

        XCTAssertTrue(result.isSolvable)
        XCTAssertFalse(result.moves.isEmpty)

        let solved = result.moves.reduce(scrambled) { partial, move in
            guard let cubeMove = Cube3x3Move(rawValue: move.token) else {
                XCTFail("Unexpected move token returned: \(move.token)")
                return partial
            }
            return partial.applying(cubeMove)
        }
        XCTAssertEqual(solved, .solved)
    }

    func testCube3x3StateValidationRejectsParityMismatch() throws {
        var invalid = Cube3x3State.solved
        var perm = invalid.cornerPermutation
        perm.swapAt(0, 1)
        invalid = Cube3x3State(
            cornerPermutation: perm,
            cornerOrientation: invalid.cornerOrientation,
            edgePermutation: invalid.edgePermutation,
            edgeOrientation: invalid.edgeOrientation
        )

        let validation = invalid.validate()
        XCTAssertFalse(validation.isValid)
    }

    func testSudokuSolverSolvesValidGrid() {
        let puzzle = SudokuGrid(rows: [
            [5, 3, 0, 0, 7, 0, 0, 0, 0],
            [6, 0, 0, 1, 9, 5, 0, 0, 0],
            [0, 9, 8, 0, 0, 0, 0, 6, 0],
            [8, 0, 0, 0, 6, 0, 0, 0, 3],
            [4, 0, 0, 8, 0, 3, 0, 0, 1],
            [7, 0, 0, 0, 2, 0, 0, 0, 6],
            [0, 6, 0, 0, 0, 0, 2, 8, 0],
            [0, 0, 0, 4, 1, 9, 0, 0, 5],
            [0, 0, 0, 0, 8, 0, 0, 7, 9]
        ])

        XCTAssertNotNil(puzzle)

        let result = SudokuSolver().solve(puzzle ?? SudokuGrid())

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.completion, .solved)
        XCTAssertNotNil(result.output)
        XCTAssertTrue(result.output?.isSolved ?? false)
    }

    func testSudokuSolverRejectsInvalidStartingGrid() {
        let invalid = SudokuGrid(rows: [
            [5, 5, 0, 0, 7, 0, 0, 0, 0],
            [6, 0, 0, 1, 9, 5, 0, 0, 0],
            [0, 9, 8, 0, 0, 0, 0, 6, 0],
            [8, 0, 0, 0, 6, 0, 0, 0, 3],
            [4, 0, 0, 8, 0, 3, 0, 0, 1],
            [7, 0, 0, 0, 2, 0, 0, 0, 6],
            [0, 6, 0, 0, 0, 0, 2, 8, 0],
            [0, 0, 0, 4, 1, 9, 0, 0, 5],
            [0, 0, 0, 0, 8, 0, 0, 7, 9]
        ])

        XCTAssertNotNil(invalid)

        let result = SudokuSolver().solve(invalid ?? SudokuGrid())

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.completion, .unsolved)
        XCTAssertNil(result.output)
    }

    func testSudokuSolverReturnsUnsolvedForNoSolutionGrid() {
        let impossible = SudokuGrid(rows: [
            [5, 1, 6, 8, 4, 9, 7, 3, 2],
            [3, 0, 7, 6, 0, 5, 0, 0, 0],
            [8, 0, 9, 7, 0, 0, 0, 6, 5],
            [1, 3, 5, 0, 6, 0, 9, 0, 7],
            [4, 7, 2, 5, 9, 1, 0, 0, 6],
            [9, 6, 8, 3, 7, 0, 0, 5, 0],
            [2, 5, 3, 1, 8, 6, 0, 7, 4],
            [6, 8, 4, 2, 0, 7, 5, 0, 0],
            [7, 9, 1, 0, 5, 0, 6, 0, 8]
        ])

        XCTAssertNotNil(impossible)

        let result = SudokuSolver().solve(impossible ?? SudokuGrid())

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.completion, .unsolved)
        XCTAssertNil(result.output)
    }

}

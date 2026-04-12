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

}

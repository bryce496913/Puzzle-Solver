import XCTest
@testable import Puzzle_Solver

final class Cube3x3PhysicalRegressionTests: XCTestCase {
    private let faces = ["U", "R", "F", "D", "L", "B"]

    func testClockwiseTurnsMatchIndependentPhysicalFixtures() throws {
        for face in faces {
            let expected = try XCTUnwrap(Cube3x3PhysicalFixtures.clockwiseSolvedColors[face])
            let actual = Cube3x3MoveEngine.apply(face, to: .solved3x3)
            XCTAssertEqual(actual.stickers, expected, "Physical fixture mismatch for \(face)")
        }
    }

    func testInverseTurnsCancelInBothOrders() {
        for face in faces {
            XCTAssertEqual(Cube3x3MoveEngine.apply([face, "\(face)'"], to: .solved3x3), .solved3x3)
            XCTAssertEqual(Cube3x3MoveEngine.apply(["\(face)'", face], to: .solved3x3), .solved3x3)
        }
    }

    func testDoubleTurnsEqualTwoPhysicalQuarterTurns() {
        for face in faces {
            XCTAssertEqual(
                Cube3x3MoveEngine.apply("\(face)2", to: .solved3x3),
                Cube3x3MoveEngine.apply([face, face], to: .solved3x3)
            )
        }
    }

    func testFourQuarterTurnsAreIdentity() {
        for face in faces {
            XCTAssertEqual(Cube3x3MoveEngine.apply(Array(repeating: face, count: 4), to: .solved3x3), .solved3x3)
        }
    }

    func testEveryTurnConservesUniqueStickerPositionsAndFixesCenters() throws {
        let labels = (0..<54).map { "sticker-\($0)" }
        let labelled = CubeState(puzzle: .threeByThree, stickers: labels)
        let centers = [4, 13, 22, 31, 40, 49]

        for face in faces {
            let sources = try XCTUnwrap(Cube3x3PhysicalFixtures.clockwiseSource[face])
            let expected = sources.map { labels[$0] }
            let actual = Cube3x3MoveEngine.apply(face, to: labelled).stickers

            XCTAssertEqual(actual, expected, "Labelled physical permutation mismatch for \(face)")
            XCTAssertEqual(actual.count, 54)
            XCTAssertEqual(Set(actual), Set(labels))
            XCTAssertEqual(Set(actual).count, 54)
            for center in centers { XCTAssertEqual(actual[center], labels[center]) }
        }
    }

    func testSolvedAndPhysicalOneTurnStatesAreValid() {
        XCTAssertNoThrow(try CubeStickerValidator.validate(.solved3x3).get())
        for face in faces {
            let fixture = CubeState(puzzle: .threeByThree, stickers: Cube3x3PhysicalFixtures.clockwiseSolvedColors[face]!)
            XCTAssertNoThrow(try CubeStickerValidator.validate(fixture).get(), face)
        }
    }

    func testImpossiblePhysicalStatesAreRejectedBeforeSolving() {
        let fixtures: [(String, CubeState)] = [
            ("one twisted corner", Cube3x3PhysicalFixtures.twistedCorner),
            ("one flipped edge", Cube3x3PhysicalFixtures.flippedEdge),
            ("duplicate/missing corner", Cube3x3PhysicalFixtures.duplicateMissingCorner),
            ("duplicate/missing edge", Cube3x3PhysicalFixtures.duplicateMissingEdge),
            ("bad centers", Cube3x3PhysicalFixtures.badCenters),
            ("permutation parity mismatch", Cube3x3PhysicalFixtures.parityMismatch)
        ]

        for (name, fixture) in fixtures {
            XCTAssertThrowsError(try CubeStickerValidator.validate(fixture).get(), name)
            let result = Cube3x3Solver().solve(fixture, options: .default)
            XCTAssertEqual(result.status, .invalidInput, name)
            XCTAssertEqual(result.nodesExplored, 0, name)
        }
    }
}

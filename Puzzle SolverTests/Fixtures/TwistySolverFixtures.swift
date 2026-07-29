import Foundation
@testable import Puzzle_Solver

/// Deterministic, UI-independent inputs for the production 2×2 move engine and solver.
struct TwistySolverFixture {
    enum PerformanceCategory { case immediate, unit, extended }

    let name: String
    let scramble: String
    let expectedSolved: Bool
    let maximumSolutionLength: Int?
    let performance: PerformanceCategory

    static let solved = TwistySolverFixture(name: "Already solved", scramble: "", expectedSolved: true, maximumSolutionLength: 0, performance: .immediate)

    static let oneMove = ["U", "R", "F"].flatMap { face in
        [face, "\(face)2", "\(face)'"]
    }.map { TwistySolverFixture(name: "One move \($0)", scramble: $0, expectedSolved: false, maximumSolutionLength: 1, performance: .unit) }

    static let short = [
        TwistySolverFixture(name: "Different faces", scramble: "R U", expectedSolved: false, maximumSolutionLength: 2, performance: .unit),
        TwistySolverFixture(name: "Repeated face", scramble: "R R", expectedSolved: false, maximumSolutionLength: 1, performance: .unit),
        TwistySolverFixture(name: "Move and inverse", scramble: "F F'", expectedSolved: true, maximumSolutionLength: 0, performance: .immediate),
        TwistySolverFixture(name: "Alternating axes", scramble: "R U F", expectedSolved: false, maximumSolutionLength: 3, performance: .unit),
        TwistySolverFixture(name: "Double and inverse", scramble: "U2 R' F", expectedSolved: false, maximumSolutionLength: 3, performance: .unit)
    ]

    static let medium = [
        TwistySolverFixture(name: "Four-turn trigger", scramble: "R U R' U'", expectedSolved: false, maximumSolutionLength: 4, performance: .extended),
        TwistySolverFixture(name: "Mixed half turns", scramble: "F2 U R2 F'", expectedSolved: false, maximumSolutionLength: 4, performance: .extended)
    ]

    static let normalSuite = [solved] + oneMove + short
}

enum SudokuFixtureBoards {
    static let printedPuzzle: [[Int?]] = [
        [5,3,nil,nil,7,nil,nil,nil,nil], [6,nil,nil,1,9,5,nil,nil,nil], [nil,9,8,nil,nil,nil,nil,6,nil],
        [8,nil,nil,nil,6,nil,nil,nil,3], [4,nil,nil,8,nil,3,nil,nil,1], [7,nil,nil,nil,2,nil,nil,nil,6],
        [nil,6,nil,nil,nil,nil,2,8,nil], [nil,nil,nil,4,1,9,nil,nil,5], [nil,nil,nil,nil,8,nil,nil,7,9]
    ]
}

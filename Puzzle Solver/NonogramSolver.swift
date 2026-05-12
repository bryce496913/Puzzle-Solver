//
//  NonogramSolver.swift
//  Puzzle Solver
//
//  Placeholder solver for future Nonogram support.
//

import Foundation

struct NonogramSolveResult {
    let state: SolveState = .unsupported
    let message = "Nonogram is planned for a future update."
}

final class NonogramSolver: LogicPuzzleSolving {
    func solve(_ board: NonogramBoard) -> NonogramSolveResult {
        NonogramSolveResult()
    }
}

//
//  SlitherlinkSolver.swift
//  Puzzle Solver
//
//  Placeholder solver for future Slitherlink support.
//

import Foundation

struct SlitherlinkSolveResult {
    let state: SolveState = .unsupported
    let message = "Slitherlink is planned for a future update."
}

final class SlitherlinkSolver: LogicPuzzleSolving {
    func solve(_ board: SlitherlinkBoard) -> SlitherlinkSolveResult {
        SlitherlinkSolveResult()
    }
}

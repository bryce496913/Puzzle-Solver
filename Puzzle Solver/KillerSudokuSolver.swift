//
//  KillerSudokuSolver.swift
//  Puzzle Solver
//
//  Placeholder solver for future Killer Sudoku support.
//

import Foundation

struct KillerSudokuSolveResult {
    let state: SolveState = .unsupported
    let message = "Killer Sudoku is planned for a future update."
}

final class KillerSudokuSolver: LogicPuzzleSolving {
    func solve(_ board: KillerSudokuBoard) -> KillerSudokuSolveResult {
        KillerSudokuSolveResult()
    }
}

//
//  KillerSudokuSolver.swift
//  Puzzle Solver
//
//  Safe placeholder solver for future Killer Sudoku support.
//

import Foundation

struct KillerSudokuSolveResult {
    let state: SolveState
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> KillerSudokuSolveResult {
        KillerSudokuSolveResult(
            state: .unsupported,
            message: "This solver is planned for a future update.",
            failureReason: "This solver is planned for a future update.",
            elapsedTime: elapsedTime,
            nodesExplored: 0
        )
    }
}

enum KillerSudokuValidator {
    static func validate(_ board: KillerSudokuBoard) -> SolveState {
        let size = board.size
        guard size.rows > 0, size.columns > 0 else { return .invalid }
        return .unsupported
    }
}

final class KillerSudokuSolver: LogicPuzzleSolving {
    func solve(_ board: KillerSudokuBoard) -> KillerSudokuSolveResult {
        let startedAt = Date()
        _ = KillerSudokuValidator.validate(board)
        // Future Killer Sudoku work should add a bounded validator, constraint propagation, and
        // backtracking/search specific to this puzzle. The solver is intentionally unavailable
        // today and returns immediately so placeholder routes always show visible feedback.
        return KillerSudokuSolveResult.solverUnavailable(elapsedTime: Date().timeIntervalSince(startedAt))
    }
}

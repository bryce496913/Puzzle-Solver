//
//  SlitherlinkSolver.swift
//  Puzzle Solver
//
//  Safe placeholder solver for future Slitherlink support.
//

import Foundation

struct SlitherlinkSolveResult {
    let state: SolveState
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> SlitherlinkSolveResult {
        SlitherlinkSolveResult(
            state: .unsupported,
            message: "This solver is planned for a future update.",
            failureReason: "This solver is planned for a future update.",
            elapsedTime: elapsedTime,
            nodesExplored: 0
        )
    }
}

enum SlitherlinkValidator {
    static func validate(_ board: SlitherlinkBoard) -> SolveState {
        let size = board.size
        guard size.rows > 0, size.columns > 0 else { return .invalid }
        return .unsupported
    }
}

final class SlitherlinkSolver: LogicPuzzleSolving {
    func solve(_ board: SlitherlinkBoard) -> SlitherlinkSolveResult {
        let startedAt = Date()
        _ = SlitherlinkValidator.validate(board)
        // Future Slitherlink work should add a bounded validator, constraint propagation, and
        // backtracking/search specific to this puzzle. The solver is intentionally unavailable
        // today and returns immediately so placeholder routes always show visible feedback.
        return SlitherlinkSolveResult.solverUnavailable(elapsedTime: Date().timeIntervalSince(startedAt))
    }
}

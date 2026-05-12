//
//  NonogramSolver.swift
//  Puzzle Solver
//
//  Safe placeholder solver for future Nonogram support.
//

import Foundation

struct NonogramSolveResult {
    let state: SolveState
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> NonogramSolveResult {
        NonogramSolveResult(
            state: .unsupported,
            message: "This solver is planned for a future update.",
            failureReason: "This solver is planned for a future update.",
            elapsedTime: elapsedTime,
            nodesExplored: 0
        )
    }
}

enum NonogramValidator {
    static func validate(_ board: NonogramBoard) -> SolveState {
        let size = board.size
        guard size.rows > 0, size.columns > 0 else { return .invalid }
        return .unsupported
    }
}

final class NonogramSolver: LogicPuzzleSolving {
    func solve(_ board: NonogramBoard) -> NonogramSolveResult {
        let startedAt = Date()
        _ = NonogramValidator.validate(board)
        // Future Nonogram work should add a bounded validator, constraint propagation, and
        // backtracking/search specific to this puzzle. The solver is intentionally unavailable
        // today and returns immediately so placeholder routes always show visible feedback.
        return NonogramSolveResult.solverUnavailable(elapsedTime: Date().timeIntervalSince(startedAt))
    }
}

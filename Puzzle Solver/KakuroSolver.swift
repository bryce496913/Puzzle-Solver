//
//  KakuroSolver.swift
//  Puzzle Solver
//
//  Safe placeholder solver for future Kakuro support.
//

import Foundation

struct KakuroSolveResult {
    let state: SolveState
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> KakuroSolveResult {
        KakuroSolveResult(
            state: .unsupported,
            message: "This solver is planned for a future update.",
            failureReason: "This solver is planned for a future update.",
            elapsedTime: elapsedTime,
            nodesExplored: 0
        )
    }
}

enum KakuroValidator {
    static func validate(_ board: KakuroBoard) -> SolveState {
        let size = board.size
        guard size.rows > 0, size.columns > 0 else { return .invalid }
        return .unsupported
    }
}

final class KakuroSolver: LogicPuzzleSolving {
    func solve(_ board: KakuroBoard) -> KakuroSolveResult {
        let startedAt = Date()
        _ = KakuroValidator.validate(board)
        // Future Kakuro work should add a bounded validator, constraint propagation, and
        // backtracking/search specific to this puzzle. The solver is intentionally unavailable
        // today and returns immediately so placeholder routes always show visible feedback.
        return KakuroSolveResult.solverUnavailable(elapsedTime: Date().timeIntervalSince(startedAt))
    }
}

//
//  PegSolitaireSolver.swift
//  Puzzle Solver
//
//  Intentional placeholder solver for the coming-soon Peg Solitaire implementation.
//

import Foundation

final class PegSolitaireSolver: MechanicalPuzzleSolving {
    func solve(_ board: PegSolitaireBoard, options: MechanicalPuzzleSolveOptions = .default) -> MechanicalPuzzleSolveResult<PegSolitaireBoard> {
        _ = PegSolitaireBoardAnalyzer.validate(board)
        // Future implementation should add legal move generation, goal detection, and bounded
        // graph search. This placeholder intentionally returns immediately with a visible
        // unsupported status so opening or solving the mode cannot block or crash.
        return MechanicalPuzzleSolveResult(
            kind: .pegSolitaire,
            state: .unsupported,
            moves: [],
            playbackFrames: [OrderedMovePlaybackFrame(order: 0, move: nil, board: board, caption: "This solver is planned for a future update.")],
            failureReason: "This solver is planned for a future update.",
            elapsedTime: 0,
            nodesExplored: 0
        )
    }
}

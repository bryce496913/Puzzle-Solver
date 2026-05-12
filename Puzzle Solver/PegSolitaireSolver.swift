//
//  PegSolitaireSolver.swift
//  Puzzle Solver
//
//  Intentional placeholder solver for the coming-soon Peg Solitaire implementation.
//

import Foundation

final class PegSolitaireSolver: MechanicalPuzzleSolving {
    func solve(_ board: PegSolitaireBoard, options: MechanicalPuzzleSolveOptions = .default) -> MechanicalPuzzleSolveResult<PegSolitaireBoard> {
        MechanicalPuzzleSolveResult(
            kind: .pegSolitaire,
            state: .unsupported,
            moves: [],
            playbackFrames: [OrderedMovePlaybackFrame(order: 0, move: nil, board: board, caption: "Coming soon")],
            failureReason: "Peg Solitaire is coming soon.",
            elapsedTime: 0,
            nodesExplored: 0
        )
    }
}

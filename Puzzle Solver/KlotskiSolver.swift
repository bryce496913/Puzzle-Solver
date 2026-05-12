//
//  KlotskiSolver.swift
//  Puzzle Solver
//
//  Intentional placeholder solver for the coming-soon Klotski implementation.
//

import Foundation

final class KlotskiSolver: MechanicalPuzzleSolving {
    func solve(_ board: KlotskiBoard, options: MechanicalPuzzleSolveOptions = .default) -> MechanicalPuzzleSolveResult<KlotskiBoard> {
        MechanicalPuzzleSolveResult(
            kind: .klotski,
            state: .unsupported,
            moves: [],
            playbackFrames: [OrderedMovePlaybackFrame(order: 0, move: nil, board: board, caption: "Coming soon")],
            failureReason: "Klotski is coming soon.",
            elapsedTime: 0,
            nodesExplored: 0
        )
    }
}

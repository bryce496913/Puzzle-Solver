//
//  PegSolitaireMove.swift
//  Puzzle Solver
//

import Foundation

struct PegSolitaireMove: Hashable, Identifiable {
    let from: MechanicalBoardCoordinate
    let jumped: MechanicalBoardCoordinate
    let to: MechanicalBoardCoordinate

    var id: String { "\(from.id)-\(jumped.id)-\(to.id)" }

    var asMechanicalMove: MechanicalPuzzleMove {
        MechanicalPuzzleMove(pieceID: "peg-\(from.id)", pieceLabel: "Peg", delta: MechanicalMoveDelta(row: to.row - from.row, column: to.column - from.column), distance: 1)
    }
}

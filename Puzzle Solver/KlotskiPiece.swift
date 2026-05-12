//
//  KlotskiPiece.swift
//  Puzzle Solver
//

import Foundation

struct KlotskiPiece: Hashable, Identifiable {
    let id: String
    let label: String
    let origin: MechanicalBoardCoordinate
    let size: MechanicalBoardSize
    let isGoalPiece: Bool

    var occupiedCoordinates: [MechanicalBoardCoordinate] {
        (0..<size.rows).flatMap { r in (0..<size.columns).map { c in MechanicalBoardCoordinate(row: origin.row + r, column: origin.column + c) } }
    }

    func moving(by delta: MechanicalMoveDelta) -> KlotskiPiece {
        KlotskiPiece(id: id, label: label, origin: MechanicalBoardCoordinate(row: origin.row + delta.row, column: origin.column + delta.column), size: size, isGoalPiece: isGoalPiece)
    }

    var asMechanicalPiece: MechanicalPuzzlePiece {
        MechanicalPuzzlePiece(id: id, label: label, origin: origin, size: size, orientation: .single, isPrimary: isGoalPiece)
    }
}

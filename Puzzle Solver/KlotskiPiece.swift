//
//  KlotskiPiece.swift
//  Puzzle Solver
//
//  Intentional placeholder model for future Klotski pieces.
//

import Foundation

struct KlotskiPiece: Hashable, Identifiable {
    let id: String
    let label: String
    let origin: MechanicalBoardCoordinate
    let size: MechanicalBoardSize
    let isGoalPiece: Bool

    var asMechanicalPiece: MechanicalPuzzlePiece {
        MechanicalPuzzlePiece(
            id: id,
            label: label,
            origin: origin,
            size: size,
            orientation: .single,
            isPrimary: isGoalPiece
        )
    }
}

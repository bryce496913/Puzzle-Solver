//
//  PegSolitaireMove.swift
//  Puzzle Solver
//
//  Intentional placeholder model for future Peg Solitaire moves.
//

import Foundation

struct PegSolitaireMove: Hashable, Identifiable {
    let from: MechanicalBoardCoordinate
    let jumped: MechanicalBoardCoordinate
    let to: MechanicalBoardCoordinate

    var id: String { "\(from.id)-\(jumped.id)-\(to.id)" }
}

//
//  PegSolitaireBoard.swift
//  Puzzle Solver
//
//  Intentional placeholder board for the coming-soon Peg Solitaire solver.
//

import Foundation

struct PegSolitaireBoard: MechanicalPuzzleBoard, Hashable {
    let occupiedCoordinates: Set<MechanicalBoardCoordinate>

    var kind: MechanicalPuzzleKind { .pegSolitaire }
    var size: MechanicalBoardSize { .pegSolitaire }
    var pieces: [MechanicalPuzzlePiece] {
        occupiedCoordinates
            .sorted { $0.id < $1.id }
            .map { coordinate in
                MechanicalPuzzlePiece(
                    id: "peg-\(coordinate.id)",
                    label: "●",
                    origin: coordinate,
                    size: MechanicalBoardSize(rows: 1, columns: 1),
                    orientation: .single,
                    isPrimary: false
                )
            }
    }

    static let comingSoon = PegSolitaireBoard(occupiedCoordinates: [])
}

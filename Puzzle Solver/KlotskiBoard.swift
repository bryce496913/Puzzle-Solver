//
//  KlotskiBoard.swift
//  Puzzle Solver
//
//  Intentional placeholder board for the coming-soon Klotski solver.
//

import Foundation

struct KlotskiBoard: MechanicalPuzzleBoard, Hashable {
    let klotskiPieces: [KlotskiPiece]

    var kind: MechanicalPuzzleKind { .klotski }
    var size: MechanicalBoardSize { .klotski }
    var pieces: [MechanicalPuzzlePiece] { klotskiPieces.map(\.asMechanicalPiece) }

    static let comingSoon = KlotskiBoard(klotskiPieces: [])
}

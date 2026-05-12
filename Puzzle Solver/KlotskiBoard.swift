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

    static let comingSoon = KlotskiBoard(klotskiPieces: [
        KlotskiPiece(id: "C", label: "C", origin: MechanicalBoardCoordinate(row: 0, column: 1), size: MechanicalBoardSize(rows: 2, columns: 2), isGoalPiece: true)
    ])

    static let example = comingSoon
}

enum KlotskiBoardAnalyzer {
    static func validate(_ board: KlotskiBoard) -> SolveState {
        guard board.klotskiPieces.allSatisfy({ piece in
            !piece.id.isEmpty && piece.size.rows > 0 && piece.size.columns > 0 && board.size.contains(piece.origin)
        }) else { return .invalid }
        return .unsupported
    }
}

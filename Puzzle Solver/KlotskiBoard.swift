//
//  KlotskiBoard.swift
//  Puzzle Solver
//
//  Board model for sliding-block Klotski puzzles.
//

import Foundation

struct KlotskiBoard: MechanicalPuzzleBoard, Hashable {
    let klotskiPieces: [KlotskiPiece]
    let exitTopLeft: MechanicalBoardCoordinate

    var kind: MechanicalPuzzleKind { .klotski }
    var size: MechanicalBoardSize { .klotski }
    var pieces: [MechanicalPuzzlePiece] { klotskiPieces.map(\.asMechanicalPiece) }
    var goalPiece: KlotskiPiece? { klotskiPieces.first(where: \.isGoalPiece) }
    var isSolved: Bool { goalPiece?.origin == exitTopLeft }

    init(klotskiPieces: [KlotskiPiece], exitTopLeft: MechanicalBoardCoordinate = MechanicalBoardCoordinate(row: 3, column: 1)) {
        self.klotskiPieces = klotskiPieces.sorted { $0.id < $1.id }
        self.exitTopLeft = exitTopLeft
    }

    static let comingSoon = KlotskiBoard(klotskiPieces: [
        KlotskiPiece(id: "C", label: "C", origin: MechanicalBoardCoordinate(row: 3, column: 1), size: MechanicalBoardSize(rows: 2, columns: 2), isGoalPiece: true)
    ])

    static let example = comingSoon

    func occupancy(excluding excludedID: String? = nil) -> [MechanicalBoardCoordinate: String] {
        var map: [MechanicalBoardCoordinate: String] = [:]
        for piece in klotskiPieces where piece.id != excludedID {
            for coordinate in piece.occupiedCoordinates { map[coordinate] = piece.id }
        }
        return map
    }

    func applying(_ move: MechanicalPuzzleMove) -> KlotskiBoard? {
        guard move.distance == 1, let piece = klotskiPieces.first(where: { $0.id == move.pieceID }) else { return nil }
        let moved = piece.moving(by: move.delta)
        var next = klotskiPieces.filter { $0.id != piece.id }
        next.append(moved)
        let board = KlotskiBoard(klotskiPieces: next, exitTopLeft: exitTopLeft)
        return KlotskiBoardAnalyzer.validate(board) == .solving || KlotskiBoardAnalyzer.validate(board) == .solved ? board : nil
    }
}

enum KlotskiBoardAnalyzer {
    static func validate(_ board: KlotskiBoard) -> SolveState {
        guard board.size.contains(board.exitTopLeft), board.goalPiece != nil else { return .invalid }
        var occupied: Set<MechanicalBoardCoordinate> = []
        for piece in board.klotskiPieces {
            guard !piece.id.isEmpty, piece.size.rows > 0, piece.size.columns > 0 else { return .invalid }
            guard piece.occupiedCoordinates.allSatisfy(board.size.contains) else { return .invalid }
            for coordinate in piece.occupiedCoordinates {
                guard !occupied.contains(coordinate) else { return .invalid }
                occupied.insert(coordinate)
            }
        }
        return board.isSolved ? .solved : .solving
    }

    static func legalMoves(from board: KlotskiBoard) -> [(move: MechanicalPuzzleMove, board: KlotskiBoard)] {
        let directions: [MechanicalMoveDelta] = [.left, .right, .up, .down]
        return board.klotskiPieces.flatMap { piece in
            directions.compactMap { delta in
                let moved = piece.moving(by: delta)
                guard moved.occupiedCoordinates.allSatisfy(board.size.contains) else { return nil }
                let occupied = board.occupancy(excluding: piece.id)
                guard moved.occupiedCoordinates.allSatisfy({ occupied[$0] == nil }) else { return nil }
                let move = MechanicalPuzzleMove(pieceID: piece.id, pieceLabel: piece.label, delta: delta, distance: 1)
                return board.applying(move).map { (move, $0) }
            }
        }
    }
}

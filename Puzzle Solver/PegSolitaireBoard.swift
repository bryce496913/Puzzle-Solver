//
//  PegSolitaireBoard.swift
//  Puzzle Solver
//
//  Board model for peg-jump solitaire.
//

import Foundation

struct PegSolitaireBoard: MechanicalPuzzleBoard, Hashable {
    enum Cell: Hashable { case peg, empty, invalid }

    let cells: [[Cell]]
    let requiredFinalPeg: MechanicalBoardCoordinate?

    var kind: MechanicalPuzzleKind { .pegSolitaire }
    var size: MechanicalBoardSize { MechanicalBoardSize(rows: cells.count, columns: cells.first?.count ?? 0) }
    var occupiedCoordinates: Set<MechanicalBoardCoordinate> {
        var set: Set<MechanicalBoardCoordinate> = []
        for r in 0..<cells.count { for c in 0..<cells[r].count where cells[r][c] == .peg { set.insert(MechanicalBoardCoordinate(row: r, column: c)) } }
        return set
    }
    var pegCount: Int { occupiedCoordinates.count }
    var isSolved: Bool { pegCount == 1 && (requiredFinalPeg == nil || occupiedCoordinates.contains(requiredFinalPeg!)) }
    var pieces: [MechanicalPuzzlePiece] {
        occupiedCoordinates.sorted { $0.id < $1.id }.map { MechanicalPuzzlePiece(id: "peg-\($0.id)", label: "●", origin: $0, size: MechanicalBoardSize(rows: 1, columns: 1), orientation: .single, isPrimary: false) }
    }

    init(cells: [[Cell]], requiredFinalPeg: MechanicalBoardCoordinate? = nil) {
        let width = cells.map(\.count).max() ?? 0
        self.cells = cells.map { $0 + Array(repeating: .invalid, count: max(0, width - $0.count)) }
        self.requiredFinalPeg = requiredFinalPeg
    }

    init(occupiedCoordinates: Set<MechanicalBoardCoordinate>) {
        var cells = Array(repeating: Array(repeating: Cell.invalid, count: 7), count: 7)
        for r in 0..<7 { for c in 0..<7 where (2...4).contains(r) || (2...4).contains(c) { cells[r][c] = .empty } }
        for coordinate in occupiedCoordinates where (0..<7).contains(coordinate.row) && (0..<7).contains(coordinate.column) { cells[coordinate.row][coordinate.column] = .peg }
        self.init(cells: cells, requiredFinalPeg: nil)
    }

    static let comingSoon = PegSolitaireBoard(occupiedCoordinates: [MechanicalBoardCoordinate(row: 3, column: 2), MechanicalBoardCoordinate(row: 3, column: 3), MechanicalBoardCoordinate(row: 3, column: 4)])
    static let example = comingSoon

    func cell(at coordinate: MechanicalBoardCoordinate) -> Cell { size.contains(coordinate) ? cells[coordinate.row][coordinate.column] : .invalid }
    func applying(_ move: PegSolitaireMove) -> PegSolitaireBoard? {
        guard cell(at: move.from) == .peg, cell(at: move.jumped) == .peg, cell(at: move.to) == .empty else { return nil }
        var next = cells
        next[move.from.row][move.from.column] = .empty
        next[move.jumped.row][move.jumped.column] = .empty
        next[move.to.row][move.to.column] = .peg
        return PegSolitaireBoard(cells: next, requiredFinalPeg: requiredFinalPeg)
    }
}

enum PegSolitaireBoardAnalyzer {
    static func validate(_ board: PegSolitaireBoard) -> SolveState {
        guard board.size.rows > 0, board.size.columns > 0, board.cells.allSatisfy({ $0.count == board.size.columns }) else { return .invalid }
        return board.isSolved ? .solved : .solving
    }

    static func legalMoves(from board: PegSolitaireBoard) -> [(move: PegSolitaireMove, board: PegSolitaireBoard)] {
        let directions = [MechanicalMoveDelta.left, .right, .up, .down]
        return board.occupiedCoordinates.flatMap { from in
            directions.compactMap { delta in
                let jumped = MechanicalBoardCoordinate(row: from.row + delta.row, column: from.column + delta.column)
                let to = MechanicalBoardCoordinate(row: from.row + delta.row * 2, column: from.column + delta.column * 2)
                let move = PegSolitaireMove(from: from, jumped: jumped, to: to)
                return board.applying(move).map { (move, $0) }
            }
        }
    }
}

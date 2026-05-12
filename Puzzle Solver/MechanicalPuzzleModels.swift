//
//  MechanicalPuzzleModels.swift
//  Puzzle Solver
//
//  Reusable board, result, and solver architecture for mechanical puzzles.
//

import Foundation

// MARK: - Mechanical puzzle catalog

enum MechanicalPuzzleKind: String, CaseIterable, Identifiable, Hashable {
    case rushHour = "Rush Hour"
    case klotski = "Klotski"
    case pegSolitaire = "Peg Solitaire"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var summary: String {
        switch self {
        case .rushHour:
            return "Slide blocking cars until the red car reaches the exit."
        case .klotski:
            return "Slide blocks until the goal block reaches its exit."
        case .pegSolitaire:
            return "Jump pegs over adjacent pegs into empty cells until one peg remains."
        }
    }

    var isPlayable: Bool { self == .rushHour }
    var solverAvailable: Bool { self == .rushHour }
    var statusLabel: String { isPlayable ? "Active" : "Coming Soon" }
    var statusDetail: String { isPlayable ? "Solver ready" : "Routes to preview screen" }
}

struct MechanicalPuzzleDescriptor: Identifiable, Hashable {
    let kind: MechanicalPuzzleKind
    let boardSize: MechanicalBoardSize?
    let enabled: Bool
    let solverAvailable: Bool
    let statusLabel: String
    let statusDetail: String
    let notes: String

    var id: MechanicalPuzzleKind { kind }
}

enum MechanicalPuzzleCatalog {
    static let descriptors: [MechanicalPuzzleDescriptor] = MechanicalPuzzleKind.allCases.map { kind in
        MechanicalPuzzleDescriptor(
            kind: kind,
            boardSize: kind == .rushHour ? .rushHour : nil,
            enabled: kind.isPlayable,
            solverAvailable: kind.solverAvailable,
            statusLabel: kind.statusLabel,
            statusDetail: kind.statusDetail,
            notes: kind.summary
        )
    }
}

// MARK: - Reusable board and result models

struct MechanicalBoardCoordinate: Hashable, Identifiable {
    let row: Int
    let column: Int

    var id: String { "\(row)-\(column)" }
}

struct MechanicalBoardSize: Hashable {
    let rows: Int
    let columns: Int

    static let rushHour = MechanicalBoardSize(rows: 6, columns: 6)
    static let klotski = MechanicalBoardSize(rows: 5, columns: 4)
    static let pegSolitaire = MechanicalBoardSize(rows: 7, columns: 7)

    func contains(_ coordinate: MechanicalBoardCoordinate) -> Bool {
        (0..<rows).contains(coordinate.row) && (0..<columns).contains(coordinate.column)
    }
}

enum MechanicalPieceOrientation: String, Hashable {
    case horizontal
    case vertical
    case single
}

struct MechanicalPuzzlePiece: Hashable, Identifiable {
    let id: String
    let label: String
    let origin: MechanicalBoardCoordinate
    let size: MechanicalBoardSize
    let orientation: MechanicalPieceOrientation
    let isPrimary: Bool

    var occupiedCoordinates: [MechanicalBoardCoordinate] {
        (0..<size.rows).flatMap { rowOffset in
            (0..<size.columns).map { columnOffset in
                MechanicalBoardCoordinate(row: origin.row + rowOffset, column: origin.column + columnOffset)
            }
        }
    }

    func moving(by delta: MechanicalMoveDelta) -> MechanicalPuzzlePiece {
        MechanicalPuzzlePiece(
            id: id,
            label: label,
            origin: MechanicalBoardCoordinate(row: origin.row + delta.row, column: origin.column + delta.column),
            size: size,
            orientation: orientation,
            isPrimary: isPrimary
        )
    }
}

protocol MechanicalPuzzleBoard {
    var kind: MechanicalPuzzleKind { get }
    var size: MechanicalBoardSize { get }
    var pieces: [MechanicalPuzzlePiece] { get }
}

struct MechanicalMoveDelta: Hashable {
    let row: Int
    let column: Int

    var isHorizontal: Bool { row == 0 && column != 0 }
    var isVertical: Bool { column == 0 && row != 0 }

    static let left = MechanicalMoveDelta(row: 0, column: -1)
    static let right = MechanicalMoveDelta(row: 0, column: 1)
    static let up = MechanicalMoveDelta(row: -1, column: 0)
    static let down = MechanicalMoveDelta(row: 1, column: 0)
}

struct MechanicalPuzzleMove: Hashable, Identifiable {
    let pieceID: String
    let pieceLabel: String
    let delta: MechanicalMoveDelta
    let distance: Int

    var id: String { "\(pieceID)-\(delta.row)-\(delta.column)-\(distance)" }

    var notation: String {
        let direction: String
        if delta.column < 0 { direction = "left" }
        else if delta.column > 0 { direction = "right" }
        else if delta.row < 0 { direction = "up" }
        else { direction = "down" }
        return "\(pieceLabel) \(direction) \(distance)"
    }
}

struct OrderedMovePlaybackFrame<Board>: Identifiable {
    let id = UUID()
    let order: Int
    let move: MechanicalPuzzleMove?
    let board: Board
    let caption: String
}

struct MechanicalPuzzleSolveResult<Board> {
    let kind: MechanicalPuzzleKind
    let state: SolveState
    let moves: [MechanicalPuzzleMove]
    let playbackFrames: [OrderedMovePlaybackFrame<Board>]
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    var succeeded: Bool { state == .solved }
    var formattedMoves: [String] { moves.enumerated().map { "\($0.offset + 1). \($0.element.notation)" } }
}

struct MechanicalPuzzleSolveOptions {
    let timeout: TimeInterval
    let maxNodes: Int

    static let `default` = MechanicalPuzzleSolveOptions(timeout: 5, maxNodes: 100_000)
}

protocol MechanicalPuzzleSolving {
    associatedtype Board: MechanicalPuzzleBoard

    func solve(_ board: Board, options: MechanicalPuzzleSolveOptions) -> MechanicalPuzzleSolveResult<Board>
}

// MARK: - Rush Hour

struct RushHourBoard: MechanicalPuzzleBoard, Hashable {
    static let targetPieceID = "X"
    static let exitRow = 2

    let pieces: [MechanicalPuzzlePiece]

    var kind: MechanicalPuzzleKind { .rushHour }
    var size: MechanicalBoardSize { .rushHour }
    var targetPiece: MechanicalPuzzlePiece? { pieces.first { $0.id == Self.targetPieceID || $0.isPrimary } }
    var isSolved: Bool { targetPiece.map { $0.origin.column + $0.size.columns == size.columns } ?? false }

    init(pieces: [MechanicalPuzzlePiece]) {
        self.pieces = pieces.sorted { $0.id < $1.id }
    }

    static let example = RushHourBoard(pieces: [
        MechanicalPuzzlePiece(id: Self.targetPieceID, label: "X", origin: MechanicalBoardCoordinate(row: 2, column: 0), size: MechanicalBoardSize(rows: 1, columns: 2), orientation: .horizontal, isPrimary: true),
        MechanicalPuzzlePiece(id: "A", label: "A", origin: MechanicalBoardCoordinate(row: 2, column: 3), size: MechanicalBoardSize(rows: 2, columns: 1), orientation: .vertical, isPrimary: false),
        MechanicalPuzzlePiece(id: "B", label: "B", origin: MechanicalBoardCoordinate(row: 0, column: 4), size: MechanicalBoardSize(rows: 2, columns: 1), orientation: .vertical, isPrimary: false),
        MechanicalPuzzlePiece(id: "C", label: "C", origin: MechanicalBoardCoordinate(row: 4, column: 0), size: MechanicalBoardSize(rows: 1, columns: 2), orientation: .horizontal, isPrimary: false),
        MechanicalPuzzlePiece(id: "D", label: "D", origin: MechanicalBoardCoordinate(row: 5, column: 3), size: MechanicalBoardSize(rows: 1, columns: 2), orientation: .horizontal, isPrimary: false)
    ])

    func occupancy(excluding excludedID: String? = nil) -> [MechanicalBoardCoordinate: String] {
        var map: [MechanicalBoardCoordinate: String] = [:]
        for piece in pieces where piece.id != excludedID {
            for coordinate in piece.occupiedCoordinates {
                map[coordinate] = piece.id
            }
        }
        return map
    }

    func piece(at coordinate: MechanicalBoardCoordinate) -> MechanicalPuzzlePiece? {
        pieces.first { $0.occupiedCoordinates.contains(coordinate) }
    }

    func applying(_ move: MechanicalPuzzleMove) -> RushHourBoard? {
        guard let piece = pieces.first(where: { $0.id == move.pieceID }) else { return nil }
        let scaledDelta = MechanicalMoveDelta(row: move.delta.row * move.distance, column: move.delta.column * move.distance)
        let movedPiece = piece.moving(by: scaledDelta)
        var nextPieces = pieces.filter { $0.id != piece.id }
        nextPieces.append(movedPiece)
        let nextBoard = RushHourBoard(pieces: nextPieces)
        return RushHourBoardAnalyzer.validate(nextBoard) ? nextBoard : nil
    }
}

enum RushHourBoardAnalyzer {
    static func validate(_ board: RushHourBoard) -> Bool {
        guard board.size == .rushHour, let target = board.targetPiece else { return false }
        guard target.orientation == .horizontal, target.origin.row == RushHourBoard.exitRow else { return false }
        var occupied: Set<MechanicalBoardCoordinate> = []
        for piece in board.pieces {
            guard !piece.id.isEmpty, piece.size.rows > 0, piece.size.columns > 0 else { return false }
            guard piece.occupiedCoordinates.allSatisfy(board.size.contains) else { return false }
            for coordinate in piece.occupiedCoordinates {
                guard !occupied.contains(coordinate) else { return false }
                occupied.insert(coordinate)
            }
        }
        return true
    }

    static func legalMoves(from board: RushHourBoard) -> [(move: MechanicalPuzzleMove, board: RushHourBoard)] {
        board.pieces.flatMap { piece in
            legalMoves(for: piece, on: board).compactMap { move in
                board.applying(move).map { (move, $0) }
            }
        }
    }

    private static func legalMoves(for piece: MechanicalPuzzlePiece, on board: RushHourBoard) -> [MechanicalPuzzleMove] {
        let directions: [MechanicalMoveDelta]
        switch piece.orientation {
        case .horizontal: directions = [.left, .right]
        case .vertical: directions = [.up, .down]
        case .single: directions = [.left, .right, .up, .down]
        }

        let occupied = board.occupancy(excluding: piece.id)
        return directions.flatMap { direction in
            legalMoves(for: piece, direction: direction, board: board, occupied: occupied)
        }
    }

    private static func legalMoves(
        for piece: MechanicalPuzzlePiece,
        direction: MechanicalMoveDelta,
        board: RushHourBoard,
        occupied: [MechanicalBoardCoordinate: String]
    ) -> [MechanicalPuzzleMove] {
        var moves: [MechanicalPuzzleMove] = []
        var distance = 1

        while true {
            let delta = MechanicalMoveDelta(row: direction.row * distance, column: direction.column * distance)
            let moved = piece.moving(by: delta)
            guard moved.occupiedCoordinates.allSatisfy(board.size.contains) else { break }
            guard moved.occupiedCoordinates.allSatisfy({ occupied[$0] == nil }) else { break }
            moves.append(MechanicalPuzzleMove(pieceID: piece.id, pieceLabel: piece.label, delta: direction, distance: distance))
            distance += 1
        }

        return moves
    }
}

final class RushHourSolver: MechanicalPuzzleSolving {
    private struct SearchNode {
        let board: RushHourBoard
        let moves: [MechanicalPuzzleMove]
        let path: [RushHourBoard]
    }

    func solve(_ board: RushHourBoard, options: MechanicalPuzzleSolveOptions = .default) -> MechanicalPuzzleSolveResult<RushHourBoard> {
        let start = Date()
        SolverDebugLogger.shared.log("RushHourSolver: validation started")
        guard RushHourBoardAnalyzer.validate(board) else {
            SolverDebugLogger.shared.log("RushHourSolver: validation failed")
            return finish(.invalid, board: board, reason: "Rush Hour boards need one horizontal target car on row 3 and non-overlapping pieces.", start: start, nodes: 0)
        }

        SolverDebugLogger.shared.log("RushHourSolver: validation passed")
        if board.isSolved {
            return success(moves: [], path: [board], start: start, nodes: 0)
        }

        let deadline = start.addingTimeInterval(max(0, options.timeout))
        var frontier = [SearchNode(board: board, moves: [], path: [board])]
        var visited: Set<RushHourBoard> = [board]
        var cursor = 0
        var nodes = 0
        SolverDebugLogger.shared.log("RushHourSolver: solve started")

        while cursor < frontier.count {
            if Date() >= deadline {
                return finish(.timedOut, board: board, reason: "Rush Hour solver exceeded the \(options.timeout)s timeout.", start: start, nodes: nodes)
            }
            if nodes >= options.maxNodes {
                return finish(.failed, board: board, reason: "Rush Hour solver exceeded the \(options.maxNodes) node safety limit.", start: start, nodes: nodes)
            }

            let current = frontier[cursor]
            cursor += 1
            nodes += 1

            for neighbor in RushHourBoardAnalyzer.legalMoves(from: current.board) {
                guard !visited.contains(neighbor.board) else { continue }
                let nextMoves = current.moves + [neighbor.move]
                let nextPath = current.path + [neighbor.board]
                if neighbor.board.isSolved {
                    SolverDebugLogger.shared.log("RushHourSolver: solve finished solved in \(nextMoves.count) moves")
                    return success(moves: nextMoves, path: nextPath, start: start, nodes: nodes)
                }
                visited.insert(neighbor.board)
                frontier.append(SearchNode(board: neighbor.board, moves: nextMoves, path: nextPath))
            }
        }

        return finish(.unsolvable, board: board, reason: "No Rush Hour solution could be found from this layout.", start: start, nodes: nodes)
    }

    private func success(moves: [MechanicalPuzzleMove], path: [RushHourBoard], start: Date, nodes: Int) -> MechanicalPuzzleSolveResult<RushHourBoard> {
        MechanicalPuzzleSolveResult(
            kind: .rushHour,
            state: .solved,
            moves: moves,
            playbackFrames: Self.makeFrames(path: path, moves: moves),
            failureReason: nil,
            elapsedTime: Date().timeIntervalSince(start),
            nodesExplored: nodes
        )
    }

    private func finish(_ state: SolveState, board: RushHourBoard, reason: String, start: Date, nodes: Int) -> MechanicalPuzzleSolveResult<RushHourBoard> {
        SolverDebugLogger.shared.log("RushHourSolver: solve finished \(state.rawValue): \(reason)")
        return MechanicalPuzzleSolveResult(
            kind: .rushHour,
            state: state,
            moves: [],
            playbackFrames: [OrderedMovePlaybackFrame(order: 0, move: nil, board: board, caption: "Start")],
            failureReason: reason,
            elapsedTime: Date().timeIntervalSince(start),
            nodesExplored: nodes
        )
    }

    private static func makeFrames(path: [RushHourBoard], moves: [MechanicalPuzzleMove]) -> [OrderedMovePlaybackFrame<RushHourBoard>] {
        path.enumerated().map { index, board in
            let move = index == 0 ? nil : moves[index - 1]
            return OrderedMovePlaybackFrame(order: index, move: move, board: board, caption: index == 0 ? "Start" : "Step \(index): \(move?.notation ?? "Move")")
        }
    }
}


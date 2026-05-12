//
//  ExperimentalPuzzleModels.swift
//  Puzzle Solver
//
//  Modular experimental architecture for visual, graph, maze, chess, and jigsaw puzzles.
//

import Foundation


// MARK: - Experimental puzzle catalog

enum ExperimentalPuzzleKind: String, CaseIterable, Identifiable, Hashable {
    case maze = "Maze"
    case chessMateInN = "Chess Mate-in-N"
    case chessBestMove = "Chess Best Move"
    case jigsawSolver = "Jigsaw Solver"

    var id: String { rawValue }
    var displayName: String { rawValue }
    var isPlayable: Bool { self != .jigsawSolver }
    var solverAvailable: Bool { self != .jigsawSolver }

    var summary: String {
        switch self {
        case .maze:
            return "Find a shortest route from S to G through walkable cells."
        case .chessMateInN:
            return "Search legal chess moves for a forced checkmate in a bounded number of moves."
        case .chessBestMove:
            return "Evaluate legal chess moves with a lightweight tactical search."
        case .jigsawSolver:
            return "Placeholder architecture for future visual piece detection and edge matching."
        }
    }
}

struct ExperimentalPuzzleDescriptor: Identifiable, Hashable {
    let kind: ExperimentalPuzzleKind
    let enabled: Bool
    let solverAvailable: Bool
    let notes: String

    var id: ExperimentalPuzzleKind { kind }
}

enum ExperimentalPuzzleCatalog {
    static let descriptors: [ExperimentalPuzzleDescriptor] = ExperimentalPuzzleKind.allCases.map { kind in
        ExperimentalPuzzleDescriptor(kind: kind, enabled: kind.isPlayable, solverAvailable: kind.solverAvailable, notes: kind.summary)
    }
}

// MARK: - Reusable graph and pathfinding utilities

struct GraphPath<Node: Hashable, Move> {
    let nodes: [Node]
    let moves: [Move]
    let cost: Int

    var start: Node? { nodes.first }
    var goal: Node? { nodes.last }
    var isEmpty: Bool { nodes.isEmpty }
}

struct GraphSearchResult<Node: Hashable, Move> {
    let state: SolveState
    let path: GraphPath<Node, Move>?
    let failureReason: String?
    let nodesExplored: Int
    let elapsedTime: TimeInterval
}

enum GraphSearch {
    static func breadthFirstSearch<Node: Hashable, Move>(
        from start: Node,
        isGoal: (Node) -> Bool,
        neighbors: (Node) -> [(node: Node, move: Move)],
        maxNodes: Int = 100_000,
        timeout: TimeInterval = 5
    ) -> GraphSearchResult<Node, Move> {
        let startedAt = Date()
        let deadline = startedAt.addingTimeInterval(max(0, timeout))
        var frontier: [Node] = [start]
        var cursor = 0
        var visited: Set<Node> = [start]
        var parents: [Node: (previous: Node, move: Move)] = [:]
        var explored = 0

        if isGoal(start) {
            return GraphSearchResult(state: .solved, path: GraphPath(nodes: [start], moves: [], cost: 0), failureReason: nil, nodesExplored: 0, elapsedTime: Date().timeIntervalSince(startedAt))
        }

        while cursor < frontier.count {
            guard Date() < deadline else {
                return GraphSearchResult(state: .timedOut, path: nil, failureReason: "Graph search exceeded the \(timeout)s timeout.", nodesExplored: explored, elapsedTime: Date().timeIntervalSince(startedAt))
            }
            guard explored < maxNodes else {
                return GraphSearchResult(state: .failed, path: nil, failureReason: "Graph search exceeded the \(maxNodes) node limit.", nodesExplored: explored, elapsedTime: Date().timeIntervalSince(startedAt))
            }

            let current = frontier[cursor]
            cursor += 1
            explored += 1

            for edge in neighbors(current) where !visited.contains(edge.node) {
                visited.insert(edge.node)
                parents[edge.node] = (current, edge.move)
                if isGoal(edge.node) {
                    return GraphSearchResult(state: .solved, path: reconstructPath(to: edge.node, parents: parents), failureReason: nil, nodesExplored: explored, elapsedTime: Date().timeIntervalSince(startedAt))
                }
                frontier.append(edge.node)
            }
        }

        return GraphSearchResult(state: .unsolvable, path: nil, failureReason: "No path connects the start and goal nodes.", nodesExplored: explored, elapsedTime: Date().timeIntervalSince(startedAt))
    }

    private static func reconstructPath<Node: Hashable, Move>(to goal: Node, parents: [Node: (previous: Node, move: Move)]) -> GraphPath<Node, Move> {
        var nodes = [goal]
        var moves: [Move] = []
        var current = goal
        while let parent = parents[current] {
            moves.append(parent.move)
            nodes.append(parent.previous)
            current = parent.previous
        }
        return GraphPath(nodes: nodes.reversed(), moves: moves.reversed(), cost: moves.count)
    }
}

// MARK: - Reusable visual puzzle result models

enum VisualPuzzleAnnotationKind: String, Hashable {
    case path
    case highlight
    case candidate
    case warning
    case piece
    case move
}

struct VisualPuzzleAnnotation: Identifiable, Hashable {
    let id: String
    let kind: VisualPuzzleAnnotationKind
    let label: String
    let coordinates: [PuzzleGridPoint]

    init(id: String = UUID().uuidString, kind: VisualPuzzleAnnotationKind, label: String, coordinates: [PuzzleGridPoint]) {
        self.id = id
        self.kind = kind
        self.label = label
        self.coordinates = coordinates
    }
}

struct VisualPuzzleStep<Board>: Identifiable {
    let id = UUID()
    let index: Int
    let title: String
    let board: Board
    let annotations: [VisualPuzzleAnnotation]
}

struct VisualPuzzleResult<Board, Move> {
    let puzzleName: String
    let state: SolveState
    let moves: [Move]
    let steps: [VisualPuzzleStep<Board>]
    let failureReason: String?
    let nodesExplored: Int
    let elapsedTime: TimeInterval

    var succeeded: Bool { state == .solved }
}

// MARK: - Shared grid primitives

struct PuzzleGridPoint: Hashable, Identifiable, CustomStringConvertible {
    let row: Int
    let column: Int

    var id: String { "\(row)-\(column)" }
    var description: String { "(\(row), \(column))" }

    func moved(by direction: GridDirection) -> PuzzleGridPoint {
        PuzzleGridPoint(row: row + direction.delta.row, column: column + direction.delta.column)
    }
}

enum GridDirection: String, CaseIterable, Hashable, CustomStringConvertible {
    case up
    case down
    case left
    case right

    var delta: (row: Int, column: Int) {
        switch self {
        case .up: return (-1, 0)
        case .down: return (1, 0)
        case .left: return (0, -1)
        case .right: return (0, 1)
        }
    }

    var description: String { rawValue }
}

// MARK: - Maze solver

enum MazeCell: Character, Hashable {
    case wall = "#"
    case open = "."
    case start = "S"
    case goal = "G"
    case path = "*"
}

struct MazeBoard: Hashable {
    let cells: [[MazeCell]]

    var rows: Int { cells.count }
    var columns: Int { cells.first?.count ?? 0 }
    var start: PuzzleGridPoint? { firstCoordinate(containing: .start) }
    var goal: PuzzleGridPoint? { firstCoordinate(containing: .goal) }

    init(cells: [[MazeCell]]) {
        let width = cells.map(\.count).max() ?? 0
        self.cells = cells.map { row in row + Array(repeating: .wall, count: max(0, width - row.count)) }
    }

    init(lines: [String]) {
        self.init(cells: lines.map { line in line.map { MazeCell(rawValue: $0) ?? .wall } })
    }

    func contains(_ point: PuzzleGridPoint) -> Bool {
        (0..<rows).contains(point.row) && (0..<columns).contains(point.column)
    }

    func cell(at point: PuzzleGridPoint) -> MazeCell? {
        guard contains(point) else { return nil }
        return cells[point.row][point.column]
    }

    func isWalkable(_ point: PuzzleGridPoint) -> Bool {
        guard let cell = cell(at: point) else { return false }
        return cell != .wall
    }

    func neighbors(of point: PuzzleGridPoint) -> [(node: PuzzleGridPoint, move: GridDirection)] {
        GridDirection.allCases.compactMap { direction in
            let next = point.moved(by: direction)
            return isWalkable(next) ? (next, direction) : nil
        }
    }

    func overlaying(path: [PuzzleGridPoint]) -> MazeBoard {
        var copy = cells
        for point in path where contains(point) && copy[point.row][point.column] == .open {
            copy[point.row][point.column] = .path
        }
        return MazeBoard(cells: copy)
    }

    func rendered() -> [String] {
        cells.map { String($0.map(\.rawValue)) }
    }

    private func firstCoordinate(containing target: MazeCell) -> PuzzleGridPoint? {
        for row in 0..<rows {
            for column in 0..<columns where cells[row][column] == target {
                return PuzzleGridPoint(row: row, column: column)
            }
        }
        return nil
    }
}

struct MazeSolveOptions {
    let timeout: TimeInterval
    let maxNodes: Int

    static let `default` = MazeSolveOptions(timeout: 2, maxNodes: 25_000)
}

final class MazeSolver {
    func solve(_ board: MazeBoard, options: MazeSolveOptions = .default) -> VisualPuzzleResult<MazeBoard, GridDirection> {
        let startedAt = Date()
        SolverDebugLogger.shared.log("MazeSolver: validation started")
        guard let start = board.start, let goal = board.goal else {
            SolverDebugLogger.shared.log("MazeSolver: validation failed")
            return VisualPuzzleResult(puzzleName: "Maze", state: .invalid, moves: [], steps: [], failureReason: "Maze requires one S start and one G goal.", nodesExplored: 0, elapsedTime: Date().timeIntervalSince(startedAt))
        }

        SolverDebugLogger.shared.log("MazeSolver: solve started")
        let result = GraphSearch.breadthFirstSearch(from: start, isGoal: { $0 == goal }, neighbors: board.neighbors(of:), maxNodes: options.maxNodes, timeout: options.timeout)
        guard let path = result.path else {
            SolverDebugLogger.shared.log("MazeSolver: solve finished \(result.state.rawValue)")
            return VisualPuzzleResult(puzzleName: "Maze", state: result.state, moves: [], steps: [VisualPuzzleStep(index: 0, title: "Start", board: board, annotations: [])], failureReason: result.failureReason, nodesExplored: result.nodesExplored, elapsedTime: result.elapsedTime)
        }

        SolverDebugLogger.shared.log("MazeSolver: solve finished solved")
        let solvedBoard = board.overlaying(path: path.nodes)
        let annotation = VisualPuzzleAnnotation(kind: .path, label: "Shortest path", coordinates: path.nodes)
        let steps = [
            VisualPuzzleStep(index: 0, title: "Start", board: board, annotations: []),
            VisualPuzzleStep(index: 1, title: "Shortest path (\(path.cost) moves)", board: solvedBoard, annotations: [annotation])
        ]
        return VisualPuzzleResult(puzzleName: "Maze", state: .solved, moves: path.moves, steps: steps, failureReason: nil, nodesExplored: result.nodesExplored, elapsedTime: result.elapsedTime)
    }
}

// MARK: - Chess puzzle solver

enum ChessColor: String, Hashable {
    case white
    case black

    var opposite: ChessColor { self == .white ? .black : .white }
}

enum ChessPieceKind: Character, Hashable {
    case king = "k"
    case queen = "q"
    case rook = "r"
    case bishop = "b"
    case knight = "n"
    case pawn = "p"
}

struct ChessPiece: Hashable, CustomStringConvertible {
    let kind: ChessPieceKind
    let color: ChessColor

    var description: String {
        let value = String(kind.rawValue)
        return color == .white ? value.uppercased() : value
    }
}

struct ChessSquare: Hashable, Identifiable, CustomStringConvertible {
    let file: Int
    let rank: Int

    var id: String { algebraic }
    var algebraic: String {
        let fileScalar = UnicodeScalar(97 + file).map(Character.init) ?? "?"
        return "\(fileScalar)\(rank + 1)"
    }
    var description: String { algebraic }

    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    init?(_ algebraic: String) {
        let chars = Array(algebraic.lowercased())
        guard chars.count == 2,
              let fileScalar = chars[0].unicodeScalars.first?.value,
              let rankValue = Int(String(chars[1])) else { return nil }
        let file = Int(fileScalar) - 97
        let rank = rankValue - 1
        guard (0..<8).contains(file), (0..<8).contains(rank) else { return nil }
        self.file = file
        self.rank = rank
    }

    func offset(file df: Int, rank dr: Int) -> ChessSquare? {
        let next = ChessSquare(file: file + df, rank: rank + dr)
        return next.isValid ? next : nil
    }

    var isValid: Bool { (0..<8).contains(file) && (0..<8).contains(rank) }
}

struct ChessMove: Hashable, Identifiable, CustomStringConvertible {
    let from: ChessSquare
    let to: ChessSquare
    let promotion: ChessPieceKind?

    var id: String { uci }
    var uci: String { from.algebraic + to.algebraic + (promotion.map { String($0.rawValue) } ?? "") }
    var description: String { uci }
}

struct ChessBoard: Hashable {
    let pieces: [ChessSquare: ChessPiece]
    let sideToMove: ChessColor

    static let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - - 0 1"

    init(pieces: [ChessSquare: ChessPiece], sideToMove: ChessColor) {
        self.pieces = pieces
        self.sideToMove = sideToMove
    }

    init?(fen: String) {
        let parts = fen.split(separator: " ")
        guard parts.count >= 2 else { return nil }
        var parsed: [ChessSquare: ChessPiece] = [:]
        let ranks = parts[0].split(separator: "/")
        guard ranks.count == 8 else { return nil }
        for (fenRankIndex, rankText) in ranks.enumerated() {
            let rank = 7 - fenRankIndex
            var file = 0
            for character in rankText {
                if let empty = Int(String(character)) {
                    file += empty
                } else {
                    let color: ChessColor = character.isUppercase ? .white : .black
                    guard let kind = ChessPieceKind(rawValue: Character(String(character).lowercased())), file < 8 else { return nil }
                    parsed[ChessSquare(file: file, rank: rank)] = ChessPiece(kind: kind, color: color)
                    file += 1
                }
            }
            guard file == 8 else { return nil }
        }
        let side: ChessColor = parts[1] == "w" ? .white : .black
        self.init(pieces: parsed, sideToMove: side)
    }

    func piece(at square: ChessSquare) -> ChessPiece? { pieces[square] }

    func applying(_ move: ChessMove) -> ChessBoard? {
        guard let moving = pieces[move.from] else { return nil }
        var copy = pieces
        copy[move.from] = nil
        copy[move.to] = ChessPiece(kind: move.promotion ?? moving.kind, color: moving.color)
        return ChessBoard(pieces: copy, sideToMove: sideToMove.opposite)
    }

    func kingSquare(for color: ChessColor) -> ChessSquare? {
        pieces.first { $0.value.kind == .king && $0.value.color == color }?.key
    }

    func legalMoves(for color: ChessColor? = nil) -> [ChessMove] {
        let movingColor = color ?? sideToMove
        return pseudoLegalMoves(for: movingColor).filter { move in
            applying(move)?.isKingInCheck(movingColor) == false
        }
    }

    func isCheckmate(for color: ChessColor) -> Bool {
        isKingInCheck(color) && legalMoves(for: color).isEmpty
    }

    func isKingInCheck(_ color: ChessColor) -> Bool {
        guard let king = kingSquare(for: color) else { return true }
        return isSquare(king, attackedBy: color.opposite)
    }

    func materialScore(for color: ChessColor) -> Int {
        pieces.values.reduce(0) { score, piece in
            let value: Int
            switch piece.kind {
            case .king: value = 0
            case .queen: value = 900
            case .rook: value = 500
            case .bishop, .knight: value = 300
            case .pawn: value = 100
            }
            return score + (piece.color == color ? value : -value)
        }
    }

    private func isSquare(_ square: ChessSquare, attackedBy attacker: ChessColor) -> Bool {
        pseudoLegalMoves(for: attacker, includeKingSafety: false).contains { $0.to == square }
    }

    private func pseudoLegalMoves(for color: ChessColor, includeKingSafety: Bool = true) -> [ChessMove] {
        pieces.flatMap { square, piece -> [ChessMove] in
            guard piece.color == color else { return [] }
            return pseudoLegalMoves(from: square, piece: piece)
        }
    }

    private func pseudoLegalMoves(from square: ChessSquare, piece: ChessPiece) -> [ChessMove] {
        switch piece.kind {
        case .king:
            return stepMoves(from: square, piece: piece, deltas: [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)])
        case .queen:
            return slideMoves(from: square, piece: piece, deltas: [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)])
        case .rook:
            return slideMoves(from: square, piece: piece, deltas: [(-1, 0), (1, 0), (0, -1), (0, 1)])
        case .bishop:
            return slideMoves(from: square, piece: piece, deltas: [(-1, -1), (-1, 1), (1, -1), (1, 1)])
        case .knight:
            return stepMoves(from: square, piece: piece, deltas: [(-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, -1), (2, 1)])
        case .pawn:
            return pawnMoves(from: square, piece: piece)
        }
    }

    private func stepMoves(from square: ChessSquare, piece: ChessPiece, deltas: [(Int, Int)]) -> [ChessMove] {
        deltas.compactMap { df, dr in
            guard let target = square.offset(file: df, rank: dr), pieces[target]?.color != piece.color else { return nil }
            return ChessMove(from: square, to: target, promotion: nil)
        }
    }

    private func slideMoves(from square: ChessSquare, piece: ChessPiece, deltas: [(Int, Int)]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for (df, dr) in deltas {
            var current = square
            while let target = current.offset(file: df, rank: dr) {
                if let occupant = pieces[target] {
                    if occupant.color != piece.color {
                        moves.append(ChessMove(from: square, to: target, promotion: nil))
                    }
                    break
                }
                moves.append(ChessMove(from: square, to: target, promotion: nil))
                current = target
            }
        }
        return moves
    }

    private func pawnMoves(from square: ChessSquare, piece: ChessPiece) -> [ChessMove] {
        let direction = piece.color == .white ? 1 : -1
        let startRank = piece.color == .white ? 1 : 6
        let promotionRank = piece.color == .white ? 7 : 0
        var moves: [ChessMove] = []
        if let one = square.offset(file: 0, rank: direction), pieces[one] == nil {
            moves.append(ChessMove(from: square, to: one, promotion: one.rank == promotionRank ? .queen : nil))
            if square.rank == startRank, let two = square.offset(file: 0, rank: direction * 2), pieces[two] == nil {
                moves.append(ChessMove(from: square, to: two, promotion: nil))
            }
        }
        for df in [-1, 1] {
            guard let target = square.offset(file: df, rank: direction), let captured = pieces[target], captured.color != piece.color else { continue }
            moves.append(ChessMove(from: square, to: target, promotion: target.rank == promotionRank ? .queen : nil))
        }
        return moves
    }
}

enum ChessPuzzleKind: String, Hashable {
    case mateInN
    case bestMove
}

struct ChessPuzzleResult {
    let kind: ChessPuzzleKind
    let state: SolveState
    let bestMove: ChessMove?
    let principalVariation: [ChessMove]
    let failureReason: String?
    let nodesExplored: Int
    let elapsedTime: TimeInterval
}

struct ChessSolveOptions {
    let mateDepth: Int
    let searchDepth: Int
    let timeout: TimeInterval
    let maxNodes: Int

    static let `default` = ChessSolveOptions(mateDepth: 1, searchDepth: 2, timeout: 3, maxNodes: 100_000)
}

final class ChessPuzzleSolver {
    private var nodesExplored = 0
    private var deadline = Date()
    private var maxNodes = 0

    func solveMate(in moves: Int, board: ChessBoard, options: ChessSolveOptions = .default) -> ChessPuzzleResult {
        let startedAt = Date()
        SolverDebugLogger.shared.log("ChessPuzzleSolver: mate search started")
        reset(startedAt: startedAt, timeout: options.timeout, maxNodes: options.maxNodes)
        let attacker = board.sideToMove
        let candidates = board.legalMoves().sorted { $0.uci < $1.uci }
        for move in candidates {
            guard canContinue else { break }
            guard let next = board.applying(move), forcedMate(from: next, attacker: attacker, pliesRemaining: max(0, moves * 2 - 1)) else { continue }
            SolverDebugLogger.shared.log("ChessPuzzleSolver: mate search solved")
            return ChessPuzzleResult(kind: .mateInN, state: .solved, bestMove: move, principalVariation: [move], failureReason: nil, nodesExplored: nodesExplored, elapsedTime: Date().timeIntervalSince(startedAt))
        }
        let state: SolveState = Date() >= deadline ? .timedOut : (nodesExplored >= maxNodes ? .failed : .unsolvable)
        SolverDebugLogger.shared.log("ChessPuzzleSolver: mate search finished \(state.rawValue)")
        return ChessPuzzleResult(kind: .mateInN, state: state, bestMove: nil, principalVariation: [], failureReason: "No forced mate in \(moves) was found for \(attacker.rawValue).", nodesExplored: nodesExplored, elapsedTime: Date().timeIntervalSince(startedAt))
    }

    func solveBestMove(board: ChessBoard, options: ChessSolveOptions = .default) -> ChessPuzzleResult {
        let startedAt = Date()
        SolverDebugLogger.shared.log("ChessPuzzleSolver: best-move search started")
        reset(startedAt: startedAt, timeout: options.timeout, maxNodes: options.maxNodes)
        let color = board.sideToMove
        var best: (move: ChessMove, score: Int)?
        for move in board.legalMoves().sorted(by: { $0.uci < $1.uci }) {
            guard canContinue, let next = board.applying(move) else { break }
            let score = minimax(next, depth: max(0, options.searchDepth - 1), maximizing: false, perspective: color)
            if best == nil || score > best!.score {
                best = (move, score)
            }
        }
        guard let best else {
            let state: SolveState = Date() >= deadline ? .timedOut : (nodesExplored >= maxNodes ? .failed : .unsolvable)
            SolverDebugLogger.shared.log("ChessPuzzleSolver: best-move search finished \(state.rawValue)")
            return ChessPuzzleResult(kind: .bestMove, state: state, bestMove: nil, principalVariation: [], failureReason: state == .unsolvable ? "No legal chess moves are available." : state.friendlyMessage, nodesExplored: nodesExplored, elapsedTime: Date().timeIntervalSince(startedAt))
        }
        SolverDebugLogger.shared.log("ChessPuzzleSolver: best-move search solved")
        return ChessPuzzleResult(kind: .bestMove, state: .solved, bestMove: best.move, principalVariation: [best.move], failureReason: nil, nodesExplored: nodesExplored, elapsedTime: Date().timeIntervalSince(startedAt))
    }

    private func reset(startedAt: Date, timeout: TimeInterval, maxNodes: Int) {
        nodesExplored = 0
        deadline = startedAt.addingTimeInterval(max(0, timeout))
        self.maxNodes = maxNodes
    }

    private var canContinue: Bool { Date() < deadline && nodesExplored < maxNodes }

    private func forcedMate(from board: ChessBoard, attacker: ChessColor, pliesRemaining: Int) -> Bool {
        nodesExplored += 1
        guard canContinue else { return false }
        if board.isCheckmate(for: attacker.opposite) { return true }
        guard pliesRemaining > 0 else { return false }
        let moves = board.legalMoves()
        guard !moves.isEmpty else { return false }
        if board.sideToMove == attacker {
            return moves.contains { move in
                guard let next = board.applying(move) else { return false }
                return forcedMate(from: next, attacker: attacker, pliesRemaining: pliesRemaining - 1)
            }
        } else {
            return moves.allSatisfy { move in
                guard let next = board.applying(move) else { return false }
                return forcedMate(from: next, attacker: attacker, pliesRemaining: pliesRemaining - 1)
            }
        }
    }

    private func minimax(_ board: ChessBoard, depth: Int, maximizing: Bool, perspective: ChessColor) -> Int {
        nodesExplored += 1
        guard canContinue else { return board.materialScore(for: perspective) }
        if board.isCheckmate(for: perspective.opposite) { return 100_000 + depth }
        if board.isCheckmate(for: perspective) { return -100_000 - depth }
        guard depth > 0 else { return board.materialScore(for: perspective) }
        let moves = board.legalMoves()
        guard !moves.isEmpty else { return board.materialScore(for: perspective) }
        let scores = moves.compactMap { board.applying($0).map { minimax($0, depth: depth - 1, maximizing: !maximizing, perspective: perspective) } }
        return maximizing ? (scores.max() ?? 0) : (scores.min() ?? 0)
    }
}

// MARK: - Jigsaw placeholder architecture

enum JigsawEdgeKind: String, Hashable {
    case flat
    case tab
    case blank
    case unknown
}

struct JigsawPiece: Identifiable, Hashable {
    let id: String
    let label: String
    // Future image-based solving can populate this from contour analysis: each side will be classified as flat, tab, blank, or unknown before color/texture matching runs.
    let edges: [GridDirection: JigsawEdgeKind]

    init(id: String, label: String, edges: [GridDirection: JigsawEdgeKind] = [:]) {
        self.id = id
        self.label = label
        self.edges = edges
    }
}

struct JigsawPuzzle: Hashable {
    let rows: Int
    let columns: Int
    // The eventual vision pipeline should convert detected piece centers into grid coordinates, then keep unmatched detections in unplacedPieces until the solver chooses a placement.
    let placedPieces: [PuzzleGridPoint: JigsawPiece]
    let unplacedPieces: [JigsawPiece]

    static let placeholder = JigsawPuzzle(rows: 0, columns: 0, placedPieces: [:], unplacedPieces: [])
}

struct JigsawSolveOptions {
    let timeout: TimeInterval
    let maxNodes: Int

    static let `default` = JigsawSolveOptions(timeout: 5, maxNodes: 100_000)
}

final class JigsawSolver {
    // This placeholder intentionally returns .unsupported while preserving the same VisualPuzzleResult shape used by other image-like puzzles; future work can rank piece placements by edge compatibility, color histograms, and seam-continuity scores.
    func solve(_ board: JigsawPuzzle, options: JigsawSolveOptions = .default) -> VisualPuzzleResult<JigsawPuzzle, String> {
        let startedAt = Date()
        SolverDebugLogger.shared.log("JigsawSolver: placeholder returned unsupported")
        return VisualPuzzleResult(
            puzzleName: "Jigsaw Solver",
            state: .unsupported,
            moves: [],
            steps: [VisualPuzzleStep(index: 0, title: "Jigsaw architecture placeholder", board: board, annotations: [])],
            failureReason: "Jigsaw piece detection, edge matching, and image-comparison heuristics are intentionally modular placeholders.",
            nodesExplored: 0,
            elapsedTime: Date().timeIntervalSince(startedAt)
        )
    }
}

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

enum RushHourOrientation: String, CaseIterable, Identifiable, Hashable {
    case horizontal
    case vertical

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum RushHourVehicleStyle: Int, CaseIterable, Hashable {
    case purple, blue, teal, orange, indigo, green
}

struct RushHourVehicle: Identifiable, Hashable {
    let id: String
    let label: String
    let orientation: RushHourOrientation
    let length: Int
    let row: Int
    let column: Int
    let style: RushHourVehicleStyle
    let isTarget: Bool

    var occupiedCells: [MechanicalBoardCoordinate] {
        (0..<length).map { offset in
            MechanicalBoardCoordinate(
                row: row + (orientation == .vertical ? offset : 0),
                column: column + (orientation == .horizontal ? offset : 0)
            )
        }
    }

    func moved(by signedDistance: Int) -> RushHourVehicle {
        RushHourVehicle(
            id: id,
            label: label,
            orientation: orientation,
            length: length,
            row: row + (orientation == .vertical ? signedDistance : 0),
            column: column + (orientation == .horizontal ? signedDistance : 0),
            style: style,
            isTarget: isTarget
        )
    }
}

struct RushHourMove: Identifiable, Hashable {
    let vehicleID: String
    let vehicleLabel: String
    let signedDistance: Int
    let orientation: RushHourOrientation
    let isTarget: Bool

    var id: String { "\(vehicleID)-\(signedDistance)" }
    var distance: Int { abs(signedDistance) }
    var direction: String {
        if orientation == .horizontal { return signedDistance < 0 ? "left" : "right" }
        return signedDistance < 0 ? "up" : "down"
    }
    var label: String {
        let name = isTarget ? "red car" : vehicleLabel
        return "Move \(name) \(direction) \(distance)"
    }
}

struct RushHourBoard: Hashable {
    static let dimension = 6

    let vehicles: [RushHourVehicle]

    init(vehicles: [RushHourVehicle]) {
        self.vehicles = vehicles.sorted { $0.id < $1.id }
    }

    static let empty = RushHourBoard(vehicles: [])
    static let example = RushHourBoard(vehicles: [
        RushHourVehicle(id: "X", label: "X", orientation: .horizontal, length: 2, row: 2, column: 0, style: .purple, isTarget: true),
        RushHourVehicle(id: "A", label: "A", orientation: .vertical, length: 2, row: 1, column: 2, style: .blue, isTarget: false),
        RushHourVehicle(id: "B", label: "B", orientation: .vertical, length: 3, row: 0, column: 3, style: .teal, isTarget: false),
        RushHourVehicle(id: "C", label: "C", orientation: .horizontal, length: 2, row: 3, column: 2, style: .orange, isTarget: false),
        RushHourVehicle(id: "D", label: "D", orientation: .vertical, length: 2, row: 3, column: 5, style: .indigo, isTarget: false)
    ])

    var targetVehicle: RushHourVehicle? { vehicles.first(where: \.isTarget) }
    var isSolved: Bool {
        guard let targetVehicle else { return false }
        return targetVehicle.column + targetVehicle.length == Self.dimension
    }
    var validationIssue: String? { RushHourBoardValidator.validationIssue(for: self) }
    var isValid: Bool { validationIssue == nil }

    func occupancy(excluding vehicleID: String? = nil) -> [MechanicalBoardCoordinate: String] {
        var result: [MechanicalBoardCoordinate: String] = [:]
        for vehicle in vehicles where vehicle.id != vehicleID {
            for cell in vehicle.occupiedCells { result[cell] = vehicle.id }
        }
        return result
    }

    func vehicle(at cell: MechanicalBoardCoordinate) -> RushHourVehicle? {
        vehicles.first { $0.occupiedCells.contains(cell) }
    }

    func grid() -> [[String?]] {
        var result = Array(repeating: Array<String?>(repeating: nil, count: Self.dimension), count: Self.dimension)
        for vehicle in vehicles {
            for cell in vehicle.occupiedCells where (0..<Self.dimension).contains(cell.row) && (0..<Self.dimension).contains(cell.column) {
                result[cell.row][cell.column] = vehicle.id
            }
        }
        return result
    }

    func canPlace(_ vehicle: RushHourVehicle) -> Bool {
        let candidate = RushHourBoard(vehicles: vehicles + [vehicle])
        return RushHourBoardValidator.placementIssue(for: candidate) == nil
    }

    func applying(_ move: RushHourMove) -> RushHourBoard? {
        guard let vehicle = vehicles.first(where: { $0.id == move.vehicleID }),
              vehicle.orientation == move.orientation else { return nil }
        let replacement = vehicle.moved(by: move.signedDistance)
        let board = RushHourBoard(vehicles: vehicles.filter { $0.id != vehicle.id } + [replacement])
        return RushHourBoardValidator.placementIssue(for: board) == nil ? board : nil
    }

    func legalMoves() -> [(move: RushHourMove, board: RushHourBoard)] {
        vehicles.flatMap { vehicle in
            [-1, 1].flatMap { direction -> [(move: RushHourMove, board: RushHourBoard)] in
                var results: [(move: RushHourMove, board: RushHourBoard)] = []
                var distance = 1
                while true {
                    let move = RushHourMove(
                        vehicleID: vehicle.id,
                        vehicleLabel: vehicle.label,
                        signedDistance: direction * distance,
                        orientation: vehicle.orientation,
                        isTarget: vehicle.isTarget
                    )
                    guard let next = applying(move) else { break }
                    results.append((move, next))
                    distance += 1
                }
                return results
            }
        }
    }
}

enum RushHourBoardValidator {
    static func placementIssue(for board: RushHourBoard) -> String? {
        guard Set(board.vehicles.map(\.id)).count == board.vehicles.count else {
            return "Each vehicle needs a unique identifier."
        }
        var occupied = Set<MechanicalBoardCoordinate>()
        for vehicle in board.vehicles {
            guard !vehicle.id.isEmpty, !vehicle.label.isEmpty else { return "Each vehicle needs an identifier and label." }
            guard vehicle.length == 2 || vehicle.length == 3 else { return "Vehicles must be length 2 or 3." }
            guard vehicle.row >= 0, vehicle.column >= 0,
                  vehicle.occupiedCells.allSatisfy({
                      $0.row < RushHourBoard.dimension && $0.column < RushHourBoard.dimension
                  }) else { return "That vehicle would extend outside the 6×6 board." }
            for cell in vehicle.occupiedCells {
                guard occupied.insert(cell).inserted else { return "Vehicles cannot overlap." }
            }
        }
        return nil
    }

    static func validationIssue(for board: RushHourBoard) -> String? {
        if let issue = placementIssue(for: board) { return issue }
        let targets = board.vehicles.filter(\.isTarget)
        guard targets.count == 1 else { return "Add exactly one red target car." }
        guard targets[0].orientation == .horizontal else { return "The red target car must be horizontal." }
        return nil
    }

    static func validate(_ board: RushHourBoard) -> Bool { validationIssue(for: board) == nil }
}

enum RushHourSolveStatus: Equatable {
    case solved
    case invalid
    case noSolution
    case timedOut
    case failed
}

struct RushHourSolutionStep: Identifiable, Hashable {
    let stepNumber: Int
    let board: RushHourBoard
    let moveLabel: String

    var id: Int { stepNumber }
}

struct RushHourSolveResult {
    let status: RushHourSolveStatus
    let steps: [RushHourSolutionStep]
    let message: String?

    var moveCount: Int { max(steps.count - 1, 0) }
}

struct RushHourSolveOptions {
    let timeout: TimeInterval
    let maxStates: Int

    static let `default` = RushHourSolveOptions(timeout: 5, maxStates: 100_000)
}

final class RushHourSolver {
    private struct SearchNode {
        let board: RushHourBoard
        let moves: [RushHourMove]
        let path: [RushHourBoard]
    }

    func solve(_ board: RushHourBoard, options: RushHourSolveOptions = .default) -> RushHourSolveResult {
        guard let timeout = options.timeout.isFinite ? Optional(max(0, options.timeout)) : nil,
              options.maxStates > 0 else {
            return RushHourSolveResult(status: .failed, steps: [], message: "The solver safety settings are invalid.")
        }
        if let issue = board.validationIssue {
            return RushHourSolveResult(status: .invalid, steps: [], message: issue)
        }
        if board.isSolved { return solved(path: [board], moves: []) }

        let deadline = Date().addingTimeInterval(timeout)
        var queue = [SearchNode(board: board, moves: [], path: [board])]
        var visited: Set<RushHourBoard> = [board]
        var cursor = 0

        while cursor < queue.count {
            if Date() >= deadline {
                return RushHourSolveResult(status: .timedOut, steps: [], message: "This puzzle took too long to solve. Try simplifying the board.")
            }
            if visited.count >= options.maxStates {
                return RushHourSolveResult(status: .failed, steps: [], message: "The puzzle reached the solver safety limit. Try simplifying the board.")
            }

            let current = queue[cursor]
            cursor += 1
            for neighbor in current.board.legalMoves() where !visited.contains(neighbor.board) {
                let moves = current.moves + [neighbor.move]
                let path = current.path + [neighbor.board]
                if neighbor.board.isSolved { return solved(path: path, moves: moves) }
                visited.insert(neighbor.board)
                queue.append(SearchNode(board: neighbor.board, moves: moves, path: path))
            }
        }

        return RushHourSolveResult(status: .noSolution, steps: [], message: "No solution found for this board.")
    }

    private func solved(path: [RushHourBoard], moves: [RushHourMove]) -> RushHourSolveResult {
        let steps = path.enumerated().map { index, board in
            RushHourSolutionStep(
                stepNumber: index,
                board: board,
                moveLabel: index == 0 ? "Start" : moves[index - 1].label
            )
        }
        return RushHourSolveResult(status: .solved, steps: steps, message: nil)
    }
}

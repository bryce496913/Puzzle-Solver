//
//  LogicPuzzleModels.swift
//  Puzzle Solver
//
//  Shared domain models and solver architecture for logic-grid puzzles.
//

import Foundation

// MARK: - Logic puzzle catalog

enum LogicPuzzleKind: String, CaseIterable, Identifiable, Hashable {
    case sudoku = "Sudoku"
    case killerSudoku = "Killer Sudoku"
    case nonogram = "Nonogram"
    case kakuro = "Kakuro"
    case slitherlink = "Slitherlink"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var summary: String {
        switch self {
        case .sudoku: return "Place 1–9 so every row, column, and box contains each digit once."
        case .killerSudoku: return "Sudoku with cage sums that constrain groups of cells."
        case .nonogram: return "Paint cells using row and column clue runs to reveal a picture."
        case .kakuro: return "Fill crossword-style number runs that add to clue sums without repeats."
        case .slitherlink: return "Draw one continuous loop around numbered clue cells. Validator available; full solver unavailable."
        }
    }

    var isPlayable: Bool { self == .sudoku }
    var solverAvailable: Bool { self == .sudoku }
}

struct LogicGridCoordinate: Hashable, Identifiable {
    let row: Int
    let column: Int

    var id: String { "\(row)-\(column)" }
}

struct LogicGridSize: Hashable {
    let rows: Int
    let columns: Int

    static let sudoku = LogicGridSize(rows: 9, columns: 9)
}

protocol LogicPuzzleBoard {
    associatedtype Cell: Equatable

    var kind: LogicPuzzleKind { get }
    var size: LogicGridSize { get }
    var cells: [[Cell]] { get }
}

protocol LogicPuzzleSolving {
    associatedtype Board: LogicPuzzleBoard
    associatedtype Result

    func solve(_ board: Board) -> Result
}

struct LogicPuzzleDescriptor: Identifiable, Hashable {
    let kind: LogicPuzzleKind
    let gridSize: LogicGridSize?
    let enabled: Bool
    let solverAvailable: Bool
    let notes: String

    var id: LogicPuzzleKind { kind }
}

enum LogicPuzzleCatalog {
    static let descriptors: [LogicPuzzleDescriptor] = LogicPuzzleKind.allCases.map { kind in
        LogicPuzzleDescriptor(
            kind: kind,
            gridSize: kind == .sudoku || kind == .killerSudoku ? .sudoku : nil,
            enabled: kind.isPlayable,
            solverAvailable: kind.solverAvailable,
            notes: kind.summary
        )
    }
}

// MARK: - Sudoku models

struct SudokuCell: Equatable, Hashable {
    var value: Int?
    var isGiven: Bool

    init(value: Int? = nil, isGiven: Bool = false) {
        self.value = value
        self.isGiven = isGiven && value != nil
    }
}

struct SudokuBoard: LogicPuzzleBoard, Equatable, Hashable {
    static let dimension = 9
    static let boxSize = 3

    let cells: [[SudokuCell]]

    var kind: LogicPuzzleKind { .sudoku }
    var size: LogicGridSize { .sudoku }
    var isComplete: Bool { cells.flatMap { $0 }.allSatisfy { $0.value != nil } }
    var filledCount: Int { cells.flatMap { $0 }.filter { $0.value != nil }.count }

    init(cells: [[SudokuCell]]) {
        self.cells = cells
    }

    init(values: [[Int?]], givens: Set<LogicGridCoordinate>? = nil) {
        let normalizedRows = values.prefix(Self.dimension).map { row in
            Array(row.prefix(Self.dimension)) + Array(repeating: nil, count: max(0, Self.dimension - row.count))
        }
        let paddedRows = normalizedRows + Array(repeating: Array(repeating: nil, count: Self.dimension), count: max(0, Self.dimension - normalizedRows.count))
        self.cells = paddedRows.enumerated().map { rowIndex, row in
            row.enumerated().map { columnIndex, value in
                let coordinate = LogicGridCoordinate(row: rowIndex, column: columnIndex)
                return SudokuCell(value: value, isGiven: givens?.contains(coordinate) ?? (value != nil))
            }
        }
    }

    static var empty: SudokuBoard {
        SudokuBoard(cells: Array(repeating: Array(repeating: SudokuCell(), count: dimension), count: dimension))
    }

    static var example: SudokuBoard {
        SudokuBoard(values: [
            [5, 3, nil, nil, 7, nil, nil, nil, nil],
            [6, nil, nil, 1, 9, 5, nil, nil, nil],
            [nil, 9, 8, nil, nil, nil, nil, 6, nil],
            [8, nil, nil, nil, 6, nil, nil, nil, 3],
            [4, nil, nil, 8, nil, 3, nil, nil, 1],
            [7, nil, nil, nil, 2, nil, nil, nil, 6],
            [nil, 6, nil, nil, nil, nil, 2, 8, nil],
            [nil, nil, nil, 4, 1, 9, nil, nil, 5],
            [nil, nil, nil, nil, 8, nil, nil, 7, 9]
        ])
    }

    func value(at coordinate: LogicGridCoordinate) -> Int? {
        guard Self.contains(coordinate) else { return nil }
        return cells[coordinate.row][coordinate.column].value
    }

    func settingValue(_ value: Int?, at coordinate: LogicGridCoordinate, markGiven: Bool? = nil) -> SudokuBoard {
        guard Self.contains(coordinate), value == nil || Self.validDigits.contains(value!) else { return self }
        var copy = cells
        copy[coordinate.row][coordinate.column].value = value
        copy[coordinate.row][coordinate.column].isGiven = markGiven ?? copy[coordinate.row][coordinate.column].isGiven && value != nil
        return SudokuBoard(cells: copy)
    }

    func values() -> [[Int?]] {
        cells.map { row in row.map(\.value) }
    }

    static let validDigits = Set(1...9)

    static func contains(_ coordinate: LogicGridCoordinate) -> Bool {
        (0..<dimension).contains(coordinate.row) && (0..<dimension).contains(coordinate.column)
    }
}

struct SudokuValidationIssue: Identifiable, Equatable, Hashable {
    enum Scope: String, Hashable {
        case row = "Row"
        case column = "Column"
        case box = "Box"
        case cell = "Cell"
    }

    let id = UUID()
    let scope: Scope
    let index: Int
    let message: String
    let coordinates: Set<LogicGridCoordinate>

    static func == (lhs: SudokuValidationIssue, rhs: SudokuValidationIssue) -> Bool {
        lhs.scope == rhs.scope && lhs.index == rhs.index && lhs.message == rhs.message && lhs.coordinates == rhs.coordinates
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(scope)
        hasher.combine(index)
        hasher.combine(message)
        hasher.combine(coordinates)
    }
}

struct SudokuValidationResult: Equatable {
    let issues: [SudokuValidationIssue]
    let isComplete: Bool

    var isValid: Bool { issues.isEmpty }
    var canSolve: Bool { isValid }
    var summary: String {
        if issues.isEmpty { return isComplete ? "Valid complete Sudoku." : "Valid puzzle so far." }
        return issues.map(\.message).joined(separator: "\n")
    }
}

enum SudokuValidator {
    static func validate(_ board: SudokuBoard) -> SudokuValidationResult {
        var issues: [SudokuValidationIssue] = []

        for row in 0..<SudokuBoard.dimension {
            let coordinates = (0..<SudokuBoard.dimension).map { LogicGridCoordinate(row: row, column: $0) }
            issues.append(contentsOf: duplicates(in: coordinates, board: board, scope: .row, index: row))
        }

        for column in 0..<SudokuBoard.dimension {
            let coordinates = (0..<SudokuBoard.dimension).map { LogicGridCoordinate(row: $0, column: column) }
            issues.append(contentsOf: duplicates(in: coordinates, board: board, scope: .column, index: column))
        }

        for boxRow in 0..<SudokuBoard.boxSize {
            for boxColumn in 0..<SudokuBoard.boxSize {
                let coordinates = (0..<SudokuBoard.boxSize).flatMap { rowOffset in
                    (0..<SudokuBoard.boxSize).map { columnOffset in
                        LogicGridCoordinate(row: boxRow * SudokuBoard.boxSize + rowOffset, column: boxColumn * SudokuBoard.boxSize + columnOffset)
                    }
                }
                let boxIndex = boxRow * SudokuBoard.boxSize + boxColumn
                issues.append(contentsOf: duplicates(in: coordinates, board: board, scope: .box, index: boxIndex))
            }
        }

        for row in 0..<SudokuBoard.dimension {
            for column in 0..<SudokuBoard.dimension {
                let coordinate = LogicGridCoordinate(row: row, column: column)
                if let value = board.value(at: coordinate), !SudokuBoard.validDigits.contains(value) {
                    issues.append(SudokuValidationIssue(scope: .cell, index: row * SudokuBoard.dimension + column, message: "Cell R\(row + 1)C\(column + 1) must be 1–9.", coordinates: [coordinate]))
                }
            }
        }

        return SudokuValidationResult(issues: issues, isComplete: board.isComplete)
    }

    static func conflictingCoordinates(in board: SudokuBoard) -> Set<LogicGridCoordinate> {
        Set(validate(board).issues.flatMap(\.coordinates))
    }

    private static func duplicates(in coordinates: [LogicGridCoordinate], board: SudokuBoard, scope: SudokuValidationIssue.Scope, index: Int) -> [SudokuValidationIssue] {
        let grouped = Dictionary(grouping: coordinates) { coordinate in board.value(at: coordinate) }
        return grouped.compactMap { value, coordinates in
            guard let value, coordinates.count > 1 else { return nil }
            return SudokuValidationIssue(
                scope: scope,
                index: index,
                message: "\(scope.rawValue) \(index + 1) contains more than one \(value).",
                coordinates: Set(coordinates)
            )
        }
    }
}

struct SudokuSolveStep: Identifiable, Equatable {
    let id = UUID()
    let coordinate: LogicGridCoordinate
    let value: Int
}

struct SudokuSolveResult: Equatable {
    let state: SolveState
    let initialBoard: SudokuBoard
    let solvedBoard: SudokuBoard?
    let steps: [SudokuSolveStep]
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    var isSolved: Bool { state == .solved && solvedBoard != nil }
}

struct SudokuSolveOptions: Equatable {
    var maxNodes: Int = 500_000
    var timeout: TimeInterval = 5
}

final class SudokuSolver: LogicPuzzleSolving {
    func solve(_ board: SudokuBoard) -> SudokuSolveResult {
        solve(board, options: SudokuSolveOptions())
    }

    func solve(_ board: SudokuBoard, options: SudokuSolveOptions) -> SudokuSolveResult {
        let start = Date()
        let validation = SudokuValidator.validate(board)
        guard validation.isValid else {
            return finish(.invalid, initialBoard: board, solvedBoard: nil, steps: [], reason: validation.summary, start: start, nodes: 0)
        }

        var values = board.values().map { row in row.map { $0 ?? 0 } }
        var steps: [SudokuSolveStep] = []
        var nodes = 0
        let deadline = start.addingTimeInterval(options.timeout)

        let solved = search(values: &values, steps: &steps, nodes: &nodes, maxNodes: options.maxNodes, deadline: deadline)
        if solved {
            let givens = Set(board.cells.enumerated().flatMap { rowIndex, row in
                row.enumerated().compactMap { columnIndex, cell in
                    cell.isGiven ? LogicGridCoordinate(row: rowIndex, column: columnIndex) : nil
                }
            })
            return finish(.solved, initialBoard: board, solvedBoard: SudokuBoard(values: values.map { $0.map { Optional($0) } }, givens: givens), steps: steps, reason: nil, start: start, nodes: nodes)
        }

        let state: SolveState = Date() >= deadline ? .timedOut : (nodes >= options.maxNodes ? .failed : .unsolvable)
        let reason: String
        switch state {
        case .timedOut: reason = "Sudoku solve exceeded \(options.timeout)s timeout."
        case .failed: reason = "Sudoku solve exceeded \(options.maxNodes) node safety limit."
        default: reason = "No solution exists for this Sudoku."
        }
        return finish(state, initialBoard: board, solvedBoard: nil, steps: [], reason: reason, start: start, nodes: nodes)
    }

    private func search(values: inout [[Int]], steps: inout [SudokuSolveStep], nodes: inout Int, maxNodes: Int, deadline: Date) -> Bool {
        guard Date() < deadline, nodes < maxNodes else { return false }
        guard let candidate = bestEmptyCell(in: values) else { return true }
        let coordinate = candidate.coordinate

        for value in candidate.values {
            nodes += 1
            values[coordinate.row][coordinate.column] = value
            steps.append(SudokuSolveStep(coordinate: coordinate, value: value))
            if search(values: &values, steps: &steps, nodes: &nodes, maxNodes: maxNodes, deadline: deadline) {
                return true
            }
            steps.removeLast()
            values[coordinate.row][coordinate.column] = 0
        }

        return false
    }

    private func bestEmptyCell(in values: [[Int]]) -> (coordinate: LogicGridCoordinate, values: [Int])? {
        var best: (coordinate: LogicGridCoordinate, values: [Int])?

        for row in 0..<SudokuBoard.dimension {
            for column in 0..<SudokuBoard.dimension where values[row][column] == 0 {
                let coordinate = LogicGridCoordinate(row: row, column: column)
                let candidates = candidatesForCell(row: row, column: column, values: values)
                if candidates.isEmpty { return (coordinate, []) }
                if best == nil || candidates.count < best!.values.count {
                    best = (coordinate, candidates)
                }
            }
        }

        return best
    }

    private func candidatesForCell(row: Int, column: Int, values: [[Int]]) -> [Int] {
        let usedInRow = Set(values[row].filter { $0 != 0 })
        let usedInColumn = Set((0..<SudokuBoard.dimension).map { values[$0][column] }.filter { $0 != 0 })
        let boxStartRow = (row / SudokuBoard.boxSize) * SudokuBoard.boxSize
        let boxStartColumn = (column / SudokuBoard.boxSize) * SudokuBoard.boxSize
        let usedInBox = Set((0..<SudokuBoard.boxSize).flatMap { rowOffset in
            (0..<SudokuBoard.boxSize).map { columnOffset in
                values[boxStartRow + rowOffset][boxStartColumn + columnOffset]
            }
        }.filter { $0 != 0 })

        return Array(SudokuBoard.validDigits.subtracting(usedInRow).subtracting(usedInColumn).subtracting(usedInBox)).sorted()
    }

    private func finish(_ state: SolveState, initialBoard: SudokuBoard, solvedBoard: SudokuBoard?, steps: [SudokuSolveStep], reason: String?, start: Date, nodes: Int) -> SudokuSolveResult {
        SudokuSolveResult(state: state, initialBoard: initialBoard, solvedBoard: solvedBoard, steps: steps, failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }
}

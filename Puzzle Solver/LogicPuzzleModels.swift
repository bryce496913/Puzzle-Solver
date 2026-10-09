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

    var isPlayable: Bool { self == .sudoku || self == .killerSudoku }
    var solverAvailable: Bool { self == .sudoku || self == .killerSudoku }
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
        guard Self.contains(coordinate), cells.indices.contains(coordinate.row),
              cells[coordinate.row].indices.contains(coordinate.column) else { return nil }
        return cells[coordinate.row][coordinate.column].value
    }

    func settingValue(_ value: Int?, at coordinate: LogicGridCoordinate, markGiven: Bool? = nil) -> SudokuBoard {
        guard Self.contains(coordinate), cells.indices.contains(coordinate.row),
              cells[coordinate.row].indices.contains(coordinate.column) else { return self }
        if let value, !Self.validDigits.contains(value) { return self }
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
    let hasEntries: Bool

    var isValid: Bool { issues.isEmpty }
    /// Manual-entry eligibility is distinct from structural validity. The solver
    /// remains the authority on whether a non-empty puzzle has one solution.
    var canSolve: Bool { isValid && hasEntries }
    var summary: String {
        if issues.isEmpty { return isComplete ? "Valid complete Sudoku." : "Valid puzzle so far." }
        return issues.map(\.message).joined(separator: "\n")
    }
}

enum SudokuValidator {
    static func validate(_ board: SudokuBoard) -> SudokuValidationResult {
        var issues: [SudokuValidationIssue] = []

        guard board.cells.count == SudokuBoard.dimension,
              board.cells.allSatisfy({ $0.count == SudokuBoard.dimension }) else {
            let issue = SudokuValidationIssue(scope: .cell, index: 0, message: "Sudoku must have a 9×9 grid.", coordinates: [])
            return SudokuValidationResult(issues: [issue], isComplete: false, hasEntries: false)
        }

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

        return SudokuValidationResult(issues: issues, isComplete: board.isComplete, hasEntries: board.filledCount > 0)
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
        var firstSolution: [[Int]]?
        var firstSteps: [SudokuSolveStep] = []
        var currentSteps: [SudokuSolveStep] = []
        var solutionCount = 0
        var interrupted = false
        var nodes = 0
        let deadline = start.addingTimeInterval(options.timeout)

        search(values: &values, steps: &currentSteps, nodes: &nodes, maxNodes: options.maxNodes, deadline: deadline, solutionCount: &solutionCount, firstSolution: &firstSolution, firstSteps: &firstSteps, interrupted: &interrupted)
        if interrupted {
            let reason = Date() >= deadline
                ? "Sudoku solve exceeded \(options.timeout)s timeout."
                : "Sudoku solve exceeded \(options.maxNodes) node safety limit."
            return finish(.timedOut, initialBoard: board, solvedBoard: nil, steps: [], reason: reason, start: start, nodes: nodes)
        }
        if solutionCount >= 2 {
            return finish(.multipleSolutions, initialBoard: board, solvedBoard: nil, steps: [], reason: SolveState.multipleSolutions.friendlyMessage, start: start, nodes: nodes)
        }
        if solutionCount == 1, let firstSolution {
            let givens = Set(board.cells.enumerated().flatMap { rowIndex, row in
                row.enumerated().compactMap { columnIndex, cell in
                    cell.isGiven ? LogicGridCoordinate(row: rowIndex, column: columnIndex) : nil
                }
            })
            return finish(.solved, initialBoard: board, solvedBoard: SudokuBoard(values: firstSolution.map { $0.map { Optional($0) } }, givens: givens), steps: firstSteps, reason: nil, start: start, nodes: nodes)
        }
        return finish(.unsolvable, initialBoard: board, solvedBoard: nil, steps: [], reason: "No solution exists for this Sudoku.", start: start, nodes: nodes)
    }

    private func search(values: inout [[Int]], steps: inout [SudokuSolveStep], nodes: inout Int, maxNodes: Int, deadline: Date, solutionCount: inout Int, firstSolution: inout [[Int]]?, firstSteps: inout [SudokuSolveStep], interrupted: inout Bool) {
        guard solutionCount < 2, !interrupted else { return }
        guard !Task.isCancelled else { interrupted = true; return }
        guard let candidate = bestEmptyCell(in: values) else {
            solutionCount += 1
            if firstSolution == nil {
                firstSolution = values
                firstSteps = steps
            }
            return
        }
        guard Date() < deadline, nodes < maxNodes else { interrupted = true; return }
        let coordinate = candidate.coordinate

        for value in candidate.values {
            guard solutionCount < 2, !interrupted else { return }
            guard !Task.isCancelled else { interrupted = true; return }
            nodes += 1
            values[coordinate.row][coordinate.column] = value
            steps.append(SudokuSolveStep(coordinate: coordinate, value: value))
            search(values: &values, steps: &steps, nodes: &nodes, maxNodes: maxNodes, deadline: deadline, solutionCount: &solutionCount, firstSolution: &firstSolution, firstSteps: &firstSteps, interrupted: &interrupted)
            steps.removeLast()
            values[coordinate.row][coordinate.column] = 0
        }
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

import Foundation

enum LogicPuzzleType: String, CaseIterable, Identifiable {
    case sudoku
    case killerSudoku
    case nonogram
    case kakuro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sudoku:
            return "Sudoku"
        case .killerSudoku:
            return "Killer Sudoku"
        case .nonogram:
            return "Nonogram"
        case .kakuro:
            return "Kakuro"
        }
    }

    var icon: String {
        switch self {
        case .sudoku:
            return "number.square.fill"
        case .killerSudoku:
            return "flame.fill"
        case .nonogram:
            return "square.grid.4x3.fill"
        case .kakuro:
            return "plus.forwardslash.minus"
        }
    }

    var isEnabled: Bool {
        self == .sudoku
    }

    var availabilitySubtitle: String {
        isEnabled ? "Ready now" : "Coming soon"
    }
}

struct LogicSolutionStep: Identifiable, Equatable {
    let id: UUID
    let title: String
    let details: String

    init(id: UUID = UUID(), title: String, details: String) {
        self.id = id
        self.title = title
        self.details = details
    }
}

enum LogicValidationError: LocalizedError, Equatable {
    case invalidInput(message: String)
    case conflictingValues(message: String)
    case unsupportedConfiguration(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message), .conflictingValues(let message), .unsupportedConfiguration(let message):
            return message
        }
    }
}

enum LogicSolveValidity: Equatable {
    case valid
    case invalid([LogicValidationError])
}

enum LogicSolveCompletion: Equatable {
    case solved
    case unsolved
}

struct LogicSolveResult<Output> {
    let puzzleType: LogicPuzzleType
    let validity: LogicSolveValidity
    let completion: LogicSolveCompletion
    let output: Output?
    let messages: [String]
    let steps: [LogicSolutionStep]?

    var isValid: Bool {
        if case .valid = validity { return true }
        return false
    }

    var isSolved: Bool {
        completion == .solved
    }
}

/// Reusable 9×9 Sudoku board model.
///
/// - Uses a flat 81-cell backing store to keep indexing cheap.
/// - Empty cells are represented by `0`.
/// - Suitable for SwiftUI editing via `setValue(_:row:column:)` and `subscript(row:column:)`.
struct SudokuGrid: Equatable, Hashable {
    static let rowCount = 9
    static let columnCount = 9
    static let boxSize = 3
    static let cellCount = 81
    static let validValues = 1...9

    private(set) var cells: [Int]

    init(cells: [Int] = Array(repeating: 0, count: SudokuGrid.cellCount)) {
        if SudokuGrid.isValidCellPayload(cells) {
            self.cells = cells
        } else {
            self.cells = Array(repeating: 0, count: SudokuGrid.cellCount)
        }
    }

    init?(rows: [[Int]]) {
        guard rows.count == SudokuGrid.rowCount,
              rows.allSatisfy({ $0.count == SudokuGrid.columnCount }) else {
            return nil
        }

        self.init(cells: rows.flatMap { $0 })
        guard SudokuGrid.isValidCellPayload(self.cells) else {
            return nil
        }
    }

    subscript(row row: Int, column column: Int) -> Int {
        get {
            guard let index = indexFor(row: row, column: column) else { return 0 }
            return cells[index]
        }
        set {
            _ = setValue(newValue, row: row, column: column)
        }
    }

    mutating func setValue(_ value: Int, row: Int, column: Int) -> Bool {
        guard let index = indexFor(row: row, column: column),
              value == 0 || SudokuGrid.validValues.contains(value) else {
            return false
        }

        cells[index] = value
        return true
    }

    func row(_ row: Int) -> [Int] {
        guard row >= 0, row < SudokuGrid.rowCount else { return [] }
        let start = row * SudokuGrid.columnCount
        return Array(cells[start..<(start + SudokuGrid.columnCount)])
    }

    func column(_ column: Int) -> [Int] {
        guard column >= 0, column < SudokuGrid.columnCount else { return [] }
        return (0..<SudokuGrid.rowCount).map { row in
            cells[(row * SudokuGrid.columnCount) + column]
        }
    }

    func box(containingRow row: Int, column: Int) -> [Int] {
        guard row >= 0, row < SudokuGrid.rowCount,
              column >= 0, column < SudokuGrid.columnCount else {
            return []
        }

        let boxStartRow = (row / SudokuGrid.boxSize) * SudokuGrid.boxSize
        let boxStartColumn = (column / SudokuGrid.boxSize) * SudokuGrid.boxSize

        var values: [Int] = []
        values.reserveCapacity(SudokuGrid.cellCount)

        for rowOffset in 0..<SudokuGrid.boxSize {
            for colOffset in 0..<SudokuGrid.boxSize {
                let currentRow = boxStartRow + rowOffset
                let currentColumn = boxStartColumn + colOffset
                values.append(self[row: currentRow, column: currentColumn])
            }
        }

        return values
    }

    func canPlace(_ value: Int, row: Int, column: Int) -> Bool {
        guard let index = indexFor(row: row, column: column),
              SudokuGrid.validValues.contains(value) else {
            return false
        }

        var board = cells
        board[index] = 0

        let rowValues = (0..<SudokuGrid.columnCount).map { board[(row * SudokuGrid.columnCount) + $0] }
        if rowValues.contains(value) {
            return false
        }

        let columnValues = (0..<SudokuGrid.rowCount).map { board[($0 * SudokuGrid.columnCount) + column] }
        if columnValues.contains(value) {
            return false
        }

        let boxStartRow = (row / SudokuGrid.boxSize) * SudokuGrid.boxSize
        let boxStartColumn = (column / SudokuGrid.boxSize) * SudokuGrid.boxSize

        for rowOffset in 0..<SudokuGrid.boxSize {
            for columnOffset in 0..<SudokuGrid.boxSize {
                let candidate = board[((boxStartRow + rowOffset) * SudokuGrid.columnCount) + (boxStartColumn + columnOffset)]
                if candidate == value {
                    return false
                }
            }
        }

        return true
    }

    func emptyCellIndices() -> [Int] {
        cells.enumerated().compactMap { index, value in
            value == 0 ? index : nil
        }
    }

    func emptyCells() -> [(row: Int, column: Int)] {
        emptyCellIndices().map { index in
            (row: index / SudokuGrid.columnCount, column: index % SudokuGrid.columnCount)
        }
    }

    func isValidBoard() -> Bool {
        rowsAreValid && columnsAreValid && boxesAreValid
    }

    var isSolved: Bool {
        !cells.contains(0) && isValidBoard()
    }

    func rows() -> [[Int]] {
        (0..<SudokuGrid.rowCount).map(row)
    }

    private var rowsAreValid: Bool {
        (0..<SudokuGrid.rowCount).allSatisfy { row in
            isUnitValid(self.row(row))
        }
    }

    private var columnsAreValid: Bool {
        (0..<SudokuGrid.columnCount).allSatisfy { column in
            isUnitValid(self.column(column))
        }
    }

    private var boxesAreValid: Bool {
        stride(from: 0, to: SudokuGrid.rowCount, by: SudokuGrid.boxSize).allSatisfy { row in
            stride(from: 0, to: SudokuGrid.columnCount, by: SudokuGrid.boxSize).allSatisfy { column in
                isUnitValid(box(containingRow: row, column: column))
            }
        }
    }

    private func isUnitValid(_ values: [Int]) -> Bool {
        let nonEmpty = values.filter { $0 != 0 }
        return Set(nonEmpty).count == nonEmpty.count
    }

    private func indexFor(row: Int, column: Int) -> Int? {
        guard row >= 0, row < SudokuGrid.rowCount,
              column >= 0, column < SudokuGrid.columnCount else {
            return nil
        }

        return row * SudokuGrid.columnCount + column
    }

    private static func isValidCellPayload(_ cells: [Int]) -> Bool {
        cells.count == SudokuGrid.cellCount && cells.allSatisfy { $0 == 0 || SudokuGrid.validValues.contains($0) }
    }
}

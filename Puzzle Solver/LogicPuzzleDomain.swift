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
    struct Cell: Identifiable, Hashable {
        let index: Int
        let row: Int
        let column: Int
        var value: Int

        var id: Int { index }
        var isEmpty: Bool { value == SudokuGrid.emptyValue }
    }

    static let rowCount = 9
    static let columnCount = 9
    static let boxSize = 3
    static let cellCount = 81
    static let emptyValue = 0
    static let validValues = 1...9

    private(set) var cells: [Int]

    init(cells: [Int] = Array(repeating: SudokuGrid.emptyValue, count: SudokuGrid.cellCount)) {
        if SudokuGrid.isValidCellPayload(cells) {
            self.cells = cells
        } else {
            self.cells = Array(repeating: SudokuGrid.emptyValue, count: SudokuGrid.cellCount)
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

    func displayCells() -> [Cell] {
        cells.enumerated().map { index, value in
            Cell(
                index: index,
                row: index / SudokuGrid.columnCount,
                column: index % SudokuGrid.columnCount,
                value: value
            )
        }
    }

    mutating func setValue(_ value: Int, row: Int, column: Int) -> Bool {
        guard let index = indexFor(row: row, column: column),
              value == SudokuGrid.emptyValue || SudokuGrid.validValues.contains(value) else {
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

    func box(_ boxIndex: Int) -> [Int] {
        guard boxIndex >= 0, boxIndex < SudokuGrid.columnCount else { return [] }
        let row = (boxIndex / SudokuGrid.boxSize) * SudokuGrid.boxSize
        let column = (boxIndex % SudokuGrid.boxSize) * SudokuGrid.boxSize
        return box(containingRow: row, column: column)
    }

    func box(containingRow row: Int, column: Int) -> [Int] {
        guard row >= 0, row < SudokuGrid.rowCount,
              column >= 0, column < SudokuGrid.columnCount else {
            return []
        }

        let boxStartRow = (row / SudokuGrid.boxSize) * SudokuGrid.boxSize
        let boxStartColumn = (column / SudokuGrid.boxSize) * SudokuGrid.boxSize

        var values: [Int] = []
        values.reserveCapacity(SudokuGrid.boxSize * SudokuGrid.boxSize)

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
        board[index] = SudokuGrid.emptyValue

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
            value == SudokuGrid.emptyValue ? index : nil
        }
    }

    func emptyCells() -> [(row: Int, column: Int)] {
        emptyCellIndices().map { index in
            (row: index / SudokuGrid.columnCount, column: index % SudokuGrid.columnCount)
        }
    }

    func firstEmptyCell() -> (row: Int, column: Int)? {
        emptyCells().first
    }

    func isValidBoard() -> Bool {
        rowsAreValid && columnsAreValid && boxesAreValid
    }

    func isPlacementValid(value: Int, row: Int, column: Int) -> Bool {
        canPlace(value, row: row, column: column)
    }

    var isSolved: Bool {
        !cells.contains(SudokuGrid.emptyValue) && isValidBoard()
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
        let nonEmpty = values.filter { $0 != SudokuGrid.emptyValue }
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
        cells.count == SudokuGrid.cellCount && cells.allSatisfy { $0 == SudokuGrid.emptyValue || SudokuGrid.validValues.contains($0) }
    }
}


struct SudokuSolver {
    func solve(_ initialGrid: SudokuGrid) -> LogicSolveResult<SudokuGrid> {
        guard initialGrid.isValidBoard() else {
            return LogicSolveResult(
                puzzleType: .sudoku,
                validity: .invalid([.conflictingValues(message: "The starting Sudoku grid has conflicting values.")]),
                completion: .unsolved,
                output: nil,
                messages: ["Fix duplicate values in a row, column, or 3×3 box and try again."],
                steps: nil
            )
        }

        var working = initialGrid
        if backtrackSolve(&working) {
            return LogicSolveResult(
                puzzleType: .sudoku,
                validity: .valid,
                completion: .solved,
                output: working,
                messages: ["Sudoku solved."],
                steps: nil
            )
        }

        return LogicSolveResult(
            puzzleType: .sudoku,
            validity: .valid,
            completion: .unsolved,
            output: nil,
            messages: ["No solution exists for this Sudoku configuration."],
            steps: nil
        )
    }

    func solveOffMainThread(_ initialGrid: SudokuGrid) async -> LogicSolveResult<SudokuGrid> {
        await Task.detached(priority: .userInitiated) {
            solve(initialGrid)
        }.value
    }

    private func backtrackSolve(_ grid: inout SudokuGrid) -> Bool {
        guard let nextCell = selectMostConstrainedEmptyCell(in: grid) else {
            return true
        }

        let row = nextCell.row
        let column = nextCell.column
        let candidates = validCandidates(in: grid, row: row, column: column)

        if candidates.isEmpty {
            return false
        }

        for candidate in candidates {
            grid.setValue(candidate, row: row, column: column)

            if backtrackSolve(&grid) {
                return true
            }

            grid.setValue(SudokuGrid.emptyValue, row: row, column: column)
        }

        return false
    }

    private func selectMostConstrainedEmptyCell(in grid: SudokuGrid) -> (row: Int, column: Int)? {
        var bestCell: (row: Int, column: Int)?
        var bestCandidateCount = Int.max

        for (row, column) in grid.emptyCells() {
            let candidateCount = validCandidates(in: grid, row: row, column: column).count

            if candidateCount < bestCandidateCount {
                bestCandidateCount = candidateCount
                bestCell = (row, column)

                if candidateCount == 1 {
                    break
                }
            }
        }

        return bestCell
    }

    private func validCandidates(in grid: SudokuGrid, row: Int, column: Int) -> [Int] {
        SudokuGrid.validValues.filter { value in
            grid.canPlace(value, row: row, column: column)
        }
    }
}

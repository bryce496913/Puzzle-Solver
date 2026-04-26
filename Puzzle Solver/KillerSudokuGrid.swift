import Foundation

/// Placeholder model for a Killer Sudoku board.
///
/// Future behavior:
/// - Stores the 9×9 Sudoku values (using `0` for empty cells).
/// - Stores cage definitions and their target sums.
/// - Enforces no duplicate digits inside each cage.
/// - Enforces standard Sudoku constraints (rows, columns, and 3×3 boxes).
struct KillerSudokuGrid: Equatable, Hashable {
    static let rowCount = 9
    static let columnCount = 9
    static let cellCount = 81
    static let emptyValue = 0

    private(set) var cells: [Int]
    private(set) var cages: [KillerSudokuCage]

    init(
        cells: [Int] = Array(repeating: KillerSudokuGrid.emptyValue, count: KillerSudokuGrid.cellCount),
        cages: [KillerSudokuCage] = []
    ) {
        self.cells = cells.count == KillerSudokuGrid.cellCount ? cells : Array(repeating: KillerSudokuGrid.emptyValue, count: KillerSudokuGrid.cellCount)
        self.cages = cages
    }
}

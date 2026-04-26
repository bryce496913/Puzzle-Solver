import Foundation

/// Represents the possible state of a Nonogram cell.
///
/// Future behavior:
/// - `filled` means the cell is confirmed as part of the final picture.
/// - `empty` means the cell is confirmed blank.
/// - `unknown` means solving has not yet determined the cell.
enum NonogramCellState: String, Codable, CaseIterable {
    case unknown
    case filled
    case empty
}

/// Placeholder grid model for a future Nonogram workflow.
///
/// Future behavior:
/// - stores grid dimensions and clue metadata.
/// - stores editable cell states while users solve.
/// - supports row/column consistency checks against clues.
struct NonogramGrid: Equatable {
    let rowCount: Int
    let columnCount: Int
    var clues: NonogramClues
    var cells: [NonogramCellState]

    init(
        rowCount: Int = 0,
        columnCount: Int = 0,
        clues: NonogramClues = NonogramClues(),
        cells: [NonogramCellState] = []
    ) {
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.clues = clues
        self.cells = cells
    }
}

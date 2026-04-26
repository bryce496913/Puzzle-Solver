import Foundation

/// Placeholder model for Nonogram clues.
///
/// Future behavior:
/// - `rowClues` will define contiguous filled runs for each row.
/// - `columnClues` will define contiguous filled runs for each column.
/// - Validation should ensure clue counts match the configured grid dimensions.
struct NonogramClues: Equatable {
    /// Each inner array describes one row's clue runs (for example, `[3, 1]`).
    let rowClues: [[Int]]

    /// Each inner array describes one column's clue runs (for example, `[2, 2]`).
    let columnClues: [[Int]]

    init(rowClues: [[Int]] = [], columnClues: [[Int]] = []) {
        self.rowClues = rowClues
        self.columnClues = columnClues
    }
}

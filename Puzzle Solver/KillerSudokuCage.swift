import Foundation

/// Represents a Killer Sudoku cage.
///
/// Future behavior:
/// - A cage groups a set of cells that share a required target sum.
/// - Digits may not repeat within the same cage.
/// - Cage validation will be combined with normal Sudoku validation.
struct KillerSudokuCage: Equatable, Hashable, Identifiable {
    struct Coordinate: Equatable, Hashable {
        let row: Int
        let column: Int
    }

    let id: UUID
    let sum: Int
    let cells: [Coordinate]

    init(id: UUID = UUID(), sum: Int, cells: [Coordinate]) {
        self.id = id
        self.sum = sum
        self.cells = cells
    }
}

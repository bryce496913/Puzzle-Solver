import Foundation

/// Placeholder model for a Kakuro board.
///
/// Future behavior:
/// - Store blocked/clue cells and playable digit cells in a single board representation.
/// - Model across and down clue runs so each run can be validated independently.
/// - Enforce digit constraints (`1...9`) for playable cells and `0` for empty entries.
/// - Enforce no repeated digits in each clue run (across and down).
struct KakuroGrid: Equatable, Hashable {
    static let minimumDigit = 1
    static let maximumDigit = 9
    static let emptyValue = 0

    /// Placeholder flat store for playable values.
    ///
    /// Future behavior:
    /// - Map values to playable coordinates only.
    /// - Ignore blocked/clue cells when reading/writing digit values.
    private(set) var values: [Int]

    /// Placeholder set of clue cells keyed by row/column coordinates.
    ///
    /// Future behavior:
    /// - Use this to compute across and down runs and their required sums.
    private(set) var clueCells: [Coordinate: KakuroClueCell]

    init(values: [Int] = [], clueCells: [Coordinate: KakuroClueCell] = [:]) {
        self.values = values
        self.clueCells = clueCells
    }
}

extension KakuroGrid {
    struct Coordinate: Equatable, Hashable {
        let row: Int
        let column: Int
    }
}

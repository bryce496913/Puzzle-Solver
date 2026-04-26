import Foundation

/// Represents a Kakuro clue cell (a blocked cell with optional clue sums).
///
/// Future behavior:
/// - `acrossSum` defines the target sum for the horizontal (across) run to the right.
/// - `downSum` defines the target sum for the vertical (down) run below.
/// - A clue cell itself cannot hold a digit; it only constrains adjacent digit cells.
struct KakuroClueCell: Equatable, Hashable, Identifiable {
    let id: UUID
    let acrossSum: Int?
    let downSum: Int?

    init(id: UUID = UUID(), acrossSum: Int? = nil, downSum: Int? = nil) {
        self.id = id
        self.acrossSum = acrossSum
        self.downSum = downSum
    }
}

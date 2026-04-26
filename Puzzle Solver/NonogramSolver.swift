import Foundation

/// Placeholder solver for future Nonogram support.
///
/// Future behavior:
/// - apply constraint solving across row clues and column clues.
/// - iteratively narrow cell states (`filled` / `empty` / `unknown`).
/// - produce explainable solving steps for the UI.
struct NonogramSolver {
    func solve(_ puzzle: NonogramPuzzle) -> LogicSolveResult<NonogramPuzzle> {
        LogicSolveResult(
            puzzleType: .nonogram,
            validity: .invalid([
                .unsupportedConfiguration(message: "Nonogram solving is not available yet.")
            ]),
            completion: .unsolved,
            output: nil,
            messages: ["Nonogram solver is a placeholder for now."],
            steps: nil
        )
    }
}

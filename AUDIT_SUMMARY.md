# Stabilization audit

## Repository map

- **Entry and launch:** `Puzzle_SolverApp.swift` is the `@main` entry point. Before this pass it immediately created `ContentView`; `ContentView` overlaid a timed splash on already-created main/onboarding content.
- **Navigation:** `ContentView` owns the single root `NavigationView`; `MainMenuView` routes to category/input screens. The splash is root content, not a navigation destination.
- **Sudoku:** `LogicPuzzleModels.swift` contains the board, validator, and bounded backtracking solver; `LogicPuzzleViews.swift` contains manual entry/review. Photo scanning had been deliberately reverted and the catalog marked it coming soon, although the history contained a local Vision pipeline. This pass restores and hardens that pipeline in `SudokuImageImport.swift`.
- **Twisty puzzles:** `PuzzleSolver.swift` is the canonical shared twisty domain, notation parser, sticker validators, move engines, and 2×2/3×3 solvers. The older cube names in that file are compatibility type aliases, not a second implementation. Other twisty types are explicitly unavailable placeholders.
- **Tests:** the Xcode project already has unit and UI-test targets. Tests were concentrated in one large unit-test file; no external twisty fixture catalog or scanner image fixtures existed. UI tests were generated placeholders.

## Cleanup and risk findings

- AppleDouble `._*` files and `.idea` metadata are unreferenced machine artifacts. They are excluded/removed rather than treated as source.
- The prior splash used uncancellable `DispatchQueue.asyncAfter`, could schedule repeatedly on appearance, and instantiated the main navigation underneath the splash.
- The reverted scanner accepted the whole image as a board when rectangle detection failed. That could silently map surrounding text into cells. The restored detector now requires a real quadrilateral.
- Sudoku board construction normalizes external arrays to 9×9, and validation detects row, column, box, and value conflicts. The scan-result mapper previously trusted OCR coordinates before indexing.
- `PuzzleSolver.swift` contains a force unwrap for an internal move-table dictionary built exhaustively from `Cube3x3Move.allCases`; this is a documented internal invariant, not user-controlled indexing. Existing views contain bounded index access in several performance-oriented grids.
- Placeholder implementations remain for cataloged future puzzle types. They return explicit unsupported results and are still referenced by availability/tests, so deletion would change public behavior.
- No UIKit root-controller replacement, `UIApplication.shared.windows`, secrets, or network OCR dependency was found.
- Build warnings could not be enumerated in this Linux container because Xcode is not installed.

## Affected systems

1. Launch ownership and deterministic transition: `Puzzle_SolverApp.swift`, `ContentView.swift`.
2. Scanner preprocessing, rectangle/perspective correction, segmentation, Vision OCR, confidence/review state, permissions, and editable review: `SudokuImageImport.swift`, `LogicPuzzleViews.swift`, project settings.
3. Twisty fixture organization and replay/notation/limit coverage: `Puzzle SolverTests/Fixtures`, `StabilizationTests.swift`.
4. Repository hygiene: AppleDouble and IDE artifacts.

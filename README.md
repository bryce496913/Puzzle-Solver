# Puzzle Solver

Puzzle Solver is a SwiftUI app for iPhone that provides a focused set of puzzle solvers. The lists below mirror the production `PuzzleAvailabilityCatalog`: **Available in V1** means the puzzle has a user-accessible input and solve flow, while **Coming Soon** means it is listed in the app but cannot be opened as a solver.

## Available in V1

The V1 contract contains exactly **nine active modes**.

| Category | Puzzle | Production behavior |
| --- | --- | --- |
| Sliding | 3×3 Sliding Puzzle | Enter the eight numbered tiles and blank, validate solvability, and view ordered solution playback. |
| Sliding | 4×4 Sliding Puzzle | Enter a board and run bounded, memory-conscious search with explicit timeout/limit feedback. |
| Sliding | 5×5 Sliding Puzzle | Enter a board and receive a result within the configured search safety limits; difficult layouts may stop without a solution rather than search indefinitely. |
| Twisty | 2×2 Cube | Enter stickers with guided or net input and solve bounded scrambles. Sticker counts and physical cubie constraints are validated, so impossible 2×2 states are rejected. |
| Twisty | 3×3 Rubik’s Cube | Enter a physical cube face by face or as a net, then solve it with the bounded two-phase solver. |
| Logic | Sudoku | Enter givens manually, check row/column/box conflicts, and solve with bounded feedback. An example board and solution display are included. |
| Logic | Sudoku Photo Scan | Capture or import a Sudoku on device, review every recognized clue, and continue through the production solve flow. |
| Logic | Killer Sudoku | Build sum cages, validate complete coverage, and solve while preserving the cage constraints. |
| Mechanical | Rush Hour | Build or load a 6×6 vehicle layout, validate it, and search for an ordered escape solution. |

All active searches use time, depth, node, or memory safeguards appropriate to the solver. An active catalog entry therefore means that its production flow is available—not that every valid, arbitrarily difficult input is guaranteed to finish with a solution.

## Coming Soon

These 12 entries are visible through the app's **Coming Soon** screen and are not production solver flows in V1:

- **Twisty:** Pyraminx, Skewb, Megaminx, and Square-1.
- **Logic:** Nonogram, Kakuro, and Slitherlink.
- **Mechanical:** Klotski and Peg Solitaire.
- **Visual / Experimental:** Maze, Chess, and Jigsaw.

## Using the App

1. Choose one of the four production categories: Sliding, Twisty, Logic, or Mechanical.
2. Select an active puzzle. Category screens are generated from active catalog entries only.
3. Enter a state or load an included example, validate it, and start the solver.
4. Review the result, ordered moves, or playback offered by that puzzle's flow. If a safety limit is reached, the app reports that outcome instead of continuing an unbounded search.

The separate **Coming Soon** screen groups every planned catalog entry by category so unavailable modes are not presented as active controls.

## Requirements and Local Development

- macOS with Xcode and an iOS Simulator, or an iPhone configured for local development.
- The app target is configured for iOS 16.0 or later.
- Swift 5 language mode is configured in the Xcode project.

To build locally:

1. Clone or download the repository.
2. Open `Puzzle Solver.xcodeproj` in Xcode.
3. Select the shared **Puzzle Solver** scheme and an iOS 16+ simulator or device.
4. Build and run.

The project has no third-party package dependency required by the production app.

## Architecture and Development-Only Work

The production UI derives availability from `PuzzleAvailabilityCatalog`, which is the source of truth for whether a mode is active or Coming Soon. Shared result types give active solvers explicit success, validation, timeout, unsolvable, unsupported, and failure outcomes.

The repository also retains model-layer and experimental code for future modes. This code is useful for continued development and tests, but its presence does not make a puzzle available in V1:

- Larger cube and other twisty-puzzle types include placeholder architecture or unavailable-result paths.
- Nonogram, Kakuro, Slitherlink, Klotski, and Peg Solitaire have varying amounts of model or solver groundwork while remaining outside production navigation.
- Reusable graph search plus maze, chess, and jigsaw models live in the experimental layer; all three remain Coming Soon.

## Testing and CI

The XCTest target covers catalog status, validation, representative solver outcomes, safety limits, move playback, and model-layer work. The XCUITest target includes launch and production-flow checks, including verification of the Sudoku photo-scan and review flow. Test coverage describes exercised behavior; it is not a guarantee that every possible puzzle state can be solved within V1 limits.

The repository's GitHub Actions workflow builds Debug and Release simulator configurations and runs the unit-test target on pushes and pull requests to `main`. UI tests are maintained separately but are not run by that workflow.

## Privacy

Production puzzle entry and solving happen on device and do not require an account or network service. The privacy manifest declares UserDefaults access used for lightweight settings such as appearance and onboarding state. Sudoku Photo Scan requests camera or photo-library access only when the user chooses the corresponding on-device import action; puzzle data does not leave the device.

## Contributing

Contributions are welcome. When activating a puzzle, update `PuzzleAvailabilityCatalog`, production navigation, tests, and this README together so repository experiments are never mistaken for shipping features.

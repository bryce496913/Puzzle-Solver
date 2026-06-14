# Puzzle Solver — App Release Readiness Report

## Cleanup status

- Release-label wording has been removed from the user-facing app, including onboarding, menus, Settings, helper text, result screens, placeholders, and diagnostics.
- The real bundle version remains visible in Settings as `Version <short version> (<build>)`.
- Rush Hour has been rebuilt as a user-generated puzzle builder with validation, bounded background solving, and ordered solution playback.

## Active puzzle list

- 3×3 Sliding Puzzle
- 4×4 Sliding Puzzle
- 5×5 Sliding Puzzle
- 2×2 Cube
- 3×3 Rubik’s Cube
- Sudoku
- Rush Hour
- Settings
- Coming Soon

No deferred puzzle modes were reactivated.

## Coming Soon puzzle list

- Pyraminx
- Skewb
- Megaminx
- Square-1
- Killer Sudoku
- Nonogram
- Kakuro
- Slitherlink
- Klotski
- Peg Solitaire
- Maze Solver
- Chess Puzzles
- Jigsaw Solver

## Rush Hour rebuilt status

- Uses a dedicated 6×6 board, vehicle, move, solution-step, solve-result, and solver model.
- Supports horizontal and vertical vehicles of length 2 or 3.
- Supports exactly one horizontal red target car and a visible right-side exit on its row.
- Rejects duplicate identifiers, overlap, out-of-bounds placement, invalid lengths, missing targets, multiple targets, and vertical targets.
- Allows adding, selecting, and removing vehicles; resetting the board; validating; and loading a built-in example.
- Renders each vehicle as one connected rounded rectangle spanning its occupied cells.
- Uses breadth-first search to return a shortest path when one is found.
- Generates every legal slide distance in each allowed direction.
- Solves on a background queue and publishes UI state on the main queue.
- Enforces timeout and maximum-state limits.
- Shows only the successful ordered solution, with move count, move list, board preview, Previous, Next, and Restart controls.
- Includes a valid example puzzle intended to solve quickly as a smoke test.

## Known limitations

- The builder places new vehicles from the tapped top-left cell; moving or rotating an existing vehicle requires removing and re-adding it.
- Vehicle labels are automatically assigned.
- Search is intentionally bounded. Very complex user-created boards can time out or reach the state safety limit.
- Result playback is manual rather than automatically animated.
- Simulator visual smoke testing and App Store archive validation still require a macOS/Xcode environment when unavailable in CI.

## QA notes

- Confirm the active catalog remains limited to the approved seven puzzle solvers.
- Confirm all Coming Soon routes remain placeholders and expose no solve action.
- Confirm an empty Rush Hour board cannot be solved.
- Confirm adding a horizontal length-2 target and vertical blockers works.
- Confirm overlap and out-of-bounds placement display friendly validation messages.
- Confirm only one target is accepted and a vertical target fails validation.
- Confirm Load Example, Validate, Solve Rush Hour, ordered moves, and playback controls work.
- Confirm solving always leaves the loading state through solved, invalid, no-solution, timed-out, or failed handling.
- Confirm Settings, Coming Soon, onboarding, and the active puzzle menus still open.
- Run unit tests, a clean app build, simulator smoke testing, and archive validation before submission.

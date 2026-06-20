# Puzzle Solver — App Release Readiness Report

## Cleanup status

- Release-label wording has been removed from the user-facing app, including onboarding, menus, Settings, helper text, result screens, placeholders, and diagnostics.
- The real bundle version remains visible in Settings as `Version <short version> (<build>)`.
- Rush Hour has been rebuilt as a user-generated puzzle builder with validation, bounded background solving, and ordered solution playback.
- Sliding puzzle and Sudoku V1 behavior has been tightened so active modes either solve safely or show clear bounded feedback.

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

## Sliding puzzle V1 status

- 3×3 Sliding Puzzle remains active with ordered solution playback.
- 4×4 Sliding Puzzle now reuses the shared sliding puzzle playback UI with animated board transitions, step count, total steps, move count, current move label, Play, Pause, Next, Previous, and Restart controls.
- 4×4 playback uses only the successful solution path returned by the bounded IDA* solver and does not expose explored states or debug output.
- 5×5 Sliding Puzzle remains visible as an active V1 puzzle with a bounded IDA* Manhattan solver, solvability checks, background solving, timeout protection, node/depth safety limits, and successful-path-only output.
- 5×5 timeout/failure feedback is intentionally friendly: “This 5×5 puzzle is too complex to solve quickly. Try a puzzle closer to solved.”
- 5×5 includes a quick solvable Load Example with the blank and 24 one legal move from solved.
- Sliding playback supports variable board sizes; 5×5 tile labels use a compact layout and the blank renders as an empty cell rather than overflowing text.

## Sudoku V1 status

- Sudoku selection feedback has been strengthened for the dark theme.
- The selected cell receives the strongest highlight.
- The selected row, column, and 3×3 box receive softer related-cell highlights.
- Matching values are highlighted when the selected cell has a number.
- A selected-cell label shows the active row and column so keypad and clear/delete input clearly target one cell.
- Existing Sudoku validation, input, and solver behavior are preserved.

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

- Sliding puzzle search is intentionally bounded. Deep 4×4 or 5×5 scrambles can time out by design instead of hanging the app.
- 5×5 solving is practical for near-solved examples and safer than an unbounded search, but arbitrary 24-puzzle scrambles may exceed the V1 safety limits.
- The Rush Hour builder places new vehicles from the tapped top-left cell; moving or rotating an existing vehicle requires removing and re-adding it.
- Rush Hour vehicle labels are automatically assigned.
- Rush Hour result playback is manual rather than automatically animated.
- Simulator visual smoke testing and App Store archive validation still require a macOS/Xcode environment when unavailable in CI.

## QA notes

- Confirm the active catalog remains limited to the approved seven puzzle solvers.
- Confirm all Coming Soon routes remain placeholders and expose no solve action.
- Confirm 4×4 Sliding Puzzle opens, accepts valid input, solves the quick example, and shows animated playback controls.
- Confirm 5×5 Sliding Puzzle opens, accepts valid input, validates solvability, solves the one-move example or fails gracefully for complex boards, and never hangs.
- Confirm 5×5 blank tiles render compactly without overflowing “Empty” text.
- Confirm Sudoku opens, selected cell/row/column/box highlights are visible, keypad updates the selected cell, and solver still works.
- Confirm an empty Rush Hour board cannot be solved.
- Confirm adding a horizontal length-2 target and vertical blockers works.
- Confirm overlap and out-of-bounds placement display friendly validation messages.
- Confirm only one target is accepted and a vertical target fails validation.
- Confirm Load Example, Validate, Solve Rush Hour, ordered moves, and playback controls work.
- Confirm solving always leaves the loading state through solved, invalid, no-solution, timed-out, or failed handling.
- Confirm Settings, Coming Soon, onboarding, and the active puzzle menus still open.
- Run unit tests, a clean app build, simulator smoke testing, and archive validation before submission.

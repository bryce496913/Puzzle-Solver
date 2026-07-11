# Puzzle Solver — App Release Readiness Report

## Cleanup status

- Release-label wording has been removed from the user-facing app, including onboarding, menus, Settings, helper text, result screens, placeholders, and diagnostics.
- The real bundle version remains visible in Settings as `Version <short version> (<build>)`.
- Rush Hour has been rebuilt as a user-generated puzzle builder with validation, bounded background solving, and ordered solution playback.
- Sliding puzzle and Sudoku V1 behavior has been tightened so active modes either solve safely or show clear bounded feedback.
- Twisty solving was rebuilt around a shared, validated, asynchronous path for the active 2×2 Cube and 3×3 Rubik’s Cube modes only.

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

No deferred puzzle modes were reactivated. Pyraminx, Skewb, Megaminx, Square-1, 4×4 Cube, and 5×5 Cube are not active twisty solve routes.

## Coming Soon puzzle list

- Killer Sudoku
- Nonogram
- Kakuro
- Slitherlink
- Klotski
- Peg Solitaire
- Maze Solver
- Chess Puzzles
- Jigsaw Solver
- Sudoku Photo Scan

## Twisty puzzle V1 status

- 2×2 Cube remains active with immediate validation, solved-state detection, timeout-guarded depth-limited solving, ordered move output, and no explored-state/debug output in the UI.
- 3×3 Rubik’s Cube remains active in a safe V1 mode: solved cubes and short generated scrambles are supported, while complex states return a clear “solver upgrade in progress” unavailable state instead of running unsafe brute force or hanging.
- Solved 2×2 and solved 3×3 inputs return immediately as `alreadySolved` with 0 moves and the user-facing message “Already solved.”
- Invalid 2×2 and 3×3 inputs fail before solving with friendly reasons for missing stickers, incorrect color counts, or invalid fixed 3×3 centers.
- The shared cube solving service dispatches solver work off the main queue and publishes completion back to SwiftUI, so solving cannot freeze view rendering.
- The cube input/result UI now shows progress text for checking colors, preparing state, solving, timeout, invalid, unavailable, and solved outcomes.
- Timeout is a safety result only after validation/solved checks; solved and invalid cubes no longer report timeout.

## Twisty smoke-test results

- Solved 2×2: expected `alreadySolved`, 0 moves, empty move list.
- Solved 3×3: expected `alreadySolved`, 0 moves, empty move list.
- One-turn 2×2 scramble: expected a real inverse move sequence that returns the sticker state to solved.
- Short 2×2 scramble `R U`: expected a real solution within the configured V1 bounds.
- One-turn 3×3 scramble: expected a real inverse move sequence that returns the sticker state to solved.
- Short 3×3 scramble `R U`: expected a real solution within the safe shallow-search V1 bounds.
- Invalid color count and missing-sticker inputs: expected `invalidInput` before any solve search starts.

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
- Manual Sudoku entry remains the only active Sudoku release flow.
- The active Sudoku screen keeps selected-cell, row, column, 3×3 box, duplicate, and matching-value highlighting.
- Example loading, validation, reset, editing, and solving remain active and unchanged.
- Sudoku Photo Scan has been removed from the active release UI because the image scanner is not reliable enough for App Store release.
- Camera/photo scanning, image import, OCR review, scanner loading states, and scanner error messages are not reachable from the active Sudoku experience.
- The scanner implementation was removed instead of retained because it depended on camera/photo permissions and unfinished OCR UI that should not ship in this release.
- Camera and photo-library usage descriptions were removed from the app target because no active feature uses those permissions.
- Sudoku Photo Scan is listed as Coming Soon only with the description “Scan a paper Sudoku or import a photo to fill the puzzle grid automatically.”

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

- 3×3 Rubik’s Cube complex-state solving is intentionally limited in V1. A complete Kociemba/two-phase solver remains a planned upgrade; unsupported complex states fail safely instead of hanging or pretending to solve.
- Sliding puzzle search is intentionally bounded. Deep 4×4 or 5×5 scrambles can time out by design instead of hanging the app.
- 5×5 solving is practical for near-solved examples and safer than an unbounded search, but arbitrary 24-puzzle scrambles may exceed the V1 safety limits.
- The Rush Hour builder places new vehicles from the tapped top-left cell; moving or rotating an existing vehicle requires removing and re-adding it.
- Rush Hour vehicle labels are automatically assigned.
- Rush Hour result playback is manual rather than automatically animated.
- Simulator visual smoke testing and App Store archive validation still require a macOS/Xcode environment when unavailable in CI.

## QA notes

- Confirm the active catalog remains limited to the approved seven puzzle solvers.
- Confirm no removed twisty puzzle modes expose active solve routes.
- Confirm solved 2×2 returns instantly with “Already solved.”
- Confirm solved 3×3 returns instantly with “Already solved.”
- Confirm invalid cubes fail before solving.
- Confirm simple 2×2 and 3×3 scrambles solve or fail gracefully without freezing.
- Confirm cube loading UI shows progress and no stuck “Solving…” screens remain.
- Confirm timeout appears only when a real solve attempt times out.
- Confirm 4×4 Sliding Puzzle opens, accepts valid input, solves the quick example, and shows animated playback controls.
- Confirm 5×5 Sliding Puzzle opens, accepts valid input, validates solvability, solves the one-move example or fails gracefully for complex boards, and never hangs.
- Confirm 5×5 blank tiles render compactly without overflowing “Empty” text.
- Confirm Sudoku opens, selected cell/row/column/box highlights are visible, keypad updates the selected cell, and solver still works.
- Confirm an empty Rush Hour board cannot be solved.
- Confirm adding a horizontal length-2 target and vertical blockers works.
- Confirm overlap and out-of-bounds placement display friendly validation messages.
- Confirm only one target is accepted and a vertical target fails validation.
- Confirm Load Example, Validate, Solve Rush Hour, ordered moves, and playback controls work.
- Confirm solving always leaves the loading state through solved, already-solved, invalid, no-solution, timed-out, failed, cancelled, or unavailable handling.
- Run unit tests, a clean app build, simulator smoke testing, and archive validation before submission.

## V1 Stability Update — Launch Screen and Sudoku Photo Scan Rollback

### Launch screen configuration
- Confirmed the bundled launch artwork exists at `Assets.xcassets/LaunchScreen.imageset/launch.png` with a valid `Contents.json` that exposes the asset name `launch`.
- Added the app target launch storyboard file `LaunchScreen.storyboard` and configured the generated Info.plist launch storyboard name to `LaunchScreen`.
- The storyboard uses a black full-screen root view and a centered `launch` image view with `scaleAspectFit` and safe-area margins so the artwork remains readable on small, 6.1-inch, and 6.7-inch iPhone portrait launch screens.
- Disabled generated launch-screen configuration to avoid conflicts with the static storyboard launch screen.

### Sudoku Photo Scan release decision
- The recent Sudoku image-upload and photo-scanning rewrite has been rolled back for the current release.
- Active Sudoku is restored to the stable manual implementation: grid entry, keypad input, clear/delete, example loading, validation, solving, solved-result display, reset, and back navigation.
- Scanner UI routes were removed from the release build, including camera/photo picker presentation, OCR review, rescan/retake/choose-another actions, scanner progress copy, and scanner error copy.
- No isolated scanner implementation is retained in the app target for this release; future Sudoku Photo Scan work should restart in an isolated future-feature area before being exposed again.
- Camera and photo-library permissions were removed because no active release feature uses them.
- Sudoku Photo Scan is now represented only as a Coming Soon catalog item under Logic Puzzles.

### Current known limitations
- Sudoku Photo Scan is planned for a future update and is not an active feature.
- Manual Sudoku solving remains available, but users must enter puzzle givens by hand for this release.
- Simulator coverage should still be checked manually across small, 6.1-inch, and 6.7-inch iPhone devices before release because launch-screen rendering is device-size dependent.

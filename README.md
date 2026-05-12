# Puzzle Solver

Puzzle Solver is a Swift application with a shared cube-solving service layer for twisty puzzles.

## Features

- Shared `CubeSolvingService` and `CubeSolverProtocol` abstractions for cube solvers.
- Common `CubeSolveResult` responses for success, invalid input, timeout, unsupported puzzles, and unavailable solvers.
- Bounded 2×2 IDA* solver path with timeout, max-depth, and max-node safety limits.
- Cubie-level 3×3 solver with edge orientation/permutation and corner orientation/permutation tracking, all face turns, validity checks, bounded two-phase search, pruning tables, and timeout handling.
- 4×4 and 5×5 reduction-method placeholders that avoid naive full-state solving.
- UI statuses for Solving…, Invalid cube, Solver unavailable, Could not solve quickly, and Solved.

## Solver Status

| Puzzle | Status |
| --- | --- |
| 2×2 Cube | Bounded IDA* search path available. |
| 3×3 Cube | Cubie-level two-phase solver available with pruning tables and sticker-input UI. |
| 4×4 Cube | Reduction-method placeholder. |
| 5×5 Cube | Reduction-method placeholder. |
| Pyraminx / Skewb | Recognized as future twisty puzzles; unsupported until a solver is registered. |

## Getting Started

1. Clone or download the repository.
2. Open `Puzzle Solver.xcodeproj` in Xcode.
3. Build and run the application on a simulator or device.
4. Open the solver screen to see a guaranteed terminal solve status.

## Contributing

Contributions to improve pruning-table coverage, add more twisty-puzzle solvers, or add reduction-method solvers for larger cubes are welcome.

## Experimental Puzzle Architecture

The experimental layer keeps new puzzle families modular and separate from the established cube, sliding, logic, and mechanical systems.

- `GraphSearch` and `GraphPath` provide reusable breadth-first pathfinding for unweighted puzzle state spaces.
- `VisualPuzzleResult`, `VisualPuzzleStep`, and `VisualPuzzleAnnotation` provide shared result/playback models for grid- and image-oriented solvers.
- `MazeSolver` solves `MazeBoard` layouts with `S` start, `G` goal, `#` walls, and `.` open cells using the shared graph utilities.
- `ChessPuzzleSolver` supports legal-move chess puzzle searches for mate-in-N and material/checkmate-oriented best-move puzzles from `ChessBoard` FEN input.
- `JigsawPuzzleSolver` defines placeholder board, piece, and edge models while returning an unsupported result until image detection and piece-matching heuristics are added.

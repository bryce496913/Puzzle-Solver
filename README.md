# Puzzle Solver

Puzzle Solver is a Swift application with a shared cube-solving service layer for twisty puzzles.

## Features

- Shared `CubeSolvingService` and `CubeSolverProtocol` abstractions for cube solvers.
- Common `CubeSolveResult` responses for success, invalid input, timeout, unsupported puzzles, and unavailable solvers.
- Bounded 2×2 IDA* solver path with timeout, max-depth, and max-node safety limits.
- Safe 3×3 architecture placeholder while a Kociemba two-phase implementation is connected.
- 4×4 and 5×5 reduction-method placeholders that avoid naive full-state solving.
- UI statuses for Solving…, Invalid cube, Solver unavailable, Could not solve quickly, and Solved.

## Solver Status

| Puzzle | Status |
| --- | --- |
| 2×2 Cube | Bounded IDA* search path available. |
| 3×3 Cube | Being upgraded; unavailable instead of running brute-force search. |
| 4×4 Cube | Reduction-method placeholder. |
| 5×5 Cube | Reduction-method placeholder. |
| Pyraminx / Skewb | Recognized as future twisty puzzles; unsupported until a solver is registered. |

## Getting Started

1. Clone or download the repository.
2. Open `Puzzle Solver.xcodeproj` in Xcode.
3. Build and run the application on a simulator or device.
4. Open the solver screen to see a guaranteed terminal solve status.

## Contributing

Contributions to complete the 3×3 Kociemba two-phase adapter, improve 2×2 pruning tables, or add reduction-method solvers for larger cubes are welcome.

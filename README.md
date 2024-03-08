# Puzzle Solver

Puzzle Solver is a Swift application designed to solve classic sliding tile puzzles efficiently using the A* search algorithm with heuristics.

## Features

- Solves sliding tile puzzles with 9 tiles.
- Implements the A* search algorithm from https://holyswift.app/solving-eight-puzzle-with-a-algorithm-in-swift/.
- Provides a graphical user interface (GUI).

## How it Works

1. User sets the locations of the 8 numbers. This is loaded into the **Initial State**
2. **Initial State**: Provide the initial configuration of the puzzle board.
3. **A* Search**: The application uses the A* search algorithm to find the optimal solution to the puzzle.
5. **Interactive Interface**: The GUI displays the current state of the puzzle and the solution path.
6. **Optimization**: The algorithm prioritizes moves based on the chosen heuristic to minimize the number of misplaced tiles.
7. **Solution Path**: Once the solution is found, the app displays the sequence of moves needed to solve the puzzle.

## Getting Started

To get started with the Puzzle Solver app:

1. Clone or download the repository to your local machine.
2. Open the project in Xcode.
3. Build and run the application on a simulator or device.
4. Provide the initial state of the puzzle board.
5. Choose the heuristic function to use.
6. Let the application solve the puzzle and display the solution path.

## Contributing

Contributions to the Puzzle Solver app are welcome! If you encounter any issues or have suggestions for improvements, please open an issue or submit a pull request on GitHub.

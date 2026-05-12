//
//  KillerSudokuModels.swift
//  Puzzle Solver
//
//  Placeholder domain models for future Killer Sudoku support.
//

import Foundation

struct KillerSudokuCage: Identifiable, Hashable {
    let id = UUID()
    var targetSum: Int
    var cells: Set<LogicGridCoordinate>
}

struct KillerSudokuBoard: LogicPuzzleBoard, Hashable {
    var cells: [[SudokuCell]]
    var cages: [KillerSudokuCage]

    var kind: LogicPuzzleKind { .killerSudoku }
    var size: LogicGridSize { .sudoku }

    static let placeholder = KillerSudokuBoard(
        cells: SudokuBoard.empty.cells,
        cages: []
    )

    static let example = placeholder
}

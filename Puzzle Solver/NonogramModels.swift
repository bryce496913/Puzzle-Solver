//
//  NonogramModels.swift
//  Puzzle Solver
//
//  Placeholder domain models for future Nonogram support.
//

import Foundation

struct NonogramClueRun: Identifiable, Hashable {
    let id = UUID()
    var length: Int
}

struct NonogramBoard: LogicPuzzleBoard, Hashable {
    enum Cell: Equatable, Hashable { case unknown, filled, empty }

    var cells: [[Cell]]
    var rowClues: [[NonogramClueRun]]
    var columnClues: [[NonogramClueRun]]

    var kind: LogicPuzzleKind { .nonogram }
    var size: LogicGridSize { LogicGridSize(rows: cells.count, columns: cells.first?.count ?? 0) }

    static let placeholder = NonogramBoard(
        cells: Array(repeating: Array(repeating: .unknown, count: 5), count: 5),
        rowClues: [],
        columnClues: []
    )

    static let example = placeholder
}

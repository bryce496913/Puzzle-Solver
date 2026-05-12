//
//  KakuroModels.swift
//  Puzzle Solver
//
//  Placeholder domain models for future Kakuro support.
//

import Foundation

struct KakuroRun: Identifiable, Hashable {
    enum Direction: Hashable { case across, down }

    let id = UUID()
    var sum: Int
    var direction: Direction
    var cells: [LogicGridCoordinate]
}

struct KakuroBoard: LogicPuzzleBoard, Hashable {
    enum Cell: Equatable, Hashable { case block, clue(across: Int?, down: Int?), value(Int?) }

    var cells: [[Cell]]
    var runs: [KakuroRun]

    var kind: LogicPuzzleKind { .kakuro }
    var size: LogicGridSize { LogicGridSize(rows: cells.count, columns: cells.first?.count ?? 0) }

    static let placeholder = KakuroBoard(
        cells: Array(repeating: Array(repeating: .block, count: 5), count: 5),
        runs: []
    )

    static let example = placeholder
}

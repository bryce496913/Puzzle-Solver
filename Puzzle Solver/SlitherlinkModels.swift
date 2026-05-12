//
//  SlitherlinkModels.swift
//  Puzzle Solver
//
//  Placeholder domain models for future Slitherlink support.
//

import Foundation

struct SlitherlinkBoard: LogicPuzzleBoard, Hashable {
    enum Cell: Equatable, Hashable { case clue(Int?), blank }
    enum EdgeState: Hashable { case unknown, line, crossed }

    var cells: [[Cell]]
    var horizontalEdges: [[EdgeState]]
    var verticalEdges: [[EdgeState]]

    var kind: LogicPuzzleKind { .slitherlink }
    var size: LogicGridSize { LogicGridSize(rows: cells.count, columns: cells.first?.count ?? 0) }

    static let placeholder = SlitherlinkBoard(
        cells: Array(repeating: Array(repeating: .blank, count: 5), count: 5),
        horizontalEdges: Array(repeating: Array(repeating: .unknown, count: 5), count: 6),
        verticalEdges: Array(repeating: Array(repeating: .unknown, count: 6), count: 5)
    )
}

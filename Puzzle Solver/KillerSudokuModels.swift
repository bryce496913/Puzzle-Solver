//
//  KillerSudokuModels.swift
//  Puzzle Solver
//
//  Killer Sudoku domain models and a bundled production fixture.
//

import Foundation

struct KillerSudokuCage: Identifiable, Hashable {
    let id = UUID()
    var targetSum: Int
    /// Kept as an array so malformed imported definitions containing the same
    /// coordinate twice can be rejected instead of silently de-duplicated.
    var cells: [LogicGridCoordinate]
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

    /// A genuine cage puzzle: the grid starts empty and its constraints, rather
    /// than pre-filled Sudoku digits, describe the puzzle.
    static let example: KillerSudokuBoard = {
        let solution = [
            [5,3,4,6,7,8,9,1,2], [6,7,2,1,9,5,3,4,8], [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3], [4,2,6,8,5,3,7,9,1], [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4], [2,8,7,4,1,9,6,3,5], [3,4,5,2,8,6,1,7,9]
        ]
        // Irregular, connected cages cover the upper half; the fixture remains
        // an empty input puzzle rather than a completed Sudoku.
        var groups: [[(Int, Int)]] = [
            [(0,0),(0,1)], [(0,2),(0,3),(1,2)], [(0,4),(0,5)], [(0,6),(0,7),(0,8)],
            [(1,0),(1,1),(2,0)], [(1,3),(2,3)], [(1,4),(1,5)], [(1,6),(1,7),(1,8)],
            [(2,1),(2,2)], [(2,4),(2,5),(2,6)], [(2,7),(2,8)],
            [(3,0),(3,1),(4,0)], [(3,2),(3,3)], [(3,4),(3,5),(4,5)], [(3,6),(3,7),(3,8)],
            [(4,1),(4,2)], [(4,3),(4,4),(5,4)], [(4,6),(4,7),(4,8)]
        ]
        let grouped = Set(groups.flatMap { $0.map { LogicGridCoordinate(row: $0.0, column: $0.1) } })
        // The lower half includes one-cell cages. These are valid published
        // Killer clues and make this deterministic fixture fast enough for UI
        // regression tests while the upper half still exercises real outlines.
        groups += (0..<9).flatMap { row in (0..<9).compactMap { column -> [(Int, Int)]? in
            grouped.contains(.init(row: row, column: column)) ? nil : [(row, column)]
        } }
        let cages = groups.map { group -> KillerSudokuCage in
            let cells = group.map { LogicGridCoordinate(row: $0.0, column: $0.1) }
            return KillerSudokuCage(targetSum: cells.reduce(0) { $0 + solution[$1.row][$1.column] }, cells: cells)
        }
        return KillerSudokuBoard(cells: SudokuBoard.empty.cells, cages: cages)
    }()
}

struct KillerSudokuValidation: Equatable {
    let invalidCageIndices: Set<Int>
    let uncoveredCells: Set<LogicGridCoordinate>
    let overlappingCells: Set<LogicGridCoordinate>

    var canSolve: Bool { invalidCageIndices.isEmpty && uncoveredCells.isEmpty && overlappingCells.isEmpty }
    var message: String {
        if !overlappingCells.isEmpty { return "These cells already belong to another cage." }
        if let index = invalidCageIndices.sorted().first { return "Cage \(index + 1) has an impossible total or disconnected cells." }
        if !uncoveredCells.isEmpty { return "\(uncoveredCells.count) cell\(uncoveredCells.count == 1 ? "" : "s") still need cages." }
        return "All 81 cells are covered. Ready to solve."
    }
}

extension KillerSudokuValidator {
    static func report(for board: KillerSudokuBoard) -> KillerSudokuValidation {
        let all = Set((0..<9).flatMap { row in (0..<9).map { LogicGridCoordinate(row: row, column: $0) } })
        var owners: [LogicGridCoordinate: Int] = [:]
        var overlaps: Set<LogicGridCoordinate> = []
        var invalid: Set<Int> = []
        for (index, cage) in board.cages.enumerated() {
            for cell in cage.cells where owners.updateValue(index, forKey: cell) != nil { overlaps.insert(cell) }
            // Local checks are repeated here because whole-board validation also
            // requires coverage and therefore cannot identify the offending cage.
            if cage.cells.isEmpty || Set(cage.cells).count != cage.cells.count ||
                !cage.cells.allSatisfy(SudokuBoard.contains) ||
                !KillerSudokuValidator.feasibleTarget(cage.targetSum, cellCount: cage.cells.count) ||
                !Self.connected(cage.cells) { invalid.insert(index) }
        }
        return KillerSudokuValidation(invalidCageIndices: invalid, uncoveredCells: all.subtracting(owners.keys), overlappingCells: overlaps)
    }

    private static func connected(_ cells: [LogicGridCoordinate]) -> Bool {
        guard let first = cells.first else { return false }
        let all = Set(cells); var seen: Set<LogicGridCoordinate> = []; var stack = [first]
        while let cell = stack.popLast() {
            guard seen.insert(cell).inserted else { continue }
            stack += [LogicGridCoordinate(row: cell.row - 1, column: cell.column), LogicGridCoordinate(row: cell.row + 1, column: cell.column), LogicGridCoordinate(row: cell.row, column: cell.column - 1), LogicGridCoordinate(row: cell.row, column: cell.column + 1)].filter(all.contains)
        }
        return seen == all
    }
}

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

    /// The first regression puzzle is also the example presented by the editor.
    /// It has no given digits: the Sudoku and cage constraints do all the work.
    static var example: KillerSudokuBoard { KillerSudokuFixtures.classic.board }
}

/// A reproducible, repository-owned Killer Sudoku fixture. Cage coordinates use
/// compact one-based `rowcolumn` notation in `definitions`, making the complete puzzle
/// easy to audit independently of the solver.
struct KillerSudokuFixture {
    let name: String
    let provenance: String
    let definitions: [(target: Int, coordinates: String)]
    let knownUniqueSolution: [[Int]]
    let expectedOutcome: SolveState

    var board: KillerSudokuBoard {
        KillerSudokuBoard(cells: SudokuBoard.empty.cells, cages: definitions.map { definition in
            KillerSudokuCage(targetSum: definition.target, cells: definition.coordinates.split(separator: " ").map { token in
                precondition(token.count == 2 && token.allSatisfy(\.isNumber), "Malformed fixture coordinate")
                let digits = token.compactMap(\.wholeNumberValue)
                return LogicGridCoordinate(row: digits[0] - 1, column: digits[1] - 1)
            })
        })
    }
}

enum KillerSudokuFixtures {
    private static let solution = [
            [5,3,4,6,7,8,9,1,2], [6,7,2,1,9,5,3,4,8], [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3], [4,2,6,8,5,3,7,9,1], [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4], [2,8,7,4,1,9,6,3,5], [3,4,5,2,8,6,1,7,9]
        ]

    /// Authored for this repository from the known solution above. The connected
    /// cage partition was generated with seed 1, then uniqueness was exhaustively
    /// checked by the production solver. It contains 42 cages (34 multi-cell).
    static let classic = KillerSudokuFixture(
        name: "Classic pairs", provenance: "Repository-authored deterministic cage partition (seed 1).",
        definitions: [
            (7,"66 56"),(9,"63 53"),(8,"27 37"),(12,"29 28"),(17,"54 64"),(9,"76 77"),
            (11,"49 48 38"),(15,"16 15"),(7,"45 46"),(5,"74"),(15,"86 87"),(10,"59 58"),
            (11,"34 33"),(21,"44 43 42"),(14,"95 96"),(7,"72 62"),(20,"71 61 51"),(11,"57 47"),
            (7,"94 93"),(10,"17 18"),(2,"52"),(14,"99 89"),(5,"84 85"),(14,"26 25"),
            (2,"19"),(7,"91 92"),(12,"12 13 11"),(13,"78 68"),(10,"55 65 75"),(8,"67"),
            (7,"14 24"),(9,"31 41"),(8,"73 83"),(9,"23 22"),(7,"39"),(9,"32"),
            (8,"98 97"),(10,"69 79"),(3,"88"),(6,"36 35"),(10,"81 82"),(6,"21")
        ], knownUniqueSolution: solution, expectedOutcome: .solved)

    /// A second independently generated partition (seed 18), with long vertical
    /// cages in different regions and seven single-cell clues among 42 cages.
    static let vertical = KillerSudokuFixture(
        name: "Vertical weave", provenance: "Repository-authored deterministic cage partition (seed 18).",
        definitions: [
            (11,"68 69"),(15,"39 29"),(11,"76 66"),(14,"94 93 83"),(9,"95 85"),(5,"28 18"),
            (13,"25 35"),(10,"31 32"),(6,"21"),(8,"89 88"),(4,"63 62"),(12,"78 79"),
            (15,"15 16"),(14,"92 82 81"),(15,"96 86"),(13,"42 41"),(16,"99 98"),(2,"19"),
            (10,"13 14"),(5,"65 75"),(10,"56 57"),(8,"11 12"),(6,"47 48"),(16,"71 61"),
            (12,"51 52 53"),(10,"67 77"),(4,"49 59"),(7,"72 73"),(3,"24 23"),(10,"44 34"),
            (9,"58"),(7,"46 45"),(3,"91"),(7,"87 97"),(11,"38 37"),(12,"17 27"),
            (7,"22"),(22,"74 64 54"),(4,"84"),(7,"26 36"),(5,"55"),(17,"33 43")
        ], knownUniqueSolution: solution, expectedOutcome: .solved)

    static let uniquePuzzles = [classic, vertical]
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

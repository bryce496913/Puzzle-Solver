//
//  KillerSudokuSolver.swift
//  Puzzle Solver
//
//  Bounded Killer Sudoku backtracking solver.
//

import Foundation

struct KillerSudokuSolveOptions: Equatable {
    var maxNodes: Int = 500_000
    var timeout: TimeInterval = 5
}

struct KillerSudokuSolveResult {
    let state: SolveState
    let solvedBoard: KillerSudokuBoard?
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> KillerSudokuSolveResult {
        KillerSudokuSolveResult(state: .unsupported, solvedBoard: nil, message: "Killer Sudoku solver unavailable.", failureReason: "This solver is planned for a future update.", elapsedTime: elapsedTime, nodesExplored: 0)
    }
}

enum KillerSudokuValidator {
    static func validate(_ board: KillerSudokuBoard) -> SolveState {
        guard board.cells.count == SudokuBoard.dimension, board.cells.allSatisfy({ $0.count == SudokuBoard.dimension }) else { return .invalid }
        let sudoku = SudokuBoard(cells: board.cells)
        guard SudokuValidator.validate(sudoku).isValid else { return .invalid }
        var covered: Set<LogicGridCoordinate> = []
        for cage in board.cages {
            guard !cage.cells.isEmpty, cage.targetSum > 0 else { return .invalid }
            guard Set(cage.cells).count == cage.cells.count else { return .invalid }
            guard cage.cells.allSatisfy(SudokuBoard.contains) else { return .invalid }
            guard cage.cells.count <= 9,
                  feasibleTarget(cage.targetSum, cellCount: cage.cells.count),
                  isOrthogonallyConnected(cage.cells) else { return .invalid }
            var seen: Set<Int> = []
            var sum = 0
            for cell in cage.cells {
                if covered.contains(cell) { return .invalid }
                covered.insert(cell)
                if let value = sudoku.value(at: cell) {
                    guard SudokuBoard.validDigits.contains(value), !seen.contains(value) else { return .invalid }
                    seen.insert(value)
                    sum += value
                }
            }
            if sum > cage.targetSum { return .invalid }
            let remaining = cage.cells.count - seen.count
            let unused = SudokuBoard.validDigits.filter { !seen.contains($0) }.sorted()
            guard remaining <= unused.count else { return .invalid }
            let minimum = unused.prefix(remaining).reduce(0, +)
            let maximum = unused.suffix(remaining).reduce(0, +)
            guard (sum + minimum...sum + maximum).contains(cage.targetSum) else { return .invalid }
        }
        guard covered.count == SudokuBoard.dimension * SudokuBoard.dimension else { return .invalid }
        return .solving
    }

    static func feasibleTarget(_ target: Int, cellCount: Int) -> Bool {
        guard (1...9).contains(cellCount) else { return false }
        let digits = Array(1...9)
        return (digits.prefix(cellCount).reduce(0, +)...digits.suffix(cellCount).reduce(0, +)).contains(target)
    }

    private static func isOrthogonallyConnected(_ cells: [LogicGridCoordinate]) -> Bool {
        let all = Set(cells)
        guard var frontier = cells.first.map({ [$0] }) else { return false }
        var visited: Set<LogicGridCoordinate> = []
        while let cell = frontier.popLast() {
            guard visited.insert(cell).inserted else { continue }
            let neighbors = [
                LogicGridCoordinate(row: cell.row - 1, column: cell.column),
                LogicGridCoordinate(row: cell.row + 1, column: cell.column),
                LogicGridCoordinate(row: cell.row, column: cell.column - 1),
                LogicGridCoordinate(row: cell.row, column: cell.column + 1)
            ]
            frontier.append(contentsOf: neighbors.filter { all.contains($0) && !visited.contains($0) })
        }
        return visited == all
    }
}

final class KillerSudokuSolver: LogicPuzzleSolving {
    func solve(_ board: KillerSudokuBoard) -> KillerSudokuSolveResult { solve(board, options: KillerSudokuSolveOptions()) }

    func solve(_ board: KillerSudokuBoard, options: KillerSudokuSolveOptions) -> KillerSudokuSolveResult {
        let start = Date(); let deadline = start.addingTimeInterval(options.timeout)
        guard KillerSudokuValidator.validate(board) != .invalid else { return finish(.invalid, board: nil, reason: "Invalid Killer Sudoku puzzle.", start: start, nodes: 0) }
        var values = board.cells.map { $0.map { $0.value ?? 0 } }
        let cageIndex = Dictionary(uniqueKeysWithValues: board.cages.enumerated().flatMap { index, cage in cage.cells.map { ($0, index) } })
        var nodes = 0
        var firstSolution: [[Int]]?
        var solutionCount = 0
        let stoppedByLimit = search(values: &values, board: board, cageIndex: cageIndex, nodes: &nodes, maxNodes: options.maxNodes, deadline: deadline, solutionCount: &solutionCount, firstSolution: &firstSolution)
        if solutionCount >= 2 {
            return finish(.multipleSolutions, board: nil, reason: SolveState.multipleSolutions.friendlyMessage, start: start, nodes: nodes)
        }
        if solutionCount == 1, !stoppedByLimit, let solution = firstSolution {
            let solvedCells = solution.map { row in row.map { SudokuCell(value: $0, isGiven: true) } }
            return finish(.solved, board: KillerSudokuBoard(cells: solvedCells, cages: board.cages), reason: nil, start: start, nodes: nodes)
        }
        let state: SolveState = Date() >= deadline ? .timedOut : (nodes >= options.maxNodes || Task.isCancelled ? .failed : .noSolution)
        let reason = state == .timedOut ? "Killer Sudoku solve timed out." : (state == .failed ? "Killer Sudoku search was cancelled or reached its node limit." : "No solution exists for this Killer Sudoku.")
        return finish(state, board: nil, reason: reason, start: start, nodes: nodes)
    }

    /// Returns true only when a search limit/cancellation interrupted proof of uniqueness.
    private func search(values: inout [[Int]], board: KillerSudokuBoard, cageIndex: [LogicGridCoordinate: Int], nodes: inout Int, maxNodes: Int, deadline: Date, solutionCount: inout Int, firstSolution: inout [[Int]]?) -> Bool {
        guard !Task.isCancelled, Date() < deadline, nodes < maxNodes else { return true }
        guard let best = bestEmptyCell(values: values, board: board, cageIndex: cageIndex) else {
            if cagesComplete(values: values, board: board) {
                solutionCount += 1
                if firstSolution == nil { firstSolution = values }
            }
            return false
        }
        for value in best.candidates {
            nodes += 1
            values[best.coordinate.row][best.coordinate.column] = value
            let stopped = search(values: &values, board: board, cageIndex: cageIndex, nodes: &nodes, maxNodes: maxNodes, deadline: deadline, solutionCount: &solutionCount, firstSolution: &firstSolution)
            values[best.coordinate.row][best.coordinate.column] = 0
            if stopped { return true }
            if solutionCount >= 2 { return false }
        }
        return false
    }

    private func bestEmptyCell(values: [[Int]], board: KillerSudokuBoard, cageIndex: [LogicGridCoordinate: Int]) -> (coordinate: LogicGridCoordinate, candidates: [Int])? {
        var best: (LogicGridCoordinate, [Int])?
        for r in 0..<9 { for c in 0..<9 where values[r][c] == 0 {
            let coord = LogicGridCoordinate(row: r, column: c)
            let candidates = (1...9).filter { canPlace($0, at: coord, values: values, board: board, cageIndex: cageIndex) }
            if candidates.isEmpty { return (coord, []) }
            if best == nil || candidates.count < best!.1.count { best = (coord, candidates) }
        }}
        return best.map { ($0.0, $0.1) }
    }

    private func canPlace(_ digit: Int, at coord: LogicGridCoordinate, values: [[Int]], board: KillerSudokuBoard, cageIndex: [LogicGridCoordinate: Int]) -> Bool {
        for i in 0..<9 { if values[coord.row][i] == digit || values[i][coord.column] == digit { return false } }
        let br = (coord.row / 3) * 3, bc = (coord.column / 3) * 3
        for r in br..<(br+3) { for c in bc..<(bc+3) where values[r][c] == digit { return false } }
        guard let index = cageIndex[coord] else { return true }
        let cage = board.cages[index]
        var sum = digit; var used: Set<Int> = [digit]; var empty = 0
        for cell in cage.cells where cell != coord {
            let value = values[cell.row][cell.column]
            if value == 0 { empty += 1; continue }
            if used.contains(value) { return false }
            used.insert(value); sum += value
        }
        let remainder = cage.targetSum - sum
        if empty == 0 { return remainder == 0 }
        let unused = SudokuBoard.validDigits.filter { !used.contains($0) }.filter { candidate in
            cage.cells.contains { cell in
                values[cell.row][cell.column] == 0 && cell != coord && sudokuAllows(candidate, at: cell, values: values)
            }
        }.sorted()
        guard unused.count >= empty else { return false }
        return (unused.prefix(empty).reduce(0, +)...unused.suffix(empty).reduce(0, +)).contains(remainder)
    }

    private func sudokuAllows(_ digit: Int, at coord: LogicGridCoordinate, values: [[Int]]) -> Bool {
        guard !values[coord.row].contains(digit), !values.map({ $0[coord.column] }).contains(digit) else { return false }
        let br = coord.row / 3 * 3, bc = coord.column / 3 * 3
        return !(br..<(br + 3)).contains { row in (bc..<(bc + 3)).contains { values[row][$0] == digit } }
    }

    private func cagesComplete(values: [[Int]], board: KillerSudokuBoard) -> Bool {
        board.cages.allSatisfy { cage in cage.cells.reduce(0) { $0 + values[$1.row][$1.column] } == cage.targetSum }
    }

    private func finish(_ state: SolveState, board: KillerSudokuBoard?, reason: String?, start: Date, nodes: Int) -> KillerSudokuSolveResult {
        KillerSudokuSolveResult(state: state, solvedBoard: board, message: reason ?? "Solution ready.", failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }
}

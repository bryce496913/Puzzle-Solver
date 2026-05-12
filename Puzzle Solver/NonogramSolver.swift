//
//  NonogramSolver.swift
//  Puzzle Solver
//
//  Constraint propagation plus bounded row backtracking solver.
//

import Foundation

struct NonogramSolveOptions: Equatable { var maxNodes: Int = 200_000; var timeout: TimeInterval = 5 }

struct NonogramSolveResult {
    let state: SolveState
    let solvedBoard: NonogramBoard?
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> NonogramSolveResult {
        NonogramSolveResult(state: .unsupported, solvedBoard: nil, message: "Nonogram solver unavailable.", failureReason: "This solver is planned for a future update.", elapsedTime: elapsedTime, nodesExplored: 0)
    }
}

enum NonogramValidator {
    static func validate(_ board: NonogramBoard) -> SolveState {
        let size = board.size
        guard size.rows > 0, size.columns > 0, board.cells.allSatisfy({ $0.count == size.columns }) else { return .invalid }
        guard board.rowClues.count == size.rows, board.columnClues.count == size.columns else { return .invalid }
        guard board.rowClues.flatMap({ $0 }).allSatisfy({ $0.length >= 0 }), board.columnClues.flatMap({ $0 }).allSatisfy({ $0.length >= 0 }) else { return .invalid }
        return .solving
    }
}

final class NonogramSolver: LogicPuzzleSolving {
    func solve(_ board: NonogramBoard) -> NonogramSolveResult { solve(board, options: NonogramSolveOptions()) }

    func solve(_ board: NonogramBoard, options: NonogramSolveOptions) -> NonogramSolveResult {
        let start = Date(); let deadline = start.addingTimeInterval(options.timeout)
        guard NonogramValidator.validate(board) != .invalid else { return finish(.invalid, board: nil, reason: "Invalid Nonogram puzzle.", start: start, nodes: 0) }
        let rows = board.size.rows, cols = board.size.columns
        var rowPoss = (0..<rows).map { row in
            linePatterns(length: cols, clues: board.rowClues[row].map(\.length)).filter { pattern in patternMatches(pattern, known: board.cells[row]) }
        }
        var colPoss = (0..<cols).map { linePatterns(length: rows, clues: board.columnClues[$0].map(\.length)) }
        var nodes = 0
        let solved = search(rowPoss: &rowPoss, colPoss: &colPoss, rows: rows, cols: cols, nodes: &nodes, maxNodes: options.maxNodes, deadline: deadline)
        if solved, let grid = materialize(rowPoss: rowPoss) {
            return finish(.solved, board: NonogramBoard(cells: grid, rowClues: board.rowClues, columnClues: board.columnClues), reason: nil, start: start, nodes: nodes)
        }
        let state: SolveState = Date() >= deadline ? .timedOut : (nodes >= options.maxNodes ? .failed : .noSolution)
        return finish(state, board: nil, reason: state == .timedOut ? "Nonogram solve timed out." : "No solution exists for this Nonogram.", start: start, nodes: nodes)
    }

    private func search(rowPoss: inout [[[NonogramBoard.Cell]]], colPoss: inout [[[NonogramBoard.Cell]]], rows: Int, cols: Int, nodes: inout Int, maxNodes: Int, deadline: Date) -> Bool {
        guard Date() < deadline, nodes < maxNodes else { return false }
        guard propagate(rowPoss: &rowPoss, colPoss: &colPoss, rows: rows, cols: cols) else { return false }
        if rowPoss.allSatisfy({ $0.count == 1 }) { return true }
        let row = rowPoss.enumerated().filter { $0.element.count > 1 }.min { $0.element.count < $1.element.count }!.offset
        let choices = rowPoss[row]
        for choice in choices {
            nodes += 1
            var nextRows = rowPoss; var nextCols = colPoss
            nextRows[row] = [choice]
            if search(rowPoss: &nextRows, colPoss: &nextCols, rows: rows, cols: cols, nodes: &nodes, maxNodes: maxNodes, deadline: deadline) {
                rowPoss = nextRows; colPoss = nextCols; return true
            }
        }
        return false
    }

    private func propagate(rowPoss: inout [[[NonogramBoard.Cell]]], colPoss: inout [[[NonogramBoard.Cell]]], rows: Int, cols: Int) -> Bool {
        var changed = true
        while changed {
            changed = false
            for r in 0..<rows {
                let before = rowPoss[r].count
                rowPoss[r] = rowPoss[r].filter { rowPattern in
                    (0..<cols).allSatisfy { c in colPoss[c].contains { $0[r] == rowPattern[c] } }
                }
                if rowPoss[r].isEmpty { return false }
                changed = changed || before != rowPoss[r].count
            }
            for c in 0..<cols {
                let before = colPoss[c].count
                colPoss[c] = colPoss[c].filter { colPattern in
                    (0..<rows).allSatisfy { r in rowPoss[r].contains { $0[c] == colPattern[r] } }
                }
                if colPoss[c].isEmpty { return false }
                changed = changed || before != colPoss[c].count
            }
        }
        return true
    }

    private func linePatterns(length: Int, clues: [Int]) -> [[NonogramBoard.Cell]] {
        let clues = clues.filter { $0 > 0 }
        if clues.isEmpty { return [Array(repeating: .empty, count: length)] }
        var output: [[NonogramBoard.Cell]] = []
        func place(_ index: Int, _ start: Int, _ line: [NonogramBoard.Cell]) {
            if index == clues.count {
                output.append(line + Array(repeating: .empty, count: length - line.count)); return
            }
            let remaining = clues[index...].reduce(0, +) + max(0, clues.count - index - 1)
            guard start + remaining <= length else { return }
            for offset in start...(length - remaining) {
                var next = line + Array(repeating: .empty, count: offset - line.count)
                next += Array(repeating: .filled, count: clues[index])
                if index < clues.count - 1 { next.append(.empty) }
                place(index + 1, next.count, next)
            }
        }
        place(0, 0, [])
        return output
    }

    private func patternMatches(_ pattern: [NonogramBoard.Cell], known: [NonogramBoard.Cell]) -> Bool {
        zip(pattern, known).allSatisfy { knownCell, given in given == .unknown || knownCell == given }
    }

    private func materialize(rowPoss: [[[NonogramBoard.Cell]]]) -> [[NonogramBoard.Cell]]? { rowPoss.allSatisfy { $0.count == 1 } ? rowPoss.map { $0[0] } : nil }
    private func finish(_ state: SolveState, board: NonogramBoard?, reason: String?, start: Date, nodes: Int) -> NonogramSolveResult { NonogramSolveResult(state: state, solvedBoard: board, message: reason ?? "Solution ready.", failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes) }
}

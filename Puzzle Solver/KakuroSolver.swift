//
//  KakuroSolver.swift
//  Puzzle Solver
//
//  Bounded Kakuro solver using run-pattern intersections.
//

import Foundation

struct KakuroSolveOptions: Equatable { var maxNodes: Int = 300_000; var timeout: TimeInterval = 5 }

struct KakuroSolveResult {
    let state: SolveState
    let solvedBoard: KakuroBoard?
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> KakuroSolveResult {
        KakuroSolveResult(state: .unsupported, solvedBoard: nil, message: "Kakuro solver unavailable.", failureReason: "This solver is planned for a future update.", elapsedTime: elapsedTime, nodesExplored: 0)
    }
}

enum KakuroValidator {
    static func validate(_ board: KakuroBoard) -> SolveState {
        let size = board.size
        guard size.rows > 0, size.columns > 0, board.cells.allSatisfy({ $0.count == size.columns }) else { return .invalid }
        for run in board.runs {
            guard !run.cells.isEmpty, run.sum > 0, run.sum <= 45, run.cells.count <= 9 else { return .invalid }
            for cell in run.cells {
                guard (0..<size.rows).contains(cell.row), (0..<size.columns).contains(cell.column) else { return .invalid }
                if case .value(let digit) = board.cells[cell.row][cell.column] {
                    if let digit, !(1...9).contains(digit) { return .invalid }
                } else { return .invalid }
            }
        }
        return .solving
    }
}

final class KakuroSolver: LogicPuzzleSolving {
    private typealias RunID = UUID
    private typealias Assignment = [LogicGridCoordinate: Int]

    func solve(_ board: KakuroBoard) -> KakuroSolveResult { solve(board, options: KakuroSolveOptions()) }

    func solve(_ board: KakuroBoard, options: KakuroSolveOptions) -> KakuroSolveResult {
        let start = Date(); let deadline = start.addingTimeInterval(options.timeout)
        guard KakuroValidator.validate(board) != .invalid else { return finish(.invalid, board: nil, reason: "Invalid Kakuro puzzle.", start: start, nodes: 0) }
        var assignments: Assignment = [:]
        for r in 0..<board.size.rows { for c in 0..<board.size.columns {
            if case .value(let digit) = board.cells[r][c], let digit = digit { assignments[LogicGridCoordinate(row: r, column: c)] = digit }
        }}
        var cellRuns: [LogicGridCoordinate: [RunID]] = [:]
        var runByID: [RunID: KakuroRun] = [:]
        var patterns: [RunID: [[Int]]] = [:]
        for run in board.runs {
            runByID[run.id] = run
            patterns[run.id] = Self.runPatterns(length: run.cells.count, sum: run.sum)
            for cell in run.cells { cellRuns[cell, default: []].append(run.id) }
        }
        var nodes = 0
        let solved = search(assignments: &assignments, cells: Array(cellRuns.keys), cellRuns: cellRuns, runByID: runByID, patterns: patterns, nodes: &nodes, maxNodes: options.maxNodes, deadline: deadline)
        if solved {
            var cells = board.cells
            for (coord, value) in assignments { cells[coord.row][coord.column] = .value(value) }
            return finish(.solved, board: KakuroBoard(cells: cells, runs: board.runs), reason: nil, start: start, nodes: nodes)
        }
        let state: SolveState = Date() >= deadline ? .timedOut : (nodes >= options.maxNodes ? .failed : .noSolution)
        return finish(state, board: nil, reason: state == .timedOut ? "Kakuro solve timed out." : "No solution exists for this Kakuro.", start: start, nodes: nodes)
    }

    private func search(assignments: inout Assignment, cells: [LogicGridCoordinate], cellRuns: [LogicGridCoordinate: [RunID]], runByID: [RunID: KakuroRun], patterns: [RunID: [[Int]]], nodes: inout Int, maxNodes: Int, deadline: Date) -> Bool {
        guard Date() < deadline, nodes < maxNodes else { return false }
        guard let choice = bestCell(assignments: assignments, cells: cells, cellRuns: cellRuns, runByID: runByID, patterns: patterns) else { return allRunsSatisfied(assignments: assignments, runByID: runByID) }
        if choice.candidates.isEmpty { return false }
        for digit in choice.candidates {
            nodes += 1; assignments[choice.cell] = digit
            if search(assignments: &assignments, cells: cells, cellRuns: cellRuns, runByID: runByID, patterns: patterns, nodes: &nodes, maxNodes: maxNodes, deadline: deadline) { return true }
            assignments[choice.cell] = nil
        }
        return false
    }

    private func bestCell(assignments: Assignment, cells: [LogicGridCoordinate], cellRuns: [LogicGridCoordinate: [RunID]], runByID: [RunID: KakuroRun], patterns: [RunID: [[Int]]]) -> (cell: LogicGridCoordinate, candidates: Set<Int>)? {
        var best: (LogicGridCoordinate, Set<Int>)?
        for cell in cells where assignments[cell] == nil {
            var candidates = Set(1...9)
            for runID in cellRuns[cell] ?? [] {
                guard let run = runByID[runID], let index = run.cells.firstIndex(of: cell) else { continue }
                let possible = (patterns[runID] ?? []).filter { pattern in isPatternCompatible(pattern, run: run, assignments: assignments) }
                candidates.formIntersection(Set(possible.map { $0[index] }))
            }
            if best == nil || candidates.count < best!.1.count { best = (cell, candidates) }
            if candidates.isEmpty { return (cell, candidates) }
        }
        return best
    }

    private func isPatternCompatible(_ pattern: [Int], run: KakuroRun, assignments: Assignment) -> Bool {
        for (index, cell) in run.cells.enumerated() { if let value = assignments[cell], value != pattern[index] { return false } }
        return true
    }

    private func allRunsSatisfied(assignments: Assignment, runByID: [RunID: KakuroRun]) -> Bool {
        runByID.values.allSatisfy { run in run.cells.compactMap { assignments[$0] }.count == run.cells.count && run.cells.reduce(0) { $0 + (assignments[$1] ?? 0) } == run.sum }
    }

    private static func runPatterns(length: Int, sum: Int) -> [[Int]] {
        var output: [[Int]] = []
        func build(_ digits: [Int], _ used: Set<Int>) {
            if digits.count == length { if digits.reduce(0, +) == sum { output.append(digits) }; return }
            let partial = digits.reduce(0, +)
            for digit in 1...9 where !used.contains(digit) && partial + digit <= sum { build(digits + [digit], used.union([digit])) }
        }
        build([], [])
        return output
    }

    private func finish(_ state: SolveState, board: KakuroBoard?, reason: String?, start: Date, nodes: Int) -> KakuroSolveResult { KakuroSolveResult(state: state, solvedBoard: board, message: reason ?? "Solution ready.", failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes) }
}

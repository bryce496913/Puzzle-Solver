//
//  SlitherlinkSolver.swift
//  Puzzle Solver
//
//  Safe first-pass Slitherlink validator. Full loop search is intentionally unavailable.
//

import Foundation

struct SlitherlinkSolveOptions: Equatable { var timeout: TimeInterval = 5; var maxNodes: Int = 100_000 }

struct SlitherlinkSolveResult {
    let state: SolveState
    let solvedBoard: SlitherlinkBoard?
    let message: String
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    static func solverUnavailable(elapsedTime: TimeInterval = 0) -> SlitherlinkSolveResult {
        SlitherlinkSolveResult(state: .unsupported, solvedBoard: nil, message: "Slitherlink solver unavailable.", failureReason: "Full Slitherlink loop search is not available in this build.", elapsedTime: elapsedTime, nodesExplored: 0)
    }
}

enum SlitherlinkValidator {
    static func validate(_ board: SlitherlinkBoard) -> SolveState {
        let size = board.size
        guard size.rows > 0, size.columns > 0, board.cells.allSatisfy({ $0.count == size.columns }) else { return .invalid }
        guard board.horizontalEdges.count == size.rows + 1, board.horizontalEdges.allSatisfy({ $0.count == size.columns }) else { return .invalid }
        guard board.verticalEdges.count == size.rows, board.verticalEdges.allSatisfy({ $0.count == size.columns + 1 }) else { return .invalid }
        for row in 0..<size.rows { for column in 0..<size.columns {
            if case .clue(let value) = board.cells[row][column], let value = value, !(0...3).contains(value) { return .invalid }
        }}
        return locallyConsistent(board) ? .solving : .invalid
    }

    static func locallyConsistent(_ board: SlitherlinkBoard) -> Bool {
        let rows = board.size.rows, cols = board.size.columns
        for row in 0...rows { for col in 0...cols {
            let degree = incidentEdges(atDotRow: row, column: col, board: board).filter { $0 == .line }.count
            if degree > 2 { return false }
        }}
        for row in 0..<rows { for col in 0..<cols {
            if case .clue(let clue?) = board.cells[row][col] {
                let edges = surroundingEdges(row: row, column: col, board: board)
                let lines = edges.filter { $0 == .line }.count
                let unknowns = edges.filter { $0 == .unknown }.count
                if lines > clue || lines + unknowns < clue { return false }
            }
        }}
        return true
    }

    private static func surroundingEdges(row: Int, column: Int, board: SlitherlinkBoard) -> [SlitherlinkBoard.EdgeState] {
        [board.horizontalEdges[row][column], board.horizontalEdges[row + 1][column], board.verticalEdges[row][column], board.verticalEdges[row][column + 1]]
    }

    private static func incidentEdges(atDotRow row: Int, column: Int, board: SlitherlinkBoard) -> [SlitherlinkBoard.EdgeState] {
        var edges: [SlitherlinkBoard.EdgeState] = []
        if column > 0 { edges.append(board.horizontalEdges[row][column - 1]) }
        if column < board.size.columns { edges.append(board.horizontalEdges[row][column]) }
        if row > 0 { edges.append(board.verticalEdges[row - 1][column]) }
        if row < board.size.rows { edges.append(board.verticalEdges[row][column]) }
        return edges
    }
}

final class SlitherlinkSolver: LogicPuzzleSolving {
    func solve(_ board: SlitherlinkBoard) -> SlitherlinkSolveResult { solve(board, options: SlitherlinkSolveOptions()) }

    func solve(_ board: SlitherlinkBoard, options: SlitherlinkSolveOptions) -> SlitherlinkSolveResult {
        let startedAt = Date()
        let validation = SlitherlinkValidator.validate(board)
        guard validation != .invalid else {
            return SlitherlinkSolveResult(state: .invalid, solvedBoard: nil, message: "Invalid Slitherlink puzzle.", failureReason: "Invalid edge dimensions, clue value, or local edge constraints.", elapsedTime: Date().timeIntervalSince(startedAt), nodesExplored: 0)
        }
        // A complete Slitherlink solver must combine local clue propagation with global single-loop
        // connectivity, degree-2 vertex constraints, and premature-cycle rejection. Returning an
        // explicit unsupported result is safer than exposing an incomplete search that may hang.
        return SlitherlinkSolveResult.solverUnavailable(elapsedTime: Date().timeIntervalSince(startedAt))
    }
}

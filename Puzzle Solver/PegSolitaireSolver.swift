//
//  PegSolitaireSolver.swift
//  Puzzle Solver
//
//  Bounded DFS/backtracking solver for peg solitaire.
//

import Foundation

final class PegSolitaireSolver: MechanicalPuzzleSolving {
    func solve(_ board: PegSolitaireBoard, options: MechanicalPuzzleSolveOptions = .default) -> MechanicalPuzzleSolveResult<PegSolitaireBoard> {
        let start = Date(); let deadline = start.addingTimeInterval(options.timeout)
        guard PegSolitaireBoardAnalyzer.validate(board) != .invalid else { return finish(.invalid, startBoard: board, boards: nil, moves: nil, reason: "Invalid Peg Solitaire board.", start: start, nodes: 0) }
        var visited: Set<PegSolitaireBoard> = []
        var boards: [PegSolitaireBoard] = [board]
        var moves: [MechanicalPuzzleMove] = []
        var nodes = 0
        let solved = dfs(board, visited: &visited, boards: &boards, moves: &moves, nodes: &nodes, maxNodes: options.maxNodes, deadline: deadline)
        if solved { return finish(.solved, startBoard: board, boards: boards, moves: moves, reason: nil, start: start, nodes: nodes) }
        let state: SolveState = Date() >= deadline ? .timedOut : (nodes >= options.maxNodes ? .failed : .noSolution)
        return finish(state, startBoard: board, boards: nil, moves: nil, reason: state == .timedOut ? "Peg Solitaire solve timed out." : "No Peg Solitaire solution found.", start: start, nodes: nodes)
    }

    private func dfs(_ board: PegSolitaireBoard, visited: inout Set<PegSolitaireBoard>, boards: inout [PegSolitaireBoard], moves: inout [MechanicalPuzzleMove], nodes: inout Int, maxNodes: Int, deadline: Date) -> Bool {
        guard Date() < deadline, nodes < maxNodes else { return false }
        if board.isSolved { return true }
        visited.insert(board)
        let nextMoves = PegSolitaireBoardAnalyzer.legalMoves(from: board).sorted { $0.board.pegCount < $1.board.pegCount }
        for next in nextMoves where !visited.contains(next.board) {
            nodes += 1
            boards.append(next.board)
            moves.append(next.move.asMechanicalMove)
            if dfs(next.board, visited: &visited, boards: &boards, moves: &moves, nodes: &nodes, maxNodes: maxNodes, deadline: deadline) { return true }
            boards.removeLast(); moves.removeLast()
        }
        return false
    }

    private func finish(_ state: SolveState, startBoard: PegSolitaireBoard, boards: [PegSolitaireBoard]?, moves: [MechanicalPuzzleMove]?, reason: String?, start: Date, nodes: Int) -> MechanicalPuzzleSolveResult<PegSolitaireBoard> {
        let boardPath = boards ?? [startBoard]
        let movePath = moves ?? []
        let frames = boardPath.enumerated().map { index, board in
            OrderedMovePlaybackFrame(order: index, move: index == 0 ? nil : movePath[index - 1], board: board, caption: index == 0 ? "Start" : movePath[index - 1].notation)
        }
        return MechanicalPuzzleSolveResult(kind: .pegSolitaire, state: state, moves: movePath, playbackFrames: frames, failureReason: state == .solved ? nil : reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }
}

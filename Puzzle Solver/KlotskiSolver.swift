//
//  KlotskiSolver.swift
//  Puzzle Solver
//
//  Shortest-path BFS over legal one-step sliding-block moves.
//

import Foundation

final class KlotskiSolver: MechanicalPuzzleSolving {
    func solve(_ board: KlotskiBoard, options: MechanicalPuzzleSolveOptions = .default) -> MechanicalPuzzleSolveResult<KlotskiBoard> {
        let start = Date()
        guard KlotskiBoardAnalyzer.validate(board) != .invalid else { return finish(.invalid, startBoard: board, path: nil, reason: "Invalid Klotski board.", start: start, nodes: 0) }
        let result = GraphSearch.breadthFirstSearch(from: board, isGoal: { $0.isSolved }, neighbors: { KlotskiBoardAnalyzer.legalMoves(from: $0).map { ($0.board, $0.move) } }, maxNodes: options.maxNodes, timeout: options.timeout)
        return finish(result.state == .unsolvable ? .noSolution : result.state, startBoard: board, path: result.path, reason: result.failureReason, start: start, nodes: result.nodesExplored)
    }

    private func finish(_ state: SolveState, startBoard: KlotskiBoard, path: GraphPath<KlotskiBoard, MechanicalPuzzleMove>?, reason: String?, start: Date, nodes: Int) -> MechanicalPuzzleSolveResult<KlotskiBoard> {
        let boards = path?.nodes ?? [startBoard]
        let moves = path?.moves ?? []
        let frames = boards.enumerated().map { index, board in
            OrderedMovePlaybackFrame(order: index, move: index == 0 ? nil : moves[index - 1], board: board, caption: index == 0 ? "Start" : moves[index - 1].notation)
        }
        return MechanicalPuzzleSolveResult(kind: .klotski, state: state, moves: moves, playbackFrames: frames, failureReason: state == .solved ? nil : (reason ?? "No Klotski solution found."), elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }
}

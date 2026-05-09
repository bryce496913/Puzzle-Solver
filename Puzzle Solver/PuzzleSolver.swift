//
//  PuzzleSolver.swift
//  Puzzle Solver
//
//  Created by Aditi Abrol on 2/3/24.
//

import Foundation

// MARK: - Shared cube-solving types

enum CubePuzzleKind: String, CaseIterable {
    case twoByTwo = "2×2 Cube"
    case threeByThree = "3×3 Cube"
    case fourByFour = "4×4 Cube"
    case fiveByFive = "5×5 Cube"
    case pyraminx = "Pyraminx"
    case skewb = "Skewb"

    var stickerCount: Int? {
        switch self {
        case .twoByTwo: return 24
        case .threeByThree: return 54
        case .fourByFour: return 96
        case .fiveByFive: return 150
        case .pyraminx, .skewb: return nil
        }
    }
}

struct CubeState: Hashable {
    let puzzle: CubePuzzleKind
    let stickers: [String]

    static let solved2x2 = CubeState(
        puzzle: .twoByTwo,
        stickers: [
            "U", "U", "U", "U",
            "R", "R", "R", "R",
            "F", "F", "F", "F",
            "D", "D", "D", "D",
            "L", "L", "L", "L",
            "B", "B", "B", "B"
        ]
    )

    static let solved3x3 = CubeState(
        puzzle: .threeByThree,
        stickers: [
            "U", "U", "U", "U", "U", "U", "U", "U", "U",
            "R", "R", "R", "R", "R", "R", "R", "R", "R",
            "F", "F", "F", "F", "F", "F", "F", "F", "F",
            "D", "D", "D", "D", "D", "D", "D", "D", "D",
            "L", "L", "L", "L", "L", "L", "L", "L", "L",
            "B", "B", "B", "B", "B", "B", "B", "B", "B"
        ]
    )
}

struct CubeSolutionStep: Identifiable, Hashable {
    let id = UUID()
    let move: String
    let state: CubeState?
}

enum CubeSolveStatus: String {
    case success
    case failure
    case invalidInput
    case timeout
    case unsupportedPuzzle
    case solverUnavailable

    var userFacingMessage: String {
        switch self {
        case .success: return "Solved"
        case .failure: return "Could not solve quickly"
        case .invalidInput: return "Invalid cube"
        case .timeout: return "Could not solve quickly"
        case .unsupportedPuzzle: return "Solver unavailable"
        case .solverUnavailable: return "Solver unavailable"
        }
    }
}

struct CubeSolveResult {
    let status: CubeSolveStatus
    let puzzle: CubePuzzleKind
    let moves: [String]
    let steps: [CubeSolutionStep]
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    var moveCount: Int { moves.count }
    var succeeded: Bool { status == .success }

    static func unavailable(for puzzle: CubePuzzleKind, reason: String, elapsedTime: TimeInterval = 0, nodesExplored: Int = 0) -> CubeSolveResult {
        CubeSolveResult(
            status: .solverUnavailable,
            puzzle: puzzle,
            moves: [],
            steps: [],
            failureReason: reason,
            elapsedTime: elapsedTime,
            nodesExplored: nodesExplored
        )
    }
}

struct CubeSolveOptions {
    let timeout: TimeInterval
    let maxDepth: Int
    let maxNodes: Int
    let includeStepStates: Bool

    static let `default` = CubeSolveOptions(timeout: 5, maxDepth: 14, maxNodes: 50_000, includeStepStates: true)
}

protocol CubeSolverProtocol {
    var supportedPuzzle: CubePuzzleKind { get }
    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult
}

// MARK: - Shared service

final class CubeSolvingService {
    static let shared = CubeSolvingService()

    private let solvers: [CubePuzzleKind: CubeSolverProtocol]
    private let queue = DispatchQueue(label: "cube.solving.service", qos: .userInitiated)

    init(solvers: [CubeSolverProtocol] = [Cube2x2Solver(), Cube3x3Solver(), Cube4x4Solver(), Cube5x5Solver()]) {
        self.solvers = Dictionary(uniqueKeysWithValues: solvers.map { ($0.supportedPuzzle, $0) })
    }

    func solve(
        _ state: CubeState,
        options: CubeSolveOptions = .default,
        completion: @escaping (CubeSolveResult) -> Void
    ) {
        queue.async {
            self.log("input validation started for \(state.puzzle.rawValue)")
            guard let solver = self.solvers[state.puzzle] else {
                self.log("failure reason: unsupported puzzle \(state.puzzle.rawValue)")
                DispatchQueue.main.async {
                    completion(CubeSolveResult(
                        status: .unsupportedPuzzle,
                        puzzle: state.puzzle,
                        moves: [],
                        steps: [],
                        failureReason: "No solver is registered for \(state.puzzle.rawValue).",
                        elapsedTime: 0,
                        nodesExplored: 0
                    ))
                }
                return
            }

            self.log("solver selected: \(type(of: solver))")
            self.log("solver start")
            let result = solver.solve(state, options: options)
            self.log("solver finish: status=\(result.status.rawValue), moves=\(result.moveCount), nodes=\(result.nodesExplored), elapsed=\(String(format: "%.3f", result.elapsedTime))s")
            if let failureReason = result.failureReason {
                self.log("failure reason: \(failureReason)")
            }
            DispatchQueue.main.async {
                self.log("UI state update: \(result.status.userFacingMessage)")
                completion(result)
            }
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[CubeSolvingService] \(message)")
        #endif
    }
}

// MARK: - 2×2 IDA* solver

final class Cube2x2Solver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .twoByTwo

    private struct SearchOutcome {
        let moves: [String]?
        let timedOut: Bool
        let nodeLimited: Bool
    }

    private let solvedState = CubeState.solved2x2
    private let moveNames = ["U", "U'", "U2", "R", "R'", "R2", "F", "F'", "F2"]

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard state.puzzle == supportedPuzzle else {
            return finish(status: .unsupportedPuzzle, state: state, reason: "2×2 solver received \(state.puzzle.rawValue).", start: start, nodes: 0)
        }
        guard validate(state) else {
            return finish(status: .invalidInput, state: state, reason: "Expected exactly 24 stickers with four stickers of each cube color.", start: start, nodes: 0)
        }
        guard state != solvedState else {
            return CubeSolveResult(status: .success, puzzle: state.puzzle, moves: [], steps: [], failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }

        var nodes = 0
        var bound = heuristic(state)
        let searchDeadline = start.addingTimeInterval(options.timeout)
        let cappedDepth = min(options.maxDepth, 14)

        while bound <= cappedDepth {
            let outcome = depthLimitedSearch(
                state: state,
                remainingDepth: bound,
                previousFace: nil,
                path: [],
                deadline: searchDeadline,
                maxNodes: options.maxNodes,
                nodes: &nodes
            )

            if let moves = outcome.moves {
                let steps = options.includeStepStates ? replaySteps(from: state, moves: moves) : moves.map { CubeSolutionStep(move: $0, state: nil) }
                return CubeSolveResult(status: .success, puzzle: state.puzzle, moves: moves, steps: steps, failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
            }
            if outcome.timedOut {
                return finish(status: .timeout, state: state, reason: "2×2 search exceeded \(options.timeout)s timeout.", start: start, nodes: nodes)
            }
            if outcome.nodeLimited {
                return finish(status: .failure, state: state, reason: "2×2 search exceeded \(options.maxNodes) node safety limit.", start: start, nodes: nodes)
            }
            bound += 1
        }

        return finish(status: .failure, state: state, reason: "No 2×2 solution found within depth \(cappedDepth).", start: start, nodes: nodes)
    }

    private func depthLimitedSearch(
        state: CubeState,
        remainingDepth: Int,
        previousFace: Character?,
        path: [String],
        deadline: Date,
        maxNodes: Int,
        nodes: inout Int
    ) -> SearchOutcome {
        if Date() >= deadline { return SearchOutcome(moves: nil, timedOut: true, nodeLimited: false) }
        if nodes >= maxNodes { return SearchOutcome(moves: nil, timedOut: false, nodeLimited: true) }
        nodes += 1

        if state == solvedState { return SearchOutcome(moves: path, timedOut: false, nodeLimited: false) }
        if remainingDepth == 0 || heuristic(state) > remainingDepth { return SearchOutcome(moves: nil, timedOut: false, nodeLimited: false) }

        for move in moveNames {
            let face = move.first
            if face == previousFace { continue }
            let next = apply(move, to: state)
            let outcome = depthLimitedSearch(
                state: next,
                remainingDepth: remainingDepth - 1,
                previousFace: face,
                path: path + [move],
                deadline: deadline,
                maxNodes: maxNodes,
                nodes: &nodes
            )
            if outcome.moves != nil || outcome.timedOut || outcome.nodeLimited { return outcome }
        }

        return SearchOutcome(moves: nil, timedOut: false, nodeLimited: false)
    }

    private func heuristic(_ state: CubeState) -> Int {
        let mismatched = zip(state.stickers, solvedState.stickers).filter { pair in pair.0 != pair.1 }.count
        return Int(ceil(Double(mismatched) / 8.0))
    }

    private func validate(_ state: CubeState) -> Bool {
        guard state.stickers.count == 24 else { return false }
        let counts = Dictionary(grouping: state.stickers, by: { $0 }).mapValues(\.count)
        return counts.count == 6 && counts.values.allSatisfy { $0 == 4 }
    }

    private func replaySteps(from state: CubeState, moves: [String]) -> [CubeSolutionStep] {
        var current = state
        return moves.map { move in
            current = apply(move, to: current)
            return CubeSolutionStep(move: move, state: current)
        }
    }

    private func finish(status: CubeSolveStatus, state: CubeState, reason: String, start: Date, nodes: Int) -> CubeSolveResult {
        CubeSolveResult(status: status, puzzle: state.puzzle, moves: [], steps: [], failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }

    private func apply(_ move: String, to state: CubeState) -> CubeState {
        let turns: Int
        switch move.last {
        case "'": turns = 3
        case "2": turns = 2
        default: turns = 1
        }

        var result = state
        for _ in 0..<turns {
            switch move.first {
            case "U": result = quarterTurn(result, cycles: [[0, 2, 3, 1], [8, 4, 20, 16], [9, 5, 21, 17]])
            case "R": result = quarterTurn(result, cycles: [[4, 6, 7, 5], [1, 9, 13, 23], [3, 11, 15, 21]])
            case "F": result = quarterTurn(result, cycles: [[8, 10, 11, 9], [2, 16, 13, 7], [3, 18, 12, 5]])
            default: break
            }
        }
        return result
    }

    private func quarterTurn(_ state: CubeState, cycles: [[Int]]) -> CubeState {
        var stickers = state.stickers
        let old = stickers
        for cycle in cycles {
            for index in 0..<cycle.count {
                stickers[cycle[(index + 1) % cycle.count]] = old[cycle[index]]
            }
        }
        return CubeState(puzzle: state.puzzle, stickers: stickers)
    }
}

// MARK: - 3×3 Kociemba architecture placeholder

final class Cube3x3Solver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .threeByThree

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard validate(state) else {
            return CubeSolveResult(status: .invalidInput, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Expected exactly 54 stickers with nine stickers of each cube color.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }

        return CubeSolveResult.unavailable(
            for: .threeByThree,
            reason: "3×3 solving is being upgraded. This mode is not available yet. The previous unbounded brute-force path has been disabled until a bounded Kociemba two-phase implementation is connected.",
            elapsedTime: Date().timeIntervalSince(start),
            nodesExplored: 0
        )
    }

    private func validate(_ state: CubeState) -> Bool {
        guard state.puzzle == supportedPuzzle, state.stickers.count == 54 else { return false }
        let counts = Dictionary(grouping: state.stickers, by: { $0 }).mapValues(\.count)
        return counts.count == 6 && counts.values.allSatisfy { $0 == 9 }
    }
}

// MARK: - Reduction-method placeholders for larger cubes

final class Cube4x4Solver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .fourByFour

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard state.puzzle == supportedPuzzle, state.stickers.count == CubePuzzleKind.fourByFour.stickerCount else {
            return CubeSolveResult(status: .invalidInput, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Expected 96 stickers for a 4×4 cube state.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }
        return CubeSolveResult.unavailable(for: .fourByFour, reason: "4×4 reduction-method solver placeholder only; naive full-state solving is intentionally disabled.", elapsedTime: Date().timeIntervalSince(start))
    }
}

final class Cube5x5Solver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .fiveByFive

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard state.puzzle == supportedPuzzle, state.stickers.count == CubePuzzleKind.fiveByFive.stickerCount else {
            return CubeSolveResult(status: .invalidInput, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Expected 150 stickers for a 5×5 cube state.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }
        return CubeSolveResult.unavailable(for: .fiveByFive, reason: "5×5 reduction-method solver placeholder only; naive full-state solving is intentionally disabled.", elapsedTime: Date().timeIntervalSince(start))
    }
}

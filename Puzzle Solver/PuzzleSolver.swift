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
        SolverDebugLogger.shared.log("CubeSolvingService: \(message)")
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


// MARK: - 3×3 two-phase cubie solver

enum Cube3x3Move: String, CaseIterable {
    case U, Ui = "U'", U2
    case D, Di = "D'", D2
    case L, Li = "L'", L2
    case R, Ri = "R'", R2
    case F, Fi = "F'", F2
    case B, Bi = "B'", B2

    var face: Character { rawValue.first! }
    var quarterTurns: Int {
        if rawValue.hasSuffix("'") { return 3 }
        if rawValue.hasSuffix("2") { return 2 }
        return 1
    }

    var isPhase2Move: Bool {
        switch self {
        case .U, .Ui, .U2, .D, .Di, .D2, .L2, .R2, .F2, .B2: return true
        default: return false
        }
    }

    var inverseName: String {
        if rawValue.hasSuffix("'") { return String(rawValue.dropLast()) }
        if rawValue.hasSuffix("2") { return rawValue }
        return rawValue + "'"
    }
}

struct Cube3x3CubieState: Hashable {
    var cornerPermutation: [Int]
    var cornerOrientation: [Int]
    var edgePermutation: [Int]
    var edgeOrientation: [Int]

    static let solved = Cube3x3CubieState(
        cornerPermutation: Array(0..<8),
        cornerOrientation: Array(repeating: 0, count: 8),
        edgePermutation: Array(0..<12),
        edgeOrientation: Array(repeating: 0, count: 12)
    )

    var isSolved: Bool { self == .solved }

    var isInPhase2Subgroup: Bool {
        cornerOrientation.allSatisfy { $0 == 0 } &&
        edgeOrientation.allSatisfy { $0 == 0 } &&
        Set(edgePermutation[8..<12]) == Set(8..<12)
    }

    func applying(_ move: Cube3x3Move, tables: Cube3x3MoveTables = .shared) -> Cube3x3CubieState {
        let transform = tables.transforms[move]!
        var next = Cube3x3CubieState.solved
        for position in 0..<8 {
            let source = transform.cornerPermutation[position]
            next.cornerPermutation[position] = cornerPermutation[source]
            next.cornerOrientation[position] = (cornerOrientation[source] + transform.cornerOrientation[position]) % 3
        }
        for position in 0..<12 {
            let source = transform.edgePermutation[position]
            next.edgePermutation[position] = edgePermutation[source]
            next.edgeOrientation[position] = (edgeOrientation[source] + transform.edgeOrientation[position]) % 2
        }
        return next
    }
}

final class Cube3x3MoveTables {
    static let shared = Cube3x3MoveTables()

    let transforms: [Cube3x3Move: Cube3x3CubieState]
    private let quarterStickerPermutations: [Character: [Int]]

    private init() {
        var quarterPermutations: [Character: [Int]] = [:]
        for face in Array("UDLRFB") {
            quarterPermutations[face] = Cube3x3MoveTables.makeQuarterStickerPermutation(for: face)
        }
        self.quarterStickerPermutations = quarterPermutations

        var built: [Cube3x3Move: Cube3x3CubieState] = [:]
        for move in Cube3x3Move.allCases {
            var stickers = CubeState.solved3x3.stickers
            for _ in 0..<move.quarterTurns {
                stickers = Cube3x3MoveTables.applyStickerPermutation(quarterPermutations[move.face]!, to: stickers)
            }
            built[move] = try! Cube3x3CubieState.from(stickers: stickers).get()
        }
        self.transforms = built
    }

    func apply(_ move: Cube3x3Move, to stickers: [String]) -> [String] {
        var result = stickers
        for _ in 0..<move.quarterTurns {
            result = Self.applyStickerPermutation(quarterStickerPermutations[move.face]!, to: result)
        }
        return result
    }

    private static func applyStickerPermutation(_ permutation: [Int], to stickers: [String]) -> [String] {
        var result = stickers
        for newIndex in 0..<stickers.count {
            result[newIndex] = stickers[permutation[newIndex]]
        }
        return result
    }

    private static func makeQuarterStickerPermutation(for face: Character) -> [Int] {
        let oldFacelets = (0..<54).map(Self.facelet)
        var lookup: [Facelet: Int] = [:]
        for (index, facelet) in oldFacelets.enumerated() { lookup[facelet] = index }

        return oldFacelets.map { destination in
            let source = rotate(destination, face: face, inverse: true)
            return lookup[source]!
        }
    }

    private static func rotate(_ facelet: Facelet, face: Character, inverse: Bool) -> Facelet {
        guard isOnLayer(facelet.coordinate, face: face) else { return facelet }
        let turns = inverse ? 3 : 1
        var coordinate = facelet.coordinate
        var normal = facelet.normal
        for _ in 0..<turns {
            coordinate = rotateClockwise(coordinate, face: face)
            normal = rotateClockwise(normal, face: face)
        }
        return Facelet(coordinate: coordinate, normal: normal)
    }

    private static func isOnLayer(_ coordinate: Vec3, face: Character) -> Bool {
        switch face {
        case "U": return coordinate.y == 1
        case "D": return coordinate.y == -1
        case "R": return coordinate.x == 1
        case "L": return coordinate.x == -1
        case "F": return coordinate.z == 1
        case "B": return coordinate.z == -1
        default: return false
        }
    }

    private static func rotateClockwise(_ v: Vec3, face: Character) -> Vec3 {
        switch face {
        case "U": return Vec3(x: v.z, y: v.y, z: -v.x)
        case "D": return Vec3(x: -v.z, y: v.y, z: v.x)
        case "R": return Vec3(x: v.x, y: -v.z, z: v.y)
        case "L": return Vec3(x: v.x, y: v.z, z: -v.y)
        case "F": return Vec3(x: v.y, y: -v.x, z: v.z)
        case "B": return Vec3(x: -v.y, y: v.x, z: v.z)
        default: return v
        }
    }

    private static func facelet(_ index: Int) -> Facelet {
        let face = index / 9
        let offset = index % 9
        let row = offset / 3
        let column = offset % 3
        switch face {
        case 0: return Facelet(coordinate: Vec3(x: column - 1, y: 1, z: row - 1), normal: Vec3(x: 0, y: 1, z: 0))
        case 1: return Facelet(coordinate: Vec3(x: 1, y: 1 - row, z: 1 - column), normal: Vec3(x: 1, y: 0, z: 0))
        case 2: return Facelet(coordinate: Vec3(x: column - 1, y: 1 - row, z: 1), normal: Vec3(x: 0, y: 0, z: 1))
        case 3: return Facelet(coordinate: Vec3(x: column - 1, y: -1, z: 1 - row), normal: Vec3(x: 0, y: -1, z: 0))
        case 4: return Facelet(coordinate: Vec3(x: -1, y: 1 - row, z: column - 1), normal: Vec3(x: -1, y: 0, z: 0))
        default: return Facelet(coordinate: Vec3(x: 1 - column, y: 1 - row, z: -1), normal: Vec3(x: 0, y: 0, z: -1))
        }
    }

    private struct Vec3: Hashable { let x: Int; let y: Int; let z: Int }
    private struct Facelet: Hashable { let coordinate: Vec3; let normal: Vec3 }
}

struct Cube3x3PruningTables {
    static let shared = Cube3x3PruningTables()

    func phase1LowerBound(_ state: Cube3x3CubieState) -> Int {
        let twistedCorners = state.cornerOrientation.filter { $0 != 0 }.count
        let flippedEdges = state.edgeOrientation.filter { $0 != 0 }.count
        let misplacedSliceEdges = state.edgePermutation[8..<12].filter { !(8..<12).contains($0) }.count
        return max(Int(ceil(Double(twistedCorners) / 4.0)), Int(ceil(Double(flippedEdges) / 4.0)), Int(ceil(Double(misplacedSliceEdges) / 4.0)))
    }

    func phase2LowerBound(_ state: Cube3x3CubieState) -> Int {
        let badCorners = zip(state.cornerPermutation, 0..<8).filter { $0.0 != $0.1 }.count
        let badEdges = zip(state.edgePermutation, 0..<12).filter { $0.0 != $0.1 }.count
        return max(Int(ceil(Double(badCorners) / 4.0)), Int(ceil(Double(badEdges) / 4.0)))
    }
}

final class Cube3x3KociembaSolver {
    private let moveTables = Cube3x3MoveTables.shared
    private let pruningTables = Cube3x3PruningTables.shared
    private let phase1Moves = Cube3x3Move.allCases
    private let phase2Moves = Cube3x3Move.allCases.filter(\.isPhase2Move)

    struct SearchResult {
        let status: CubeSolveStatus
        let moves: [Cube3x3Move]
        let nodes: Int
        let reason: String?
    }

    func solve(_ start: Cube3x3CubieState, options: CubeSolveOptions) -> SearchResult {
        if start.isSolved { return SearchResult(status: .success, moves: [], nodes: 0, reason: nil) }

        let deadline = Date().addingTimeInterval(max(0.1, options.timeout))
        let maxNodes = max(1_000, options.maxNodes)
        let phase1Limit = min(max(7, options.maxDepth), 12)
        let totalLimit = max(20, options.maxDepth)
        var nodes = 0

        for depth in 0...phase1Limit {
            var path: [Cube3x3Move] = []
            let outcome = searchPhase1(state: start, remainingDepth: depth, previousFace: nil, path: &path, deadline: deadline, maxNodes: maxNodes, nodes: &nodes, totalLimit: totalLimit)
            if let moves = outcome.moves { return SearchResult(status: .success, moves: moves, nodes: nodes, reason: nil) }
            if outcome.timedOut { return SearchResult(status: .timeout, moves: [], nodes: nodes, reason: "Timed out during 3×3 two-phase search.") }
            if outcome.nodeLimited { return SearchResult(status: .failure, moves: [], nodes: nodes, reason: "Stopped at the configured 3×3 search safety limit.") }
        }
        return SearchResult(status: .failure, moves: [], nodes: nodes, reason: "No phase-1 reduction was found within the bounded search depth.")
    }

    private struct Outcome { let moves: [Cube3x3Move]?; let timedOut: Bool; let nodeLimited: Bool }

    private func searchPhase1(state: Cube3x3CubieState, remainingDepth: Int, previousFace: Character?, path: inout [Cube3x3Move], deadline: Date, maxNodes: Int, nodes: inout Int, totalLimit: Int) -> Outcome {
        if Date() >= deadline { return Outcome(moves: nil, timedOut: true, nodeLimited: false) }
        if nodes >= maxNodes { return Outcome(moves: nil, timedOut: false, nodeLimited: true) }
        if pruningTables.phase1LowerBound(state) > remainingDepth { return Outcome(moves: nil, timedOut: false, nodeLimited: false) }

        if remainingDepth == 0 {
            guard state.isInPhase2Subgroup else { return Outcome(moves: nil, timedOut: false, nodeLimited: false) }
            let remainingTotal = max(0, totalLimit - path.count)
            for depth in 0...remainingTotal {
                var phase2Path: [Cube3x3Move] = []
                let outcome = searchPhase2(state: state, remainingDepth: depth, previousFace: nil, path: &phase2Path, deadline: deadline, maxNodes: maxNodes, nodes: &nodes)
                if let suffix = outcome.moves { return Outcome(moves: path + suffix, timedOut: false, nodeLimited: false) }
                if outcome.timedOut || outcome.nodeLimited { return outcome }
            }
            return Outcome(moves: nil, timedOut: false, nodeLimited: false)
        }

        for move in phase1Moves where shouldTry(move, after: previousFace) {
            nodes += 1
            path.append(move)
            let outcome = searchPhase1(state: state.applying(move, tables: moveTables), remainingDepth: remainingDepth - 1, previousFace: move.face, path: &path, deadline: deadline, maxNodes: maxNodes, nodes: &nodes, totalLimit: totalLimit)
            if outcome.moves != nil || outcome.timedOut || outcome.nodeLimited { return outcome }
            path.removeLast()
        }
        return Outcome(moves: nil, timedOut: false, nodeLimited: false)
    }

    private func searchPhase2(state: Cube3x3CubieState, remainingDepth: Int, previousFace: Character?, path: inout [Cube3x3Move], deadline: Date, maxNodes: Int, nodes: inout Int) -> Outcome {
        if Date() >= deadline { return Outcome(moves: nil, timedOut: true, nodeLimited: false) }
        if nodes >= maxNodes { return Outcome(moves: nil, timedOut: false, nodeLimited: true) }
        if state.isSolved { return Outcome(moves: path, timedOut: false, nodeLimited: false) }
        if remainingDepth == 0 || pruningTables.phase2LowerBound(state) > remainingDepth { return Outcome(moves: nil, timedOut: false, nodeLimited: false) }

        for move in phase2Moves where shouldTry(move, after: previousFace) {
            nodes += 1
            path.append(move)
            let outcome = searchPhase2(state: state.applying(move, tables: moveTables), remainingDepth: remainingDepth - 1, previousFace: move.face, path: &path, deadline: deadline, maxNodes: maxNodes, nodes: &nodes)
            if outcome.moves != nil || outcome.timedOut || outcome.nodeLimited { return outcome }
            path.removeLast()
        }
        return Outcome(moves: nil, timedOut: false, nodeLimited: false)
    }

    private func shouldTry(_ move: Cube3x3Move, after previousFace: Character?) -> Bool {
        guard let previousFace else { return true }
        if move.face == previousFace { return false }
        if (previousFace == "U" && move.face == "D") || (previousFace == "D" && move.face == "U") { return false }
        if (previousFace == "L" && move.face == "R") || (previousFace == "R" && move.face == "L") { return false }
        if (previousFace == "F" && move.face == "B") || (previousFace == "B" && move.face == "F") { return false }
        return true
    }
}

final class Cube3x3Solver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .threeByThree
    private let kociembaSolver = Cube3x3KociembaSolver()

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard state.puzzle == supportedPuzzle else {
            return CubeSolveResult(status: .invalidInput, puzzle: supportedPuzzle, moves: [], steps: [], failureReason: "Expected a 3×3 cube state.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }
        let normalizedOptions = CubeSolveOptions(timeout: options.timeout, maxDepth: max(options.maxDepth, 20), maxNodes: max(options.maxNodes, 250_000), includeStepStates: options.includeStepStates)

        let cubieState: Cube3x3CubieState
        switch Cube3x3CubieState.from(stickers: state.stickers) {
        case .success(let converted): cubieState = converted
        case .failure(let error):
            return CubeSolveResult(status: .invalidInput, puzzle: supportedPuzzle, moves: [], steps: [], failureReason: error.localizedDescription, elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }

        let search = kociembaSolver.solve(cubieState, options: normalizedOptions)
        let moveNames = search.moves.map(\.rawValue)
        return CubeSolveResult(status: search.status, puzzle: supportedPuzzle, moves: moveNames, steps: [], failureReason: search.reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: search.nodes)
    }

}

extension Cube3x3CubieState {
    enum ConversionError: LocalizedError {
        case wrongStickerCount
        case invalidColorCounts
        case duplicateCenters
        case missingCorner(String)
        case missingEdge(String)
        case duplicateCubie(String)
        case invalidOrientation
        case parityMismatch

        var errorDescription: String? {
            switch self {
            case .wrongStickerCount: return "Expected exactly 54 stickers for a 3×3 cube."
            case .invalidColorCounts: return "Expected exactly nine stickers of each of the six center colors."
            case .duplicateCenters: return "The six center stickers must be distinct so face colors can be identified."
            case .missingCorner(let cubie): return "Missing or impossible corner cubie: \(cubie)."
            case .missingEdge(let cubie): return "Missing or impossible edge cubie: \(cubie)."
            case .duplicateCubie(let cubie): return "Duplicate cubie detected: \(cubie)."
            case .invalidOrientation: return "The cube has impossible cubie orientation."
            case .parityMismatch: return "The cube has impossible permutation parity."
            }
        }
    }

    static func from(stickers: [String]) -> Result<Cube3x3CubieState, ConversionError> {
        guard stickers.count == 54 else { return .failure(.wrongStickerCount) }
        let centerIndices = [4, 13, 22, 31, 40, 49]
        let faceNames = ["U", "R", "F", "D", "L", "B"]
        let centers = centerIndices.map { stickers[$0] }
        guard Set(centers).count == 6 else { return .failure(.duplicateCenters) }
        let counts = Dictionary(grouping: stickers, by: { $0 }).mapValues(\.count)
        guard centers.allSatisfy({ counts[$0] == 9 }) && counts.count == 6 else { return .failure(.invalidColorCounts) }
        let colorToFace = Dictionary(uniqueKeysWithValues: zip(centers, faceNames))
        let normalized = stickers.map { colorToFace[$0] ?? "?" }

        let cornerFacelets = [[8, 9, 20], [6, 18, 38], [0, 36, 47], [2, 45, 11], [29, 26, 15], [27, 44, 24], [33, 53, 42], [35, 17, 51]]
        let cornerColors = [["U", "R", "F"], ["U", "F", "L"], ["U", "L", "B"], ["U", "B", "R"], ["D", "F", "R"], ["D", "L", "F"], ["D", "B", "L"], ["D", "R", "B"]]
        let edgeFacelets = [[5, 10], [7, 19], [3, 37], [1, 46], [32, 16], [28, 25], [30, 43], [34, 52], [23, 12], [21, 41], [50, 39], [48, 14]]
        let edgeColors = [["U", "R"], ["U", "F"], ["U", "L"], ["U", "B"], ["D", "R"], ["D", "F"], ["D", "L"], ["D", "B"], ["F", "R"], ["F", "L"], ["B", "L"], ["B", "R"]]
        let cornerLookup = Dictionary(uniqueKeysWithValues: cornerColors.enumerated().map { (Set($0.element), $0.offset) })
        let edgeLookup = Dictionary(uniqueKeysWithValues: edgeColors.enumerated().map { (Set($0.element), $0.offset) })

        var cp = Array(repeating: -1, count: 8)
        var co = Array(repeating: 0, count: 8)
        var seenCorners = Set<Int>()
        for position in 0..<8 {
            let colors = cornerFacelets[position].map { normalized[$0] }
            guard let cubie = cornerLookup[Set(colors)] else { return .failure(.missingCorner(colors.joined())) }
            guard seenCorners.insert(cubie).inserted else { return .failure(.duplicateCubie(colors.joined())) }
            cp[position] = cubie
            guard let orientation = colors.firstIndex(where: { $0 == "U" || $0 == "D" }) else { return .failure(.missingCorner(colors.joined())) }
            co[position] = orientation % 3
        }

        var ep = Array(repeating: -1, count: 12)
        var eo = Array(repeating: 0, count: 12)
        var seenEdges = Set<Int>()
        for position in 0..<12 {
            let colors = edgeFacelets[position].map { normalized[$0] }
            guard let cubie = edgeLookup[Set(colors)] else { return .failure(.missingEdge(colors.joined())) }
            guard seenEdges.insert(cubie).inserted else { return .failure(.duplicateCubie(colors.joined())) }
            ep[position] = cubie
            if colors.contains("U") || colors.contains("D") {
                eo[position] = (colors[0] == "U" || colors[0] == "D") ? 0 : 1
            } else {
                eo[position] = (colors[0] == "F" || colors[0] == "B") ? 0 : 1
            }
        }

        guard co.reduce(0, +) % 3 == 0, eo.reduce(0, +) % 2 == 0 else { return .failure(.invalidOrientation) }
        guard parity(cp) == parity(ep) else { return .failure(.parityMismatch) }
        return .success(Cube3x3CubieState(cornerPermutation: cp, cornerOrientation: co, edgePermutation: ep, edgeOrientation: eo))
    }

    private static func parity(_ permutation: [Int]) -> Int {
        var inversions = 0
        for i in 0..<permutation.count {
            for j in (i + 1)..<permutation.count where permutation[i] > permutation[j] { inversions += 1 }
        }
        return inversions % 2
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

// MARK: - Shared solve states, diagnostics, and logging

enum SolveState: String, CaseIterable, Equatable {
    case idle
    case validating
    case solving
    case solved
    case invalid
    case unsolvable
    case timedOut
    case failed
    case unsupported

    var friendlyTitle: String {
        switch self {
        case .idle: return "Ready"
        case .validating: return "Checking puzzle…"
        case .solving: return "Solving…"
        case .solved: return "Solved"
        case .invalid: return "Check your puzzle"
        case .unsolvable: return "This puzzle cannot be solved"
        case .timedOut: return "Solver took too long"
        case .failed: return "Could not solve this one"
        case .unsupported: return "Solver unavailable"
        }
    }

    var friendlyMessage: String {
        switch self {
        case .idle: return "Enter a puzzle or try an example."
        case .validating: return "Making sure the puzzle is valid."
        case .solving: return "Looking for a safe solution."
        case .solved: return "Solution ready."
        case .invalid: return "Please check the puzzle and try again."
        case .unsolvable: return "This layout is not solvable."
        case .timedOut: return "Try a simpler scramble or raise the limit."
        case .failed: return "Please try another puzzle."
        case .unsupported: return "This mode is not supported yet."
        }
    }
}

struct SolveStatusSnapshot: Equatable {
    let modeName: String
    let state: SolveState
    let detail: String
    let timestamp: Date
}

final class SolverDiagnosticsStore {
    static let shared = SolverDiagnosticsStore()

    private let lock = NSLock()
    private var snapshot = SolveStatusSnapshot(modeName: "None", state: .idle, detail: "No solve has run yet.", timestamp: Date())

    var lastSolveStatus: SolveStatusSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshot
    }

    func record(modeName: String, state: SolveState, detail: String) {
        lock.lock()
        snapshot = SolveStatusSnapshot(modeName: modeName, state: state, detail: detail, timestamp: Date())
        lock.unlock()
    }
}

final class SolverDebugLogger {
    static let shared = SolverDebugLogger()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "SolverDebugLoggingEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "SolverDebugLoggingEnabled") }
    }

    func log(_ message: String) {
        #if DEBUG
        guard isEnabled else { return }
        print("[SolverDebug] \(message)")
        #endif
    }
}

struct PuzzleModeDiagnostic: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let enabled: Bool
    let solverAvailable: Bool
}

enum PuzzleModeRegistry {
    static let diagnostics: [PuzzleModeDiagnostic] = [
        PuzzleModeDiagnostic(name: "3×3 Sliding Puzzle", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "4×4 Sliding Puzzle", enabled: false, solverAvailable: true),
        PuzzleModeDiagnostic(name: "2×2 Cube", enabled: false, solverAvailable: true),
        PuzzleModeDiagnostic(name: "3×3 Cube", enabled: false, solverAvailable: true),
        PuzzleModeDiagnostic(name: "4×4 Cube", enabled: false, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Sudoku", enabled: false, solverAvailable: false)
    ]
}

// MARK: - Sliding puzzle solver

struct SlidingPuzzleBoard: Hashable, Equatable {
    let size: Int
    let tiles: [Int]

    var blankIndex: Int? { tiles.firstIndex(of: 0) }
    var isSolved: Bool { tiles == SlidingPuzzleBoard.solved(size: size).tiles }

    static func solved(size: Int) -> SlidingPuzzleBoard {
        SlidingPuzzleBoard(size: size, tiles: Array(1..<(size * size)) + [0])
    }

    static func fromGrid(_ grid: [[Int?]], size: Int) -> SlidingPuzzleBoard? {
        guard grid.count == size, grid.allSatisfy({ $0.count == size }) else { return nil }
        return SlidingPuzzleBoard(size: size, tiles: grid.flatMap { row in row.map { $0 ?? 0 } })
    }

    func toGrid() -> [[Int?]] {
        stride(from: 0, to: tiles.count, by: size).map { start in
            tiles[start..<(start + size)].map { $0 == 0 ? nil : $0 }
        }
    }
}

struct SlidingPuzzleSolveOptions {
    let timeout: TimeInterval
    let maxNodes: Int

    static let `default` = SlidingPuzzleSolveOptions(timeout: 5, maxNodes: 250_000)
}

struct SlidingPuzzleSolveResult: Equatable {
    let state: SolveState
    let moves: [String]
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    var succeeded: Bool { state == .solved }
}

final class SlidingPuzzleSolver {
    private struct SearchNode {
        let board: SlidingPuzzleBoard
        let moves: [String]
        let cost: Int
        let priority: Int
    }

    func solve(_ board: SlidingPuzzleBoard, options: SlidingPuzzleSolveOptions = .default) -> SlidingPuzzleSolveResult {
        let start = Date()
        SolverDebugLogger.shared.log("solver selected: SlidingPuzzleSolver \(board.size)×\(board.size)")
        SolverDebugLogger.shared.log("validation result: started")

        guard validate(board) else {
            SolverDebugLogger.shared.log("validation result: invalid")
            SolverDebugLogger.shared.log("failure reason: invalid sliding puzzle input")
            return finish(.invalid, reason: "Please use each tile once.", start: start, nodes: 0)
        }
        SolverDebugLogger.shared.log("validation result: valid")

        guard isSolvable(board) else {
            SolverDebugLogger.shared.log("failure reason: unsolvable sliding puzzle")
            return finish(.unsolvable, reason: "This layout is not solvable.", start: start, nodes: 0)
        }

        if board.isSolved {
            SolverDebugLogger.shared.log("solve finished: already solved")
            return SlidingPuzzleSolveResult(state: .solved, moves: [], failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }

        SolverDebugLogger.shared.log("solve started")
        let deadline = start.addingTimeInterval(max(0, options.timeout))
        var frontier = [SearchNode(board: board, moves: [], cost: 0, priority: manhattan(board))]
        var bestCost: [SlidingPuzzleBoard: Int] = [board: 0]
        var nodes = 0

        while !frontier.isEmpty {
            if Date() >= deadline {
                SolverDebugLogger.shared.log("failure reason: sliding puzzle timed out")
                return finish(.timedOut, reason: "Solver took too long.", start: start, nodes: nodes)
            }
            if nodes >= options.maxNodes {
                SolverDebugLogger.shared.log("failure reason: sliding puzzle node limit reached")
                return finish(.timedOut, reason: "Solver took too long.", start: start, nodes: nodes)
            }

            frontier.sort { lhs, rhs in
                lhs.priority == rhs.priority ? lhs.cost > rhs.cost : lhs.priority > rhs.priority
            }
            let current = frontier.removeLast()
            nodes += 1

            if current.board.isSolved {
                SolverDebugLogger.shared.log("solve finished: solved in \(current.moves.count) moves")
                return SlidingPuzzleSolveResult(state: .solved, moves: current.moves, failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
            }

            for neighbor in neighbors(of: current.board) {
                let nextCost = current.cost + 1
                guard nextCost < (bestCost[neighbor.board] ?? Int.max) else { continue }
                bestCost[neighbor.board] = nextCost
                let nextMoves = current.moves + [neighbor.move]
                frontier.append(SearchNode(board: neighbor.board, moves: nextMoves, cost: nextCost, priority: nextCost + manhattan(neighbor.board)))
            }
        }

        SolverDebugLogger.shared.log("failure reason: no solution found")
        return finish(.failed, reason: "Could not find a solution.", start: start, nodes: nodes)
    }

    private func validate(_ board: SlidingPuzzleBoard) -> Bool {
        guard board.size >= 2, board.tiles.count == board.size * board.size else { return false }
        return board.tiles.sorted() == Array(0..<(board.size * board.size))
    }

    private func isSolvable(_ board: SlidingPuzzleBoard) -> Bool {
        let values = board.tiles.filter { $0 != 0 }
        var inversions = 0
        for i in 0..<values.count {
            for j in (i + 1)..<values.count where values[i] > values[j] { inversions += 1 }
        }
        if board.size % 2 == 1 { return inversions % 2 == 0 }
        guard let blankIndex = board.blankIndex else { return false }
        let blankRowFromBottom = board.size - (blankIndex / board.size)
        return blankRowFromBottom % 2 == 0 ? inversions % 2 == 1 : inversions % 2 == 0
    }

    private func manhattan(_ board: SlidingPuzzleBoard) -> Int {
        board.tiles.enumerated().reduce(0) { total, entry in
            let (index, value) = entry
            guard value != 0 else { return total }
            let goal = value - 1
            return total + abs(index / board.size - goal / board.size) + abs(index % board.size - goal % board.size)
        }
    }

    private func neighbors(of board: SlidingPuzzleBoard) -> [(board: SlidingPuzzleBoard, move: String)] {
        guard let blank = board.blankIndex else { return [] }
        let row = blank / board.size
        let col = blank % board.size
        let candidates: [(dr: Int, dc: Int, move: String)] = [(-1, 0, "Move blank up"), (1, 0, "Move blank down"), (0, -1, "Move blank left"), (0, 1, "Move blank right")]

        return candidates.compactMap { candidate in
            let nextRow = row + candidate.dr
            let nextCol = col + candidate.dc
            guard (0..<board.size).contains(nextRow), (0..<board.size).contains(nextCol) else { return nil }
            var tiles = board.tiles
            let swapIndex = nextRow * board.size + nextCol
            tiles[blank] = tiles[swapIndex]
            tiles[swapIndex] = 0
            return (SlidingPuzzleBoard(size: board.size, tiles: tiles), candidate.move)
        }
    }

    private func finish(_ state: SolveState, reason: String, start: Date, nodes: Int) -> SlidingPuzzleSolveResult {
        SlidingPuzzleSolveResult(state: state, moves: [], failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }
}

enum PuzzlePresets {
    static let sliding3x3Solved = SlidingPuzzleBoard.solved(size: 3)
    static let sliding3x3OneMove = SlidingPuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8])
    static let sliding3x3Medium = SlidingPuzzleBoard(size: 3, tiles: [1, 2, 3, 5, 0, 6, 4, 7, 8])
    static let sliding3x3Unsolvable = SlidingPuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 8, 7, 0])

    static let sliding4x4Solved = SlidingPuzzleBoard.solved(size: 4)
    static let sliding4x4OneMove = SlidingPuzzleBoard(size: 4, tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 15])
    static let sliding4x4Medium = SlidingPuzzleBoard(size: 4, tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 0, 14, 15])
}

extension CubeSolveStatus {
    var solveState: SolveState {
        switch self {
        case .success: return .solved
        case .failure: return .failed
        case .invalidInput: return .invalid
        case .timeout: return .timedOut
        case .unsupportedPuzzle, .solverUnavailable: return .unsupported
        }
    }
}

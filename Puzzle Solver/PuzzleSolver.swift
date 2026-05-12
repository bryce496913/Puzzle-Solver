//
//  PuzzleSolver.swift
//  Puzzle Solver
//
//  Created by Aditi Abrol on 2/3/24.
//

import Foundation

// MARK: - Shared twisty puzzle domain models

enum TwistyPuzzleKind: String, CaseIterable, Identifiable, Hashable {
    case twoByTwo = "2×2 Cube"
    case threeByThree = "3×3 Cube"
    case pyraminx = "Pyraminx"
    case skewb = "Skewb"
    case megaminx = "Megaminx"
    case squareOne = "Square-1"
    case fourByFour = "4×4 Cube"
    case fiveByFive = "5×5 Cube"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var stickerCount: Int? {
        switch self {
        case .twoByTwo: return 24
        case .threeByThree: return 54
        case .pyraminx: return 36
        case .skewb: return 30
        case .megaminx: return 132
        case .squareOne: return 24
        case .fourByFour: return 96
        case .fiveByFive: return 150
        }
    }

    var faces: [String] {
        switch self {
        case .pyraminx: return ["U", "L", "R", "B"]
        case .megaminx: return ["U", "R", "F", "D", "L", "B", "uR", "uL", "dR", "dL", "bR", "bL"]
        case .squareOne: return ["U", "D", "M"]
        default: return ["U", "R", "F", "D", "L", "B"]
        }
    }

    var isSolveEnabled: Bool {
        switch self {
        case .twoByTwo, .threeByThree, .pyraminx, .skewb: return true
        case .megaminx, .squareOne, .fourByFour, .fiveByFive: return false
        }
    }

    var notation: TwistyNotationSpec { TwistyNotationSpec(puzzle: self) }
}

struct TwistyPuzzleState: Hashable {
    let puzzle: TwistyPuzzleKind
    let stickers: [String]

    var isSolvedByFace: Bool {
        guard let stickerCount = puzzle.stickerCount, stickers.count == stickerCount else { return false }
        let perFace = stickerCount / puzzle.faces.count
        for faceIndex in 0..<puzzle.faces.count {
            let range = (faceIndex * perFace)..<((faceIndex + 1) * perFace)
            guard let first = stickers[safe: range.lowerBound], stickers[range].allSatisfy({ $0 == first }) else { return false }
        }
        return true
    }

    static func solved(_ puzzle: TwistyPuzzleKind) -> TwistyPuzzleState {
        let stickers = puzzle.faces.flatMap { face -> [String] in
            let perFace = (puzzle.stickerCount ?? puzzle.faces.count) / puzzle.faces.count
            return Array(repeating: face, count: perFace)
        }
        return TwistyPuzzleState(puzzle: puzzle, stickers: stickers)
    }

    static let solved2x2 = TwistyPuzzleState.solved(.twoByTwo)
    static let solved3x3 = TwistyPuzzleState.solved(.threeByThree)
    static let solvedPyraminx = TwistyPuzzleState.solved(.pyraminx)
    static let solvedSkewb = TwistyPuzzleState.solved(.skewb)
    static let solvedMegaminx = TwistyPuzzleState.solved(.megaminx)
    static let solvedSquareOne = TwistyPuzzleState.solved(.squareOne)
}

struct TwistyMove: Hashable, Identifiable, CustomStringConvertible {
    enum Amount: Int, Hashable {
        case clockwise = 1
        case halfTurn = 2
        case counterClockwise = 3

        var suffix: String {
            switch self {
            case .clockwise: return ""
            case .halfTurn: return "2"
            case .counterClockwise: return "'"
            }
        }
    }

    let face: String
    let amount: Amount
    let wide: Bool

    var id: String { notation }
    var notation: String { face + (wide ? "w" : "") + amount.suffix }
    var description: String { notation }
    var inverse: TwistyMove {
        switch amount {
        case .clockwise: return TwistyMove(face: face, amount: .counterClockwise, wide: wide)
        case .counterClockwise: return TwistyMove(face: face, amount: .clockwise, wide: wide)
        case .halfTurn: return self
        }
    }
}

struct TwistyNotationSpec: Hashable {
    let puzzle: TwistyPuzzleKind
    let allowedFaces: Set<String>
    let allowedAmounts: Set<TwistyMove.Amount>
    let allowWideMoves: Bool
    let sampleScramble: String
    let helpText: String

    init(puzzle: TwistyPuzzleKind) {
        self.puzzle = puzzle
        switch puzzle {
        case .twoByTwo:
            allowedFaces = Set(["U", "R", "F"])
            allowedAmounts = Set([.clockwise, .halfTurn, .counterClockwise])
            allowWideMoves = false
            sampleScramble = "R U R' U'"
            helpText = "2×2 uses U/R/F quarter turns, inverse turns, and half turns."
        case .threeByThree:
            allowedFaces = Set(["U", "R", "F", "D", "L", "B"])
            allowedAmounts = Set([.clockwise, .halfTurn, .counterClockwise])
            allowWideMoves = false
            sampleScramble = "R U R' U'"
            helpText = "3×3 uses standard Singmaster notation: U R F D L B, optional ' or 2."
        case .pyraminx:
            allowedFaces = Set(["U", "L", "R", "B", "u", "l", "r", "b"])
            allowedAmounts = Set([.clockwise, .counterClockwise])
            allowWideMoves = false
            sampleScramble = "U R L' B u r'"
            helpText = "Pyraminx supports U/L/R/B body turns plus lowercase u/l/r/b tip turns; use ' for inverse."
        case .skewb:
            allowedFaces = Set(["U", "L", "R", "B"])
            allowedAmounts = Set([.clockwise, .counterClockwise])
            allowWideMoves = false
            sampleScramble = "R U R' B L'"
            helpText = "Skewb supports U/L/R/B corner-axis turns and inverse turns."
        case .megaminx:
            allowedFaces = Set(["R", "D", "U"])
            allowedAmounts = Set([.clockwise, .counterClockwise])
            allowWideMoves = true
            sampleScramble = "R D' U'"
            helpText = "Megaminx placeholder accepts a future R++/R--/D++/D-- style notation architecture."
        case .squareOne:
            allowedFaces = []
            allowedAmounts = []
            allowWideMoves = false
            sampleScramble = "(1,0) / (3,-2) /"
            helpText = "Square-1 placeholder is reserved for tuple turns such as (1,0) followed by slash moves."
        case .fourByFour:
            allowedFaces = Set(["U", "R", "F", "D", "L", "B"])
            allowedAmounts = Set([.clockwise, .halfTurn, .counterClockwise])
            allowWideMoves = true
            sampleScramble = "Rw U Rw' F2"
            helpText = "4×4 placeholder supports future outer and wide move notation."
        case .fiveByFive:
            allowedFaces = Set(["U", "R", "F", "D", "L", "B"])
            allowedAmounts = Set([.clockwise, .halfTurn, .counterClockwise])
            allowWideMoves = true
            sampleScramble = "Rw U2 Fw' R"
            helpText = "5×5 placeholder supports future outer and wide move notation."
        }
    }

    var supportedMovesText: String {
        switch puzzle {
        case .pyraminx: return "U U' L L' R R' B B' u u' l l' r r' b b'"
        case .skewb: return "U U' L L' R R' B B'"
        case .squareOne: return "Tuple notation placeholder: (top,bottom) and /"
        case .megaminx: return "Placeholder parser: R R' D D' U U' (R++/D-- tables planned)"
        default:
            return allowedFaces.sorted().flatMap { face in
                allowedAmounts.sorted { $0.rawValue < $1.rawValue }.map { face + $0.suffix }
            }.joined(separator: " ")
        }
    }
}

enum TwistyMoveNotation {
    enum NotationError: LocalizedError {
        case emptyToken
        case invalidFace(String)
        case invalidSuffix(String)

        var errorDescription: String? {
            switch self {
            case .emptyToken: return "Move notation contains an empty token."
            case .invalidFace(let token): return "Unsupported move face in token \"\(token)\"."
            case .invalidSuffix(let token): return "Unsupported move suffix in token \"\(token)\"."
            }
        }
    }

    static func parse(_ notation: String, allowedFaces: Set<String>, allowedAmounts: Set<TwistyMove.Amount> = Set([.clockwise, .halfTurn, .counterClockwise]), allowWideMoves: Bool = true) -> Result<[TwistyMove], NotationError> {
        let normalized = notation.replacingOccurrences(of: "’", with: "'")
        let tokens = normalized.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        var moves: [TwistyMove] = []
        for token in tokens {
            switch parseToken(token, allowedFaces: allowedFaces, allowedAmounts: allowedAmounts, allowWideMoves: allowWideMoves) {
            case .success(let move): moves.append(move)
            case .failure(let error): return .failure(error)
            }
        }
        return .success(moves)
    }

    static func format(_ moves: [TwistyMove]) -> String {
        moves.map(\.notation).joined(separator: " ")
    }

    static func parse(_ notation: String, spec: TwistyNotationSpec) -> Result<[TwistyMove], NotationError> {
        parse(notation, allowedFaces: spec.allowedFaces, allowedAmounts: spec.allowedAmounts, allowWideMoves: spec.allowWideMoves)
    }

    private static func parseToken(_ token: String, allowedFaces: Set<String>, allowedAmounts: Set<TwistyMove.Amount>, allowWideMoves: Bool) -> Result<TwistyMove, NotationError> {
        guard !token.isEmpty else { return .failure(.emptyToken) }
        var remaining = token
        let face = String(remaining.removeFirst())
        guard allowedFaces.contains(face) else { return .failure(.invalidFace(token)) }

        var wide = false
        if allowWideMoves, remaining.first == "w" {
            wide = true
            remaining.removeFirst()
        }

        let amount: TwistyMove.Amount
        switch remaining {
        case "": amount = .clockwise
        case "2": amount = .halfTurn
        case "'": amount = .counterClockwise
        default: return .failure(.invalidSuffix(token))
        }
        guard allowedAmounts.contains(amount) else { return .failure(.invalidSuffix(token)) }
        return .success(TwistyMove(face: face, amount: amount, wide: wide))
    }
}

struct TwistySolutionStep: Identifiable, Hashable {
    let id = UUID()
    let move: TwistyMove?
    let notation: String
    let state: TwistyPuzzleState?

    init(move: TwistyMove?, state: TwistyPuzzleState?) {
        self.move = move
        self.notation = move?.notation ?? "Start"
        self.state = state
    }

    init(move: String, state: TwistyPuzzleState?) {
        let parsed = TwistyMoveNotation.parse(move, allowedFaces: Set("URFDLB".map(String.init)))
        self.move = try? parsed.get().first
        self.notation = move
        self.state = state
    }
}

enum TwistySolveStatus: String {
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
        case .invalidInput: return "Invalid puzzle"
        case .timeout: return "Could not solve before the timeout"
        case .unsupportedPuzzle, .solverUnavailable: return "Solver unavailable"
        }
    }
}

struct TwistySolveResult {
    let status: TwistySolveStatus
    let puzzle: TwistyPuzzleKind
    let moves: [String]
    let steps: [TwistySolutionStep]
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    var moveCount: Int { moves.count }
    var succeeded: Bool { status == .success }
    var formattedMoves: String { moves.joined(separator: " ") }

    static func unavailable(for puzzle: TwistyPuzzleKind, reason: String, elapsedTime: TimeInterval = 0, nodesExplored: Int = 0) -> TwistySolveResult {
        TwistySolveResult(status: .solverUnavailable, puzzle: puzzle, moves: [], steps: [], failureReason: reason, elapsedTime: elapsedTime, nodesExplored: nodesExplored)
    }
}

struct TwistySolveOptions {
    let timeout: TimeInterval
    let maxDepth: Int
    let maxNodes: Int
    let includeStepStates: Bool

    static let `default` = TwistySolveOptions(timeout: 5, maxDepth: 14, maxNodes: 50_000, includeStepStates: true)
}

protocol TwistyPuzzleSolving {
    var supportedPuzzle: TwistyPuzzleKind { get }
    func solve(_ state: TwistyPuzzleState, options: TwistySolveOptions) -> TwistySolveResult
}

// Backwards-compatible cube names used by the existing views and diagnostics.
typealias CubePuzzleKind = TwistyPuzzleKind
typealias CubeState = TwistyPuzzleState
typealias CubeSolutionStep = TwistySolutionStep
typealias CubeSolveStatus = TwistySolveStatus
typealias CubeSolveResult = TwistySolveResult
typealias CubeSolveOptions = TwistySolveOptions
typealias CubeSolverProtocol = TwistyPuzzleSolving


private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Shared service

final class CubeSolvingService {
    static let shared = CubeSolvingService()

    private let solvers: [CubePuzzleKind: CubeSolverProtocol]
    private let queue = DispatchQueue(label: "cube.solving.service", qos: .userInitiated)

    init(solvers: [CubeSolverProtocol] = [Cube2x2Solver(), Cube3x3Solver(), PyraminxSolver(), SkewbSolver(), MegaminxSolver(), SquareOneSolver(), Cube4x4Solver(), Cube5x5Solver()]) {
        self.solvers = Dictionary(uniqueKeysWithValues: solvers.map { ($0.supportedPuzzle, $0) })
    }

    func solve(
        _ state: CubeState,
        options: CubeSolveOptions = .default,
        completion: @escaping (CubeSolveResult) -> Void
    ) {
        let ticket = TimedSolveTicket()
        let timeout = max(0.1, options.timeout)
        let started = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard ticket.claim() else { return }
            self.log("solver timeout delivered after \(timeout)s")
            completion(CubeSolveResult(
                status: .timeout,
                puzzle: state.puzzle,
                moves: [],
                steps: [],
                failureReason: "Solver exceeded the \(timeout)s timeout.",
                elapsedTime: Date().timeIntervalSince(started),
                nodesExplored: 0
            ))
        }

        queue.async {
            self.log("input validation started for \(state.puzzle.rawValue)")
            guard let solver = self.solvers[state.puzzle] else {
                self.log("failure reason: unsupported puzzle \(state.puzzle.rawValue)")
                DispatchQueue.main.async {
                    guard ticket.claim() else { return }
                    completion(CubeSolveResult(
                        status: .unsupportedPuzzle,
                        puzzle: state.puzzle,
                        moves: [],
                        steps: [],
                        failureReason: "No solver is registered for \(state.puzzle.rawValue).",
                        elapsedTime: Date().timeIntervalSince(started),
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
                guard ticket.claim() else { return }
                self.log("UI state update: \(result.status.userFacingMessage)")
                completion(result)
            }
        }
    }

    private func log(_ message: String) {
        SolverDebugLogger.shared.log("CubeSolvingService: \(message)")
    }
}

private final class TimedSolveTicket {
    private let lock = NSLock()
    private var finished = false

    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !finished else { return false }
        finished = true
        return true
    }
}

// MARK: - 2×2 IDA* solver


enum TwoByTwoMoveEngine {
    static let legalMoveNotation = "U U' U2 R R' R2 F F' F2"
    static let legalMoves = TwistyMoveNotation.parse(legalMoveNotation, allowedFaces: Set(["U", "R", "F"])).movesOrEmpty

    static func apply(_ move: String, to state: CubeState) -> CubeState {
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

    static func apply(_ moves: [String], to state: CubeState) -> CubeState {
        moves.reduce(state) { apply($1, to: $0) }
    }

    private static func quarterTurn(_ state: CubeState, cycles: [[Int]]) -> CubeState {
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

final class Cube2x2Solver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .twoByTwo

    private struct SearchOutcome {
        let moves: [String]?
        let timedOut: Bool
        let nodeLimited: Bool
    }

    private let solvedState = CubeState.solved2x2
    private let moveNames = TwoByTwoMoveEngine.legalMoves.map(\.notation)

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
            let next = TwoByTwoMoveEngine.apply(move, to: state)
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
            current = TwoByTwoMoveEngine.apply(move, to: current)
            return CubeSolutionStep(move: move, state: current)
        }
    }

    private func finish(status: CubeSolveStatus, state: CubeState, reason: String, start: Date, nodes: Int) -> CubeSolveResult {
        CubeSolveResult(status: status, puzzle: state.puzzle, moves: [], steps: [], failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
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

    private let cornerOrientationDepth: [Int8]
    private let edgeOrientationDepth: [Int8]
    private let sliceCombinationDepth: [Int8]
    private let phase2CornerPermutationDepth: [Int8]
    private let phase2UDEdgePermutationDepth: [Int8]
    private let phase2SliceEdgePermutationDepth: [Int8]

    init(moveTables: Cube3x3MoveTables = .shared) {
        let allMoves = Cube3x3Move.allCases
        let phase2Moves = Cube3x3Move.allCases.filter(\.isPhase2Move)
        cornerOrientationDepth = Self.buildPruningTable(size: 2_187, moves: allMoves, moveTables: moveTables, coordinate: Self.cornerOrientationCoordinate)
        edgeOrientationDepth = Self.buildPruningTable(size: 2_048, moves: allMoves, moveTables: moveTables, coordinate: Self.edgeOrientationCoordinate)
        sliceCombinationDepth = Self.buildPruningTable(size: 495, moves: allMoves, moveTables: moveTables, coordinate: Self.sliceCombinationCoordinate)
        phase2CornerPermutationDepth = Self.buildPruningTable(size: 40_320, moves: phase2Moves, moveTables: moveTables, coordinate: Self.cornerPermutationCoordinate)
        phase2UDEdgePermutationDepth = Self.buildPruningTable(size: 40_320, moves: phase2Moves, moveTables: moveTables, coordinate: Self.udEdgePermutationCoordinate)
        phase2SliceEdgePermutationDepth = Self.buildPruningTable(size: 24, moves: phase2Moves, moveTables: moveTables, coordinate: Self.sliceEdgePermutationCoordinate)
    }

    func phase1LowerBound(_ state: Cube3x3CubieState) -> Int {
        max(
            Int(cornerOrientationDepth[Self.cornerOrientationCoordinate(state)]),
            Int(edgeOrientationDepth[Self.edgeOrientationCoordinate(state)]),
            Int(sliceCombinationDepth[Self.sliceCombinationCoordinate(state)])
        )
    }

    func phase2LowerBound(_ state: Cube3x3CubieState) -> Int {
        max(
            Int(phase2CornerPermutationDepth[Self.cornerPermutationCoordinate(state)]),
            Int(phase2UDEdgePermutationDepth[Self.udEdgePermutationCoordinate(state)]),
            Int(phase2SliceEdgePermutationDepth[Self.sliceEdgePermutationCoordinate(state)])
        )
    }

    private static func buildPruningTable(size: Int, moves: [Cube3x3Move], moveTables: Cube3x3MoveTables, coordinate: (Cube3x3CubieState) -> Int) -> [Int8] {
        var depths = Array(repeating: Int8(-1), count: size)
        var frontier = [Cube3x3CubieState.solved]
        depths[coordinate(.solved)] = 0
        var depth = Int8(0)

        while !frontier.isEmpty {
            var nextFrontier: [Cube3x3CubieState] = []
            nextFrontier.reserveCapacity(frontier.count * 2)
            for state in frontier {
                for move in moves {
                    let next = state.applying(move, tables: moveTables)
                    let index = coordinate(next)
                    if depths[index] == -1 {
                        depths[index] = depth + 1
                        nextFrontier.append(next)
                    }
                }
            }
            frontier = nextFrontier
            depth += 1
        }
        return depths
    }

    private static func cornerOrientationCoordinate(_ state: Cube3x3CubieState) -> Int {
        state.cornerOrientation.dropLast().reduce(0) { $0 * 3 + $1 }
    }

    private static func edgeOrientationCoordinate(_ state: Cube3x3CubieState) -> Int {
        state.edgeOrientation.dropLast().reduce(0) { $0 * 2 + $1 }
    }

    private static func sliceCombinationCoordinate(_ state: Cube3x3CubieState) -> Int {
        let positions = state.edgePermutation.enumerated().compactMap { (index, cubie) in (8..<12).contains(cubie) ? index : nil }
        return combinationRank(positions, choose: 4, from: 12)
    }

    private static func cornerPermutationCoordinate(_ state: Cube3x3CubieState) -> Int {
        permutationRank(state.cornerPermutation)
    }

    private static func udEdgePermutationCoordinate(_ state: Cube3x3CubieState) -> Int {
        let udEdges = state.edgePermutation[0..<8].map { $0 }
        return permutationRank(Array(udEdges))
    }

    private static func sliceEdgePermutationCoordinate(_ state: Cube3x3CubieState) -> Int {
        let sliceEdges = state.edgePermutation[8..<12].map { $0 - 8 }
        return permutationRank(Array(sliceEdges))
    }

    private static func permutationRank(_ permutation: [Int]) -> Int {
        var rank = 0
        var factor = 1
        for i in stride(from: permutation.count - 1, through: 0, by: -1) {
            var smaller = 0
            if i + 1 < permutation.count {
                for j in (i + 1)..<permutation.count where permutation[j] < permutation[i] { smaller += 1 }
            }
            rank += smaller * factor
            factor *= permutation.count - i
        }
        return rank
    }

    private static func combinationRank(_ selected: [Int], choose k: Int, from n: Int) -> Int {
        var rank = 0
        var nextMinimum = 0
        for (i, value) in selected.sorted().enumerated() {
            if nextMinimum < value {
                for skipped in nextMinimum..<value {
                    rank += binomial(n - 1 - skipped, k - 1 - i)
                }
            }
            nextMinimum = value + 1
        }
        return rank
    }

    private static func binomial(_ n: Int, _ k: Int) -> Int {
        guard k >= 0 && k <= n else { return 0 }
        if k == 0 || k == n { return 1 }
        var result = 1
        for i in 1...min(k, n - k) {
            result = result * (n - k + i) / i
        }
        return result
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



enum Cube3x3MoveEngine {
    static let legalMoveNotation = Cube3x3Move.allCases.map(\.rawValue).joined(separator: " ")

    static func apply(_ move: String, to state: CubeState) -> CubeState {
        guard state.puzzle == .threeByThree, let cubeMove = Cube3x3Move(rawValue: move) else { return state }
        return CubeState(puzzle: state.puzzle, stickers: Cube3x3MoveTables.shared.apply(cubeMove, to: state.stickers))
    }

    static func apply(_ moves: [String], to state: CubeState) -> CubeState {
        moves.reduce(state) { apply($1, to: $0) }
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
        let moveNames = search.status == .success ? Self.simplify(search.moves).map(\.rawValue) : []
        return CubeSolveResult(status: search.status, puzzle: supportedPuzzle, moves: moveNames, steps: [], failureReason: search.reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: search.nodes)
    }

    private static func simplify(_ moves: [Cube3x3Move]) -> [Cube3x3Move] {
        var simplified: [Cube3x3Move] = []
        for move in moves {
            guard let last = simplified.last, last.face == move.face else {
                simplified.append(move)
                continue
            }
            simplified.removeLast()
            let turns = (last.quarterTurns + move.quarterTurns) % 4
            if turns == 0 { continue }
            let notation = String(move.face) + (turns == 2 ? "2" : turns == 3 ? "'" : "")
            if let combined = Cube3x3Move(rawValue: notation) { simplified.append(combined) }
        }
        return simplified
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

// MARK: - Advanced twisty permutation engines

protocol StickerPermutationEngine {
    static var puzzle: TwistyPuzzleKind { get }
    static var legalMoveNotation: String { get }
    static var legalMoves: [TwistyMove] { get }
    static var maxChangedStickersPerMove: Int { get }
    static func apply(_ move: TwistyMove, to state: TwistyPuzzleState) -> TwistyPuzzleState
}

extension StickerPermutationEngine {
    static func apply(_ moves: [TwistyMove], to state: TwistyPuzzleState) -> TwistyPuzzleState {
        moves.reduce(state) { apply($1, to: $0) }
    }

    static func apply(_ moveNames: [String], to state: TwistyPuzzleState) -> TwistyPuzzleState {
        let spec = puzzle.notation
        let moves = moveNames.compactMap { try? TwistyMoveNotation.parse($0, spec: spec).get().first }
        return apply(moves, to: state)
    }
}

private enum StickerCycleEngine {
    static func apply(_ move: TwistyMove, cycles: [[Int]], to state: TwistyPuzzleState) -> TwistyPuzzleState {
        var stickers = state.stickers
        let turns = move.amount == .counterClockwise ? 2 : 1
        for _ in 0..<turns {
            for cycle in cycles where cycle.count > 1 {
                let last = stickers[cycle[cycle.count - 1]]
                for index in stride(from: cycle.count - 1, through: 1, by: -1) {
                    stickers[cycle[index]] = stickers[cycle[index - 1]]
                }
                stickers[cycle[0]] = last
            }
        }
        return TwistyPuzzleState(puzzle: state.puzzle, stickers: stickers)
    }

    static func changedStickerCount(in cycles: [[Int]]) -> Int {
        Set(cycles.flatMap { $0 }).count
    }
}

enum PyraminxMoveEngine: StickerPermutationEngine {
    static let puzzle: TwistyPuzzleKind = .pyraminx
    static let legalMoveNotation = TwistyPuzzleKind.pyraminx.notation.supportedMovesText
    static let legalMoves = TwistyMoveNotation.parse(legalMoveNotation, spec: TwistyPuzzleKind.pyraminx.notation).movesOrEmpty
    static let maxChangedStickersPerMove = bodyCycles.values.map(StickerCycleEngine.changedStickerCount).max() ?? 12

    private static let bodyCycles: [String: [[Int]]] = [
        "U": [[0, 2, 8], [1, 5, 7], [9, 18, 27], [10, 19, 28], [11, 20, 29]],
        "L": [[9, 11, 17], [10, 14, 16], [0, 27, 24], [3, 30, 21], [6, 33, 18]],
        "R": [[18, 20, 26], [19, 23, 25], [2, 15, 29], [5, 12, 32], [8, 9, 35]],
        "B": [[27, 29, 35], [28, 32, 34], [6, 26, 17], [7, 25, 16], [8, 24, 15]]
    ]
    private static let tipCycles: [String: [[Int]]] = [
        "u": [[0, 1, 2]],
        "l": [[9, 10, 11]],
        "r": [[18, 19, 20]],
        "b": [[27, 28, 29]]
    ]

    static func apply(_ move: TwistyMove, to state: TwistyPuzzleState) -> TwistyPuzzleState {
        StickerCycleEngine.apply(move, cycles: bodyCycles[move.face] ?? tipCycles[move.face] ?? [], to: state)
    }
}

enum SkewbMoveEngine: StickerPermutationEngine {
    static let puzzle: TwistyPuzzleKind = .skewb
    static let legalMoveNotation = TwistyPuzzleKind.skewb.notation.supportedMovesText
    static let legalMoves = TwistyMoveNotation.parse(legalMoveNotation, spec: TwistyPuzzleKind.skewb.notation).movesOrEmpty
    static let maxChangedStickersPerMove = cyclesByFace.values.map(StickerCycleEngine.changedStickerCount).max() ?? 14

    private static let cyclesByFace: [String: [[Int]]] = [
        "U": [[0, 1, 2], [5, 10, 25], [6, 11, 26], [7, 12, 27], [15, 20, 28]],
        "L": [[20, 21, 22], [0, 25, 15], [2, 27, 17], [4, 29, 19], [10, 5, 16]],
        "R": [[7, 8, 9], [0, 10, 15], [1, 11, 16], [3, 13, 18], [25, 20, 19]],
        "B": [[25, 26, 27], [0, 20, 10], [1, 21, 11], [2, 22, 12], [5, 15, 23]]
    ]

    static func apply(_ move: TwistyMove, to state: TwistyPuzzleState) -> TwistyPuzzleState {
        StickerCycleEngine.apply(move, cycles: cyclesByFace[move.face] ?? [], to: state)
    }
}

class IterativeDeepeningTwistySolver<Engine: StickerPermutationEngine>: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = Engine.puzzle

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard state.puzzle == supportedPuzzle, state.stickers.count == supportedPuzzle.stickerCount else {
            return CubeSolveResult(status: .invalidInput, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Expected \(supportedPuzzle.stickerCount ?? 0) stickers for a \(supportedPuzzle.displayName) state.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }
        let counts = Dictionary(grouping: state.stickers, by: { $0 }).mapValues(\.count)
        let expected = (supportedPuzzle.stickerCount ?? 0) / supportedPuzzle.faces.count
        guard Set(counts.keys) == Set(supportedPuzzle.faces), counts.values.allSatisfy({ $0 == expected }) else {
            return CubeSolveResult(status: .invalidInput, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Sticker colors must match the \(supportedPuzzle.displayName) face inventory.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }
        if state.isSolvedByFace {
            return CubeSolveResult(status: .success, puzzle: state.puzzle, moves: [], steps: [CubeSolutionStep(move: nil, state: state)], failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }

        let solved = CubeState.solved(supportedPuzzle)
        var nodes = 0
        var path: [TwistyMove] = []
        let depthLimit = max(0, options.maxDepth)
        for depth in 0...depthLimit {
            if Date().timeIntervalSince(start) >= options.timeout {
                return CubeSolveResult(status: .timeout, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Solver exceeded the \(options.timeout)s timeout.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
            }
            if search(state, solved: solved, depthRemaining: depth, previous: nil, path: &path, nodes: &nodes, options: options, start: start) {
                let steps = makeSteps(from: state, moves: path, includeStates: options.includeStepStates)
                return CubeSolveResult(status: .success, puzzle: state.puzzle, moves: path.map(\.notation), steps: steps, failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
            }
            if nodes >= options.maxNodes { break }
        }
        let reason = nodes >= options.maxNodes ? "Solver reached the \(options.maxNodes) node limit." : "No solution found within depth \(depthLimit)."
        return CubeSolveResult(status: .failure, puzzle: state.puzzle, moves: [], steps: [], failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }

    private var effectiveMoves: [TwistyMove] {
        let solved = CubeState.solved(supportedPuzzle)
        return Engine.legalMoves.filter { Engine.apply($0, to: solved) != solved }
    }

    private func search(_ state: CubeState, solved: CubeState, depthRemaining: Int, previous: TwistyMove?, path: inout [TwistyMove], nodes: inout Int, options: CubeSolveOptions, start: Date) -> Bool {
        nodes += 1
        if state == solved { return true }
        if depthRemaining == 0 { return false }
        if nodes >= options.maxNodes || Date().timeIntervalSince(start) >= options.timeout { return false }
        if heuristic(state, solved: solved) > depthRemaining { return false }

        for move in effectiveMoves {
            if let previous, move.face == previous.face { continue }
            let next = Engine.apply(move, to: state)
            path.append(move)
            if search(next, solved: solved, depthRemaining: depthRemaining - 1, previous: move, path: &path, nodes: &nodes, options: options, start: start) { return true }
            path.removeLast()
        }
        return false
    }

    private func heuristic(_ state: CubeState, solved: CubeState) -> Int {
        let mismatched = zip(state.stickers, solved.stickers).filter { $0 != $1 }.count
        return Int(ceil(Double(mismatched) / Double(max(1, Engine.maxChangedStickersPerMove))))
    }

    private func makeSteps(from state: CubeState, moves: [TwistyMove], includeStates: Bool) -> [CubeSolutionStep] {
        var current = state
        var steps = [CubeSolutionStep(move: nil, state: includeStates ? state : nil)]
        for move in moves {
            current = Engine.apply(move, to: current)
            steps.append(CubeSolutionStep(move: move, state: includeStates ? current : nil))
        }
        return steps
    }
}

final class PyraminxSolver: IterativeDeepeningTwistySolver<PyraminxMoveEngine> {}
final class SkewbSolver: IterativeDeepeningTwistySolver<SkewbMoveEngine> {}


// MARK: - Placeholder architectures for future twisty solvers

struct TwistySolverPhase: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let implemented: Bool
}

protocol TwistyPlaceholderArchitecture {
    var puzzle: TwistyPuzzleKind { get }
    var phases: [TwistySolverPhase] { get }
    var supportedMoves: [TwistyMove] { get }
}

struct Cube3x3SolverArchitecture: TwistyPlaceholderArchitecture {
    let puzzle: TwistyPuzzleKind = .threeByThree
    let phases = [
        TwistySolverPhase(name: "Input normalization", description: "Convert stickers into cubie coordinates.", implemented: true),
        TwistySolverPhase(name: "Two-phase search", description: "Reduce orientation/slice state, then solve permutations.", implemented: false),
        TwistySolverPhase(name: "Step replay", description: "Replay solved moves into displayable cube states.", implemented: false)
    ]
    let supportedMoves = TwistyMoveNotation.parse("U U' U2 D D' D2 L L' L2 R R' R2 F F' F2 B B' B2", allowedFaces: Set(["U", "D", "L", "R", "F", "B"])).movesOrEmpty
}

struct PyraminxSolverArchitecture: TwistyPlaceholderArchitecture {
    let puzzle: TwistyPuzzleKind = .pyraminx
    let phases = [
        TwistySolverPhase(name: "Tip solving", description: "Orient independent tips.", implemented: false),
        TwistySolverPhase(name: "Center alignment", description: "Align face centers before edge search.", implemented: false),
        TwistySolverPhase(name: "Edge permutation/orientation", description: "Search legal Pyraminx turns for remaining edges.", implemented: false)
    ]
    let supportedMoves = TwistyMoveNotation.parse("U U' L L' R R' B B'", allowedFaces: Set(["U", "L", "R", "B"])).movesOrEmpty
}

struct SkewbSolverArchitecture: TwistyPlaceholderArchitecture {
    let puzzle: TwistyPuzzleKind = .skewb
    let phases = [
        TwistySolverPhase(name: "Corner orientation", description: "Orient four-turn corner axes.", implemented: false),
        TwistySolverPhase(name: "Center permutation", description: "Place centers with legal Skewb turns.", implemented: false),
        TwistySolverPhase(name: "Final layer cleanup", description: "Finish remaining corner permutation.", implemented: false)
    ]
    let supportedMoves = TwistyMoveNotation.parse("U U' L L' R R' B B'", allowedFaces: Set(["U", "L", "R", "B"])).movesOrEmpty
}

struct MegaminxSolverArchitecture: TwistyPlaceholderArchitecture {
    let puzzle: TwistyPuzzleKind = .megaminx
    let phases = [
        TwistySolverPhase(name: "Star and F2L reduction", description: "Plan dodecahedral layer-by-layer state coordinates.", implemented: false),
        TwistySolverPhase(name: "Last-layer edge orientation", description: "Reserve pruning tables for Megaminx edge orientation patterns.", implemented: false),
        TwistySolverPhase(name: "Last-layer permutation", description: "Apply Megaminx-specific algorithms and replay states.", implemented: false)
    ]
    let supportedMoves = TwistyMoveNotation.parse("R R' D D' U U'", spec: TwistyPuzzleKind.megaminx.notation).movesOrEmpty
}

struct SquareOneSolverArchitecture: TwistyPlaceholderArchitecture {
    let puzzle: TwistyPuzzleKind = .squareOne
    let phases = [
        TwistySolverPhase(name: "Shape normalization", description: "Model top and bottom layer tuple turns plus slash transitions.", implemented: false),
        TwistySolverPhase(name: "Cubeshape search", description: "Add a shape-space search before permutation solving.", implemented: false),
        TwistySolverPhase(name: "Piece permutation", description: "Solve corners and edges with Square-1 parity handling.", implemented: false)
    ]
    let supportedMoves: [TwistyMove] = []
}

extension Result where Success == [TwistyMove], Failure == TwistyMoveNotation.NotationError {
    var movesOrEmpty: [TwistyMove] { (try? get()) ?? [] }
}


final class MegaminxSolver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .megaminx
    private let architecture = MegaminxSolverArchitecture()

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard state.puzzle == supportedPuzzle, state.stickers.count == CubePuzzleKind.megaminx.stickerCount else {
            return CubeSolveResult(status: .invalidInput, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Expected 132 stickers for a Megaminx state.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }
        return CubeSolveResult.unavailable(for: .megaminx, reason: "Megaminx placeholder architecture is registered with \(architecture.phases.count) planned phases; search tables are not implemented yet.", elapsedTime: Date().timeIntervalSince(start))
    }
}

final class SquareOneSolver: CubeSolverProtocol {
    let supportedPuzzle: CubePuzzleKind = .squareOne
    private let architecture = SquareOneSolverArchitecture()

    func solve(_ state: CubeState, options: CubeSolveOptions) -> CubeSolveResult {
        let start = Date()
        guard state.puzzle == supportedPuzzle, state.stickers.count == CubePuzzleKind.squareOne.stickerCount else {
            return CubeSolveResult(status: .invalidInput, puzzle: state.puzzle, moves: [], steps: [], failureReason: "Expected 24 stickers for a Square-1 state.", elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }
        return CubeSolveResult.unavailable(for: .squareOne, reason: "Square-1 placeholder architecture is registered with \(architecture.phases.count) planned phases; tuple-turn shape search is not implemented yet.", elapsedTime: Date().timeIntervalSince(start))
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

    func log(_ message: String) {
        _ = message
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
        PuzzleModeDiagnostic(name: "4×4 Sliding Puzzle", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "2×2 Cube", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "3×3 Cube", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Pyraminx", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Skewb", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Megaminx", enabled: true, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Square-1", enabled: true, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Sudoku", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Killer Sudoku", enabled: false, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Nonogram", enabled: false, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Kakuro", enabled: false, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Slitherlink", enabled: false, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Rush Hour", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Klotski", enabled: false, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Peg Solitaire", enabled: false, solverAvailable: false),
        PuzzleModeDiagnostic(name: "Maze", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Chess Mate-in-N", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Chess Best Move", enabled: true, solverAvailable: true),
        PuzzleModeDiagnostic(name: "Jigsaw Solver", enabled: true, solverAvailable: false)
    ]
}

// MARK: - Sliding puzzle architecture

enum SlidingPuzzleKind: Int, CaseIterable, Equatable {
    case threeByThree = 3
    case fourByFour = 4

    var size: Int { rawValue }
    var displayName: String { "\(size)×\(size) Sliding Puzzle" }
}

enum SlidingPuzzleMove: String, CaseIterable, Equatable {
    case up = "Move blank up"
    case down = "Move blank down"
    case left = "Move blank left"
    case right = "Move blank right"

    var opposite: SlidingPuzzleMove {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    var delta: (row: Int, column: Int) {
        switch self {
        case .up: return (-1, 0)
        case .down: return (1, 0)
        case .left: return (0, -1)
        case .right: return (0, 1)
        }
    }
}

struct SlidingPuzzleStep: Identifiable, Equatable {
    let id = UUID()
    let move: SlidingPuzzleMove?
    let board: SlidingPuzzleBoard

    static func == (lhs: SlidingPuzzleStep, rhs: SlidingPuzzleStep) -> Bool {
        lhs.move == rhs.move && lhs.board == rhs.board
    }
}

struct SlidingPuzzleBoard: Hashable, Equatable {
    let size: Int
    let tiles: [Int]

    var kind: SlidingPuzzleKind? { SlidingPuzzleKind(rawValue: size) }
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

    func applying(_ move: SlidingPuzzleMove) -> SlidingPuzzleBoard? {
        guard let blank = blankIndex else { return nil }
        let row = blank / size
        let column = blank % size
        let delta = move.delta
        let nextRow = row + delta.row
        let nextColumn = column + delta.column
        guard (0..<size).contains(nextRow), (0..<size).contains(nextColumn) else { return nil }

        var nextTiles = tiles
        let swapIndex = nextRow * size + nextColumn
        nextTiles[blank] = nextTiles[swapIndex]
        nextTiles[swapIndex] = 0
        return SlidingPuzzleBoard(size: size, tiles: nextTiles)
    }
}

struct SlidingPuzzleSolveOptions {
    let timeout: TimeInterval
    let maxNodes: Int
    let maxDepth: Int

    init(timeout: TimeInterval, maxNodes: Int, maxDepth: Int = 80) {
        self.timeout = timeout
        self.maxNodes = maxNodes
        self.maxDepth = maxDepth
    }

    static let `default` = SlidingPuzzleSolveOptions(timeout: 5, maxNodes: 250_000, maxDepth: 80)
}

struct SlidingPuzzleSolveResult: Equatable {
    let state: SolveState
    let moves: [String]
    let path: [SlidingPuzzleBoard]
    let steps: [SlidingPuzzleStep]
    let failureReason: String?
    let elapsedTime: TimeInterval
    let nodesExplored: Int

    var succeeded: Bool { state == .solved }

    init(
        state: SolveState,
        moves: [String],
        path: [SlidingPuzzleBoard] = [],
        failureReason: String?,
        elapsedTime: TimeInterval,
        nodesExplored: Int
    ) {
        self.state = state
        self.moves = state == .solved ? moves : []
        self.path = state == .solved ? path : []
        self.steps = state == .solved ? Self.makeSteps(path: path, moves: moves) : []
        self.failureReason = failureReason
        self.elapsedTime = elapsedTime
        self.nodesExplored = nodesExplored
    }

    private static func makeSteps(path: [SlidingPuzzleBoard], moves: [String]) -> [SlidingPuzzleStep] {
        guard !path.isEmpty else { return [] }
        return path.enumerated().map { index, board in
            let move = index == 0 ? nil : SlidingPuzzleMove(rawValue: moves[index - 1])
            return SlidingPuzzleStep(move: move, board: board)
        }
    }
}

protocol SlidingPuzzleSolving {
    var supportedKind: SlidingPuzzleKind { get }
    var algorithmName: String { get }
    func solve(_ board: SlidingPuzzleBoard, options: SlidingPuzzleSolveOptions, start: Date) -> SlidingPuzzleSolveResult
}

enum SlidingPuzzleAnalyzer {
    static func validate(_ board: SlidingPuzzleBoard) -> Bool {
        guard board.size >= 2, board.tiles.count == board.size * board.size else { return false }
        return board.tiles.sorted() == Array(0..<(board.size * board.size))
    }

    static func isSolvable(_ board: SlidingPuzzleBoard) -> Bool {
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

    static func manhattan(_ board: SlidingPuzzleBoard) -> Int {
        board.tiles.enumerated().reduce(0) { total, entry in
            let (index, value) = entry
            guard value != 0 else { return total }
            let goal = value - 1
            return total + abs(index / board.size - goal / board.size) + abs(index % board.size - goal % board.size)
        }
    }

    static func neighbors(of board: SlidingPuzzleBoard, avoiding previousMove: SlidingPuzzleMove? = nil) -> [(board: SlidingPuzzleBoard, move: SlidingPuzzleMove)] {
        SlidingPuzzleMove.allCases.compactMap { move in
            guard move != previousMove?.opposite, let next = board.applying(move) else { return nil }
            return (next, move)
        }
    }
}

final class SlidingPuzzleSolver {
    private let solvers: [SlidingPuzzleKind: SlidingPuzzleSolving]

    init(solvers: [SlidingPuzzleSolving] = [SlidingPuzzleAStarSolver(), SlidingPuzzleIDAStarSolver()]) {
        self.solvers = Dictionary(uniqueKeysWithValues: solvers.map { ($0.supportedKind, $0) })
    }

    func solve(_ board: SlidingPuzzleBoard, options: SlidingPuzzleSolveOptions = .default) -> SlidingPuzzleSolveResult {
        let start = Date()
        SolverDebugLogger.shared.log("solver selected: SlidingPuzzleSolver \(board.size)×\(board.size)")
        SolverDebugLogger.shared.log("validation result: started")

        guard SlidingPuzzleAnalyzer.validate(board) else {
            SolverDebugLogger.shared.log("validation result: invalid")
            SolverDebugLogger.shared.log("failure reason: invalid sliding puzzle input")
            return finish(.invalid, reason: "Please use each tile once.", start: start, nodes: 0)
        }
        SolverDebugLogger.shared.log("validation result: valid")

        guard let kind = board.kind, let solver = solvers[kind] else {
            SolverDebugLogger.shared.log("failure reason: unsupported sliding puzzle size")
            return finish(.unsupported, reason: "Sliding puzzle size \(board.size)×\(board.size) is not supported yet.", start: start, nodes: 0)
        }

        guard SlidingPuzzleAnalyzer.isSolvable(board) else {
            SolverDebugLogger.shared.log("failure reason: unsolvable sliding puzzle")
            return finish(.unsolvable, reason: "This layout is not solvable.", start: start, nodes: 0)
        }

        if board.isSolved {
            SolverDebugLogger.shared.log("solve finished: already solved")
            return SlidingPuzzleSolveResult(state: .solved, moves: [], path: [board], failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: 0)
        }

        SolverDebugLogger.shared.log("solve started with \(solver.algorithmName)")
        return solver.solve(board, options: options, start: start)
    }

    private func finish(_ state: SolveState, reason: String, start: Date, nodes: Int) -> SlidingPuzzleSolveResult {
        SlidingPuzzleSolveResult(state: state, moves: [], path: [], failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
    }
}

final class SlidingPuzzleAStarSolver: SlidingPuzzleSolving {
    let supportedKind: SlidingPuzzleKind = .threeByThree
    let algorithmName = "A* Manhattan"

    private struct SearchNode {
        let board: SlidingPuzzleBoard
        let moves: [SlidingPuzzleMove]
        let path: [SlidingPuzzleBoard]
        let cost: Int
        let priority: Int
    }

    func solve(_ board: SlidingPuzzleBoard, options: SlidingPuzzleSolveOptions, start: Date) -> SlidingPuzzleSolveResult {
        let deadline = start.addingTimeInterval(max(0, options.timeout))
        var frontier = [SearchNode(board: board, moves: [], path: [board], cost: 0, priority: SlidingPuzzleAnalyzer.manhattan(board))]
        var bestCost: [SlidingPuzzleBoard: Int] = [board: 0]
        var nodes = 0

        while !frontier.isEmpty {
            if Date() >= deadline { return finish(.timedOut, reason: "Solver took too long.", start: start, nodes: nodes) }
            if nodes >= options.maxNodes { return finish(.timedOut, reason: "Solver took too long.", start: start, nodes: nodes) }

            frontier.sort { lhs, rhs in
                lhs.priority == rhs.priority ? lhs.cost > rhs.cost : lhs.priority > rhs.priority
            }
            let current = frontier.removeLast()
            nodes += 1

            if current.board.isSolved {
                SolverDebugLogger.shared.log("solve finished: solved in \(current.moves.count) moves")
                return success(moves: current.moves, path: current.path, start: start, nodes: nodes)
            }

            for neighbor in SlidingPuzzleAnalyzer.neighbors(of: current.board) {
                let nextCost = current.cost + 1
                guard nextCost < (bestCost[neighbor.board] ?? Int.max) else { continue }
                bestCost[neighbor.board] = nextCost
                let nextMoves = current.moves + [neighbor.move]
                let nextPath = current.path + [neighbor.board]
                frontier.append(SearchNode(board: neighbor.board, moves: nextMoves, path: nextPath, cost: nextCost, priority: nextCost + SlidingPuzzleAnalyzer.manhattan(neighbor.board)))
            }
        }

        return finish(.failed, reason: "Could not find a solution.", start: start, nodes: nodes)
    }
}

final class SlidingPuzzleIDAStarSolver: SlidingPuzzleSolving {
    let supportedKind: SlidingPuzzleKind = .fourByFour
    let algorithmName = "IDA* Manhattan"

    private struct SearchContext {
        let deadline: Date
        let maxNodes: Int
        var nodes: Int = 0
        var timedOut = false
        var nodeLimited = false
    }

    private enum SearchResult {
        case found([SlidingPuzzleMove], [SlidingPuzzleBoard])
        case nextBound(Int)
    }

    func solve(_ board: SlidingPuzzleBoard, options: SlidingPuzzleSolveOptions, start: Date) -> SlidingPuzzleSolveResult {
        var context = SearchContext(deadline: start.addingTimeInterval(max(0, options.timeout)), maxNodes: options.maxNodes)
        var bound = SlidingPuzzleAnalyzer.manhattan(board)
        let maximumBound = max(bound, options.maxDepth)

        while bound <= maximumBound {
            var path: Set<SlidingPuzzleBoard> = [board]
            switch search(board, g: 0, bound: bound, previousMove: nil, moves: [], boards: [board], path: &path, context: &context) {
            case .found(let moves, let boards):
                SolverDebugLogger.shared.log("solve finished: solved in \(moves.count) moves")
                return success(moves: moves, path: boards, start: start, nodes: context.nodes)
            case .nextBound(let nextBound):
                if context.timedOut { return finish(.timedOut, reason: "Solver took too long.", start: start, nodes: context.nodes) }
                if context.nodeLimited { return finish(.timedOut, reason: "Solver took too long.", start: start, nodes: context.nodes) }
                if nextBound == Int.max { return finish(.failed, reason: "Could not find a solution.", start: start, nodes: context.nodes) }
                bound = nextBound
            }
        }

        return finish(.timedOut, reason: "Solver reached the safe depth limit for this 4×4 puzzle.", start: start, nodes: context.nodes)
    }

    private func search(
        _ board: SlidingPuzzleBoard,
        g: Int,
        bound: Int,
        previousMove: SlidingPuzzleMove?,
        moves: [SlidingPuzzleMove],
        boards: [SlidingPuzzleBoard],
        path: inout Set<SlidingPuzzleBoard>,
        context: inout SearchContext
    ) -> SearchResult {
        if Date() >= context.deadline {
            context.timedOut = true
            return .nextBound(Int.max)
        }
        if context.nodes >= context.maxNodes {
            context.nodeLimited = true
            return .nextBound(Int.max)
        }

        context.nodes += 1
        let fScore = g + SlidingPuzzleAnalyzer.manhattan(board)
        if fScore > bound { return .nextBound(fScore) }
        if board.isSolved { return .found(moves, boards) }

        var minimum = Int.max
        let orderedNeighbors = SlidingPuzzleAnalyzer.neighbors(of: board, avoiding: previousMove)
            .sorted { SlidingPuzzleAnalyzer.manhattan($0.board) < SlidingPuzzleAnalyzer.manhattan($1.board) }

        for neighbor in orderedNeighbors {
            guard !path.contains(neighbor.board) else { continue }
            path.insert(neighbor.board)
            var nextMoves = moves
            nextMoves.append(neighbor.move)
            var nextBoards = boards
            nextBoards.append(neighbor.board)
            let result = search(neighbor.board, g: g + 1, bound: bound, previousMove: neighbor.move, moves: nextMoves, boards: nextBoards, path: &path, context: &context)
            path.remove(neighbor.board)

            switch result {
            case .found:
                return result
            case .nextBound(let nextBound):
                minimum = min(minimum, nextBound)
                if context.timedOut || context.nodeLimited { return .nextBound(Int.max) }
            }
        }

        return .nextBound(minimum)
    }
}

private func success(moves: [SlidingPuzzleMove], path: [SlidingPuzzleBoard], start: Date, nodes: Int) -> SlidingPuzzleSolveResult {
    SlidingPuzzleSolveResult(state: .solved, moves: moves.map(\.rawValue), path: path, failureReason: nil, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
}

private func finish(_ state: SolveState, reason: String, start: Date, nodes: Int) -> SlidingPuzzleSolveResult {
    SolverDebugLogger.shared.log("failure reason: \(reason)")
    return SlidingPuzzleSolveResult(state: state, moves: [], path: [], failureReason: reason, elapsedTime: Date().timeIntervalSince(start), nodesExplored: nodes)
}

enum PuzzlePresets {
    // Sliding examples used by the input screen, previews, diagnostics, and unit tests.
    static let sliding3x3Solved = SlidingPuzzleBoard.solved(size: 3)
    static let sliding3x3OneMove = SlidingPuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8])
    static let sliding3x3Medium = SlidingPuzzleBoard(size: 3, tiles: [1, 2, 3, 5, 0, 6, 4, 7, 8])
    static let sliding3x3Unsolvable = SlidingPuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 8, 7, 0])

    static let sliding4x4Solved = SlidingPuzzleBoard.solved(size: 4)
    static let sliding4x4OneMove = SlidingPuzzleBoard(size: 4, tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 15])
    static let sliding4x4Medium = SlidingPuzzleBoard(size: 4, tiles: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 0, 14, 15])
}

struct ExamplePuzzlePreset: Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let detail: String
}

enum ExamplePuzzlePresets {
    static let all: [ExamplePuzzlePreset] = [
        ExamplePuzzlePreset(id: "sliding-3x3-medium", title: "3×3 Sliding Medium", category: "Sliding", detail: "A short A* example that demonstrates ordered move playback."),
        ExamplePuzzlePreset(id: "sliding-4x4-medium", title: "4×4 Sliding Medium", category: "Sliding", detail: "A bounded IDA* preset that solves within the default safety limits."),
        ExamplePuzzlePreset(id: "cube-2x2-sexy", title: "2×2 R U R' U'", category: "Twisty", detail: "A compact cube scramble for validating the 2×2 search path."),
        ExamplePuzzlePreset(id: "cube-3x3-four-move", title: "3×3 R U R' U'", category: "Twisty", detail: "A shallow 3×3 scramble covered by the two-phase solver tests."),
        ExamplePuzzlePreset(id: "pyraminx-url", title: "Pyraminx U R L'", category: "Twisty", detail: "A small Pyraminx preset using shared twisty notation."),
        ExamplePuzzlePreset(id: "skewb-rub", title: "Skewb R U B'", category: "Twisty", detail: "A small Skewb preset using the shared iterative solver."),
        ExamplePuzzlePreset(id: "sudoku-example", title: "Sudoku Example", category: "Logic", detail: "The built-in Sudoku grid used by validation and solver tests."),
        ExamplePuzzlePreset(id: "rush-hour-example", title: "Rush Hour Example", category: "Mechanical", detail: "A non-overlapping traffic puzzle with ordered playback frames."),
        ExamplePuzzlePreset(id: "maze-example", title: "Maze Shortest Path", category: "Experimental", detail: "A simple grid graph pathfinding puzzle for BFS diagnostics."),
        ExamplePuzzlePreset(id: "chess-mate-one", title: "Chess Mate in One", category: "Experimental", detail: "A forced-mate board used to verify bounded chess search." )
    ]
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

import Foundation

enum TwistyPuzzleType: String, CaseIterable, Identifiable, Sendable {
    case cube2x2
    case cube3x3
    case pyraminx
    case skewb

    var id: String { rawValue }

    var metadata: TwistyPuzzleMetadata {
        switch self {
        case .cube2x2:
            return TwistyPuzzleMetadata(
                title: "2×2 Cube",
                shortTitle: "2×2",
                icon: "square.grid.2x2.fill",
                availability: .available,
                subtitle: "Ready now",
                supportedNotation: [.wca]
            )
        case .cube3x3:
            return TwistyPuzzleMetadata(
                title: "3×3 Rubik’s Cube",
                shortTitle: "3×3",
                icon: "cube.fill",
                availability: .available,
                subtitle: "Ready now",
                supportedNotation: [.wca]
            )
        case .pyraminx:
            return TwistyPuzzleMetadata(
                title: "Pyraminx",
                shortTitle: "Pyraminx",
                icon: "triangle.fill",
                availability: .available,
                subtitle: "Ready now",
                supportedNotation: [.wca]
            )
        case .skewb:
            return TwistyPuzzleMetadata(
                title: "Skewb",
                shortTitle: "Skewb",
                icon: "diamond.fill",
                availability: .available,
                subtitle: "Ready now",
                supportedNotation: [.wca]
            )
        }
    }
}

struct TwistyPuzzleMetadata: Sendable {
    let title: String
    let shortTitle: String
    let icon: String
    let availability: TwistyPuzzleAvailability
    let subtitle: String
    let supportedNotation: [TwistyNotation]
}

enum TwistyPuzzleAvailability: Sendable {
    case available
    case comingSoon
}

enum TwistyNotation: String, Sendable {
    case wca
}

struct TwistyMove: Hashable, Sendable {
    let token: String
    let family: TwistyMoveFamily
    let turnAmount: TwistyTurnAmount

    init(token: String, family: TwistyMoveFamily = .outerFace, turnAmount: TwistyTurnAmount = .clockwiseQuarter) {
        self.token = token
        self.family = family
        self.turnAmount = turnAmount
    }
}

enum TwistyMoveFamily: Sendable {
    case outerFace
    case wide
    case slice
    case rotation
    case tip
}

enum TwistyTurnAmount: Sendable {
    case clockwiseQuarter
    case counterClockwiseQuarter
    case halfTurn
}

struct TwistySolutionStep: Hashable, Sendable, Identifiable {
    let id: UUID
    let move: TwistyMove?
    let explanation: String

    init(id: UUID = UUID(), move: TwistyMove?, explanation: String) {
        self.id = id
        self.move = move
        self.explanation = explanation
    }
}

struct TwistySolveResult: Sendable {
    let puzzleType: TwistyPuzzleType
    let isSolvable: Bool
    let moves: [TwistyMove]
    let steps: [TwistySolutionStep]
    let elapsedTime: TimeInterval?
    let finalStateDescription: String?

    var moveCount: Int {
        moves.count
    }
}

struct TwistyPuzzleCatalogItem: Identifiable, Sendable {
    let puzzleType: TwistyPuzzleType

    var id: String { puzzleType.id }
    var title: String { puzzleType.metadata.title }
    var subtitle: String { puzzleType.metadata.subtitle }
    var icon: String { puzzleType.metadata.icon }
    var isEnabled: Bool { puzzleType.metadata.availability == .available }
}

struct TwistySolutionStepViewData: Identifiable, Hashable, Sendable {
    let id: UUID
    let stepNumber: Int
    let primaryText: String
    let secondaryText: String?
}

struct TwistySolveSummaryViewData: Sendable {
    let statusText: String
    let moveCountText: String
    let stepCountText: String
}


enum TwistyEntryValidationStatus {
    case incomplete(String)
    case invalid(String)
    case ready(String)

    var message: String {
        switch self {
        case .incomplete(let message), .invalid(let message), .ready(let message):
            return message
        }
    }

    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }
}

protocol TwistyPuzzleState {
    var puzzleType: TwistyPuzzleType { get }
}

protocol TwistyPuzzleSolver {
    associatedtype State: TwistyPuzzleState

    func solve(from initialState: State) async -> TwistySolveResult
}

protocol TwistyNotationRenderer {
    func notation(for move: TwistyMove, puzzleType: TwistyPuzzleType) -> String
    func formattedText(for step: TwistySolutionStep, puzzleType: TwistyPuzzleType, stepNumber: Int) -> TwistySolutionStepViewData
}

struct StandardTwistyNotationRenderer: TwistyNotationRenderer {
    func notation(for move: TwistyMove, puzzleType: TwistyPuzzleType) -> String {
        move.token
    }

    func formattedText(for step: TwistySolutionStep, puzzleType: TwistyPuzzleType, stepNumber: Int) -> TwistySolutionStepViewData {
        let primaryText: String
        if let move = step.move {
            primaryText = notation(for: move, puzzleType: puzzleType)
        } else {
            primaryText = "Inspection"
        }

        return TwistySolutionStepViewData(
            id: step.id,
            stepNumber: stepNumber,
            primaryText: primaryText,
            secondaryText: step.explanation.isEmpty ? nil : step.explanation
        )
    }
}

extension TwistySolveResult {
    func makeSummaryViewData() -> TwistySolveSummaryViewData {
        TwistySolveSummaryViewData(
            statusText: isSolvable ? "Status: Solvable" : "Status: Unsolvable",
            moveCountText: "Move count: \(moveCount)",
            stepCountText: "Ordered solution steps: \(steps.count)"
        )
    }

    func makeStepViewData(renderer: TwistyNotationRenderer = StandardTwistyNotationRenderer()) -> [TwistySolutionStepViewData] {
        steps.enumerated().map { index, step in
            renderer.formattedText(for: step, puzzleType: puzzleType, stepNumber: index + 1)
        }
    }
}

enum Cube2x2Move: String, CaseIterable, Hashable, Sendable {
    case u = "U"
    case uPrime = "U'"
    case r = "R"
    case rPrime = "R'"
    case f = "F"
    case fPrime = "F'"

    var inverse: Cube2x2Move {
        switch self {
        case .u: return .uPrime
        case .uPrime: return .u
        case .r: return .rPrime
        case .rPrime: return .r
        case .f: return .fPrime
        case .fPrime: return .f
        }
    }

    var twistyMove: TwistyMove {
        TwistyMove(
            token: rawValue,
            family: .outerFace,
            turnAmount: rawValue.hasSuffix("'") ? .counterClockwiseQuarter : .clockwiseQuarter
        )
    }
}

struct Cube2x2DisplayState: Sendable {
    let cornerSummary: [String]
}

struct Cube2x2State: TwistyPuzzleState, Hashable, Sendable {
    static let solved = Cube2x2State(
        cornerPermutation: [0, 1, 2, 3, 4, 5, 6, 7],
        cornerOrientation: [0, 0, 0, 0, 0, 0, 0, 0]
    )

    let cornerPermutation: [UInt8]
    let cornerOrientation: [UInt8]

    var puzzleType: TwistyPuzzleType { .cube2x2 }
    var isSolved: Bool { self == .solved }

    init(cornerPermutation: [UInt8], cornerOrientation: [UInt8]) {
        self.cornerPermutation = cornerPermutation
        self.cornerOrientation = cornerOrientation
    }

    func applying(_ move: Cube2x2Move) -> Cube2x2State {
        switch move {
        case .u:
            return applyingBaseMove(.u)
        case .uPrime:
            return applyingBaseMove(.u).applyingBaseMove(.u).applyingBaseMove(.u)
        case .r:
            return applyingBaseMove(.r)
        case .rPrime:
            return applyingBaseMove(.r).applyingBaseMove(.r).applyingBaseMove(.r)
        case .f:
            return applyingBaseMove(.f)
        case .fPrime:
            return applyingBaseMove(.f).applyingBaseMove(.f).applyingBaseMove(.f)
        }
    }

    func neighbors() -> [(move: Cube2x2Move, state: Cube2x2State)] {
        Cube2x2Move.allCases.map { move in
            (move, applying(move))
        }
    }

    func makeDisplayState() -> Cube2x2DisplayState {
        let cornerNames = ["URF", "UFL", "ULB", "UBR", "DFR", "DLF", "DBL", "DRB"]
        let summary = cornerPermutation.enumerated().map { index, cubie in
            let name = cornerNames[Int(cubie)]
            let orientation = cornerOrientation[index]
            return "Pos \(cornerNames[index]): \(name) (ori \(orientation))"
        }
        return Cube2x2DisplayState(cornerSummary: summary)
    }

    fileprivate enum BaseMove {
        case u
        case r
        case f
    }

    private func applyingBaseMove(_ move: BaseMove) -> Cube2x2State {
        let transform = CornerTransform.base(for: move)
        var nextPermutation = Array(repeating: UInt8(0), count: 8)
        var nextOrientation = Array(repeating: UInt8(0), count: 8)

        for index in 0..<8 {
            let source = Int(transform.permutation[index])
            nextPermutation[index] = cornerPermutation[source]
            nextOrientation[index] = (cornerOrientation[source] + transform.orientationDelta[index]) % 3
        }

        return Cube2x2State(cornerPermutation: nextPermutation, cornerOrientation: nextOrientation)
    }
}

private struct CornerTransform {
    let permutation: [UInt8]
    let orientationDelta: [UInt8]

    static func base(for move: Cube2x2State.BaseMove) -> CornerTransform {
        switch move {
        case .u:
            return CornerTransform(
                permutation: [1, 2, 3, 0, 4, 5, 6, 7],
                orientationDelta: [0, 0, 0, 0, 0, 0, 0, 0]
            )
        case .r:
            return CornerTransform(
                permutation: [4, 1, 2, 0, 7, 5, 6, 3],
                orientationDelta: [2, 0, 0, 1, 1, 0, 0, 2]
            )
        case .f:
            return CornerTransform(
                permutation: [1, 5, 2, 3, 0, 4, 6, 7],
                orientationDelta: [1, 2, 0, 0, 2, 1, 0, 0]
            )
        }
    }
}

struct Cube2x2Solver: TwistyPuzzleSolver {
    typealias State = Cube2x2State

    func solve(from initialState: Cube2x2State) async -> TwistySolveResult {
        let startTime = Date()
        let solved = Cube2x2State.solved

        if initialState == solved {
            return TwistySolveResult(
                puzzleType: .cube2x2,
                isSolvable: true,
                moves: [],
                steps: [TwistySolutionStep(move: nil, explanation: "Cube is already solved.")],
                elapsedTime: Date().timeIntervalSince(startTime),
                finalStateDescription: solved.makeDisplayState().cornerSummary.joined(separator: " • ")
            )
        }

        let path = bidirectionalBFS(from: initialState, to: solved)
        let solvedStateDescription = solved.makeDisplayState().cornerSummary.joined(separator: " • ")

        guard let path else {
            return TwistySolveResult(
                puzzleType: .cube2x2,
                isSolvable: false,
                moves: [],
                steps: [TwistySolutionStep(move: nil, explanation: "No solution found within the search bounds.")],
                elapsedTime: Date().timeIntervalSince(startTime),
                finalStateDescription: nil
            )
        }

        let steps = path.enumerated().map { index, move in
            TwistySolutionStep(
                move: move.twistyMove,
                explanation: "Step \(index + 1): apply \(move.rawValue)."
            )
        }

        return TwistySolveResult(
            puzzleType: .cube2x2,
            isSolvable: true,
            moves: path.map(\.twistyMove),
            steps: steps,
            elapsedTime: Date().timeIntervalSince(startTime),
            finalStateDescription: solvedStateDescription
        )
    }

    private func bidirectionalBFS(from start: Cube2x2State, to goal: Cube2x2State) -> [Cube2x2Move]? {
        var forwardParents: [Cube2x2State: (parent: Cube2x2State, move: Cube2x2Move)] = [:]
        var backwardParents: [Cube2x2State: (parent: Cube2x2State, move: Cube2x2Move)] = [:]
        var forwardVisited: Set<Cube2x2State> = [start]
        var backwardVisited: Set<Cube2x2State> = [goal]
        var forwardFrontier: [Cube2x2State] = [start]
        var backwardFrontier: [Cube2x2State] = [goal]

        while !forwardFrontier.isEmpty, !backwardFrontier.isEmpty {
            if forwardFrontier.count <= backwardFrontier.count {
                if let meeting = expandFrontier(
                    frontier: &forwardFrontier,
                    visited: &forwardVisited,
                    ownParents: &forwardParents,
                    oppositeVisited: backwardVisited,
                    isForward: true
                ) {
                    return stitchPath(
                        meeting: meeting,
                        forwardParents: forwardParents,
                        backwardParents: backwardParents
                    )
                }
            } else {
                if let meeting = expandFrontier(
                    frontier: &backwardFrontier,
                    visited: &backwardVisited,
                    ownParents: &backwardParents,
                    oppositeVisited: forwardVisited,
                    isForward: false
                ) {
                    return stitchPath(
                        meeting: meeting,
                        forwardParents: forwardParents,
                        backwardParents: backwardParents
                    )
                }
            }
        }

        return nil
    }

    private func expandFrontier(
        frontier: inout [Cube2x2State],
        visited: inout Set<Cube2x2State>,
        ownParents: inout [Cube2x2State: (parent: Cube2x2State, move: Cube2x2Move)],
        oppositeVisited: Set<Cube2x2State>,
        isForward: Bool
    ) -> Cube2x2State? {
        var nextLevel: [Cube2x2State] = []

        for state in frontier {
            for (move, nextStateRaw) in state.neighbors() {
                let nextState: Cube2x2State
                let recordedMove: Cube2x2Move

                if isForward {
                    nextState = nextStateRaw
                    recordedMove = move
                } else {
                    nextState = nextStateRaw
                    recordedMove = move.inverse
                }

                guard !visited.contains(nextState) else { continue }

                visited.insert(nextState)
                ownParents[nextState] = (state, recordedMove)

                if oppositeVisited.contains(nextState) {
                    return nextState
                }

                nextLevel.append(nextState)
            }
        }

        frontier = nextLevel
        return nil
    }

    private func stitchPath(
        meeting: Cube2x2State,
        forwardParents: [Cube2x2State: (parent: Cube2x2State, move: Cube2x2Move)],
        backwardParents: [Cube2x2State: (parent: Cube2x2State, move: Cube2x2Move)]
    ) -> [Cube2x2Move] {
        var left: [Cube2x2Move] = []
        var cursor = meeting
        while let record = forwardParents[cursor] {
            left.append(record.move)
            cursor = record.parent
        }
        left.reverse()

        var right: [Cube2x2Move] = []
        cursor = meeting
        while let record = backwardParents[cursor] {
            right.append(record.move)
            cursor = record.parent
        }

        return left + right
    }
}

extension TwistyPuzzleType {
    static var catalog: [TwistyPuzzleCatalogItem] {
        allCases.map(TwistyPuzzleCatalogItem.init)
    }
}

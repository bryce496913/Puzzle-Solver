import Foundation

struct Cube3x3State: TwistyPuzzleState, Hashable, Sendable {
    static let empty = Cube3x3State(faceletTokens: [])

    let faceletTokens: [String]

    var puzzleType: TwistyPuzzleType { .cube3x3 }
}

struct PyraminxState: TwistyPuzzleState, Hashable, Sendable {
    static let empty = PyraminxState(stickerTokens: [])

    let stickerTokens: [String]

    var puzzleType: TwistyPuzzleType { .pyraminx }
}

struct SkewbState: TwistyPuzzleState, Hashable, Sendable {
    static let empty = SkewbState(stickerTokens: [])

    let stickerTokens: [String]

    var puzzleType: TwistyPuzzleType { .skewb }
}

struct Cube3x3Solver: TwistyPuzzleSolver {
    typealias State = Cube3x3State

    func solve(from initialState: Cube3x3State) async -> TwistySolveResult {
        .placeholderResult(for: initialState.puzzleType)
    }
}

struct PyraminxSolver: TwistyPuzzleSolver {
    typealias State = PyraminxState

    func solve(from initialState: PyraminxState) async -> TwistySolveResult {
        .placeholderResult(for: initialState.puzzleType)
    }
}

struct SkewbSolver: TwistyPuzzleSolver {
    typealias State = SkewbState

    func solve(from initialState: SkewbState) async -> TwistySolveResult {
        .placeholderResult(for: initialState.puzzleType)
    }
}

struct TwistyPuzzleImplementationPlan: Sendable {
    let plannedStateType: String
    let plannedSolverType: String
    let entryExpectation: String
    let solvingExpectation: String

    var checklist: [String] {
        [
            "State scaffold: \(plannedStateType)",
            "Solver scaffold: \(plannedSolverType)",
            "Entry screen expectation: \(entryExpectation)",
            "Result/solving screen expectation: \(solvingExpectation)"
        ]
    }
}

extension TwistyPuzzleType {
    var implementationPlan: TwistyPuzzleImplementationPlan? {
        switch self {
        case .cube2x2:
            return nil
        case .cube3x3:
            return TwistyPuzzleImplementationPlan(
                plannedStateType: "Cube3x3State",
                plannedSolverType: "Cube3x3Solver",
                entryExpectation: "3×3 facelet entry with validation",
                solvingExpectation: "Layer-by-layer or two-phase solving pipeline"
            )
        case .pyraminx:
            return TwistyPuzzleImplementationPlan(
                plannedStateType: "PyraminxState",
                plannedSolverType: "PyraminxSolver",
                entryExpectation: "Tip + edge sticker entry with constraints",
                solvingExpectation: "Beginner reduction + tip finish pipeline"
            )
        case .skewb:
            return TwistyPuzzleImplementationPlan(
                plannedStateType: "SkewbState",
                plannedSolverType: "SkewbSolver",
                entryExpectation: "Corner-centric net entry and validation",
                solvingExpectation: "Center orientation and corner permutation stages"
            )
        }
    }
}

private extension TwistySolveResult {
    static func placeholderResult(for puzzleType: TwistyPuzzleType) -> TwistySolveResult {
        TwistySolveResult(
            puzzleType: puzzleType,
            isSolvable: false,
            moves: [],
            steps: [
                TwistySolutionStep(
                    move: nil,
                    explanation: "\(puzzleType.metadata.title) solver is not implemented yet."
                )
            ],
            elapsedTime: nil,
            finalStateDescription: nil
        )
    }
}

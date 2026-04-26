import Foundation

enum PyraminxMove: String, CaseIterable, Hashable, Sendable {
    case u = "U"
    case uPrime = "U'"
    case l = "L"
    case lPrime = "L'"
    case r = "R"
    case rPrime = "R'"
    case b = "B"
    case bPrime = "B'"

    case tipU = "u"
    case tipUPrime = "u'"
    case tipL = "l"
    case tipLPrime = "l'"
    case tipR = "r"
    case tipRPrime = "r'"
    case tipB = "b"
    case tipBPrime = "b'"

    var twistyMove: TwistyMove {
        TwistyMove(
            token: rawValue,
            family: rawValue.first?.isLowercase == true ? .tip : .outerFace,
            turnAmount: rawValue.hasSuffix("'") ? .counterClockwiseQuarter : .clockwiseQuarter
        )
    }
}

enum SkewbMove: String, CaseIterable, Hashable, Sendable {
    case r = "R"
    case rPrime = "R'"
    case l = "L"
    case lPrime = "L'"
    case b = "B"
    case bPrime = "B'"
    case u = "U"
    case uPrime = "U'"

    var twistyMove: TwistyMove {
        TwistyMove(
            token: rawValue,
            family: .outerFace,
            turnAmount: rawValue.hasSuffix("'") ? .counterClockwiseQuarter : .clockwiseQuarter
        )
    }
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

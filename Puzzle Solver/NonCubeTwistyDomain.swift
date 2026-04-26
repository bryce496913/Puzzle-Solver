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

    static let outerMoves: [PyraminxMove] = [.u, .uPrime, .l, .lPrime, .r, .rPrime, .b, .bPrime]
    static let allSolvingMoves: [PyraminxMove] = Self.allCases

    var inverse: PyraminxMove {
        switch self {
        case .u: return .uPrime
        case .uPrime: return .u
        case .l: return .lPrime
        case .lPrime: return .l
        case .r: return .rPrime
        case .rPrime: return .r
        case .b: return .bPrime
        case .bPrime: return .b
        case .tipU: return .tipUPrime
        case .tipUPrime: return .tipU
        case .tipL: return .tipLPrime
        case .tipLPrime: return .tipL
        case .tipR: return .tipRPrime
        case .tipRPrime: return .tipR
        case .tipB: return .tipBPrime
        case .tipBPrime: return .tipB
        }
    }

    var twistyMove: TwistyMove {
        TwistyMove(
            token: rawValue,
            family: rawValue.first?.isLowercase == true ? .tip : .outerFace,
            turnAmount: rawValue.hasSuffix("'") ? .counterClockwiseQuarter : .clockwiseQuarter
        )
    }

    var quarterTurnCount: Int {
        rawValue.hasSuffix("'") ? 2 : 1
    }

    var baseTurn: PyraminxBaseTurn {
        switch self {
        case .u, .uPrime, .tipU, .tipUPrime: return .u
        case .l, .lPrime, .tipL, .tipLPrime: return .l
        case .r, .rPrime, .tipR, .tipRPrime: return .r
        case .b, .bPrime, .tipB, .tipBPrime: return .b
        }
    }

    var isTipMove: Bool {
        rawValue.first?.isLowercase == true
    }
}

enum PyraminxBaseTurn: CaseIterable, Hashable, Sendable {
    case u
    case l
    case r
    case b
}

enum PyraminxStickerColor: String, CaseIterable, Hashable, Sendable {
    case up = "U"
    case left = "L"
    case right = "R"
    case back = "B"
}

struct PyraminxDisplayModel: Hashable, Sendable {
    let faces: [PyraminxDisplayFace]
}

struct PyraminxDisplayFace: Hashable, Sendable, Identifiable {
    let id: String
    let title: String
    let stickers: [PyraminxStickerColor]
}

struct PyraminxState: TwistyPuzzleState, Hashable, Sendable {
    static let solved = PyraminxState(
        stickers: Array(repeating: .up, count: 9)
            + Array(repeating: .left, count: 9)
            + Array(repeating: .right, count: 9)
            + Array(repeating: .back, count: 9)
    )

    static let empty = PyraminxState.solved

    let stickers: [PyraminxStickerColor]
    let inputTokens: [String]
    let invalidTokens: [String]

    var puzzleType: TwistyPuzzleType { .pyraminx }

    init(stickers: [PyraminxStickerColor], inputTokens: [String] = [], invalidTokens: [String] = []) {
        self.stickers = stickers.count == 36 ? stickers : PyraminxState.solved.stickers
        self.inputTokens = inputTokens
        self.invalidTokens = invalidTokens
    }

    init(stickerTokens: [String]) {
        let parseResult = PyraminxTokenParser.parse(stickerTokens)
        let stateFromTokens = PyraminxState.solved.applying(sequence: parseResult.validMoves)
        self = PyraminxState(
            stickers: stateFromTokens.stickers,
            inputTokens: stickerTokens,
            invalidTokens: parseResult.invalidTokens
        )
    }

    func applying(_ move: PyraminxMove) -> PyraminxState {
        var next = self
        for _ in 0..<move.quarterTurnCount {
            next = move.isTipMove
                ? next.applyingTipTurn(move.baseTurn)
                : next.applyingOuterTurn(move.baseTurn)
        }
        return next
    }

    func applying(sequence: [PyraminxMove]) -> PyraminxState {
        sequence.reduce(self) { state, move in
            state.applying(move)
        }
    }

    func neighbors() -> [(move: PyraminxMove, state: PyraminxState)] {
        PyraminxMove.allSolvingMoves.map { move in
            (move, applying(move))
        }
    }

    var isInputValid: Bool {
        invalidTokens.isEmpty
    }

    func makeDisplayModel() -> PyraminxDisplayModel {
        PyraminxDisplayModel(
            faces: [
                PyraminxDisplayFace(id: "U", title: "Up", stickers: Array(stickers[0..<9])),
                PyraminxDisplayFace(id: "L", title: "Left", stickers: Array(stickers[9..<18])),
                PyraminxDisplayFace(id: "R", title: "Right", stickers: Array(stickers[18..<27])),
                PyraminxDisplayFace(id: "B", title: "Back", stickers: Array(stickers[27..<36]))
            ]
        )
    }

    private func applyingOuterTurn(_ turn: PyraminxBaseTurn) -> PyraminxState {
        var next = stickers

        switch turn {
        case .u:
            rotateCycle(in: &next, indices: [0, 6, 8])
            rotateCycle(in: &next, indices: [1, 3, 7])
            rotateCycle(in: &next, indices: [2, 4, 5])
            rotateTripletStrips(
                in: &next,
                a: [9, 10, 11],
                b: [18, 19, 20],
                c: [27, 28, 29]
            )
        case .l:
            rotateCycle(in: &next, indices: [9, 15, 17])
            rotateCycle(in: &next, indices: [10, 12, 16])
            rotateCycle(in: &next, indices: [11, 13, 14])
            rotateTripletStrips(
                in: &next,
                a: [0, 3, 6],
                b: [27, 30, 33],
                c: [20, 23, 26]
            )
        case .r:
            rotateCycle(in: &next, indices: [18, 24, 26])
            rotateCycle(in: &next, indices: [19, 21, 25])
            rotateCycle(in: &next, indices: [20, 22, 23])
            rotateTripletStrips(
                in: &next,
                a: [2, 5, 8],
                b: [11, 14, 17],
                c: [27, 31, 34]
            )
        case .b:
            rotateCycle(in: &next, indices: [27, 33, 35])
            rotateCycle(in: &next, indices: [28, 30, 34])
            rotateCycle(in: &next, indices: [29, 31, 32])
            rotateTripletStrips(
                in: &next,
                a: [6, 7, 8],
                b: [15, 16, 17],
                c: [24, 25, 26]
            )
        }

        return PyraminxState(stickers: next)
    }

    private func applyingTipTurn(_ turn: PyraminxBaseTurn) -> PyraminxState {
        var next = stickers

        switch turn {
        case .u:
            rotateCycle(in: &next, indices: [0, 6, 8])
        case .l:
            rotateCycle(in: &next, indices: [9, 15, 17])
        case .r:
            rotateCycle(in: &next, indices: [18, 24, 26])
        case .b:
            rotateCycle(in: &next, indices: [27, 33, 35])
        }

        return PyraminxState(stickers: next)
    }

    private func rotateCycle(in stickers: inout [PyraminxStickerColor], indices: [Int]) {
        guard indices.count == 3 else { return }
        let temp = stickers[indices[0]]
        stickers[indices[0]] = stickers[indices[1]]
        stickers[indices[1]] = stickers[indices[2]]
        stickers[indices[2]] = temp
    }

    private func rotateTripletStrips(
        in stickers: inout [PyraminxStickerColor],
        a: [Int],
        b: [Int],
        c: [Int]
    ) {
        for idx in 0..<3 {
            let temp = stickers[a[idx]]
            stickers[a[idx]] = stickers[b[idx]]
            stickers[b[idx]] = stickers[c[idx]]
            stickers[c[idx]] = temp
        }
    }
}

extension PyraminxState {
    static func == (lhs: PyraminxState, rhs: PyraminxState) -> Bool {
        lhs.stickers == rhs.stickers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stickers)
    }
}

private struct PyraminxTokenParseResult {
    let validMoves: [PyraminxMove]
    let invalidTokens: [String]
}

private enum PyraminxTokenParser {
    static func parse(_ tokens: [String]) -> PyraminxTokenParseResult {
        var validMoves: [PyraminxMove] = []
        var invalidTokens: [String] = []

        for token in tokens {
            if let move = PyraminxMove(rawValue: token) {
                validMoves.append(move)
            } else {
                invalidTokens.append(token)
            }
        }

        return PyraminxTokenParseResult(validMoves: validMoves, invalidTokens: invalidTokens)
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

    static let allSolvingMoves: [SkewbMove] = Self.allCases

    var inverse: SkewbMove {
        switch self {
        case .r: return .rPrime
        case .rPrime: return .r
        case .l: return .lPrime
        case .lPrime: return .l
        case .b: return .bPrime
        case .bPrime: return .b
        case .u: return .uPrime
        case .uPrime: return .u
        }
    }

    var baseTurn: SkewbBaseTurn {
        switch self {
        case .r, .rPrime: return .r
        case .l, .lPrime: return .l
        case .b, .bPrime: return .b
        case .u, .uPrime: return .u
        }
    }

    var turnCount: Int {
        rawValue.hasSuffix("'") ? 2 : 1
    }

    var twistyMove: TwistyMove {
        TwistyMove(
            token: rawValue,
            family: .outerFace,
            turnAmount: rawValue.hasSuffix("'") ? .counterClockwiseQuarter : .clockwiseQuarter
        )
    }
}

enum SkewbBaseTurn: CaseIterable, Hashable, Sendable {
    case r
    case l
    case u
    case b
}

enum SkewbStickerColor: String, CaseIterable, Hashable, Sendable {
    case up = "U"
    case left = "L"
    case front = "F"
    case right = "R"
    case back = "B"
    case down = "D"
}

struct SkewbDisplayModel: Hashable, Sendable {
    let faces: [SkewbDisplayFace]
}

struct SkewbDisplayFace: Hashable, Sendable, Identifiable {
    let id: String
    let title: String
    let stickers: [SkewbStickerColor]
}

struct SkewbState: TwistyPuzzleState, Hashable, Sendable {
    static let solved = SkewbState(
        stickers: Array(repeating: .up, count: 5)
            + Array(repeating: .left, count: 5)
            + Array(repeating: .front, count: 5)
            + Array(repeating: .right, count: 5)
            + Array(repeating: .back, count: 5)
            + Array(repeating: .down, count: 5)
    )

    static let empty = SkewbState(stickerTokens: [])

    let stickers: [SkewbStickerColor]
    let inputTokens: [String]
    let invalidTokens: [String]

    var puzzleType: TwistyPuzzleType { .skewb }

    init(stickers: [SkewbStickerColor], inputTokens: [String] = [], invalidTokens: [String] = []) {
        self.stickers = stickers.count == 30 ? stickers : SkewbState.solved.stickers
        self.inputTokens = inputTokens
        self.invalidTokens = invalidTokens
    }

    init(stickerTokens: [String]) {
        let parseResult = SkewbTokenParser.parse(stickerTokens)
        let stateFromTokens = SkewbState.solved.applying(sequence: parseResult.validMoves)
        self = SkewbState(
            stickers: stateFromTokens.stickers,
            inputTokens: stickerTokens,
            invalidTokens: parseResult.invalidTokens
        )
    }

    func applying(_ move: SkewbMove) -> SkewbState {
        var next = self
        for _ in 0..<move.turnCount {
            next = next.applying(move.baseTurn)
        }
        return next
    }

    func applying(sequence: [SkewbMove]) -> SkewbState {
        sequence.reduce(self) { state, move in
            state.applying(move)
        }
    }

    func neighbors() -> [(move: SkewbMove, state: SkewbState)] {
        SkewbMove.allSolvingMoves.map { move in
            (move, applying(move))
        }
    }

    var isInputValid: Bool {
        invalidTokens.isEmpty
    }

    func makeDisplayModel() -> SkewbDisplayModel {
        SkewbDisplayModel(
            faces: [
                SkewbDisplayFace(id: "U", title: "Up", stickers: Array(stickers[0..<5])),
                SkewbDisplayFace(id: "L", title: "Left", stickers: Array(stickers[5..<10])),
                SkewbDisplayFace(id: "F", title: "Front", stickers: Array(stickers[10..<15])),
                SkewbDisplayFace(id: "R", title: "Right", stickers: Array(stickers[15..<20])),
                SkewbDisplayFace(id: "B", title: "Back", stickers: Array(stickers[20..<25])),
                SkewbDisplayFace(id: "D", title: "Down", stickers: Array(stickers[25..<30]))
            ]
        )
    }

    private func applying(_ move: SkewbBaseTurn) -> SkewbState {
        var next = stickers

        switch move {
        case .r:
            rotateCycle(in: &next, indices: [17, 18, 19])
            rotateCycle(in: &next, indices: [0, 10, 25])
            rotateCycle(in: &next, indices: [2, 13, 27])
            rotateCycle(in: &next, indices: [3, 14, 26])
            rotateCycle(in: &next, indices: [12, 28, 22])
            rotateCycle(in: &next, indices: [15, 23, 11])
        case .l:
            rotateCycle(in: &next, indices: [7, 8, 9])
            rotateCycle(in: &next, indices: [0, 25, 20])
            rotateCycle(in: &next, indices: [1, 29, 21])
            rotateCycle(in: &next, indices: [4, 26, 24])
            rotateCycle(in: &next, indices: [10, 22, 6])
            rotateCycle(in: &next, indices: [14, 5, 23])
        case .u:
            rotateCycle(in: &next, indices: [1, 2, 3])
            rotateCycle(in: &next, indices: [10, 15, 20])
            rotateCycle(in: &next, indices: [11, 16, 21])
            rotateCycle(in: &next, indices: [12, 17, 22])
            rotateCycle(in: &next, indices: [6, 13, 18])
            rotateCycle(in: &next, indices: [9, 24, 19])
        case .b:
            rotateCycle(in: &next, indices: [21, 22, 23])
            rotateCycle(in: &next, indices: [0, 20, 25])
            rotateCycle(in: &next, indices: [1, 24, 29])
            rotateCycle(in: &next, indices: [2, 21, 28])
            rotateCycle(in: &next, indices: [15, 7, 27])
            rotateCycle(in: &next, indices: [16, 8, 26])
        }

        return SkewbState(stickers: next)
    }

    private func rotateCycle(in stickers: inout [SkewbStickerColor], indices: [Int]) {
        guard indices.count == 3 else { return }
        let temp = stickers[indices[0]]
        stickers[indices[0]] = stickers[indices[1]]
        stickers[indices[1]] = stickers[indices[2]]
        stickers[indices[2]] = temp
    }
}

extension SkewbState {
    static func == (lhs: SkewbState, rhs: SkewbState) -> Bool {
        lhs.stickers == rhs.stickers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stickers)
    }
}

private struct SkewbTokenParseResult {
    let validMoves: [SkewbMove]
    let invalidTokens: [String]
}

private enum SkewbTokenParser {
    static func parse(_ tokens: [String]) -> SkewbTokenParseResult {
        var validMoves: [SkewbMove] = []
        var invalidTokens: [String] = []

        for token in tokens {
            if let move = SkewbMove(rawValue: token) {
                validMoves.append(move)
            } else {
                invalidTokens.append(token)
            }
        }

        return SkewbTokenParseResult(validMoves: validMoves, invalidTokens: invalidTokens)
    }
}

struct PyraminxSolver: TwistyPuzzleSolver {
    typealias State = PyraminxState

    func solve(from initialState: PyraminxState) async -> TwistySolveResult {
        let start = Date()
        if !initialState.isInputValid {
            let invalidList = initialState.invalidTokens.joined(separator: ", ")
            return TwistySolveResult(
                puzzleType: .pyraminx,
                stateValidation: .invalid(reason: "Unrecognized tokens: \(invalidList)"),
                isSolvable: false,
                moves: [],
                steps: [
                    TwistySolutionStep(
                        move: nil,
                        explanation: "Input contains invalid tokens. Fix and try again."
                    )
                ],
                elapsedTime: Date().timeIntervalSince(start),
                finalStateDescription: nil
            )
        }

        if initialState == .solved {
            return TwistySolveResult(
                puzzleType: .pyraminx,
                stateValidation: .valid,
                isSolvable: true,
                moves: [],
                steps: [TwistySolutionStep(move: nil, explanation: "Pyraminx is already solved.")],
                elapsedTime: Date().timeIntervalSince(start),
                finalStateDescription: "Solved"
            )
        }

        guard let moveSequence = bidirectionalBFS(from: initialState, to: .solved) else {
            return TwistySolveResult(
                puzzleType: .pyraminx,
                stateValidation: .valid,
                isSolvable: false,
                moves: [],
                steps: [TwistySolutionStep(move: nil, explanation: "No solution found within search bounds.")],
                elapsedTime: Date().timeIntervalSince(start),
                finalStateDescription: nil
            )
        }

        let steps = moveSequence.enumerated().map { index, move in
            TwistySolutionStep(
                move: move.twistyMove,
                explanation: "Step \(index + 1): apply \(move.rawValue)."
            )
        }

        return TwistySolveResult(
            puzzleType: .pyraminx,
            stateValidation: .valid,
            isSolvable: true,
            moves: moveSequence.map(\.twistyMove),
            steps: steps,
            elapsedTime: Date().timeIntervalSince(start),
            finalStateDescription: "Solved"
        )
    }

    private func bidirectionalBFS(from start: PyraminxState, to goal: PyraminxState) -> [PyraminxMove]? {
        var forwardParents: [PyraminxState: (parent: PyraminxState, move: PyraminxMove)] = [:]
        var backwardParents: [PyraminxState: (parent: PyraminxState, move: PyraminxMove)] = [:]
        var forwardVisited: Set<PyraminxState> = [start]
        var backwardVisited: Set<PyraminxState> = [goal]
        var forwardFrontier: [PyraminxState] = [start]
        var backwardFrontier: [PyraminxState] = [goal]

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
        frontier: inout [PyraminxState],
        visited: inout Set<PyraminxState>,
        ownParents: inout [PyraminxState: (parent: PyraminxState, move: PyraminxMove)],
        oppositeVisited: Set<PyraminxState>,
        isForward: Bool
    ) -> PyraminxState? {
        var nextLevel: [PyraminxState] = []

        for state in frontier {
            for (move, adjacentState) in state.neighbors() {
                let nextState: PyraminxState
                let recordedMove: PyraminxMove

                if isForward {
                    nextState = adjacentState
                    recordedMove = move
                } else {
                    nextState = adjacentState
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
        meeting: PyraminxState,
        forwardParents: [PyraminxState: (parent: PyraminxState, move: PyraminxMove)],
        backwardParents: [PyraminxState: (parent: PyraminxState, move: PyraminxMove)]
    ) -> [PyraminxMove] {
        var left: [PyraminxMove] = []
        var cursor = meeting
        while let record = forwardParents[cursor] {
            left.append(record.move)
            cursor = record.parent
        }
        left.reverse()

        var right: [PyraminxMove] = []
        cursor = meeting
        while let record = backwardParents[cursor] {
            right.append(record.move)
            cursor = record.parent
        }

        return left + right
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
            stateValidation: .valid,
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

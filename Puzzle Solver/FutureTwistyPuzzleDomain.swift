import Foundation

enum Cube3x3FaceTurn: String, CaseIterable, Hashable, Sendable {
    case u = "U"
    case d = "D"
    case l = "L"
    case r = "R"
    case f = "F"
    case b = "B"
}

enum Cube3x3Move: String, CaseIterable, Hashable, Sendable {
    case u = "U"
    case uPrime = "U'"
    case u2 = "U2"

    case d = "D"
    case dPrime = "D'"
    case d2 = "D2"

    case l = "L"
    case lPrime = "L'"
    case l2 = "L2"

    case r = "R"
    case rPrime = "R'"
    case r2 = "R2"

    case f = "F"
    case fPrime = "F'"
    case f2 = "F2"

    case b = "B"
    case bPrime = "B'"
    case b2 = "B2"

    var baseTurn: Cube3x3FaceTurn {
        switch self {
        case .u, .uPrime, .u2: return .u
        case .d, .dPrime, .d2: return .d
        case .l, .lPrime, .l2: return .l
        case .r, .rPrime, .r2: return .r
        case .f, .fPrime, .f2: return .f
        case .b, .bPrime, .b2: return .b
        }
    }

    var quarterTurnCount: Int {
        switch self {
        case .u, .d, .l, .r, .f, .b:
            return 1
        case .u2, .d2, .l2, .r2, .f2, .b2:
            return 2
        case .uPrime, .dPrime, .lPrime, .rPrime, .fPrime, .bPrime:
            return 3
        }
    }

    var twistyMove: TwistyMove {
        let turnAmount: TwistyTurnAmount
        if rawValue.hasSuffix("2") {
            turnAmount = .halfTurn
        } else if rawValue.hasSuffix("'") {
            turnAmount = .counterClockwiseQuarter
        } else {
            turnAmount = .clockwiseQuarter
        }

        return TwistyMove(token: rawValue, family: .outerFace, turnAmount: turnAmount)
    }
}

enum Cube3x3Face: CaseIterable, Hashable, Sendable {
    case up
    case right
    case front
    case down
    case left
    case back
}

enum Cube3x3StickerColor: String, CaseIterable, Hashable, Sendable {
    case up = "U"
    case right = "R"
    case front = "F"
    case down = "D"
    case left = "L"
    case back = "B"
}

struct Cube3x3StickerNet: Hashable, Sendable {
    let up: [Cube3x3StickerColor]
    let right: [Cube3x3StickerColor]
    let front: [Cube3x3StickerColor]
    let down: [Cube3x3StickerColor]
    let left: [Cube3x3StickerColor]
    let back: [Cube3x3StickerColor]

    subscript(face: Cube3x3Face) -> [Cube3x3StickerColor] {
        switch face {
        case .up: return up
        case .right: return right
        case .front: return front
        case .down: return down
        case .left: return left
        case .back: return back
        }
    }
}

enum Cube3x3StateValidation: Hashable, Sendable {
    case valid
    case invalid([String])

    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
}

struct Cube3x3State: TwistyPuzzleState, Hashable, Sendable {
    static let solved = Cube3x3State(
        cornerPermutation: [0, 1, 2, 3, 4, 5, 6, 7],
        cornerOrientation: [0, 0, 0, 0, 0, 0, 0, 0],
        edgePermutation: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        edgeOrientation: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )

    static let empty = solved

    let cornerPermutation: [UInt8]
    let cornerOrientation: [UInt8]
    let edgePermutation: [UInt8]
    let edgeOrientation: [UInt8]

    var puzzleType: TwistyPuzzleType { .cube3x3 }
    var isSolved: Bool { self == .solved }

    init(
        cornerPermutation: [UInt8],
        cornerOrientation: [UInt8],
        edgePermutation: [UInt8],
        edgeOrientation: [UInt8]
    ) {
        self.cornerPermutation = cornerPermutation
        self.cornerOrientation = cornerOrientation
        self.edgePermutation = edgePermutation
        self.edgeOrientation = edgeOrientation
    }

    func applying(_ move: Cube3x3Move) -> Cube3x3State {
        var next = self
        for _ in 0..<move.quarterTurnCount {
            next = next.applyingBaseMove(move.baseTurn)
        }
        return next
    }

    func applying(sequence: [Cube3x3Move]) -> Cube3x3State {
        sequence.reduce(self) { partial, move in
            partial.applying(move)
        }
    }

    func neighbors() -> [(move: Cube3x3Move, state: Cube3x3State)] {
        Cube3x3Move.allCases.map { move in
            (move, applying(move))
        }
    }

    func validate() -> Cube3x3StateValidation {
        var issues: [String] = []

        if cornerPermutation.count != 8 { issues.append("Corner permutation must contain exactly 8 entries.") }
        if cornerOrientation.count != 8 { issues.append("Corner orientation must contain exactly 8 entries.") }
        if edgePermutation.count != 12 { issues.append("Edge permutation must contain exactly 12 entries.") }
        if edgeOrientation.count != 12 { issues.append("Edge orientation must contain exactly 12 entries.") }

        if issues.isEmpty {
            let cornerSet = Set(cornerPermutation)
            let edgeSet = Set(edgePermutation)

            if cornerSet.count != 8 || cornerSet != Set(0...7) {
                issues.append("Corner permutation must be a permutation of 0...7.")
            }

            if edgeSet.count != 12 || edgeSet != Set(0...11) {
                issues.append("Edge permutation must be a permutation of 0...11.")
            }

            if cornerOrientation.contains(where: { $0 > 2 }) {
                issues.append("Corner orientations must be in range 0...2.")
            }

            if edgeOrientation.contains(where: { $0 > 1 }) {
                issues.append("Edge orientations must be in range 0...1.")
            }

            if cornerOrientation.reduce(0, +) % 3 != 0 {
                issues.append("Corner orientation parity is invalid (sum mod 3 must be 0).")
            }

            if edgeOrientation.reduce(0, +) % 2 != 0 {
                issues.append("Edge orientation parity is invalid (sum mod 2 must be 0).")
            }
        }

        return issues.isEmpty ? .valid : .invalid(issues)
    }

    func makeStickerNet() -> Cube3x3StickerNet {
        let facelets = makeFacelets()

        return Cube3x3StickerNet(
            up: Array(facelets[0..<9]),
            right: Array(facelets[9..<18]),
            front: Array(facelets[18..<27]),
            down: Array(facelets[27..<36]),
            left: Array(facelets[36..<45]),
            back: Array(facelets[45..<54])
        )
    }

    private func makeFacelets() -> [Cube3x3StickerColor] {
        var stickers = Array(repeating: Cube3x3StickerColor.up, count: 54)

        for position in 0..<8 {
            let cubie = Int(cornerPermutation[position])
            let orientation = Int(cornerOrientation[position])

            for stickerIndex in 0..<3 {
                let faceletIndex = Self.cornerFaceletIndices[position][(stickerIndex + orientation) % 3]
                stickers[faceletIndex] = Self.cornerColors[cubie][stickerIndex]
            }
        }

        for position in 0..<12 {
            let cubie = Int(edgePermutation[position])
            let orientation = Int(edgeOrientation[position])

            for stickerIndex in 0..<2 {
                let faceletIndex = Self.edgeFaceletIndices[position][(stickerIndex + orientation) % 2]
                stickers[faceletIndex] = Self.edgeColors[cubie][stickerIndex]
            }
        }

        return stickers
    }

    private func applyingBaseMove(_ move: Cube3x3FaceTurn) -> Cube3x3State {
        let transform = Cube3x3Transform.base(for: move)

        var nextCornerPermutation = Array(repeating: UInt8(0), count: 8)
        var nextCornerOrientation = Array(repeating: UInt8(0), count: 8)
        var nextEdgePermutation = Array(repeating: UInt8(0), count: 12)
        var nextEdgeOrientation = Array(repeating: UInt8(0), count: 12)

        for index in 0..<8 {
            let source = Int(transform.cornerPermutation[index])
            nextCornerPermutation[index] = cornerPermutation[source]
            nextCornerOrientation[index] = (cornerOrientation[source] + transform.cornerOrientationDelta[index]) % 3
        }

        for index in 0..<12 {
            let source = Int(transform.edgePermutation[index])
            nextEdgePermutation[index] = edgePermutation[source]
            nextEdgeOrientation[index] = (edgeOrientation[source] + transform.edgeOrientationDelta[index]) % 2
        }

        return Cube3x3State(
            cornerPermutation: nextCornerPermutation,
            cornerOrientation: nextCornerOrientation,
            edgePermutation: nextEdgePermutation,
            edgeOrientation: nextEdgeOrientation
        )
    }

    private static let cornerFaceletIndices: [[Int]] = [
        [8, 9, 20],
        [6, 18, 38],
        [0, 36, 47],
        [2, 45, 11],
        [29, 26, 15],
        [27, 44, 24],
        [33, 53, 42],
        [35, 17, 51]
    ]

    private static let edgeFaceletIndices: [[Int]] = [
        [5, 10],
        [7, 19],
        [3, 37],
        [1, 46],
        [32, 16],
        [28, 25],
        [30, 43],
        [34, 52],
        [23, 12],
        [21, 41],
        [50, 39],
        [48, 14]
    ]

    private static let cornerColors: [[Cube3x3StickerColor]] = [
        [.up, .right, .front],
        [.up, .front, .left],
        [.up, .left, .back],
        [.up, .back, .right],
        [.down, .front, .right],
        [.down, .left, .front],
        [.down, .back, .left],
        [.down, .right, .back]
    ]

    private static let edgeColors: [[Cube3x3StickerColor]] = [
        [.up, .right],
        [.up, .front],
        [.up, .left],
        [.up, .back],
        [.down, .right],
        [.down, .front],
        [.down, .left],
        [.down, .back],
        [.front, .right],
        [.front, .left],
        [.back, .left],
        [.back, .right]
    ]
}

private struct Cube3x3Transform {
    let cornerPermutation: [UInt8]
    let cornerOrientationDelta: [UInt8]
    let edgePermutation: [UInt8]
    let edgeOrientationDelta: [UInt8]

    static func base(for move: Cube3x3FaceTurn) -> Cube3x3Transform {
        switch move {
        case .u:
            return Cube3x3Transform(
                cornerPermutation: [3, 0, 1, 2, 4, 5, 6, 7],
                cornerOrientationDelta: [0, 0, 0, 0, 0, 0, 0, 0],
                edgePermutation: [3, 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11],
                edgeOrientationDelta: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            )
        case .d:
            return Cube3x3Transform(
                cornerPermutation: [0, 1, 2, 3, 5, 6, 7, 4],
                cornerOrientationDelta: [0, 0, 0, 0, 0, 0, 0, 0],
                edgePermutation: [0, 1, 2, 3, 5, 6, 7, 4, 8, 9, 10, 11],
                edgeOrientationDelta: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            )
        case .r:
            return Cube3x3Transform(
                cornerPermutation: [4, 1, 2, 0, 7, 5, 6, 3],
                cornerOrientationDelta: [2, 0, 0, 1, 1, 0, 0, 2],
                edgePermutation: [8, 1, 2, 3, 11, 5, 6, 7, 4, 9, 10, 0],
                edgeOrientationDelta: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            )
        case .l:
            return Cube3x3Transform(
                cornerPermutation: [0, 2, 6, 3, 4, 1, 5, 7],
                cornerOrientationDelta: [0, 1, 2, 0, 0, 2, 1, 0],
                edgePermutation: [0, 1, 10, 3, 4, 5, 9, 7, 8, 2, 6, 11],
                edgeOrientationDelta: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            )
        case .f:
            return Cube3x3Transform(
                cornerPermutation: [1, 5, 2, 3, 0, 4, 6, 7],
                cornerOrientationDelta: [1, 2, 0, 0, 2, 1, 0, 0],
                edgePermutation: [0, 9, 2, 3, 4, 8, 6, 7, 1, 5, 10, 11],
                edgeOrientationDelta: [0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0]
            )
        case .b:
            return Cube3x3Transform(
                cornerPermutation: [0, 1, 3, 7, 4, 5, 2, 6],
                cornerOrientationDelta: [0, 0, 1, 2, 0, 0, 2, 1],
                edgePermutation: [0, 1, 2, 11, 4, 5, 6, 10, 8, 9, 3, 7],
                edgeOrientationDelta: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1]
            )
        }
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

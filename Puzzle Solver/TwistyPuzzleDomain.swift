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
                subtitle: "Phase 2 target",
                supportedNotation: [.wca]
            )
        case .cube3x3:
            return TwistyPuzzleMetadata(
                title: "3×3 Rubik’s Cube",
                shortTitle: "3×3",
                icon: "cube.fill",
                availability: .comingSoon,
                subtitle: "Coming soon",
                supportedNotation: [.wca]
            )
        case .pyraminx:
            return TwistyPuzzleMetadata(
                title: "Pyraminx",
                shortTitle: "Pyraminx",
                icon: "triangle.fill",
                availability: .comingSoon,
                subtitle: "Coming soon",
                supportedNotation: [.wca]
            )
        case .skewb:
            return TwistyPuzzleMetadata(
                title: "Skewb",
                shortTitle: "Skewb",
                icon: "diamond.fill",
                availability: .comingSoon,
                subtitle: "Coming soon",
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
    let title: String
    let statusText: String
    let moveCountText: String
    let stepCountText: String
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
            title: puzzleType.metadata.title,
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

extension TwistyPuzzleType {
    static var catalog: [TwistyPuzzleCatalogItem] {
        allCases.map(TwistyPuzzleCatalogItem.init)
    }
}

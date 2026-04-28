import Foundation

enum MechanicalPuzzleType: String, CaseIterable, Identifiable, Sendable {
    case rushHour
    case klotski
    case pegSolitaire
    case towersOfHanoi
    case lightsOut

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rushHour: return "Rush Hour"
        case .klotski: return "Klotski"
        case .pegSolitaire: return "Peg Solitaire"
        case .towersOfHanoi: return "Towers of Hanoi"
        case .lightsOut: return "Lights Out"
        }
    }

    var icon: String {
        switch self {
        case .rushHour: return "car.fill"
        case .klotski: return "rectangle.3.group.fill"
        case .pegSolitaire: return "circle.grid.3x3.fill"
        case .towersOfHanoi: return "square.3.layers.3d.down.right"
        case .lightsOut: return "lightbulb.fill"
        }
    }

    var isEnabled: Bool {
        self == .rushHour
    }

    var subtitle: String {
        isEnabled ? "Phase 6 active now" : "Coming soon"
    }
}

enum MechanicalSolveStatus: Sendable {
    case solved
    case unsolved
}

struct MechanicalMove: Hashable, Sendable {
    let notation: String
    let description: String?

    init(notation: String, description: String? = nil) {
        self.notation = notation
        self.description = description
    }
}

struct MechanicalSolutionStep<BoardState: Hashable & Sendable>: Hashable, Sendable, Identifiable {
    let id: UUID
    let stepNumber: Int
    let move: MechanicalMove?
    let instruction: String
    let boardState: BoardState?

    init(
        id: UUID = UUID(),
        stepNumber: Int,
        move: MechanicalMove?,
        instruction: String,
        boardState: BoardState? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.move = move
        self.instruction = instruction
        self.boardState = boardState
    }
}

struct MechanicalSolveResult<BoardState: Hashable & Sendable>: Sendable {
    let puzzleType: MechanicalPuzzleType
    let status: MechanicalSolveStatus
    let steps: [MechanicalSolutionStep<BoardState>]

    var isSolved: Bool {
        status == .solved
    }

    var moveCount: Int {
        steps.compactMap(\.move).count
    }

    var orderedSteps: [MechanicalSolutionStep<BoardState>] {
        steps.sorted { $0.stepNumber < $1.stepNumber }
    }
}

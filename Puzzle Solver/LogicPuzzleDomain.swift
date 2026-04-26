import Foundation

enum LogicPuzzleType: String, CaseIterable, Identifiable {
    case sudoku
    case killerSudoku
    case nonogram
    case kakuro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sudoku:
            return "Sudoku"
        case .killerSudoku:
            return "Killer Sudoku"
        case .nonogram:
            return "Nonogram"
        case .kakuro:
            return "Kakuro"
        }
    }

    var icon: String {
        switch self {
        case .sudoku:
            return "number.square.fill"
        case .killerSudoku:
            return "flame.fill"
        case .nonogram:
            return "square.grid.4x3.fill"
        case .kakuro:
            return "plus.forwardslash.minus"
        }
    }

    var isEnabled: Bool {
        self == .sudoku
    }

    var availabilitySubtitle: String {
        isEnabled ? "Ready now" : "Coming soon"
    }
}

struct LogicSolutionStep: Identifiable, Equatable {
    let id: UUID
    let title: String
    let details: String

    init(id: UUID = UUID(), title: String, details: String) {
        self.id = id
        self.title = title
        self.details = details
    }
}

enum LogicValidationError: LocalizedError, Equatable {
    case invalidInput(message: String)
    case conflictingValues(message: String)
    case unsupportedConfiguration(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message), .conflictingValues(let message), .unsupportedConfiguration(let message):
            return message
        }
    }
}

enum LogicSolveValidity: Equatable {
    case valid
    case invalid([LogicValidationError])
}

enum LogicSolveCompletion: Equatable {
    case solved
    case unsolved
}

struct LogicSolveResult<Output> {
    let puzzleType: LogicPuzzleType
    let validity: LogicSolveValidity
    let completion: LogicSolveCompletion
    let output: Output?
    let messages: [String]
    let steps: [LogicSolutionStep]?

    var isValid: Bool {
        if case .valid = validity { return true }
        return false
    }

    var isSolved: Bool {
        completion == .solved
    }
}

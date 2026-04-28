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

enum RushHourOrientation: String, Hashable, Sendable {
    case horizontal
    case vertical
}

enum RushHourWall: String, Hashable, Sendable {
    case top
    case bottom
    case left
    case right
}

struct RushHourExit: Hashable, Sendable {
    let wall: RushHourWall
    let index: Int

    init?(wall: RushHourWall, index: Int) {
        guard (0..<RushHourBoardState.gridSize).contains(index) else { return nil }
        self.wall = wall
        self.index = index
    }
}

struct RushHourVehicle: Hashable, Sendable, Identifiable {
    let id: String
    let orientation: RushHourOrientation
    let length: Int
    let row: Int
    let column: Int
    let isTarget: Bool

    init?(
        id: String,
        orientation: RushHourOrientation,
        length: Int,
        row: Int,
        column: Int,
        isTarget: Bool = false
    ) {
        guard !id.isEmpty else { return nil }
        guard (2...3).contains(length) else { return nil }
        guard (0..<RushHourBoardState.gridSize).contains(row) else { return nil }
        guard (0..<RushHourBoardState.gridSize).contains(column) else { return nil }

        let maxRow = orientation == .vertical ? row + length - 1 : row
        let maxColumn = orientation == .horizontal ? column + length - 1 : column
        guard maxRow < RushHourBoardState.gridSize, maxColumn < RushHourBoardState.gridSize else { return nil }

        self.id = id
        self.orientation = orientation
        self.length = length
        self.row = row
        self.column = column
        self.isTarget = isTarget
    }

    var occupiedCells: [RushHourBoardState.Cell] {
        (0..<length).map { offset in
            switch orientation {
            case .horizontal:
                return .init(row: row, column: column + offset)
            case .vertical:
                return .init(row: row + offset, column: column)
            }
        }
    }

    func moved(by delta: Int) -> RushHourVehicle? {
        guard delta != 0 else { return self }

        switch orientation {
        case .horizontal:
            return RushHourVehicle(
                id: id,
                orientation: orientation,
                length: length,
                row: row,
                column: column + delta,
                isTarget: isTarget
            )
        case .vertical:
            return RushHourVehicle(
                id: id,
                orientation: orientation,
                length: length,
                row: row + delta,
                column: column,
                isTarget: isTarget
            )
        }
    }
}

struct RushHourMove: Hashable, Sendable {
    let vehicleID: String
    let delta: Int

    init?(vehicleID: String, delta: Int) {
        guard !vehicleID.isEmpty, delta != 0 else { return nil }
        self.vehicleID = vehicleID
        self.delta = delta
    }
}

struct RushHourBoardState: Hashable, Sendable {
    static let gridSize = 6

    struct Cell: Hashable, Sendable {
        let row: Int
        let column: Int
    }

    let vehicles: [RushHourVehicle]
    let exit: RushHourExit

    init?(vehicles: [RushHourVehicle], exit: RushHourExit) {
        guard !vehicles.isEmpty else { return nil }

        let uniqueIDs = Set(vehicles.map(\.id))
        guard uniqueIDs.count == vehicles.count else { return nil }
        guard vehicles.filter(\.isTarget).count == 1 else { return nil }

        var occupancy = Set<Cell>()
        for vehicle in vehicles {
            for cell in vehicle.occupiedCells {
                guard occupancy.insert(cell).inserted else { return nil }
            }
        }

        self.vehicles = vehicles.sorted { $0.id < $1.id }
        self.exit = exit
    }

    var targetVehicle: RushHourVehicle? {
        vehicles.first(where: \.isTarget)
    }

    func vehicle(withID id: String) -> RushHourVehicle? {
        vehicles.first(where: { $0.id == id })
    }

    func isSolved() -> Bool {
        guard let target = targetVehicle else { return false }

        switch exit.wall {
        case .right:
            guard target.orientation == .horizontal, target.row == exit.index else { return false }
            let frontColumn = target.column + target.length - 1
            return frontColumn == Self.gridSize - 1
        case .left:
            guard target.orientation == .horizontal, target.row == exit.index else { return false }
            return target.column == 0
        case .bottom:
            guard target.orientation == .vertical, target.column == exit.index else { return false }
            let frontRow = target.row + target.length - 1
            return frontRow == Self.gridSize - 1
        case .top:
            guard target.orientation == .vertical, target.column == exit.index else { return false }
            return target.row == 0
        }
    }

    func canApply(_ move: RushHourMove) -> Bool {
        guard let vehicle = vehicle(withID: move.vehicleID) else { return false }
        return isValidMove(vehicle: vehicle, delta: move.delta)
    }

    func applying(_ move: RushHourMove) -> RushHourBoardState? {
        guard canApply(move) else { return nil }
        guard let index = vehicles.firstIndex(where: { $0.id == move.vehicleID }) else { return nil }
        guard let movedVehicle = vehicles[index].moved(by: move.delta) else { return nil }

        var updated = vehicles
        updated[index] = movedVehicle
        return RushHourBoardState(vehicles: updated, exit: exit)
    }

    func validMoves() -> [RushHourMove] {
        var moves: [RushHourMove] = []

        for vehicle in vehicles {
            var negativeDelta = -1
            while isValidMove(vehicle: vehicle, delta: negativeDelta) {
                if let move = RushHourMove(vehicleID: vehicle.id, delta: negativeDelta) {
                    moves.append(move)
                }
                negativeDelta -= 1
            }

            var positiveDelta = 1
            while isValidMove(vehicle: vehicle, delta: positiveDelta) {
                if let move = RushHourMove(vehicleID: vehicle.id, delta: positiveDelta) {
                    moves.append(move)
                }
                positiveDelta += 1
            }
        }

        return moves
    }

    private func isValidMove(vehicle: RushHourVehicle, delta: Int) -> Bool {
        guard delta != 0 else { return false }
        guard let moved = vehicle.moved(by: delta) else { return false }

        let occupiedByOthers = Set(
            vehicles
                .filter { $0.id != vehicle.id }
                .flatMap(\.occupiedCells)
        )

        for cell in moved.occupiedCells {
            guard isWithinBounds(cell) else { return false }
            guard !occupiedByOthers.contains(cell) else { return false }
        }

        return true
    }

    private func isWithinBounds(_ cell: Cell) -> Bool {
        (0..<Self.gridSize).contains(cell.row) && (0..<Self.gridSize).contains(cell.column)
    }
}

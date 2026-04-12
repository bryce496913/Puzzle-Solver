import Foundation

enum Cube3x3FaceSlot: String, CaseIterable, Sendable {
    case u = "U"
    case l = "L"
    case f = "F"
    case r = "R"
    case b = "B"
    case d = "D"

    var stateFace: Cube3x3Face {
        switch self {
        case .u: return .up
        case .l: return .left
        case .f: return .front
        case .r: return .right
        case .b: return .back
        case .d: return .down
        }
    }

    var lockedCenterColor: Cube3x3StickerColor {
        switch self {
        case .u: return .up
        case .r: return .right
        case .f: return .front
        case .d: return .down
        case .l: return .left
        case .b: return .back
        }
    }
}

struct Cube3x3StickerCoordinate: Hashable, Sendable {
    let face: Cube3x3FaceSlot
    let index: Int

    var isCenter: Bool { index == 4 }

    static let all: [Cube3x3StickerCoordinate] = Cube3x3FaceSlot.allCases.flatMap { face in
        (0..<9).map { Cube3x3StickerCoordinate(face: face, index: $0) }
    }
}

enum Cube3x3StateBuildError: Error, Sendable {
    case invalidInput(message: String)

    var message: String {
        switch self {
        case .invalidInput(let message):
            return message
        }
    }
}

enum Cube3x3StateBuilder {
    private static let cornerDefinitions: [CornerDefinition] = [
        .init(position: "URF", stickers: [.init(face: .u, index: 8), .init(face: .r, index: 0), .init(face: .f, index: 2)], solvedColors: [.up, .right, .front]),
        .init(position: "UFL", stickers: [.init(face: .u, index: 6), .init(face: .f, index: 0), .init(face: .l, index: 2)], solvedColors: [.up, .front, .left]),
        .init(position: "ULB", stickers: [.init(face: .u, index: 0), .init(face: .l, index: 0), .init(face: .b, index: 2)], solvedColors: [.up, .left, .back]),
        .init(position: "UBR", stickers: [.init(face: .u, index: 2), .init(face: .b, index: 0), .init(face: .r, index: 2)], solvedColors: [.up, .back, .right]),
        .init(position: "DFR", stickers: [.init(face: .d, index: 2), .init(face: .f, index: 8), .init(face: .r, index: 6)], solvedColors: [.down, .front, .right]),
        .init(position: "DLF", stickers: [.init(face: .d, index: 0), .init(face: .l, index: 8), .init(face: .f, index: 6)], solvedColors: [.down, .left, .front]),
        .init(position: "DBL", stickers: [.init(face: .d, index: 6), .init(face: .b, index: 8), .init(face: .l, index: 6)], solvedColors: [.down, .back, .left]),
        .init(position: "DRB", stickers: [.init(face: .d, index: 8), .init(face: .r, index: 8), .init(face: .b, index: 6)], solvedColors: [.down, .right, .back])
    ]

    private static let edgeDefinitions: [EdgeDefinition] = [
        .init(position: "UR", stickers: [.init(face: .u, index: 5), .init(face: .r, index: 1)], solvedColors: [.up, .right]),
        .init(position: "UF", stickers: [.init(face: .u, index: 7), .init(face: .f, index: 1)], solvedColors: [.up, .front]),
        .init(position: "UL", stickers: [.init(face: .u, index: 3), .init(face: .l, index: 1)], solvedColors: [.up, .left]),
        .init(position: "UB", stickers: [.init(face: .u, index: 1), .init(face: .b, index: 1)], solvedColors: [.up, .back]),
        .init(position: "DR", stickers: [.init(face: .d, index: 5), .init(face: .r, index: 7)], solvedColors: [.down, .right]),
        .init(position: "DF", stickers: [.init(face: .d, index: 1), .init(face: .f, index: 7)], solvedColors: [.down, .front]),
        .init(position: "DL", stickers: [.init(face: .d, index: 3), .init(face: .l, index: 7)], solvedColors: [.down, .left]),
        .init(position: "DB", stickers: [.init(face: .d, index: 7), .init(face: .b, index: 7)], solvedColors: [.down, .back]),
        .init(position: "FR", stickers: [.init(face: .f, index: 5), .init(face: .r, index: 3)], solvedColors: [.front, .right]),
        .init(position: "FL", stickers: [.init(face: .f, index: 3), .init(face: .l, index: 5)], solvedColors: [.front, .left]),
        .init(position: "BL", stickers: [.init(face: .b, index: 5), .init(face: .l, index: 3)], solvedColors: [.back, .left]),
        .init(position: "BR", stickers: [.init(face: .b, index: 3), .init(face: .r, index: 5)], solvedColors: [.back, .right])
    ]

    static func makeState(from assignments: [Cube3x3StickerCoordinate: Cube3x3StickerColor]) -> Result<Cube3x3State, Cube3x3StateBuildError> {
        guard assignments.count == Cube3x3StickerCoordinate.all.count else {
            return .failure(.invalidInput(message: "Please fill in all 54 stickers."))
        }

        var cornerPermutation = Array(repeating: UInt8(0), count: 8)
        var cornerOrientation = Array(repeating: UInt8(0), count: 8)
        var edgePermutation = Array(repeating: UInt8(0), count: 12)
        var edgeOrientation = Array(repeating: UInt8(0), count: 12)

        var usedCorners: Set<Int> = []
        var usedEdges: Set<Int> = []

        for (positionIndex, definition) in cornerDefinitions.enumerated() {
            let colors = definition.stickers.compactMap { assignments[$0] }
            guard colors.count == 3 else {
                return .failure(.invalidInput(message: "Missing stickers around corner \(definition.position)."))
            }

            let sortedObserved = colors.sorted(by: { $0.rawValue < $1.rawValue })

            guard let cubieIndex = cornerDefinitions.firstIndex(where: { $0.solvedColors.sorted(by: { $0.rawValue < $1.rawValue }) == sortedObserved }) else {
                return .failure(.invalidInput(message: "Corner \(definition.position) has an impossible color combination."))
            }

            if usedCorners.contains(cubieIndex) {
                return .failure(.invalidInput(message: "A corner cubie is duplicated. Please re-check sticker placement."))
            }
            usedCorners.insert(cubieIndex)

            let cubieUDColor = cornerDefinitions[cubieIndex].solvedColors[0]
            guard let udIndex = colors.firstIndex(of: cubieUDColor) else {
                return .failure(.invalidInput(message: "Corner orientation is invalid at \(definition.position)."))
            }

            cornerPermutation[positionIndex] = UInt8(cubieIndex)
            cornerOrientation[positionIndex] = UInt8(udIndex)
        }

        for (positionIndex, definition) in edgeDefinitions.enumerated() {
            let colors = definition.stickers.compactMap { assignments[$0] }
            guard colors.count == 2 else {
                return .failure(.invalidInput(message: "Missing stickers around edge \(definition.position)."))
            }

            let sortedObserved = colors.sorted(by: { $0.rawValue < $1.rawValue })

            guard let cubieIndex = edgeDefinitions.firstIndex(where: { $0.solvedColors.sorted(by: { $0.rawValue < $1.rawValue }) == sortedObserved }) else {
                return .failure(.invalidInput(message: "Edge \(definition.position) has an impossible color combination."))
            }

            if usedEdges.contains(cubieIndex) {
                return .failure(.invalidInput(message: "An edge cubie is duplicated. Please re-check sticker placement."))
            }
            usedEdges.insert(cubieIndex)

            let orientation = colors == edgeDefinitions[cubieIndex].solvedColors ? 0 : 1
            edgePermutation[positionIndex] = UInt8(cubieIndex)
            edgeOrientation[positionIndex] = UInt8(orientation)
        }

        let state = Cube3x3State(
            cornerPermutation: cornerPermutation,
            cornerOrientation: cornerOrientation,
            edgePermutation: edgePermutation,
            edgeOrientation: edgeOrientation
        )

        switch state.validate() {
        case .valid:
            return .success(state)
        case .invalid(let messages):
            return .failure(.invalidInput(message: messages.first ?? "This cube state is invalid."))
        }
    }
}

private struct CornerDefinition {
    let position: String
    let stickers: [Cube3x3StickerCoordinate]
    let solvedColors: [Cube3x3StickerColor]
}

private struct EdgeDefinition {
    let position: String
    let stickers: [Cube3x3StickerCoordinate]
    let solvedColors: [Cube3x3StickerColor]
}

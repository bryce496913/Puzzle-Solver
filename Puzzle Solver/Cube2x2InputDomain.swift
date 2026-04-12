import Foundation

enum Cube2x2StickerColor: String, CaseIterable, Hashable, Sendable {
    case white
    case yellow
    case red
    case orange
    case blue
    case green

    var label: String { rawValue.capitalized }

    var shortLabel: String {
        switch self {
        case .white: return "W"
        case .yellow: return "Y"
        case .red: return "R"
        case .orange: return "O"
        case .blue: return "B"
        case .green: return "G"
        }
    }
}

enum Cube2x2FaceSlot: String, CaseIterable, Sendable {
    case u = "U"
    case l = "L"
    case f = "F"
    case r = "R"
    case b = "B"
    case d = "D"

    var coordinates: [Cube2x2StickerCoordinate] {
        switch self {
        case .u: return [.u00, .u01, .u10, .u11]
        case .l: return [.l00, .l01, .l10, .l11]
        case .f: return [.f00, .f01, .f10, .f11]
        case .r: return [.r00, .r01, .r10, .r11]
        case .b: return [.b00, .b01, .b10, .b11]
        case .d: return [.d00, .d01, .d10, .d11]
        }
    }
}

enum Cube2x2StickerCoordinate: CaseIterable, Hashable, Sendable {
    case u00, u01, u10, u11
    case l00, l01, l10, l11
    case f00, f01, f10, f11
    case r00, r01, r10, r11
    case b00, b01, b10, b11
    case d00, d01, d10, d11
}

enum Cube2x2StateBuildError: Error, Sendable {
    case invalidInput(message: String)

    var message: String {
        switch self {
        case .invalidInput(let message):
            return message
        }
    }
}

enum Cube2x2StateBuilder {
    private static let cornerDefinitions: [Cube2x2CornerDefinition] = [
        .init(position: "URF", stickers: [.u11, .r00, .f01], solvedColors: [.white, .red, .green]),
        .init(position: "UFL", stickers: [.u10, .f00, .l01], solvedColors: [.white, .green, .orange]),
        .init(position: "ULB", stickers: [.u00, .l00, .b01], solvedColors: [.white, .orange, .blue]),
        .init(position: "UBR", stickers: [.u01, .b00, .r01], solvedColors: [.white, .blue, .red]),
        .init(position: "DFR", stickers: [.d01, .f11, .r10], solvedColors: [.yellow, .green, .red]),
        .init(position: "DLF", stickers: [.d00, .l11, .f10], solvedColors: [.yellow, .orange, .green]),
        .init(position: "DBL", stickers: [.d10, .b11, .l10], solvedColors: [.yellow, .blue, .orange]),
        .init(position: "DRB", stickers: [.d11, .r11, .b10], solvedColors: [.yellow, .red, .blue])
    ]

    static func makeState(from assignments: [Cube2x2StickerCoordinate: Cube2x2StickerColor]) -> Result<Cube2x2State, Cube2x2StateBuildError> {
        guard assignments.count == Cube2x2StickerCoordinate.allCases.count else {
            return .failure(.invalidInput(message: "Please fill in all 24 stickers."))
        }

        var permutation = Array(repeating: UInt8(0), count: 8)
        var orientation = Array(repeating: UInt8(0), count: 8)
        var usedCubies: Set<Int> = []

        for (positionIndex, definition) in cornerDefinitions.enumerated() {
            let colors = definition.stickers.compactMap { assignments[$0] }
            guard colors.count == 3 else {
                return .failure(.invalidInput(message: "Missing stickers around corner \(definition.position)."))
            }

            let sortedObserved = colors.sorted(by: { $0.rawValue < $1.rawValue })

            guard let cubieIndex = cornerDefinitions.firstIndex(where: { $0.solvedColors.sorted(by: { $0.rawValue < $1.rawValue }) == sortedObserved }) else {
                return .failure(.invalidInput(message: "Corner \(definition.position) has an impossible color combination."))
            }

            if usedCubies.contains(cubieIndex) {
                return .failure(.invalidInput(message: "A corner cubie is duplicated. Please re-check sticker placement."))
            }
            usedCubies.insert(cubieIndex)

            let cubieUDColor = cornerDefinitions[cubieIndex].solvedColors[0]
            guard let udIndex = colors.firstIndex(of: cubieUDColor) else {
                return .failure(.invalidInput(message: "Corner orientation is invalid at \(definition.position)."))
            }

            permutation[positionIndex] = UInt8(cubieIndex)
            orientation[positionIndex] = UInt8(udIndex)
        }

        let orientationSum = orientation.reduce(0, +)
        if orientationSum % 3 != 0 {
            return .failure(.invalidInput(message: "This cube orientation is invalid. Please review your sticker colors."))
        }

        if !isEvenPermutation(permutation.map(Int.init)) {
            return .failure(.invalidInput(message: "This corner permutation is not reachable on a physical 2×2 cube."))
        }

        return .success(Cube2x2State(cornerPermutation: permutation, cornerOrientation: orientation))
    }

    private static func isEvenPermutation(_ values: [Int]) -> Bool {
        var inversionCount = 0
        for i in 0..<values.count {
            for j in (i + 1)..<values.count where values[i] > values[j] {
                inversionCount += 1
            }
        }
        return inversionCount % 2 == 0
    }
}

private struct Cube2x2CornerDefinition {
    let position: String
    let stickers: [Cube2x2StickerCoordinate]
    let solvedColors: [Cube2x2StickerColor]
}

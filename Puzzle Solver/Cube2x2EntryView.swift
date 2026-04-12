import SwiftUI

struct Cube2x2EntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedColor: CubeStickerColor = .white
    @State private var stickerAssignments: [StickerCoordinate: CubeStickerColor] = [:]
    @State private var inputError: String?
    @State private var solveState: Cube2x2State?
    @State private var shouldNavigateToSolve = false

    private var colorCounts: [CubeStickerColor: Int] {
        Dictionary(grouping: stickerAssignments.values, by: { $0 }).mapValues(\.count)
    }

    private var validationMessage: String {
        let assigned = stickerAssignments.count
        if assigned < StickerCoordinate.allCases.count {
            return "Fill all 24 stickers. Remaining: \(StickerCoordinate.allCases.count - assigned)."
        }

        for color in CubeStickerColor.allCases {
            let count = colorCounts[color, default: 0]
            if count != 4 {
                return "Each color must appear exactly 4 times. \(color.label) has \(count)."
            }
        }

        switch Cube2x2StateBuilder.makeState(from: stickerAssignments) {
        case .success:
            return "Looks good. Tap Solve when you're ready."
        case .failure(let message):
            return message
        }
    }

    private var isReadyToSolve: Bool {
        if stickerAssignments.count != StickerCoordinate.allCases.count { return false }
        for color in CubeStickerColor.allCases where colorCounts[color, default: 0] != 4 {
            return false
        }
        if case .failure = Cube2x2StateBuilder.makeState(from: stickerAssignments) {
            return false
        }
        return true
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("2×2 Cube Entry")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    helperCard
                        .appSurfaceCard()

                    colorPickerRow
                        .appSurfaceCard()

                    CubeNetInputView(stickerAssignments: $stickerAssignments, selectedColor: selectedColor)
                        .appSurfaceCard()

                    if let inputError {
                        Text(inputError)
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.highlight)
                    }

                    Button {
                        startSolveFlow()
                    } label: {
                        Text("Solve")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!isReadyToSolve)
                    .opacity(isReadyToSolve ? 1 : 0.5)

                    HStack(spacing: AppTheme.Spacing.medium) {
                        Button("Back") { dismiss() }
                            .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))

                        Button("Reset") { resetEntry() }
                            .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))
                    }
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("2×2 Cube")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToSolve) {
            if let solveState {
                Cube2x2SolvingView(initialState: solveState)
            }
        }
    }

    private var helperCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("How to enter your cube")
                .appTextStyle(.h2)

            Text("1) Choose a color below. 2) Tap stickers on the cube net to paint them. 3) Enter only what you currently see on your cube, one sticker at a time.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.86))

            Text(validationMessage)
                .appTextStyle(.paragraph)
                .foregroundStyle(isReadyToSolve ? AppTheme.Colors.text : AppTheme.Colors.highlight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var colorPickerRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Selected color")
                .appTextStyle(.h2)

            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(CubeStickerColor.allCases, id: \.self) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        VStack(spacing: AppTheme.Spacing.xSmall) {
                            Circle()
                                .fill(color.displayColor)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 1))
                            Text(color.shortLabel)
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xSmall)
                        .background(selectedColor == color ? AppTheme.Colors.highlight.opacity(0.22) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func startSolveFlow() {
        inputError = nil

        let stateResult = Cube2x2StateBuilder.makeState(from: stickerAssignments)
        guard case .success(let cubeState) = stateResult else {
            if case .failure(let message) = stateResult {
                inputError = message
            }
            return
        }

        solveState = cubeState
        shouldNavigateToSolve = true
    }

    private func resetEntry() {
        stickerAssignments = [:]
        inputError = nil
        selectedColor = .white
        solveState = nil
        shouldNavigateToSolve = false
    }
}

private struct CubeNetInputView: View {
    @Binding var stickerAssignments: [StickerCoordinate: CubeStickerColor]
    let selectedColor: CubeStickerColor

    private let netRows: [[FacePosition?]] = [
        [nil, .u00, .u01, nil, nil, nil, nil, nil],
        [nil, .u10, .u11, nil, nil, nil, nil, nil],
        [.l00, .l01, .f00, .f01, .r00, .r01, .b00, .b01],
        [.l10, .l11, .f10, .f11, .r10, .r11, .b10, .b11],
        [nil, .d00, .d01, nil, nil, nil, nil, nil],
        [nil, .d10, .d11, nil, nil, nil, nil, nil]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Cube net")
                .appTextStyle(.h2)

            VStack(spacing: 2) {
                ForEach(Array(netRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 2) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, facePosition in
                            if let facePosition {
                                stickerTile(facePosition.coordinate)
                            } else {
                                Color.clear
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.small)
            .background(AppTheme.Colors.background.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
        }
    }

    private func stickerTile(_ coordinate: StickerCoordinate) -> some View {
        let color = stickerAssignments[coordinate]?.displayColor ?? AppTheme.Colors.surface
        return Button {
            stickerAssignments[coordinate] = selectedColor
        } label: {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private enum Cube2x2StateBuilder {
    private static let cornerDefinitions: [CornerDefinition] = [
        .init(position: "URF", stickers: [.u11, .r00, .f01], solvedColors: [.white, .red, .green]),
        .init(position: "UFL", stickers: [.u10, .f00, .l01], solvedColors: [.white, .green, .orange]),
        .init(position: "ULB", stickers: [.u00, .l00, .b01], solvedColors: [.white, .orange, .blue]),
        .init(position: "UBR", stickers: [.u01, .b00, .r01], solvedColors: [.white, .blue, .red]),
        .init(position: "DFR", stickers: [.d01, .f11, .r10], solvedColors: [.yellow, .green, .red]),
        .init(position: "DLF", stickers: [.d00, .l11, .f10], solvedColors: [.yellow, .orange, .green]),
        .init(position: "DBL", stickers: [.d10, .b11, .l10], solvedColors: [.yellow, .blue, .orange]),
        .init(position: "DRB", stickers: [.d11, .r11, .b10], solvedColors: [.yellow, .red, .blue])
    ]

    static func makeState(from assignments: [StickerCoordinate: CubeStickerColor]) -> Result<Cube2x2State, String> {
        guard assignments.count == StickerCoordinate.allCases.count else {
            return .failure("Please fill in all 24 stickers.")
        }

        var permutation = Array(repeating: UInt8(0), count: 8)
        var orientation = Array(repeating: UInt8(0), count: 8)
        var usedCubies: Set<Int> = []

        for (positionIndex, definition) in cornerDefinitions.enumerated() {
            let colors = definition.stickers.compactMap { assignments[$0] }
            guard colors.count == 3 else {
                return .failure("Missing stickers around corner \(definition.position).")
            }

            let sortedObserved = colors.sorted(by: { $0.rawValue < $1.rawValue })

            guard let cubieIndex = cornerDefinitions.firstIndex(where: { $0.solvedColors.sorted(by: { $0.rawValue < $1.rawValue }) == sortedObserved }) else {
                return .failure("Corner \(definition.position) has an impossible color combination.")
            }

            if usedCubies.contains(cubieIndex) {
                return .failure("A corner cubie is duplicated. Please re-check sticker placement.")
            }
            usedCubies.insert(cubieIndex)

            let cubieUDColor = cornerDefinitions[cubieIndex].solvedColors[0]
            guard let udIndex = colors.firstIndex(of: cubieUDColor) else {
                return .failure("Corner orientation is invalid at \(definition.position).")
            }

            permutation[positionIndex] = UInt8(cubieIndex)
            orientation[positionIndex] = UInt8(udIndex)
        }

        let orientationSum = orientation.reduce(0, +)
        if orientationSum % 3 != 0 {
            return .failure("This cube orientation is invalid. Please review your sticker colors.")
        }

        if !isEvenPermutation(permutation.map(Int.init)) {
            return .failure("This corner permutation is not reachable on a physical 2×2 cube.")
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

private struct CornerDefinition {
    let position: String
    let stickers: [StickerCoordinate]
    let solvedColors: [CubeStickerColor]
}

private enum CubeStickerColor: String, CaseIterable {
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

    var displayColor: Color {
        switch self {
        case .white: return Color.white
        case .yellow: return Color.yellow
        case .red: return Color.red
        case .orange: return Color.orange
        case .blue: return Color.blue
        case .green: return Color.green
        }
    }
}

private enum FacePosition {
    case u00, u01, u10, u11
    case l00, l01, l10, l11
    case f00, f01, f10, f11
    case r00, r01, r10, r11
    case b00, b01, b10, b11
    case d00, d01, d10, d11

    var coordinate: StickerCoordinate {
        switch self {
        case .u00: return .u00
        case .u01: return .u01
        case .u10: return .u10
        case .u11: return .u11
        case .l00: return .l00
        case .l01: return .l01
        case .l10: return .l10
        case .l11: return .l11
        case .f00: return .f00
        case .f01: return .f01
        case .f10: return .f10
        case .f11: return .f11
        case .r00: return .r00
        case .r01: return .r01
        case .r10: return .r10
        case .r11: return .r11
        case .b00: return .b00
        case .b01: return .b01
        case .b10: return .b10
        case .b11: return .b11
        case .d00: return .d00
        case .d01: return .d01
        case .d10: return .d10
        case .d11: return .d11
        }
    }
}

private enum StickerCoordinate: CaseIterable, Hashable {
    case u00, u01, u10, u11
    case l00, l01, l10, l11
    case f00, f01, f10, f11
    case r00, r01, r10, r11
    case b00, b01, b10, b11
    case d00, d01, d10, d11
}

#Preview {
    NavigationStack {
        Cube2x2EntryView()
    }
}

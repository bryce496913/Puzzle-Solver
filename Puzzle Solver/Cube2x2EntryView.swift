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

    private var validationStatus: CubeEntryValidationStatus {
        let requiredStickerCount = StickerCoordinate.allCases.count
        let assigned = stickerAssignments.count
        if assigned < requiredStickerCount {
            return .incomplete("Fill all 24 stickers. Remaining: \(requiredStickerCount - assigned).")
        }

        for color in CubeStickerColor.allCases {
            let count = colorCounts[color, default: 0]
            if count != 4 {
                return .invalid("Each color must appear exactly 4 times. \(color.label) currently has \(count).")
            }
        }

        switch Cube2x2StateBuilder.makeState(from: stickerAssignments) {
        case .success:
            return .ready("Great! Your cube input looks valid. Tap Solve when you're ready.")
        case .failure:
            return .invalid("This sticker layout doesn’t form a valid 2×2 cube state yet. Double-check corner colors and try again.")
        }
    }

    private var isReadyToSolve: Bool {
        validationStatus.isReady
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
                            .padding(AppTheme.Spacing.small)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.Colors.highlight.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
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

            Text("1) Pick a color below. 2) Tap stickers on the cube net to paint them. 3) Enter what you see on your real cube, one sticker at a time.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.86))

            Text("Tip: each color must appear exactly 4 times in a complete 2×2 state.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.82))

            Text(validationStatus.message)
                .appTextStyle(.paragraph)
                .foregroundStyle(validationStatus.messageColor)

            colorCountSummary
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var colorCountSummary: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text("Color count check")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.86))

            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(CubeStickerColor.allCases, id: \.self) { color in
                    let count = colorCounts[color, default: 0]
                    let isExact = count == 4

                    HStack(spacing: 6) {
                        Circle()
                            .fill(color.displayColor)
                            .frame(width: 12, height: 12)

                        Text("\(count)/4")
                            .appTextStyle(.paragraph)
                            .foregroundStyle(isExact ? AppTheme.Colors.text : AppTheme.Colors.highlight)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(AppTheme.Colors.background.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                }
            }
        }
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
            inputError = "We couldn’t start solving from this input yet. Please check the highlighted validation notes and try again."
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

private enum CubeEntryValidationStatus {
    case incomplete(String)
    case invalid(String)
    case ready(String)

    var message: String {
        switch self {
        case .incomplete(let message), .invalid(let message), .ready(let message):
            return message
        }
    }

    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }

    var messageColor: Color {
        switch self {
        case .ready:
            return AppTheme.Colors.text
        case .incomplete, .invalid:
            return AppTheme.Colors.highlight
        }
    }
}

private struct CubeNetInputView: View {
    @Binding var stickerAssignments: [StickerCoordinate: CubeStickerColor]
    let selectedColor: CubeStickerColor

    private let netRows: [[String?]] = [
        [nil, "U", nil, nil],
        ["L", "F", "R", "B"],
        [nil, "D", nil, nil]
    ]

    private var faceModels: [String: TwistyFaceModel] {
        Dictionary(uniqueKeysWithValues: CubeFaceSlot.allCases.map { slot in
            let stickers = slot.coordinates.enumerated().map { index, coordinate in
                TwistyFaceSticker(
                    id: "\(slot.rawValue)-\(index)",
                    color: stickerAssignments[coordinate]?.displayColor ?? TwistyStickerPalette.standard.fallback
                )
            }
            return (
                slot.rawValue,
                TwistyFaceModel(
                    id: slot.rawValue,
                    title: slot.rawValue,
                    dimension: 2,
                    stickers: stickers
                )
            )
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Cube net")
                .appTextStyle(.h2)

            CubeNetView(layoutRows: netRows, facesByID: faceModels, stickerSize: 30) { faceID, sticker in
                guard let slot = CubeFaceSlot(rawValue: faceID),
                      let stickerIndex = Int(sticker.id.split(separator: "-").last ?? ""),
                      slot.coordinates.indices.contains(stickerIndex) else {
                    return
                }
                stickerAssignments[slot.coordinates[stickerIndex]] = selectedColor
            }
            .padding(AppTheme.Spacing.small)
            .background(AppTheme.Colors.background.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
        }
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
        case .white: return TwistyStickerPalette.standard.white
        case .yellow: return TwistyStickerPalette.standard.yellow
        case .red: return TwistyStickerPalette.standard.red
        case .orange: return TwistyStickerPalette.standard.orange
        case .blue: return TwistyStickerPalette.standard.blue
        case .green: return TwistyStickerPalette.standard.green
        }
    }
}

private enum CubeFaceSlot: String, CaseIterable {
    case u = "U"
    case l = "L"
    case f = "F"
    case r = "R"
    case b = "B"
    case d = "D"

    var coordinates: [StickerCoordinate] {
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

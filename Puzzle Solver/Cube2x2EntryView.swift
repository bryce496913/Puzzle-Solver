import SwiftUI

struct Cube2x2EntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedColor: Cube2x2StickerColor = .white
    @State private var stickerAssignments: [Cube2x2StickerCoordinate: Cube2x2StickerColor] = [:]
    @State private var inputError: String?
    @State private var solveState: Cube2x2State?
    @State private var shouldNavigateToSolve = false

    private var colorCounts: [Cube2x2StickerColor: Int] {
        Dictionary(grouping: stickerAssignments.values, by: { $0 }).mapValues(\.count)
    }

    private var validationStatus: CubeEntryValidationStatus {
        let requiredStickerCount = Cube2x2StickerCoordinate.allCases.count
        let assigned = stickerAssignments.count
        if assigned < requiredStickerCount {
            return .incomplete("Fill all 24 stickers. Remaining: \(requiredStickerCount - assigned).")
        }

        for color in Cube2x2StickerColor.allCases {
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
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "2×2 Cube Entry",
                subtitle: "Enter your sticker colors to build a valid cube state."
            )

            helperCard
                .appSurfaceCard()

            colorPickerRow
                .appSurfaceCard()

            CubeNetInputView(stickerAssignments: $stickerAssignments, selectedColor: selectedColor)
                .appSurfaceCard()

            if let inputError {
                TwistyInlineStatusMessage(message: inputError)
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
                ForEach(Cube2x2StickerColor.allCases, id: \.self) { color in
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
                ForEach(Cube2x2StickerColor.allCases, id: \.self) { color in
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
    @Binding var stickerAssignments: [Cube2x2StickerCoordinate: Cube2x2StickerColor]
    let selectedColor: Cube2x2StickerColor

    private let netRows: [[String?]] = [
        [nil, "U", nil, nil],
        ["L", "F", "R", "B"],
        [nil, "D", nil, nil]
    ]

    private var faceModels: [String: TwistyFaceModel] {
        Dictionary(uniqueKeysWithValues: Cube2x2FaceSlot.allCases.map { slot in
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
                guard let slot = Cube2x2FaceSlot(rawValue: faceID),
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

private extension Cube2x2StickerColor {
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

#Preview {
    NavigationStack {
        Cube2x2EntryView()
    }
}

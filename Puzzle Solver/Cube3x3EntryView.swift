import SwiftUI

struct Cube3x3EntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedColor: Cube3x3StickerColor = .up
    @State private var stickerAssignments: [Cube3x3StickerCoordinate: Cube3x3StickerColor] = Self.makeInitialAssignments()
    @State private var selectedSticker: Cube3x3StickerCoordinate?
    @State private var inputError: String?
    @State private var solveState: Cube3x3State?
    @State private var shouldNavigateToSolve = false

    private static func makeInitialAssignments() -> [Cube3x3StickerCoordinate: Cube3x3StickerColor] {
        var assignments: [Cube3x3StickerCoordinate: Cube3x3StickerColor] = [:]
        for face in Cube3x3FaceSlot.allCases {
            assignments[.init(face: face, index: 4)] = face.lockedCenterColor
        }
        return assignments
    }

    private var colorCounts: [Cube3x3StickerColor: Int] {
        Dictionary(grouping: stickerAssignments.values, by: { $0 }).mapValues(\.count)
    }

    private var validationStatus: TwistyEntryValidationStatus {
        let requiredStickerCount = Cube3x3StickerCoordinate.all.count
        let assigned = stickerAssignments.count
        if assigned < requiredStickerCount {
            return .incomplete("Fill all 54 stickers. Remaining: \(requiredStickerCount - assigned).")
        }

        for color in Cube3x3StickerColor.allCases {
            let count = colorCounts[color, default: 0]
            if count != 9 {
                return .invalid("Each color must appear exactly 9 times. \(color.label) currently has \(count).")
            }
        }

        switch Cube3x3StateBuilder.makeState(from: stickerAssignments) {
        case .success:
            return .ready("Great! Your cube input looks valid. Tap Solve when you're ready.")
        case .failure(let error):
            return .invalid(friendlyValidationMessage(for: error))
        }
    }

    private var isReadyToSolve: Bool {
        validationStatus.isReady
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "3×3 Cube Entry",
                subtitle: "Enter your sticker colors to build a valid cube state."
            )

            helperCard
                .appSurfaceCard()

            colorPickerRow
                .appSurfaceCard()

            Cube3x3NetInputView(
                stickerAssignments: $stickerAssignments,
                selectedSticker: $selectedSticker,
                selectedColor: selectedColor
            )
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
        .navigationTitle("3×3 Cube")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToSolve) {
            if let solveState {
                Cube3x3SolvingView(initialState: solveState)
            }
        }
    }

    private var helperCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("How to enter your cube")
                .appTextStyle(.h2)

            Text("1) Pick a color below. 2) Tap stickers on the cube net to paint them. 3) Enter exactly what you see on your real cube.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.86))

            Text("Center stickers are fixed to standard faces (U/R/F/D/L/B) and are locked.")
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

            TwistyColorCountRow(
                items: Cube3x3StickerColor.allCases.map { color in
                    TwistyColorCountItem(
                        id: color.rawValue,
                        color: color.displayColor,
                        count: colorCounts[color, default: 0],
                        target: 9
                    )
                }
            )
        }
    }

    private var colorPickerRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Selected color")
                .appTextStyle(.h2)

            TwistyColorPickerRow(
                options: Cube3x3StickerColor.allCases.map { color in
                    TwistyColorOption(id: color.rawValue, label: color.shortLabel, color: color.displayColor)
                },
                selectedColorID: selectedColor.rawValue,
                onSelect: { selectedID in
                    if let color = Cube3x3StickerColor(rawValue: selectedID) {
                        selectedColor = color
                    }
                }
            )
        }
    }

    private func startSolveFlow() {
        inputError = nil

        let stateResult = Cube3x3StateBuilder.makeState(from: stickerAssignments)
        guard case .success(let cubeState) = stateResult else {
            if case .failure(let error) = stateResult {
                inputError = friendlyValidationMessage(for: error)
            } else {
                inputError = "Please check your cube input and try again."
            }
            return
        }

        solveState = cubeState
        shouldNavigateToSolve = true
    }

    private func resetEntry() {
        stickerAssignments = Self.makeInitialAssignments()
        inputError = nil
        selectedColor = .up
        selectedSticker = nil
        solveState = nil
        shouldNavigateToSolve = false
    }

    private func friendlyValidationMessage(for error: Cube3x3StateBuildError) -> String {
        let raw = error.message.lowercased()

        if raw.contains("fill in all 54 stickers") || raw.contains("missing stickers") {
            return "Please fill every sticker before solving."
        }
        if raw.contains("impossible color combination") || raw.contains("duplicated") {
            return "Some pieces don’t match a real 3×3 cube. Recheck nearby stickers."
        }
        if raw.contains("parity") || raw.contains("orientation") || raw.contains("permutation") || raw.contains("invalid cube state") {
            return "This sticker layout can’t be solved as entered. Please verify each face."
        }

        return "We couldn’t use this cube input yet. Please review and try again."
    }
}




private struct Cube3x3NetInputView: View {
    @Binding var stickerAssignments: [Cube3x3StickerCoordinate: Cube3x3StickerColor]
    @Binding var selectedSticker: Cube3x3StickerCoordinate?
    let selectedColor: Cube3x3StickerColor

    private let stickerSize: CGFloat = 22

    private var stickersByFace: [Cube3x3FaceSlot: [Cube3x3StickerColor]] {
        Dictionary(uniqueKeysWithValues: Cube3x3FaceSlot.allCases.map { slot in
            let stickers = (0..<9).map { index in
                let coordinate = Cube3x3StickerCoordinate(face: slot, index: index)
                return stickerAssignments[coordinate] ?? slot.lockedCenterColor
            }
            return (slot, stickers)
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Cube net")
                .appTextStyle(.h2)

            Cube3x3NetView(
                stickersByFace: stickersByFace,
                selectedSticker: selectedSticker,
                stickerSize: stickerSize,
                isReadOnly: false
            ) { coordinate in
                handleTap(on: coordinate)
            }
        }
    }

    private func handleTap(on coordinate: Cube3x3StickerCoordinate) {
        guard !coordinate.isCenter else {
            return
        }

        stickerAssignments[coordinate] = selectedColor
        selectedSticker = coordinate
    }
}

#Preview {
    NavigationStack {
        Cube3x3EntryView()
    }
}

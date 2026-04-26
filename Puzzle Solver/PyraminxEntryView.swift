import SwiftUI

struct PyraminxEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedColor: PyraminxStickerColor = .up
    @State private var stickerAssignments: [Int: PyraminxStickerColor] = [:]
    @State private var selectedStickerID: Int?
    @State private var inputError: String?
    @State private var solveState: PyraminxState?
    @State private var shouldNavigateToSolve = false

    private let faces: [PyraminxFaceDefinition] = [
        .init(id: "U", title: "Up", stickerRange: 0..<9),
        .init(id: "L", title: "Left", stickerRange: 9..<18),
        .init(id: "R", title: "Right", stickerRange: 18..<27),
        .init(id: "B", title: "Back", stickerRange: 27..<36)
    ]

    private var colorCounts: [PyraminxStickerColor: Int] {
        Dictionary(grouping: stickerAssignments.values, by: { $0 }).mapValues(\.count)
    }

    private var validationStatus: TwistyEntryValidationStatus {
        if let overflow = PyraminxStickerColor.allCases.first(where: { colorCounts[$0, default: 0] > 9 }) {
            return .invalid("Too many \(overflow.label) stickers. Max is 9.")
        }

        let requiredStickerCount = 36
        if stickerAssignments.count < requiredStickerCount {
            return .incomplete("Fill all 36 stickers. Remaining: \(requiredStickerCount - stickerAssignments.count).")
        }

        for color in PyraminxStickerColor.allCases {
            let count = colorCounts[color, default: 0]
            if count != 9 {
                return .invalid("Each color must appear exactly 9 times. \(color.label) currently has \(count).")
            }
        }

        return .ready("Great! Your Pyraminx input looks valid. Tap Solve when you're ready.")
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Pyraminx Entry",
                subtitle: "Tap triangles to paint each sticker from your real puzzle."
            )

            helperCard
                .appSurfaceCard()

            colorPicker
                .appSurfaceCard()

            faceInputGrid
                .appSurfaceCard()

            if let inputError {
                TwistyInlineStatusMessage(message: inputError)
            }

            Button("Solve") {
                startSolveFlow()
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(!validationStatus.isReady)
            .opacity(validationStatus.isReady ? 1 : 0.5)

            HStack(spacing: AppTheme.Spacing.medium) {
                Button("Back") { dismiss() }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))

                Button("Reset") { resetEntry() }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Pyraminx")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToSolve) {
            if let solveState {
                PyraminxResultView(initialState: solveState)
            }
        }
    }

    private var helperCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("How to enter your Pyraminx")
                .appTextStyle(.h2)

            Text("1) Pick a color. 2) Tap triangular stickers to paint them. 3) Match exactly what you see on your puzzle.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))

            Text(validationStatus.message)
                .appTextStyle(.paragraph)
                .foregroundStyle(validationStatus.messageColor)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("Color count check")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.86))

                TwistyColorCountRow(
                    items: PyraminxStickerColor.allCases.map { color in
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Selected color")
                .appTextStyle(.h2)

            TwistyColorPickerRow(
                options: PyraminxStickerColor.allCases.map { color in
                    TwistyColorOption(id: color.rawValue, label: color.shortLabel, color: color.displayColor)
                },
                selectedColorID: selectedColor.rawValue,
                onSelect: { selectedID in
                    if let color = PyraminxStickerColor(rawValue: selectedID) {
                        selectedColor = color
                    }
                }
            )
        }
    }

    private var faceInputGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Pyraminx faces")
                .appTextStyle(.h2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.small) {
                ForEach(faces) { face in
                    PyraminxFaceInputView(
                        face: face,
                        stickerAssignments: $stickerAssignments,
                        selectedStickerID: $selectedStickerID,
                        selectedColor: selectedColor
                    )
                }
            }
        }
    }

    private func startSolveFlow() {
        inputError = nil
        guard validationStatus.isReady else {
            inputError = validationStatus.message
            return
        }

        let stickers = (0..<36).compactMap { stickerAssignments[$0] }
        guard stickers.count == 36 else {
            inputError = "Please fill every sticker before solving."
            return
        }

        solveState = PyraminxState(stickers: stickers)
        shouldNavigateToSolve = true
    }

    private func resetEntry() {
        stickerAssignments = [:]
        selectedStickerID = nil
        selectedColor = .up
        inputError = nil
        solveState = nil
        shouldNavigateToSolve = false
    }
}

struct PyraminxResultView: View {
    let initialState: PyraminxState

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?
    @State private var currentStepIndex = 0
    @State private var isAutoPlaying = false
    @State private var autoPlayTask: Task<Void, Never>?

    private var stepViewData: [TwistySolutionStepViewData] {
        solveResult?.makeStepViewData() ?? []
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Pyraminx Results",
                subtitle: "Review your solution output and ordered moves."
            )

            if isSolving {
                loadingCard
            } else if let result = solveResult {
                if !result.stateValidation.isValid {
                    invalidStateCard(result: result)
                } else {
                    TwistySolveSummaryCard(result: result, showChipMetrics: true)

                    if result.isSolvable {
                        TwistyNumberedMoveListView(title: "Ordered move list", moves: result.moves)
                    } else {
                        unsolvedCard(result: result)
                    }

                    if !stepViewData.isEmpty {
                        TwistySolutionPlaybackView(
                            step: stepViewData[currentStepIndex],
                            totalSteps: stepViewData.count,
                            isAutoPlaying: isAutoPlaying,
                            onPrevious: moveToPreviousStep,
                            onNext: moveToNextStep,
                            onToggleAutoPlay: toggleAutoPlay
                        )
                    }
                }
            }
        }
        .task {
            await solvePyraminx()
        }
        .onDisappear {
            stopAutoPlay()
        }
        .navigationTitle("Pyraminx Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var loadingCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            ProgressView()
                .tint(AppTheme.Colors.highlight)

            Text("Solving your Pyraminx…")
                .appTextStyle(.h2)

            Text("Calculating move sequence and formatting step cards.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private func invalidStateCard(result: TwistySolveResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Invalid state")
                .appTextStyle(.h2)
                .foregroundStyle(AppTheme.Colors.highlight)

            Text(result.stateValidation.summaryText)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private func unsolvedCard(result: TwistySolveResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("No solution found")
                .appTextStyle(.h2)
                .foregroundStyle(AppTheme.Colors.highlight)

            Text(result.steps.first?.explanation ?? "Try re-entering your state.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private func moveToPreviousStep() {
        stopAutoPlay()
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    private func moveToNextStep() {
        guard !stepViewData.isEmpty else { return }

        if currentStepIndex < stepViewData.count - 1 {
            currentStepIndex += 1
        } else {
            stopAutoPlay()
        }
    }

    private func toggleAutoPlay() {
        if isAutoPlaying {
            stopAutoPlay()
        } else {
            startAutoPlay()
        }
    }

    private func startAutoPlay() {
        guard stepViewData.count > 1 else { return }

        if currentStepIndex >= stepViewData.count - 1 {
            currentStepIndex = 0
        }

        stopAutoPlay()
        isAutoPlaying = true

        autoPlayTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.1))

                if Task.isCancelled {
                    return
                }

                await MainActor.run {
                    if currentStepIndex < stepViewData.count - 1 {
                        currentStepIndex += 1
                    } else {
                        stopAutoPlay()
                    }
                }
            }
        }
    }

    private func stopAutoPlay() {
        isAutoPlaying = false
        autoPlayTask?.cancel()
        autoPlayTask = nil
    }

    @MainActor
    private func solvePyraminx() async {
        isSolving = true
        stopAutoPlay()
        let result = await Task.detached(priority: .userInitiated) {
            await PyraminxSolver().solve(from: initialState)
        }.value

        solveResult = result
        currentStepIndex = 0
        isSolving = false
    }
}

private struct PyraminxFaceDefinition: Identifiable {
    let id: String
    let title: String
    let stickerRange: Range<Int>
}

private struct PyraminxFaceInputView: View {
    let face: PyraminxFaceDefinition
    @Binding var stickerAssignments: [Int: PyraminxStickerColor]
    @Binding var selectedStickerID: Int?
    let selectedColor: PyraminxStickerColor

    private let rows: [[Int]] = [
        [0],
        [1, 2],
        [3, 4, 5],
        [6, 7, 8]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(face.title)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.8))

            VStack(spacing: AppTheme.Spacing.xSmall) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: AppTheme.Spacing.xSmall) {
                        Spacer(minLength: CGFloat(rows.count - rowIndex - 1) * 10)

                        ForEach(rows[rowIndex], id: \.self) { localIndex in
                            let stickerID = face.stickerRange.lowerBound + localIndex
                            PyraminxTriangleStickerView(
                                color: stickerAssignments[stickerID]?.displayColor ?? AppTheme.Colors.background.opacity(0.55),
                                isSelected: selectedStickerID == stickerID,
                                onTap: {
                                    stickerAssignments[stickerID] = selectedColor
                                    selectedStickerID = stickerID
                                }
                            )
                        }

                        Spacer()
                    }
                }
            }
            .padding(AppTheme.Spacing.small)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.background.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
        }
    }
}

private struct PyraminxTriangleStickerView: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        TriangleShape()
            .fill(color)
            .frame(width: 28, height: 24)
            .overlay {
                TriangleShape()
                    .stroke(isSelected ? AppTheme.Colors.highlight : Color.white.opacity(0.75), lineWidth: isSelected ? 2.3 : 1)
            }
            .contentShape(TriangleShape())
            .onTapGesture(perform: onTap)
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private extension PyraminxStickerColor {
    var label: String {
        switch self {
        case .up: return "Up"
        case .left: return "Left"
        case .right: return "Right"
        case .back: return "Back"
        }
    }

    var shortLabel: String { rawValue }

    var displayColor: Color {
        switch self {
        case .up: return TwistyStickerPalette.standard.yellow
        case .left: return TwistyStickerPalette.standard.green
        case .right: return TwistyStickerPalette.standard.red
        case .back: return TwistyStickerPalette.standard.blue
        }
    }
}

#Preview {
    NavigationStack {
        PyraminxEntryView()
    }
}

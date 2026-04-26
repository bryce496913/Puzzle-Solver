import SwiftUI

struct TwistyPuzzlePickerView: View {
    private let twistyPuzzleTypes = TwistyPuzzleType.catalog

    private var activePuzzles: [TwistyPuzzleCatalogItem] {
        twistyPuzzleTypes.filter(\.isEnabled)
    }

    private var comingSoonPuzzles: [TwistyPuzzleCatalogItem] {
        twistyPuzzleTypes.filter { !$0.isEnabled }
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Twisty Puzzles",
                subtitle: "Choose a twisty puzzle type"
            )

            if !activePuzzles.isEmpty {
                sectionTitle("Available now")
                ForEach(activePuzzles) { catalogItem in
                    NavigationLink {
                        destinationView(for: catalogItem.puzzleType)
                    } label: {
                        PuzzleTypeCard(
                            title: catalogItem.title,
                            subtitle: catalogItem.subtitle,
                            icon: catalogItem.icon,
                            isEnabled: true,
                            accentVariant: .accent
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if !comingSoonPuzzles.isEmpty {
                sectionTitle("Coming soon")
                ForEach(comingSoonPuzzles) { catalogItem in
                    NavigationLink {
                        destinationView(for: catalogItem.puzzleType)
                    } label: {
                        PuzzleTypeCard(
                            title: catalogItem.title,
                            subtitle: catalogItem.subtitle,
                            icon: catalogItem.icon,
                            isEnabled: false,
                            accentVariant: .highlight
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Twisty Puzzles")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appTextStyle(.paragraph)
            .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func destinationView(for puzzleType: TwistyPuzzleType) -> some View {
        switch puzzleType {
        case .cube2x2:
            Cube2x2EntryView()
        case .cube3x3:
            Cube3x3EntryView()
        case .pyraminx:
            PyraminxEntryView()
        case .skewb:
            SkewbEntryView()
        }
    }
}

struct SkewbEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedColor: SkewbStickerColor = .up
    @State private var stickerAssignments: [Int: SkewbStickerColor] = [:]
    @State private var inputError: String?
    @State private var solveState: SkewbState?
    @State private var shouldNavigateToSolve = false

    private let faceLayouts: [(id: String, title: String, start: Int)] = [
        ("U", "Up", 0),
        ("L", "Left", 5),
        ("F", "Front", 10),
        ("R", "Right", 15),
        ("B", "Back", 20),
        ("D", "Down", 25)
    ]

    private var colorCounts: [SkewbStickerColor: Int] {
        Dictionary(grouping: stickerAssignments.values, by: { $0 }).mapValues(\.count)
    }

    private var validationStatus: TwistyEntryValidationStatus {
        if let overflow = SkewbStickerColor.allCases.first(where: { colorCounts[$0, default: 0] > 5 }) {
            return .invalid("Too many \(overflow.label) stickers. Max is 5.")
        }

        let requiredStickerCount = 30
        if stickerAssignments.count < requiredStickerCount {
            return .incomplete("Fill all 30 stickers. Remaining: \(requiredStickerCount - stickerAssignments.count).")
        }

        for color in SkewbStickerColor.allCases {
            let count = colorCounts[color, default: 0]
            if count != 5 {
                return .invalid("Each color must appear exactly 5 times. \(color.label) currently has \(count).")
            }
        }

        return .ready("Great! Your Skewb input looks valid. Tap Solve when you're ready.")
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Skewb Entry",
                subtitle: "Paint each sticker from your Skewb using a cube-net layout."
            )

            skewbEntryHelpCard
                .appSurfaceCard()

            skewbColorPicker
                .appSurfaceCard()

            SkewbNetInputView(stickerAssignments: $stickerAssignments, selectedColor: selectedColor, faceLayouts: faceLayouts)
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
        .navigationTitle("Skewb")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToSolve) {
            if let solveState {
                SkewbResultView(initialState: solveState)
            }
        }
    }

    private var skewbEntryHelpCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("How to enter your Skewb")
                .appTextStyle(.h2)

            Text("1) Pick a color. 2) Tap stickers in the net below. 3) Match your real Skewb exactly as seen.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))

            Text(validationStatus.message)
                .appTextStyle(.paragraph)
                .foregroundStyle(validationStatus.messageColor)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text("Color count check")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.86))

                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(SkewbStickerColor.allCases, id: \.self) { color in
                        let count = colorCounts[color, default: 0]
                        HStack(spacing: 6) {
                            Circle()
                                .fill(color.displayColor)
                                .frame(width: 12, height: 12)
                            Text("\(count)/5")
                                .appTextStyle(.paragraph)
                                .foregroundStyle(count == 5 ? AppTheme.Colors.text : AppTheme.Colors.highlight)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(AppTheme.Colors.background.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var skewbColorPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Selected color")
                .appTextStyle(.h2)

            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(SkewbStickerColor.allCases, id: \.self) { color in
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
        guard validationStatus.isReady else {
            inputError = validationStatus.message
            return
        }

        let stickers = (0..<30).compactMap { stickerAssignments[$0] }
        guard stickers.count == 30 else {
            inputError = "Please fill every sticker before solving."
            return
        }

        solveState = SkewbState(stickers: stickers)
        shouldNavigateToSolve = true
    }

    private func resetEntry() {
        selectedColor = .up
        stickerAssignments = [:]
        inputError = nil
        solveState = nil
        shouldNavigateToSolve = false
    }
}

struct SkewbResultView: View {
    let initialState: SkewbState

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
                title: "Skewb Results",
                subtitle: "Review solve status, move count, and ordered steps."
            )

            if isSolving {
                skewbLoadingCard
            } else if let result = solveResult {
                if !result.stateValidation.isValid {
                    invalidStateCard(result: result)
                } else {
                    TwistySolveSummaryCard(result: result, showChipMetrics: true)
                    TwistyNumberedMoveListView(title: "Ordered move list", moves: result.moves)

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
            await solveSkewb()
        }
        .onDisappear {
            stopAutoPlay()
        }
        .navigationTitle("Skewb Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var skewbLoadingCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            ProgressView()
                .tint(AppTheme.Colors.highlight)

            Text("Solving your Skewb…")
                .appTextStyle(.h2)

            Text("Calculating move count and generating an ordered move list.")
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
    private func solveSkewb() async {
        isSolving = true
        stopAutoPlay()
        let result = await Task.detached(priority: .userInitiated) {
            await SkewbSolver().solve(from: initialState)
        }.value
        solveResult = result
        currentStepIndex = 0
        isSolving = false
    }
}

private struct SkewbNetInputView: View {
    @Binding var stickerAssignments: [Int: SkewbStickerColor]
    let selectedColor: SkewbStickerColor
    let faceLayouts: [(id: String, title: String, start: Int)]

    private let netRows: [[String?]] = [
        [nil, "U", nil, nil],
        ["L", "F", "R", "B"],
        [nil, "D", nil, nil]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Skewb net")
                .appTextStyle(.h2)

            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(Array(netRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: AppTheme.Spacing.small) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            if let faceID = cell,
                               let face = faceLayouts.first(where: { $0.id == faceID }) {
                                SkewbFaceInputView(
                                    title: face.title,
                                    stickerColors: (0..<5).map { stickerAssignments[face.start + $0]?.displayColor ?? TwistyStickerPalette.standard.fallback },
                                    onStickerTap: { localIndex in
                                        stickerAssignments[face.start + localIndex] = selectedColor
                                    }
                                )
                            } else {
                                Color.clear
                                    .frame(width: 80, height: 102)
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
}

private struct SkewbFaceInputView: View {
    let title: String
    let stickerColors: [Color]
    let onStickerTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(title)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.8))

            VStack(spacing: AppTheme.Spacing.xSmall) {
                stickerButton(index: 0)
                    .padding(.leading, 20)

                HStack(spacing: AppTheme.Spacing.xSmall) {
                    stickerButton(index: 1)
                    stickerButton(index: 2)
                    stickerButton(index: 3)
                }

                stickerButton(index: 4)
                    .padding(.leading, 20)
            }
            .padding(AppTheme.Spacing.xSmall)
            .background(AppTheme.Colors.background.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
        }
        .frame(width: 80)
    }

    private func stickerButton(index: Int) -> some View {
        CubeStickerView(
            color: stickerColors.indices.contains(index) ? stickerColors[index] : TwistyStickerPalette.standard.fallback,
            size: 18,
            isReadOnly: false,
            onTap: { onStickerTap(index) }
        )
    }
}

private extension SkewbStickerColor {
    var label: String {
        switch self {
        case .up: return "Up"
        case .left: return "Left"
        case .front: return "Front"
        case .right: return "Right"
        case .back: return "Back"
        case .down: return "Down"
        }
    }

    var shortLabel: String {
        rawValue
    }

    var displayColor: Color {
        switch self {
        case .up: return TwistyStickerPalette.standard.white
        case .left: return TwistyStickerPalette.standard.orange
        case .front: return TwistyStickerPalette.standard.green
        case .right: return TwistyStickerPalette.standard.red
        case .back: return TwistyStickerPalette.standard.blue
        case .down: return TwistyStickerPalette.standard.yellow
        }
    }
}

private struct TwistySimpleTokenEntryView<State: TwistyPuzzleState>: View {
    @Environment(\.dismiss) private var dismiss

    let puzzleType: TwistyPuzzleType
    let subtitle: String
    let helperText: String
    let makeState: ([String]) -> State

    @State private var tokenInput = ""
    @State private var solveState: State?
    @State private var shouldNavigateToSolve = false

    private var tokens: [String] {
        tokenInput
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private var validation: TwistyEntryValidationStatus {
        if tokens.isEmpty {
            return .incomplete("Enter at least one move token to continue.")
        }
        return .ready("Looks good. \(tokens.count) token\(tokens.count == 1 ? "" : "s") detected.")
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "\(puzzleType.metadata.shortTitle) Entry",
                subtitle: subtitle
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("How to enter")
                    .appTextStyle(.h2)
                Text(helperText)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.86))
                Text(validation.message)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(validation.messageColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurfaceCard()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Move tokens")
                    .appTextStyle(.h2)

                TextEditor(text: $tokenInput)
                    .frame(minHeight: 120)
                    .padding(AppTheme.Spacing.xSmall)
                    .background(AppTheme.Colors.background.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))

                Text("Detected: \(tokens.joined(separator: " "))")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurfaceCard()

            Button("Solve") {
                solveState = makeState(tokens)
                shouldNavigateToSolve = true
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(!validation.isReady)
            .opacity(validation.isReady ? 1 : 0.5)

            HStack(spacing: AppTheme.Spacing.medium) {
                Button("Back") { dismiss() }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))

                Button("Reset") { tokenInput = "" }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(puzzleType.metadata.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToSolve) {
            if let solveState {
                TwistySimpleSolveView(initialState: solveState)
            }
        }
    }
}

private struct TwistySimpleSolveView<State: TwistyPuzzleState>: View {
    let initialState: State

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "\(initialState.puzzleType.metadata.shortTitle) Solution",
                subtitle: "Review solving output for your entered tokens."
            )

            if isSolving {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    ProgressView()
                        .tint(AppTheme.Colors.highlight)
                    Text("Solving \(initialState.puzzleType.metadata.shortTitle)…")
                        .appTextStyle(.h2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appSurfaceCard()
            } else if let solveResult {
                TwistySolveSummaryCard(result: solveResult)
                TwistyNumberedMoveListView(title: "Ordered move list", moves: solveResult.moves)

                ForEach(solveResult.makeStepViewData()) { step in
                    TwistyStepCardView(step: step)
                }
            }
        }
        .task {
            await solve()
        }
        .navigationTitle("\(initialState.puzzleType.metadata.shortTitle) Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func solve() async {
        let result: TwistySolveResult

        switch initialState.puzzleType {
        case .pyraminx:
            guard let state = initialState as? PyraminxState else { return }
            result = await Task.detached(priority: .userInitiated) {
                await PyraminxSolver().solve(from: state)
            }.value
        case .skewb:
            guard let state = initialState as? SkewbState else { return }
            result = await Task.detached(priority: .userInitiated) {
                await SkewbSolver().solve(from: state)
            }.value
        case .cube2x2, .cube3x3:
            return
        }

        solveResult = result
        isSolving = false
    }
}

#Preview {
    NavigationStack {
        TwistyPuzzlePickerView()
    }
}

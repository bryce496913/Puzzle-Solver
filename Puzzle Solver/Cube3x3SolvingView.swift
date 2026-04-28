import SwiftUI

struct Cube3x3SolvingView: View {
    let initialState: Cube3x3State

    @State private var loadState: Cube3x3SolveLoadState = .idle
    @State private var currentStepIndex = 0
    @State private var showsStepCards = false
    @State private var isAutoPlaying = false
    @State private var autoPlayTask: Task<Void, Never>?

    private let notationRenderer = StandardTwistyNotationRenderer()
    private let solveTimeoutSeconds: TimeInterval = 12

    private var stepViewData: [TwistySolutionStepViewData] {
        currentResult?.makeStepViewData(renderer: notationRenderer) ?? []
    }

    private var playbackMoves: [TwistyMove] {
        guard let result = currentResult, result.isSolvable else { return [] }
        return result.moves
    }
    
    private var currentResult: TwistySolveResult? {
        if case .solved(let result) = loadState {
            return result
        }
        return nil
    }

    private var stepPreviewNets: [Cube3x3StickerNet] {
        guard !playbackMoves.isEmpty else { return [] }

        var state = initialState
        var previews: [Cube3x3StickerNet] = []

        for token in playbackMoves.map(\.token) {
            if let move = Cube3x3Move(rawValue: token) {
                state = state.applying(move)
            }
            previews.append(state.makeStickerNet())
        }

        return previews
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "3×3 Cube Solution",
                subtitle: "Review the move list and step-by-step walkthrough."
            )

            if isSolvingState {
                solvingStateCard
            } else if case .invalid(let message) = loadState {
                unsolvableCard(message: message)
            } else if case .failed(let message) = loadState {
                unsolvableCard(message: message)
            } else if case .timedOut(let message) = loadState {
                unsolvableCard(message: message)
            } else if let solveResult = currentResult {
                TwistySolveSummaryCard(result: solveResult, showChipMetrics: true, elapsedFormatter: elapsedText)

                if solveResult.isSolvable {
                    TwistyNumberedMoveListView(title: "Ordered move list", moves: solveResult.moves)

                    if !playbackMoves.isEmpty {
                        stepPreviewsSection
                    }
                } else {
                    unsolvableCard(message: friendlyFailureMessage(from: solveResult))
                }
            }
        }
        .task {
            await solveCube()
        }
        .onDisappear {
            stopAutoPlay()
        }
        .navigationTitle("3×3 Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var solvingStateCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            ProgressView()
                .tint(AppTheme.Colors.highlight)

            Text("Solving your 3×3 cube…")
                .appTextStyle(.h2)

            Text("Finding a valid move sequence and preparing an ordered step-by-step result.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.82))

            Text("Only the final successful sequence is shown.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }


    @ViewBuilder
    private func unsolvableCard(message: String?) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("We couldn’t solve this cube.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.highlight)

            if let message, !message.isEmpty {
                Text(message)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.9))
            }

            Text("Please go back, check each face, and try again.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private var stepPreviewsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Toggle(isOn: $showsStepCards.animation(.easeInOut(duration: 0.2))) {
                Text("Step previews")
                    .appTextStyle(.h2)
            }
            .tint(AppTheme.Colors.highlight)

            if showsStepCards {
                let currentStep = stepViewData[safe: currentStepIndex] ?? TwistySolutionStepViewData(
                        id: UUID(),
                        stepNumber: currentStepIndex + 1,
                        primaryText: playbackMoves[safe: currentStepIndex]?.token ?? "—",
                        secondaryText: nil
                    )

                TwistySolutionPlaybackView(
                    step: currentStep,
                    totalSteps: playbackMoves.count,
                    isAutoPlaying: isAutoPlaying,
                    onPrevious: moveToPreviousStep,
                    onNext: moveToNextStep,
                    onToggleAutoPlay: toggleAutoPlay,
                    previewCaption: "Cube state after this move"
                ) {
                    if let previewNet = stepPreviewNets[safe: currentStepIndex] {
                        Cube3x3NetView(
                            stickersByFace: [
                                .u: previewNet.up,
                                .r: previewNet.right,
                                .f: previewNet.front,
                                .d: previewNet.down,
                                .l: previewNet.left,
                                .b: previewNet.back
                            ],
                            stickerSize: 14,
                            isReadOnly: true
                        )
                    } else {
                        playbackPreviewUnavailable
                    }
                }
            } else {
                Text("Turn on previews to step through the sequence one move at a time.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
                    .padding(AppTheme.Spacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.background.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private var playbackPreviewUnavailable: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: "cube.transparent")
                .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
            Text("Step playback preview not available.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
        }
        .padding(AppTheme.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.background.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
    }


    private func elapsedText(for elapsedTime: TimeInterval) -> String {
        if elapsedTime < 0.1 {
            return "<0.1s"
        }
        return String(format: "%.1fs", elapsedTime)
    }

    private func moveToPreviousStep() {
        stopAutoPlay()
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    private func moveToNextStep() {
        guard !playbackMoves.isEmpty else { return }

        if currentStepIndex < playbackMoves.count - 1 {
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
        guard playbackMoves.count > 1 else { return }

        if currentStepIndex >= playbackMoves.count - 1 {
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
                    if currentStepIndex < playbackMoves.count - 1 {
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
    private func solveCube() async {
        print("[Cube3x3][UI] Solving screen appeared. Starting solve flow.")
        loadState = .solving
        stopAutoPlay()
        currentStepIndex = 0
        showsStepCards = false

        let result = await solveWithTimeout(initialState: initialState, timeoutSeconds: solveTimeoutSeconds)

        if Task.isCancelled {
            let message = "Solving was interrupted. Please try again."
            print("[Cube3x3][UI] Solver failure: \(message)")
            loadState = .failed(message)
            return
        }

        guard result.puzzleType == .cube3x3 else {
            let message = "Something went wrong while solving. Please try again."
            print("[Cube3x3][UI] Solver failure: unexpected puzzle result type.")
            loadState = .failed(message)
            return
        }

        if case .invalid(let reason) = result.stateValidation {
            let message = "This cube entry is invalid: \(reason)"
            print("[Cube3x3][UI] Solver failure: invalid input surfaced by solver.")
            loadState = .invalid(message)
            return
        }

        if result.steps.first?.explanation.lowercased().contains("timed out") == true {
            let message = "This cube could not be solved quickly. Please check the entered colors and try again."
            print("[Cube3x3][UI] Solver timeout reached.")
            loadState = .timedOut(message)
            return
        }

        if !result.isSolvable {
            let message = friendlyFailureMessage(from: result)
            print("[Cube3x3][UI] Solver reported unsolved result: \(message)")
            loadState = .failed(message)
            return
        }

        print("[Cube3x3][UI] Solver finished successfully. Updating UI result state.")
        loadState = .solved(result)
        currentStepIndex = 0
        showsStepCards = !result.moves.isEmpty
    }

    private func solveWithTimeout(initialState: Cube3x3State, timeoutSeconds: TimeInterval) async -> TwistySolveResult {
        await withTaskGroup(of: TwistySolveResult.self) { group in
            group.addTask(priority: .userInitiated) {
                print("[Cube3x3][UI] Dispatching solver off main thread.")
                return await Cube3x3Solver().solve(from: initialState)
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutSeconds))
                print("[Cube3x3][UI] Timeout task fired after \(Int(timeoutSeconds))s.")
                return TwistySolveResult(
                    puzzleType: .cube3x3,
                    stateValidation: .valid,
                    isSolvable: false,
                    moves: [],
                    steps: [TwistySolutionStep(move: nil, explanation: "Solver timed out while searching for a solution.")],
                    elapsedTime: timeoutSeconds,
                    finalStateDescription: nil
                )
            }

            let first = await group.next() ?? TwistySolveResult(
                puzzleType: .cube3x3,
                stateValidation: .invalid(reason: "Solver failed to produce a result."),
                isSolvable: false,
                moves: [],
                steps: [TwistySolutionStep(move: nil, explanation: "Internal solver failure.")],
                elapsedTime: nil,
                finalStateDescription: nil
            )
            group.cancelAll()
            return first
        }
    }

    private func friendlyFailureMessage(from result: TwistySolveResult) -> String {
        if let detail = result.steps.first?.explanation.lowercased() {
            if detail.contains("invalid") || detail.contains("parity") || detail.contains("orientation") || detail.contains("permutation") {
                return "This cube entry doesn’t describe a valid 3×3 state."
            }
            if detail.contains("search limit") || detail.contains("no solution") {
                return "We couldn’t finish solving this entry. Please check your stickers and retry."
            }
        }

        return "Please verify your sticker input and try again."
    }

    private var isSolvingState: Bool {
        if case .solving = loadState { return true }
        return false
    }
}

private enum Cube3x3SolveLoadState {
    case idle
    case solving
    case solved(TwistySolveResult)
    case invalid(String)
    case failed(String)
    case timedOut(String)
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#Preview {
    NavigationStack {
        Cube3x3SolvingView(initialState: .solved)
    }
}

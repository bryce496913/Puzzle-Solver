import SwiftUI

struct Cube3x3SolvingView: View {
    let initialState: Cube3x3State

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?
    @State private var solveFailureMessage: String?
    @State private var currentStepIndex = 0
    @State private var showsStepCards = false
    @State private var isAutoPlaying = false
    @State private var autoPlayTask: Task<Void, Never>?

    private let notationRenderer = StandardTwistyNotationRenderer()

    private var stepViewData: [TwistySolutionStepViewData] {
        solveResult?.makeStepViewData(renderer: notationRenderer) ?? []
    }

    private var playbackMoves: [TwistyMove] {
        guard let solveResult, solveResult.isSolvable else { return [] }
        return solveResult.moves
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

            if isSolving {
                solvingStateCard
            } else if let solveFailureMessage {
                unsolvableCard(message: solveFailureMessage)
            } else if let solveResult {
                solveSummaryCard(for: solveResult)

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

    private func solveSummaryCard(for result: TwistySolveResult) -> some View {
        let summary = result.makeSummaryViewData()

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(summary.statusText)
                .appTextStyle(.h2)
                .foregroundStyle(result.isSolvable ? AppTheme.Colors.text : AppTheme.Colors.highlight)

            HStack(spacing: AppTheme.Spacing.small) {
                summaryChip(label: "Moves", value: "\(result.moveCount)")
                summaryChip(label: "Steps", value: "\(result.steps.count)")
                if let elapsedTime = result.elapsedTime {
                    summaryChip(label: "Time", value: elapsedText(for: elapsedTime))
                }
            }

            Text(result.isSolvable ? "Use the ordered sequence below exactly as listed." : summary.stepCountText)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
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
                TwistyStepPlaybackControlsView(
                    currentStepNumber: currentStepIndex + 1,
                    totalSteps: playbackMoves.count,
                    currentMoveText: playbackMoves[safe: currentStepIndex]?.token,
                    isAutoPlaying: isAutoPlaying,
                    onPrevious: moveToPreviousStep,
                    onNext: moveToNextStep,
                    onToggleAutoPlay: toggleAutoPlay
                )

                CubeMoveStepCardView(
                    step: stepViewData[safe: currentStepIndex] ?? TwistySolutionStepViewData(
                        id: UUID(),
                        stepNumber: currentStepIndex + 1,
                        primaryText: playbackMoves[safe: currentStepIndex]?.token ?? "—",
                        secondaryText: nil
                    ),
                    previewNet: stepPreviewNets[safe: currentStepIndex],
                    previewCaption: "Cube state after this move"
                )
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

    private func summaryChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(label)
                .appTextStyle(.h3)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            Text(value)
                .appTextStyle(.h2)
                .foregroundStyle(AppTheme.Colors.highlight)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
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
        isSolving = true
        stopAutoPlay()
        solveFailureMessage = nil
        solveResult = nil

        let result = await Task.detached(priority: .userInitiated) {
            await Cube3x3Solver().solve(from: initialState)
        }.value

        if Task.isCancelled {
            solveFailureMessage = "Solving was interrupted. Please try again."
            isSolving = false
            return
        }

        guard result.puzzleType == .cube3x3 else {
            solveFailureMessage = "Something went wrong while solving. Please try again."
            isSolving = false
            return
        }

        solveResult = result
        currentStepIndex = 0
        showsStepCards = !result.moves.isEmpty
        isSolving = false
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

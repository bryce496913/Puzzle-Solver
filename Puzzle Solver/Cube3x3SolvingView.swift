import SwiftUI

struct Cube3x3SolvingView: View {
    let initialState: Cube3x3State

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?
    @State private var currentStepIndex = 0
    @State private var showsStepCards = false

    private let notationRenderer = StandardTwistyNotationRenderer()

    private var stepViewData: [TwistySolutionStepViewData] {
        solveResult?.makeStepViewData(renderer: notationRenderer) ?? []
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "3×3 Cube Solution",
                subtitle: "Review the move list and step-by-step walkthrough."
            )

            if isSolving {
                solvingStateCard
            } else if let solveResult {
                solveSummaryCard(for: solveResult)

                if solveResult.isSolvable {
                    TwistyNumberedMoveListView(title: "Ordered move list", moves: solveResult.moves)

                    if !stepViewData.isEmpty {
                        stepPreviewsSection
                    }
                } else {
                    unsolvableCard(message: stepViewData.first?.secondaryText)
                }
            }
        }
        .task {
            await solveCube()
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
            Text("We couldn't find a solution for this sticker input.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.highlight)

            if let message, !message.isEmpty {
                Text(message)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.9))
            }

            Text("This usually means one or more stickers were entered incorrectly. Go back, verify each face, and try again.")
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
                    totalSteps: stepViewData.count,
                    isAutoPlaying: false,
                    onPrevious: moveToPreviousStep,
                    onNext: moveToNextStep,
                    onToggleAutoPlay: {}
                )

                TwistyStepCardView(step: stepViewData[currentStepIndex])
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
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    private func moveToNextStep() {
        guard !stepViewData.isEmpty else { return }
        currentStepIndex = min(currentStepIndex + 1, stepViewData.count - 1)
    }

    @MainActor
    private func solveCube() async {
        isSolving = true

        let result = await Task.detached(priority: .userInitiated) {
            await Cube3x3Solver().solve(from: initialState)
        }.value

        solveResult = result
        currentStepIndex = 0
        showsStepCards = !result.steps.isEmpty
        isSolving = false
    }
}

#Preview {
    NavigationStack {
        Cube3x3SolvingView(initialState: .solved)
    }
}

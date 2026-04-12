import SwiftUI

struct Cube3x3SolvingView: View {
    let initialState: Cube3x3State

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?
    @State private var currentStepIndex = 0

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
                    TwistyMoveListView(title: "Ordered move list", moves: solveResult.moves)

                    if !stepViewData.isEmpty {
                        TwistyStepPlaybackControlsView(
                            currentStepNumber: currentStepIndex + 1,
                            totalSteps: stepViewData.count,
                            isAutoPlaying: false,
                            onPrevious: moveToPreviousStep,
                            onNext: moveToNextStep,
                            onToggleAutoPlay: {}
                        )

                        TwistyStepCardView(step: stepViewData[currentStepIndex])
                    }
                } else {
                    unsolvableCard
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

            Text(summary.moveCountText)
                .appTextStyle(.paragraph)

            Text(summary.stepCountText)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private var unsolvableCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("We couldn't find a solution for this sticker input.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.highlight)

            Text("This usually means one or more stickers were entered incorrectly. Go back, verify each face, and try again.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
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
        isSolving = false
    }
}

#Preview {
    NavigationStack {
        Cube3x3SolvingView(initialState: .solved)
    }
}

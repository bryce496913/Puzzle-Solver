import SwiftUI

struct Cube2x2SolvingView: View {
    let initialState: Cube2x2State

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?
    @State private var currentStepIndex = 0
    @State private var isAutoPlaying = false
    @State private var autoPlayTask: Task<Void, Never>?

    private let notationRenderer = StandardTwistyNotationRenderer()

    private var stepViewData: [TwistySolutionStepViewData] {
        solveResult?.makeStepViewData(renderer: notationRenderer) ?? []
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("2×2 Cube Solution")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

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
                                    isAutoPlaying: isAutoPlaying,
                                    onPrevious: moveToPreviousStep,
                                    onNext: moveToNextStep,
                                    onToggleAutoPlay: toggleAutoPlay
                                )

                                TwistyStepCardView(step: stepViewData[currentStepIndex])
                            }
                        } else {
                            unsolvableCard
                        }
                    }
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .task {
            await solveCube()
        }
        .onDisappear {
            stopAutoPlay()
        }
        .navigationTitle("2×2 Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var solvingStateCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            ProgressView()
                .tint(AppTheme.Colors.highlight)

            Text("Solving your 2×2 cube…")
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
    private func solveCube() async {
        isSolving = true
        stopAutoPlay()

        let result = await Task.detached(priority: .userInitiated) {
            await Cube2x2Solver().solve(from: initialState)
        }.value

        solveResult = result
        currentStepIndex = 0
        isSolving = false
    }
}

#Preview {
    NavigationStack {
        Cube2x2SolvingView(initialState: .solved)
    }
}

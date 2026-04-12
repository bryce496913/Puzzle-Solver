import SwiftUI

struct Cube2x2SolvingView: View {
    let initialState: Cube2x2State

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?

    private let notationRenderer = StandardTwistyNotationRenderer()

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

                            ForEach(solveResult.makeStepViewData(renderer: notationRenderer)) { stepData in
                                TwistyStepCardView(step: stepData)
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
            Text("This cube state could not be solved from the current sticker input.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.highlight)

            Text("Go back, verify your sticker colors, and try again.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    @MainActor
    private func solveCube() async {
        isSolving = true

        let result = await Task.detached(priority: .userInitiated) {
            await Cube2x2Solver().solve(from: initialState)
        }.value

        solveResult = result
        isSolving = false
    }
}

#Preview {
    NavigationStack {
        Cube2x2SolvingView(initialState: .solved)
    }
}

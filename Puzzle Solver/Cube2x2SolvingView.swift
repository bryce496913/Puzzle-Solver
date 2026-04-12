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
                            orderedMoveListCard(for: solveResult)

                            ForEach(solveResult.makeStepViewData(renderer: notationRenderer)) { stepData in
                                Cube2x2SolutionStepCardView(step: stepData)
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

    private func orderedMoveListCard(for result: TwistySolveResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Ordered move list")
                .appTextStyle(.h2)

            if result.moves.isEmpty {
                Text("No moves needed — this cube is already solved.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
            } else {
                Text(result.moves.map(\.token).joined(separator: " "))
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.highlight)
                    .textSelection(.enabled)
            }
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

private struct Cube2x2SolutionStepCardView: View {
    let step: TwistySolutionStepViewData

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                Text("Step \(step.stepNumber)")
                    .appTextStyle(.h2)

                Spacer(minLength: AppTheme.Spacing.small)

                Text(step.primaryText)
                    .appTextStyle(.h2)
                    .foregroundStyle(AppTheme.Colors.highlight)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                    .background(AppTheme.Colors.background.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            }

            if let secondaryText = step.secondaryText {
                Text(secondaryText)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.8))
            }

            HStack(spacing: AppTheme.Spacing.xSmall) {
                Image(systemName: "cube.transparent")
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
                Text("Cube preview coming soon")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
            }
            .padding(AppTheme.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.background.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }
}

#Preview {
    NavigationStack {
        Cube2x2SolvingView(initialState: .solved)
    }
}

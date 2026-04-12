//
//  SolvingView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct SolvingView: View {
    let initialState: SlidingPuzzleState

    @State private var isSolving = true
    @State private var solveResult: SlidingPuzzleSolveResult?

    private var puzzleTitle: String {
        "\(initialState.size)×\(initialState.size) Sliding Puzzle"
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text(puzzleTitle)
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    if isSolving {
                        solvingStateCard
                    } else if let solveResult {
                        resultSummaryCard(for: solveResult)

                        if solveResult.isSolvable {
                            ForEach(Array(solveResult.steps.enumerated()), id: \.offset) { _, step in
                                SolutionStepCardView(step: step)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .task {
            await solvePuzzle()
        }
    }

    private var solvingStateCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            ProgressView()
                .tint(AppTheme.Colors.highlight)

            Text(initialState.size == 4 ? "Solving 4×4 puzzle…" : "Solving puzzle…")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text)

            Text(solvingDescriptionText)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))

            if initialState.size == 4 {
                Text("Thanks for your patience — this can take a little longer.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private func resultSummaryCard(for result: SlidingPuzzleSolveResult) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(result.isSolvable ? "Status: Solvable" : "Status: Unsolvable")
                .appTextStyle(.h2)
                .foregroundStyle(result.isSolvable ? AppTheme.Colors.text : AppTheme.Colors.highlight)

            Text("Move count: \(result.moveCount)")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text)

            if result.isSolvable {
                Text("Ordered solution steps: \(result.steps.count)")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
            } else {
                Text("This arrangement can’t be solved from the current layout.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.highlight)

                Text("Go back, adjust a few tiles, and try again.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    @MainActor
    private func solvePuzzle() async {
        isSolving = true

        let result = await Task.detached(priority: .userInitiated) {
            SlidingPuzzleSolver().solve(from: initialState)
        }.value

        solveResult = result
        isSolving = false
    }

    private var solvingDescriptionText: String {
        if initialState.size == 4 {
            return "We’re carefully searching for the best path for your 4×4 board."
        }
        return "Finding a successful solution path for this \(initialState.size)×\(initialState.size) board."
    }
}

struct SolvingView_Previews: PreviewProvider {
    static var previews: some View {
        if let state = SlidingPuzzleState(board: [[1, 2, 3], [4, 5, 6], [7, nil, 8]]) {
            SolvingView(initialState: state)
        }
    }
}

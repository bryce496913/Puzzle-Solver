//
//  SolvingView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct SolvingView: View {
    let initialState: [[Int?]]

    @State private var isSolving = true
    @State private var solveResult: SlidingPuzzleSolveResult?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("Solution")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    if isSolving {
                        ProgressView("Solving puzzle…")
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, AppTheme.Spacing.small)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.highlight)
                    } else if let solveResult {
                        if !solveResult.isSolvable {
                            Text("This puzzle is unsolvable. Please return and enter a solvable 3×3 board.")
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.highlight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appSurfaceCard()
                        }

                        ForEach(Array(solveResult.steps.enumerated()), id: \.offset) { index, step in
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Step \(index)")
                                    .appTextStyle(.h3)
                                    .foregroundStyle(AppTheme.Colors.text)

                                if let moveLabel = step.moveLabel {
                                    Text(moveLabel)
                                        .appTextStyle(.paragraph)
                                        .foregroundStyle(AppTheme.Colors.highlight)
                                } else {
                                    Text("Initial state")
                                        .appTextStyle(.paragraph)
                                        .foregroundStyle(AppTheme.Colors.highlight)
                                }

                                MovementGridView(boardState: step.state.asBoard())
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

    @MainActor
    private func solvePuzzle() async {
        isSolving = true
        errorMessage = nil

        guard let startState = SlidingPuzzleState(board: initialState) else {
            isSolving = false
            errorMessage = "Invalid puzzle input. Please go back and re-enter all tiles."
            return
        }

        let result = await Task.detached(priority: .userInitiated) {
            SlidingPuzzleSolver().solve(from: startState)
        }.value

        solveResult = result
        isSolving = false
    }
}

struct SolvingView_Previews: PreviewProvider {
    static var previews: some View {
        SolvingView(initialState: [[1, 2, 3], [4, 5, 6], [7, nil, 8]])
    }
}

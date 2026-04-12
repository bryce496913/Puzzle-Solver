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
                            Text("This puzzle is unsolvable. Please return and enter a solvable \(initialState.size)×\(initialState.size) board.")
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.highlight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appSurfaceCard()
                        }

                        ForEach(Array(solveResult.steps.enumerated()), id: \.offset) { _, step in
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("Step \(step.stepNumber)")
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

                                MovementGridView(boardState: step.state.boardRows())
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

        let result = await Task.detached(priority: .userInitiated) {
            SlidingPuzzleSolver().solve(from: initialState)
        }.value

        solveResult = result
        isSolving = false
    }
}

struct SolvingView_Previews: PreviewProvider {
    static var previews: some View {
        if let state = SlidingPuzzleState(board: [[1, 2, 3], [4, 5, 6], [7, nil, 8]]) {
            SolvingView(initialState: state)
        }
    }
}

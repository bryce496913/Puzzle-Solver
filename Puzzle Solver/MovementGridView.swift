//
//  MovementGrideView.swift
//  Puzzle Solver
//
//  Created by Bryce Cameron on 3/3/24.
//

import SwiftUI

struct MovementGridView: View {
    let boardState: [[Int?]]

    private var boardSize: Int {
        boardState.count
    }

    private var flattenedBoardValues: [Int?] {
        boardState.flatMap { $0 }
    }

    var body: some View {
        SlidingPuzzleBoardView(
            boardValues: flattenedBoardValues,
            boardSize: boardSize,
            mode: .solution
        )
    }
}

struct SolutionStepCardView: View {
    let step: SlidingPuzzleSolutionStep

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Step \(step.stepNumber)")
                    .appTextStyle(.h2)
                    .foregroundStyle(AppTheme.Colors.text)

                Spacer(minLength: AppTheme.Spacing.small)

                if let moveLabel = step.moveLabel {
                    Text(moveLabel)
                        .appTextStyle(.h3)
                        .foregroundStyle(AppTheme.Colors.highlight)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text("Initial state")
                        .appTextStyle(.h3)
                        .foregroundStyle(AppTheme.Colors.highlight)
                }
            }

            MovementGridView(boardState: step.state.boardRows())
                .padding(AppTheme.Spacing.xSmall)
                .background(AppTheme.Colors.background.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        }
        .appSurfaceCard()
    }
}

struct MovementGridView_Previews: PreviewProvider {
    static var previews: some View {
        MovementGridView(boardState: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil]
        ])
        .padding()
        .background(AppTheme.Colors.background)
    }
}

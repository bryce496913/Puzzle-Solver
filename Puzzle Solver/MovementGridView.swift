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

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - (AppTheme.Spacing.small * 2), 1)
            let spacingTotal = AppTheme.Spacing.small * CGFloat(max(boardSize - 1, 0))
            let tileSize = max((availableWidth - spacingTotal) / CGFloat(max(boardSize, 1)), 32)

            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(0..<boardSize, id: \.self) { row in
                    HStack(spacing: AppTheme.Spacing.small) {
                        ForEach(0..<boardSize, id: \.self) { column in
                            MovementTileView(number: boardState[row][column], tileSize: tileSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
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

struct MovementTileView: View {
    let number: Int?
    let tileSize: CGFloat

    var body: some View {
        Text(number.map(String.init) ?? "")
            .appTextStyle(.h3)
            .frame(width: tileSize, height: tileSize)
            .background(number == nil ? AppTheme.Colors.surface.opacity(0.8) : AppTheme.Colors.highlight.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .stroke(AppTheme.Colors.highlight.opacity(0.45), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
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

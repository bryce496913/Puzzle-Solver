//
//  MovementGrideView.swift
//  Puzzle Solver
//
//  Created by Aditi Abrol on 3/3/24.
//

import SwiftUI

struct MovementGridView: View {
    let boardState: [[Int?]]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(0..<3, id: \.self) { column in
                        MovementTileView(number: boardState[row][column])
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.xSmall)
        .appSurfaceCard()
    }
}

struct MovementTileView: View {
    let number: Int?

    var body: some View {
        Text(number != nil ? "\(number!)" : "")
            .appTextStyle(.h3)
            .frame(width: 40, height: 40)
            .background(number == nil ? AppTheme.Colors.surface : AppTheme.Colors.highlight.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .stroke(AppTheme.Colors.highlight.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            .padding(2)
    }
}

struct MovementGridView_Previews: PreviewProvider {
    static var previews: some View {
        MovementGridView(boardState: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil]
        ])
    }
}

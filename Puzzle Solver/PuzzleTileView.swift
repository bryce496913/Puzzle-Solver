//
//  PuzzleTileView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct PuzzleTileView: View {
    let number: Int?

    var body: some View {
        Text(number.map(String.init) ?? "")
            .appTextStyle(.h2)
            .frame(width: 60, height: 60)
            .background(number == nil ? AppTheme.Colors.surface : AppTheme.Colors.accent.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .stroke(AppTheme.Colors.text, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
    }
}

struct PuzzleTileView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleTileView(number: 1)
    }
}

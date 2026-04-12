//
//  PuzzleGridView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct PuzzleGridView: View {
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
            mode: .display
        )
        .padding(AppTheme.Spacing.small)
        .appSurfaceCard()
    }
}

struct PuzzleGridView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleGridView(boardState: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, nil]
        ])
    }
}

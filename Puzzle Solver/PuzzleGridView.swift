//
//  PuzzleGridView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct PuzzleGridView: View {
    let boardState: [[Int?]]
    var tileSize: CGFloat = 60
    var spacing: CGFloat = 10

    private var puzzleSize: Int { boardState.count }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<puzzleSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<boardState[row].count, id: \.self) { column in
                        PuzzleTileView(number: boardState[row][column], size: tileSize)
                    }
                }
            }
        }
    }
}

struct PuzzleGridView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PuzzleGridView(boardState: PuzzlePresets.sliding3x3Medium.toGrid())
            PuzzleGridView(boardState: PuzzlePresets.sliding4x4Medium.toGrid(), tileSize: 44)
        }
    }
}

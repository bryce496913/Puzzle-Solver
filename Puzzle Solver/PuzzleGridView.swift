//
//  PuzzleGridView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct PuzzleGridView: View {
    let boardState: [[Int?]]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { column in
                        PuzzleTileView(number: boardState[row][column])
                    }
                }
            }
        }
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

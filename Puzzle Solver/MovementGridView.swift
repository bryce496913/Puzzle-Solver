//
//  MovementGrideView.swift
//  Puzzle Solver
//
//  Created by Aditi Abrol on 3/3/24.
//

import SwiftUI

struct MovementGridView: View {
    let boardState: [[Int?]]
    var tileSize: CGFloat = 40
    var spacing: CGFloat = 10

    private var puzzleSize: Int { boardState.count }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<puzzleSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<boardState[row].count, id: \.self) { column in
                        MovementTileView(number: boardState[row][column], size: tileSize)
                    }
                }
            }
        }
    }
}

struct MovementTileView: View {
    let number: Int?
    var size: CGFloat = 40

    var body: some View {
        Text(number.map(String.init) ?? " ")
            .font(.system(size: max(14, size * 0.45), weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Color.blue)
            .cornerRadius(max(6, size * 0.2))
            .padding(2)
    }
}

struct MovementGridView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MovementGridView(boardState: PuzzlePresets.sliding3x3Medium.toGrid())
            MovementGridView(boardState: PuzzlePresets.sliding4x4Medium.toGrid(), tileSize: 32)
        }
    }
}

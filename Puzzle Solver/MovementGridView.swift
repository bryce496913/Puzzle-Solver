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
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { column in
                        MovementTileView(number: boardState[row][column])
                    }
                }
            }
        }
    }
}

struct MovementTileView: View {
    let number: Int?

    var body: some View {
        Text(number != nil ? "\(number!)" : " ")
            .font(.title)
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Color.blue)
            .cornerRadius(8)
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


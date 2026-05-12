//
//  PuzzleTileView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct PuzzleTileView: View {
    let number: Int?
    var size: CGFloat = 60
    var backgroundColor: Color = .gray
    var foregroundColor: Color = .black

    var body: some View {
        Text(number.map(String.init) ?? "")
            .font(.system(size: max(16, size * 0.42), weight: .semibold))
            .frame(width: size, height: size)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(max(6, size * 0.16))
            .accessibilityLabel(number.map { "Tile \($0)" } ?? "Empty tile")
    }
}

struct PuzzleTileView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PuzzleTileView(number: 1)
            PuzzleTileView(number: 15, size: 44)
        }
    }
}

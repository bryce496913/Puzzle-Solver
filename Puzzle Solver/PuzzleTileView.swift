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
            .font(.title)
            .frame(width: 60, height: 60)
            .background(Color.gray)
            .foregroundColor(.black)
            .cornerRadius(10)
    }
}

struct PuzzleTileView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleTileView(number: 1)
    }
}

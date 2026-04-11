//
//  SolvingView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct SolvingView: View {
    let initialState: [[Int?]]
    @State private var solvedState: [[Int?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)
    @State private var movementList: [String] = []

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Movement List")
                    .appTextStyle(.h1)
                    .foregroundStyle(AppTheme.Colors.highlight)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        ForEach(movementList, id: \.self) { movement in
                            Text(movement)
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .appSurfaceCard()
            }
            .padding(AppTheme.Spacing.large)
        }
        .onAppear {
            solvedState = initialState
            solvePuzzle()
        }
    }

    private func solvePuzzle() {
        DispatchQueue.global().async {
            let puzzleSolver = PuzzleSolver()

            let puzzleSolved = puzzleSolver.aStarSearch(start: initialState.map { $0.map { $0 != nil ? "\($0!)" : "0" } })

            let combinedList = zip(puzzleSolved.boardPathStateList, puzzleSolved.movementHistory)

            var flatMovementList: [String] = []
            for (board, movement) in combinedList {
                flatMovementList.append(boardString(board))
                flatMovementList.append("Move: \(movement)")
                flatMovementList.append("")
            }

            DispatchQueue.main.async {
                movementList = flatMovementList
            }
        }
    }

    private func boardString(_ board: [[String]]) -> String {
        return board.map { $0.joined(separator: "  ") }.joined(separator: "\n")
    }
}

struct SolvingView_Previews: PreviewProvider {
    static var previews: some View {
        SolvingView(initialState: [[1, 2, 3], [4, 5, 6], [7, 8, nil]])
    }
}

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
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Movement List:")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.bottom)

                        ForEach(movementList, id: \.self) { movement in
                            Text(movement)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            solvedState = initialState // Set the initial state
            solvePuzzle()
        }
    }

    private func solvePuzzle() {
        DispatchQueue.global().async {
            let puzzleSolver = PuzzleSolver()
            
            let puzzleSolved = puzzleSolver.aStarSearch(start: initialState.map { $0.map { $0 != nil ? "\($0!)" : "0" } })
            
            // Combine boardPathStateList and movementHistory into a single array
            let combinedList = zip(puzzleSolved.boardPathStateList, puzzleSolved.movementHistory)
            
            // Convert combined list to a flat list of movements with proper formatting
            var flatMovementList: [String] = []
            for (board, movement) in combinedList {
                flatMovementList.append(boardString(board))
                flatMovementList.append("Move: \(movement)")
                flatMovementList.append("") // Add an empty string to start the next move on a new line
            }
            
            DispatchQueue.main.async {
                movementList = flatMovementList
            }
        }
    }
    
    // Convert a board state to a formatted string
    private func boardString(_ board: [[String]]) -> String {
        return board.map { $0.joined(separator: "  ") }.joined(separator: "\n")
    }
}

struct SolvingView_Previews: PreviewProvider {
    static var previews: some View {
        SolvingView(initialState: [[1, 2, 3], [4, 5, 6], [7, 8, nil]])
    }
}

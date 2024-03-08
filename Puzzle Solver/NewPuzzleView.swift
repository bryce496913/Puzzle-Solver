//
//  NewPuzzleView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct NewPuzzleView: View {
    @State private var selectedTile: Int?
    @State private var gridNumbers: [[Int?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)
    @State private var numbersInGrid: Set<Int> = Set(1...8)
    @State private var isSolveButtonVisible: Bool = false
    @State private var initialState: [[Int?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 10) {
                Spacer()

                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { column in
                            PuzzleTileSolvedView(
                                number: gridNumbers[row][column],
                                backgroundColor: tileBackgroundColor(number: gridNumbers[row][column]),
                                isSelected: selectedTile == row * 3 + column,
                                onTap: {
                                    handleTileSelection(row: row, column: column)
                                }
                            )
                        }
                    }
                }

                // Conditionally render KeypadView or SolveButton based on UI state
                if isSolveButtonVisible {
                    NavigationLink(
                        destination: {
                            SolvingView(initialState: initialState)
                        },
                        label: {
                            Text("Solve")
                                .font(.title)
                                .frame(width: 200, height: 50)
                                .background(Color(hex: 0x99ffcc))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    )
                } else {
                    KeypadView(
                        onTap: { number in
                            handleKeypadButtonTap(number: number)
                        }
                    )
                }

                Spacer()

                HStack {
                    NavigationLink(
                        destination: MainMenuView(),
                        label: {
                            Text("Back")
                                .font(.title)
                                .frame(width: 100, height: 35)
                                .background(Color(hex: 0xccccff))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    )
                    .padding(.trailing, 40)

                    NavigationLink(
                        destination: NewPuzzleView(),
                        label: {
                            Text("Reset")
                                .font(.title)
                                .frame(width: 100, height: 35)
                                .background(Color(hex: 0xff99cc))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    )
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationBarHidden(true)
    }

    private func handleTileSelection(row: Int, column: Int) {
        // If the "Solve" button is visible, hide it and show the keypad
        if isSolveButtonVisible {
            isSolveButtonVisible = false
        }
        self.selectedTile = row * 3 + column
    }

    private func handleKeypadButtonTap(number: Int) {
        // Handle keypad button tap logic
        if number == 9 {
            // 'x' button pressed, remove number
            if let selectedTile = selectedTile {
                if let removedNumber = gridNumbers[selectedTile / 3][selectedTile % 3] {
                    // Reassign the removed number to the set of available numbers
                    numbersInGrid.insert(removedNumber)
                }
                gridNumbers[selectedTile / 3][selectedTile % 3] = nil
            }
        } else if numbersInGrid.contains(number) {
            // Check if the number is available for assignment
            if let selectedTile = selectedTile {
                gridNumbers[selectedTile / 3][selectedTile % 3] = number
                numbersInGrid.remove(number)
            }
        }
        self.selectedTile = nil

        // Check if all 8 numbers are assigned, show the "Solve" button
        if numbersInGrid.isEmpty {
            // Save the initial state
            initialState = gridNumbers
            isSolveButtonVisible = true
        }
    }

    private func tileBackgroundColor(number: Int?) -> Color {
        switch number {
        case 1: return Color(hex: 0xffffcc)
        case 2: return Color(hex: 0xffcc99)
        case 3: return Color(hex: 0xffcccc)
        case 4: return Color(hex: 0xffccff)
        case 5: return Color(hex: 0xcc99ff)
        case 6: return Color(hex: 0x99ccff)
        case 7: return Color(hex: 0xccffff)
        case 8: return Color(hex: 0xccffcc)
        default: return Color.gray
        }
    }
}

struct NewPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        NewPuzzleView()
    }
}

struct PuzzleTileSolvedView: View {
    let number: Int?
    let backgroundColor: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(number.map(String.init) ?? "")
            .font(.title)
            .frame(width: 60, height: 60)
            .background(backgroundColor)
            .border(isSelected ? Color(hex: 0xffcc99) : Color.clear, width: 2)
            .foregroundColor(.black)
            .cornerRadius(10)
            .onTapGesture {
                onTap()
            }
    }
}

struct KeypadView: View {
    let onTap: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(1...3, id: \.self) { column in
                        KeypadButton(number: row * 3 + column, onTap: onTap)
                    }
                }
            }
        }
        .padding()
    }
}

struct KeypadButton: View {
    let number: Int
    let onTap: (Int) -> Void

    var body: some View {
        Button(action: {
            onTap(number)
        }) {
            Text(number == 9 ? "x" : "\(number)")
                .font(.title)
                .frame(width: 40, height: 40)
                .background(number == 9 ? Color(hex: 0xff99cc) : Color(hex: 0x99ccff))
                .foregroundColor(.black)
                .cornerRadius(20)
        }
    }
}

//
//  NewPuzzleView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct NewPuzzleView: View {
    let puzzleSize: Int

    @State private var selectedTile: Int?
    @State private var gridNumbers: [[Int?]]
    @State private var numbersInGrid: Set<Int>
    @State private var isSolveButtonVisible: Bool = false
    @State private var initialState: [[Int?]]

    init(puzzleSize: Int = 3) {
        self.puzzleSize = puzzleSize
        let emptyGrid = Array(repeating: Array(repeating: Optional<Int>.none, count: puzzleSize), count: puzzleSize)
        _gridNumbers = State(initialValue: emptyGrid)
        _initialState = State(initialValue: emptyGrid)
        _numbersInGrid = State(initialValue: Set(1..<(puzzleSize * puzzleSize)))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.large) {
                Text("Set Up \(puzzleSize)×\(puzzleSize) Puzzle")
                    .appTextStyle(.h1)
                    .foregroundStyle(AppTheme.Colors.highlight)

                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(0..<puzzleSize, id: \.self) { row in
                        HStack(spacing: AppTheme.Spacing.small) {
                            ForEach(0..<puzzleSize, id: \.self) { column in
                                PuzzleTileSolvedView(
                                    number: gridNumbers[row][column],
                                    backgroundColor: tileBackgroundColor(number: gridNumbers[row][column]),
                                    isSelected: selectedTile == row * puzzleSize + column,
                                    onTap: {
                                        handleTileSelection(row: row, column: column)
                                    }
                                )
                            }
                        }
                    }
                }
                .appSurfaceCard()

                Group {
                    if isSolveButtonVisible {
                        NavigationLink(
                            destination: {
                                SolvingView(initialState: initialState)
                            },
                            label: {
                                Text("Solve")
                            }
                        )
                        .buttonStyle(AppPrimaryButtonStyle())
                    } else {
                        KeypadView(
                            puzzleSize: puzzleSize,
                            onTap: { number in
                                handleKeypadButtonTap(number: number)
                            }
                        )
                    }
                }
                .appSurfaceCard()

                HStack(spacing: AppTheme.Spacing.medium) {
                    NavigationLink(
                        destination: MainMenuView(),
                        label: {
                            Text("Back")
                        }
                    )
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))

                    NavigationLink(
                        destination: NewPuzzleView(puzzleSize: puzzleSize),
                        label: {
                            Text("Reset")
                        }
                    )
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .navigationBarHidden(true)
    }

    private func handleTileSelection(row: Int, column: Int) {
        if isSolveButtonVisible {
            isSolveButtonVisible = false
        }
        selectedTile = row * puzzleSize + column
    }

    private func handleKeypadButtonTap(number: Int) {
        let clearToken = puzzleSize * puzzleSize

        if number == clearToken {
            if let selectedTile {
                if let removedNumber = gridNumbers[selectedTile / puzzleSize][selectedTile % puzzleSize] {
                    numbersInGrid.insert(removedNumber)
                }
                gridNumbers[selectedTile / puzzleSize][selectedTile % puzzleSize] = nil
            }
        } else if numbersInGrid.contains(number) {
            if let selectedTile {
                gridNumbers[selectedTile / puzzleSize][selectedTile % puzzleSize] = number
                numbersInGrid.remove(number)
            }
        }

        selectedTile = nil

        if numbersInGrid.isEmpty {
            initialState = gridNumbers
            isSolveButtonVisible = true
        }
    }

    private func tileBackgroundColor(number: Int?) -> Color {
        number == nil ? AppTheme.Colors.surface : AppTheme.Colors.accent.opacity(0.35)
    }
}

struct NewPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        NewPuzzleView(puzzleSize: 3)
    }
}

struct PuzzleTileSolvedView: View {
    let number: Int?
    let backgroundColor: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(number.map(String.init) ?? "")
            .appTextStyle(.h2)
            .frame(width: 64, height: 64)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .stroke(isSelected ? AppTheme.Colors.highlight : AppTheme.Colors.text, lineWidth: isSelected ? 2 : 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            .onTapGesture {
                onTap()
            }
    }
}

struct KeypadView: View {
    let puzzleSize: Int
    let onTap: (Int) -> Void

    var body: some View {
        let totalTiles = puzzleSize * puzzleSize

        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(0..<puzzleSize, id: \.self) { row in
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(1...puzzleSize, id: \.self) { column in
                        let number = row * puzzleSize + column
                        KeypadButton(number: number, clearToken: totalTiles, onTap: onTap)
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }
}

struct KeypadButton: View {
    let number: Int
    let clearToken: Int
    let onTap: (Int) -> Void

    var body: some View {
        Button(action: {
            onTap(number)
        }) {
            Text(number == clearToken ? "x" : "\(number)")
                .appTextStyle(.h2)
                .frame(width: 48, height: 48)
                .background(number == clearToken ? AppTheme.Colors.highlight : AppTheme.Colors.accent)
                .foregroundStyle(AppTheme.Colors.text)
                .clipShape(Circle())
        }
    }
}

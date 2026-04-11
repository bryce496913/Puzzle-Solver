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
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.large) {
                Text("Set Up Puzzle")
                    .appTextStyle(.h1)
                    .foregroundStyle(AppTheme.Colors.highlight)

                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: AppTheme.Spacing.small) {
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
                        destination: NewPuzzleView(),
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
        self.selectedTile = row * 3 + column
    }

    private func handleKeypadButtonTap(number: Int) {
        if number == 9 {
            if let selectedTile = selectedTile {
                if let removedNumber = gridNumbers[selectedTile / 3][selectedTile % 3] {
                    numbersInGrid.insert(removedNumber)
                }
                gridNumbers[selectedTile / 3][selectedTile % 3] = nil
            }
        } else if numbersInGrid.contains(number) {
            if let selectedTile = selectedTile {
                gridNumbers[selectedTile / 3][selectedTile % 3] = number
                numbersInGrid.remove(number)
            }
        }
        self.selectedTile = nil

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
    let onTap: (Int) -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: AppTheme.Spacing.medium) {
                    ForEach(1...3, id: \.self) { column in
                        KeypadButton(number: row * 3 + column, onTap: onTap)
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
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
                .appTextStyle(.h2)
                .frame(width: 48, height: 48)
                .background(number == 9 ? AppTheme.Colors.highlight : AppTheme.Colors.accent)
                .foregroundStyle(AppTheme.Colors.text)
                .clipShape(Circle())
        }
    }
}

//
//  NewPuzzleView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct NewPuzzleView: View {
    @State private var selectedKind: SlidingPuzzleKind = .threeByThree
    @State private var selectedTile: Int?
    @State private var gridNumbers: [[Int?]] = NewPuzzleView.emptyGrid(size: SlidingPuzzleKind.threeByThree.size)
    @State private var numbersInGrid: Set<Int> = NewPuzzleView.availableNumbers(size: SlidingPuzzleKind.threeByThree.size)
    @State private var isSolveButtonVisible = false
    @State private var initialState: [[Int?]] = NewPuzzleView.emptyGrid(size: SlidingPuzzleKind.threeByThree.size)

    private var puzzleSize: Int { selectedKind.size }
    private var tileSize: CGFloat { selectedKind == .threeByThree ? 60 : 48 }
    private var keypadColumns: [GridItem] { Array(repeating: GridItem(.fixed(44), spacing: 14), count: selectedKind == .threeByThree ? 3 : 4) }

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 14) {
                Spacer()

                Picker("Puzzle Size", selection: $selectedKind) {
                    ForEach(SlidingPuzzleKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedKind) { _ in
                    resetPuzzle()
                }

                VStack(spacing: 10) {
                    ForEach(0..<puzzleSize, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<puzzleSize, id: \.self) { column in
                                PuzzleTileSolvedView(
                                    number: gridNumbers[row][column],
                                    size: tileSize,
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

                Button(action: loadExample) {
                    Text("Try \(selectedKind.displayName) Example")
                        .font(.title3)
                        .frame(width: 260, height: 44)
                        .background(Color(hex: 0xccffff))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }

                if isSolveButtonVisible {
                    NavigationLink(
                        destination: {
                            SolvingView(initialState: initialState, puzzleSize: puzzleSize)
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
                    KeypadView(size: puzzleSize, columns: keypadColumns) { number in
                        handleKeypadButtonTap(number: number)
                    }
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

                    Button(action: resetPuzzle) {
                        Text("Reset")
                            .font(.title)
                            .frame(width: 100, height: 35)
                            .background(Color(hex: 0xff99cc))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding()
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
        guard let selectedTile else { return }
        let row = selectedTile / puzzleSize
        let column = selectedTile % puzzleSize
        let clearButton = puzzleSize * puzzleSize

        if number == clearButton {
            if let removedNumber = gridNumbers[row][column] {
                numbersInGrid.insert(removedNumber)
            }
            gridNumbers[row][column] = nil
        } else if numbersInGrid.contains(number) {
            if let existingNumber = gridNumbers[row][column] {
                numbersInGrid.insert(existingNumber)
            }
            gridNumbers[row][column] = number
            numbersInGrid.remove(number)
        }

        self.selectedTile = nil
        updateSolveButtonVisibility()
    }

    private func loadExample() {
        let preset = selectedKind == .threeByThree ? PuzzlePresets.sliding3x3Medium : PuzzlePresets.sliding4x4Medium
        gridNumbers = preset.toGrid()
        numbersInGrid = []
        initialState = gridNumbers
        selectedTile = nil
        isSolveButtonVisible = true
        SolverDebugLogger.shared.log("sample preset selected: \(selectedKind.displayName) medium")
    }

    private func resetPuzzle() {
        gridNumbers = Self.emptyGrid(size: puzzleSize)
        numbersInGrid = Self.availableNumbers(size: puzzleSize)
        initialState = gridNumbers
        selectedTile = nil
        isSolveButtonVisible = false
    }

    private func updateSolveButtonVisibility() {
        if numbersInGrid.isEmpty {
            initialState = gridNumbers
            isSolveButtonVisible = true
        } else {
            isSolveButtonVisible = false
        }
    }

    private func tileBackgroundColor(number: Int?) -> Color {
        guard let number else { return Color.gray }
        let palette = [0xffffcc, 0xffcc99, 0xffcccc, 0xffccff, 0xcc99ff, 0x99ccff, 0xccffff, 0xccffcc]
        return Color(hex: palette[(number - 1) % palette.count])
    }

    private static func emptyGrid(size: Int) -> [[Int?]] {
        Array(repeating: Array(repeating: nil, count: size), count: size)
    }

    private static func availableNumbers(size: Int) -> Set<Int> {
        Set(1..<(size * size))
    }
}

struct NewPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        NewPuzzleView()
    }
}

struct PuzzleTileSolvedView: View {
    let number: Int?
    var size: CGFloat = 60
    let backgroundColor: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(number.map(String.init) ?? "")
            .font(.system(size: max(16, size * 0.42), weight: .semibold))
            .frame(width: size, height: size)
            .background(backgroundColor)
            .border(isSelected ? Color(hex: 0xffcc99) : Color.clear, width: 2)
            .foregroundColor(.black)
            .cornerRadius(max(6, size * 0.16))
            .onTapGesture {
                onTap()
            }
    }
}

struct KeypadView: View {
    let size: Int
    let columns: [GridItem]
    let onTap: (Int) -> Void

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(1...(size * size), id: \.self) { number in
                KeypadButton(number: number, clearButton: size * size, onTap: onTap)
            }
        }
        .frame(width: CGFloat(size) * 58)
        .padding()
    }
}

struct KeypadButton: View {
    let number: Int
    let clearButton: Int
    let onTap: (Int) -> Void

    var body: some View {
        Button(action: {
            onTap(number)
        }) {
            Text(number == clearButton ? "x" : "\(number)")
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(number == clearButton ? Color(hex: 0xff99cc) : Color(hex: 0x99ccff))
                .foregroundColor(.black)
                .cornerRadius(20)
        }
    }
}

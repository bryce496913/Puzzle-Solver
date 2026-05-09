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

// MARK: - Reusable twisty puzzle UI

struct TwistyPuzzleInputView: View {
    @State private var selectedPuzzle: TwistyPuzzleKind = .threeByThree
    @State private var scrambleNotation = "R U R' U'"
    @State private var selectedSticker = "U"
    @State private var currentState = CubeState.solved2x2
    @State private var solveResult: CubeSolveResult?
    @State private var notationError: String?
    @State private var isSolving = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Twisty Puzzles")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: 0xccffff))

                    Picker("Puzzle", selection: $selectedPuzzle) {
                        ForEach(TwistyPuzzleKind.allCases.filter { [.twoByTwo, .threeByThree, .pyraminx, .skewb].contains($0) }) { puzzle in
                            Text(puzzle.displayName).tag(puzzle)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedPuzzle) { _ in resetForSelectedPuzzle() }

                    if selectedPuzzle == .threeByThree {
                        Cube3x3StickerInputView(state: currentState, selectedSticker: $selectedSticker) { index in
                            setSticker(at: index)
                        }
                    } else {
                        TwistyFaceNetView(state: currentState)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scramble notation")
                            .foregroundColor(.white)
                            .font(.headline)
                        TextField("Example: U R F", text: $scrambleNotation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("2×2: \(TwoByTwoMoveEngine.legalMoveNotation) • 3×3: \(Cube3x3MoveEngine.legalMoveNotation)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    if let notationError {
                        Text(notationError)
                            .foregroundColor(Color(hex: 0xff99cc))
                    }

                    HStack(spacing: 12) {
                        Button("Apply Scramble") { applyScramble() }
                            .twistyActionStyle(color: Color(hex: 0x99ccff))

                        Button("Solve") { solveCurrentPuzzle() }
                            .twistyActionStyle(color: selectedPuzzle.isSolveEnabled ? Color(hex: 0x99ffcc) : Color.gray)
                            .disabled(!selectedPuzzle.isSolveEnabled || isSolving)
                    }

                    if isSolving {
                        HStack {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Solving off the main thread…")
                                .foregroundColor(.gray)
                        }
                    }

                    if let solveResult {
                        TwistySolveResultView(result: solveResult)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resetForSelectedPuzzle() }
    }

    private func resetForSelectedPuzzle() {
        currentState = CubeState.solved(selectedPuzzle)
        solveResult = nil
        selectedSticker = "U"
        notationError = selectedPuzzle.isSolveEnabled ? nil : "\(selectedPuzzle.displayName) has a registered placeholder architecture; solving is not implemented yet."
    }

    private func applyScramble() {
        notationError = nil
        solveResult = nil
        switch selectedPuzzle {
        case .twoByTwo:
            switch TwistyMoveNotation.parse(scrambleNotation, allowedFaces: Set(["U", "R", "F"])) {
            case .success(let moves): currentState = TwoByTwoMoveEngine.apply(moves.map(\.notation), to: .solved2x2)
            case .failure(let error): notationError = error.localizedDescription
            }
        case .threeByThree:
            switch TwistyMoveNotation.parse(scrambleNotation, allowedFaces: Set(["U", "R", "F", "D", "L", "B"])) {
            case .success(let moves): currentState = Cube3x3MoveEngine.apply(moves.map(\.notation), to: .solved3x3)
            case .failure(let error): notationError = error.localizedDescription
            }
        default:
            currentState = CubeState.solved(selectedPuzzle)
            notationError = "Scramble replay is implemented for 2×2 and 3×3 cubes."
        }
    }


    private func setSticker(at index: Int) {
        guard selectedPuzzle == .threeByThree, ![4, 13, 22, 31, 40, 49].contains(index) else { return }
        var stickers = currentState.stickers
        guard stickers.indices.contains(index) else { return }
        stickers[index] = selectedSticker
        currentState = CubeState(puzzle: .threeByThree, stickers: stickers)
        solveResult = nil
        notationError = nil
    }

    private func solveCurrentPuzzle() {
        notationError = nil
        isSolving = true
        SolverDiagnosticsStore.shared.record(modeName: selectedPuzzle.displayName, state: .solving, detail: "Twisty solve started.")
        CubeSolvingService.shared.solve(currentState, options: CubeSolveOptions(timeout: selectedPuzzle == .threeByThree ? 10 : 5, maxDepth: selectedPuzzle == .threeByThree ? 24 : 14, maxNodes: selectedPuzzle == .threeByThree ? 1_000_000 : 75_000, includeStepStates: false)) { result in
            isSolving = false
            solveResult = result
            SolverDiagnosticsStore.shared.record(modeName: selectedPuzzle.displayName, state: result.status.solveState, detail: result.failureReason ?? result.status.userFacingMessage)
        }
    }
}

struct Cube3x3StickerInputView: View {
    let state: CubeState
    @Binding var selectedSticker: String
    let onStickerTap: (Int) -> Void

    private let faces = ["U", "R", "F", "D", "L", "B"]
    private let centerIndices: Set<Int> = [4, 13, 22, 31, 40, 49]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3×3 sticker input")
                .font(.headline)
                .foregroundColor(.white)

            Text("Choose a color, then tap stickers in the cube net. Centers are fixed and validity is checked before solving.")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 8) {
                ForEach(faces, id: \.self) { face in
                    Button(face) { selectedSticker = face }
                        .font(.caption.bold())
                        .frame(width: 34, height: 34)
                        .background(stickerColor(face))
                        .foregroundColor(.black)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedSticker == face ? Color(hex: 0xccffff) : Color.clear, lineWidth: 3))
                        .cornerRadius(8)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(Array(faces.enumerated()), id: \.offset) { faceIndex, face in
                    VStack(spacing: 6) {
                        Text(face)
                            .foregroundColor(.gray)
                            .font(.caption)
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 4), count: 3), spacing: 4) {
                            ForEach(0..<9, id: \.self) { offset in
                                let stickerIndex = faceIndex * 9 + offset
                                Button(action: { onStickerTap(stickerIndex) }) {
                                    Text(state.stickers[safe: stickerIndex] ?? "?")
                                        .font(.caption2.bold())
                                        .frame(width: 22, height: 22)
                                        .background(stickerColor(state.stickers[safe: stickerIndex] ?? "?"))
                                        .foregroundColor(.black)
                                        .cornerRadius(5)
                                        .opacity(centerIndices.contains(stickerIndex) ? 0.7 : 1)
                                }
                                .disabled(centerIndices.contains(stickerIndex))
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                }
            }
        }
    }

    private func stickerColor(_ label: String) -> Color {
        switch label {
        case "U": return .white
        case "R": return Color(hex: 0xff9999)
        case "F": return Color(hex: 0x99ff99)
        case "D": return Color(hex: 0xffff99)
        case "L": return Color(hex: 0xffcc99)
        case "B": return Color(hex: 0x99ccff)
        default: return Color(hex: 0xccccff)
        }
    }
}

struct TwistyFaceNetView: View {
    let state: TwistyPuzzleState

    private var faceStickerCount: Int { max(1, (state.puzzle.stickerCount ?? state.stickers.count) / max(1, state.puzzle.faces.count)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(state.puzzle.displayName)
                .foregroundColor(.white)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                ForEach(Array(state.puzzle.faces.enumerated()), id: \.offset) { index, face in
                    let start = index * faceStickerCount
                    let end = min(start + faceStickerCount, state.stickers.count)
                    TwistyFaceView(faceName: face, stickers: Array(state.stickers[start..<end]))
                }
            }
        }
    }
}

struct TwistyFaceView: View {
    let faceName: String
    let stickers: [String]

    private var columns: [GridItem] {
        let side = Int(ceil(sqrt(Double(max(1, stickers.count)))))
        return Array(repeating: GridItem(.fixed(18), spacing: 3), count: side)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(faceName)
                .foregroundColor(.gray)
                .font(.caption)
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(Array(stickers.enumerated()), id: \.offset) { _, sticker in
                    TwistyStickerView(label: sticker)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }
}

struct TwistyStickerView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2)
            .frame(width: 18, height: 18)
            .background(stickerColor)
            .foregroundColor(.black)
            .cornerRadius(4)
    }

    private var stickerColor: Color {
        switch label {
        case "U": return .white
        case "R": return Color(hex: 0xff9999)
        case "F": return Color(hex: 0x99ff99)
        case "D": return Color(hex: 0xffff99)
        case "L": return Color(hex: 0xffcc99)
        case "B": return Color(hex: 0x99ccff)
        default: return Color(hex: 0xccccff)
        }
    }
}

struct TwistyMoveListView: View {
    let moves: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Moves")
                .font(.headline)
                .foregroundColor(.white)
            if moves.isEmpty {
                Text("Already solved.")
                    .foregroundColor(.gray)
            } else {
                ForEach(Array(moves.enumerated()), id: \.offset) { index, move in
                    Text("\(index + 1). \(move)")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct TwistySolveResultView: View {
    let result: CubeSolveResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.status.userFacingMessage)
                .font(.title2)
                .foregroundColor(result.succeeded ? Color(hex: 0xccffcc) : Color(hex: 0xff99cc))
            Text("Move count: \(result.moveCount) • Nodes checked: \(result.nodesExplored) • Time: \(String(format: "%.2f", result.elapsedTime))s")
                .font(.caption)
                .foregroundColor(.gray)
            if let failureReason = result.failureReason {
                Text(failureReason)
                    .foregroundColor(.white)
            }
            TwistyMoveListView(moves: result.moves)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

private extension View {
    func twistyActionStyle(color: Color) -> some View {
        self.font(.headline)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(color)
            .foregroundColor(.black)
            .cornerRadius(10)
    }
}

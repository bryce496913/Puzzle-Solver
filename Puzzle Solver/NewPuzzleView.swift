//
//  NewPuzzleView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct NewPuzzleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedKind: SlidingPuzzleKind = .threeByThree
    @State private var selectedTile: Int?
    @State private var gridNumbers: [[Int?]] = NewPuzzleView.emptyGrid(size: SlidingPuzzleKind.threeByThree.size)
    @State private var numbersInGrid: Set<Int> = NewPuzzleView.availableNumbers(size: SlidingPuzzleKind.threeByThree.size)
    @State private var isSolveButtonVisible = false
    @State private var initialState: [[Int?]] = NewPuzzleView.emptyGrid(size: SlidingPuzzleKind.threeByThree.size)

    private var puzzleSize: Int { selectedKind.size }
    private var tileSize: CGFloat { selectedKind == .threeByThree ? 60 : 48 }
    private var keypadColumns: [GridItem] { Array(repeating: GridItem(.fixed(72), spacing: 14), count: selectedKind == .threeByThree ? 3 : 4) }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    Text("Sliding Puzzle")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(AppTheme.cyan)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)

                Picker("Puzzle Size", selection: $selectedKind) {
                    ForEach(SlidingPuzzleKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedKind) { newKind in
                    resetPuzzle(size: newKind.size)
                }

                VStack(spacing: 10) {
                    ForEach(0..<puzzleSize, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<puzzleSize, id: \.self) { column in
                                PuzzleTileSolvedView(
                                    number: gridValue(row: row, column: column),
                                    size: tileSize,
                                    backgroundColor: tileBackgroundColor(number: gridValue(row: row, column: column)),
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
                        .appButtonLabel()
                }
                .buttonStyle(AppSecondaryButtonStyle())
                .accessibilityHint("Loads a valid sample puzzle so you can preview solving.")

                if isSolveButtonVisible {
                    NavigationLink(
                        destination: {
                            SolvingView(initialState: initialState, puzzleSize: puzzleSize)
                        },
                        label: {
                            Text("Solve")
                                .appButtonLabel()
                        }
                    )
                    .buttonStyle(AppPrimaryButtonStyle())
                    .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.96)))
                } else {
                    KeypadView(size: puzzleSize, columns: keypadColumns) { number in
                        handleKeypadButtonTap(number: number)
                    }
                }

                Spacer()

                    HStack(spacing: 16) {
                        Button("Back") { dismiss() }
                            .buttonStyle(AppSecondaryButtonStyle())

                        Button("Reset", action: resetPuzzle)
                            .buttonStyle(AppDangerButtonStyle())
                    }
                    .font(.headline.weight(.semibold))
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isSolveButtonVisible)
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
        guard gridNumbers.indices.contains(row), gridNumbers[row].indices.contains(column) else {
            resetPuzzle(size: puzzleSize)
            return
        }

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
        resetPuzzle(size: puzzleSize)
        let preset = selectedKind == .threeByThree ? PuzzlePresets.sliding3x3Medium : PuzzlePresets.sliding4x4Medium
        gridNumbers = preset.toGrid()
        numbersInGrid = []
        initialState = gridNumbers
        selectedTile = nil
        isSolveButtonVisible = true
    }

    private func resetPuzzle() {
        resetPuzzle(size: puzzleSize)
    }

    private func resetPuzzle(size: Int) {
        gridNumbers = Self.emptyGrid(size: size)
        numbersInGrid = Self.availableNumbers(size: size)
        initialState = gridNumbers
        selectedTile = nil
        isSolveButtonVisible = false
    }

    private func gridValue(row: Int, column: Int) -> Int? {
        guard gridNumbers.indices.contains(row), gridNumbers[row].indices.contains(column) else { return nil }
        return gridNumbers[row][column]
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
            .overlay(
                RoundedRectangle(cornerRadius: max(6, size * 0.16))
                    .stroke(isSelected ? AppTheme.amber : Color.clear, lineWidth: 3)
            )
            .contentShape(RoundedRectangle(cornerRadius: max(6, size * 0.16)))
            .accessibilityLabel(number.map { "Tile \($0)" } ?? "Empty tile")
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityAddTraits(.isButton)
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
        .frame(width: CGFloat(size) * 86)
        .padding()
        .accessibilityElement(children: .contain)
    }
}

struct KeypadButton: View {
    let number: Int
    let clearButton: Int
    let onTap: (Int) -> Void

    var body: some View {
        if number == clearButton {
            Button(action: { onTap(number) }) {
                Text("Blank")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(AppDangerButtonStyle())
            .accessibilityLabel("Blank tile")
        } else {
            Button(action: { onTap(number) }) {
                Text("\(number)")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(AppSecondaryButtonStyle())
            .accessibilityLabel("Number \(number)")
        }
    }
}

// MARK: - Reusable twisty puzzle UI

struct TwistyPuzzleInputView: View {
    @State private var selectedPuzzle: TwistyPuzzleKind = .threeByThree
    @State private var scrambleNotation = "R U R' U'"
    @State private var selectedSticker = "U"
    @State private var currentState = CubeState.solved3x3
    @State private var solveResult: CubeSolveResult?
    @State private var notationError: String?
    @State private var isSolving = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Twisty Puzzles")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: 0xccffff))

                    Picker("Puzzle", selection: $selectedPuzzle) {
                        ForEach(TwistyPuzzleKind.allCases) { puzzle in
                            Text(puzzle.displayName).tag(puzzle)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedPuzzle) { _ in resetForSelectedPuzzle() }

                    TwistyStickerInputGrid(state: currentState, selectedSticker: $selectedSticker) { index in
                        setSticker(at: index)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scramble notation")
                            .foregroundColor(AppTheme.primaryText)
                            .font(.headline)
                        TextField("Example: U R F", text: $scrambleNotation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text(selectedPuzzle.notation.helpText)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Text("Supported: \(selectedPuzzle.notation.supportedMovesText)")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    if let notationError {
                        Text(notationError)
                            .foregroundColor(Color(hex: 0xff99cc))
                    }

                    HStack(spacing: 12) {
                        Button("Apply Scramble") { applyScramble() }
                            .buttonStyle(AppSecondaryButtonStyle())

                        Button("Solve") { solveCurrentPuzzle() }
                            .buttonStyle(AppPrimaryButtonStyle())
                            .disabled(!selectedPuzzle.isSolveEnabled || isSolving)
                    }

                    if isSolving {
                        HStack {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Solving off the main thread…")
                                .foregroundColor(AppTheme.secondaryText)
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
        selectedSticker = selectedPuzzle.faces.first ?? "U"
        scrambleNotation = selectedPuzzle.notation.sampleScramble
        notationError = selectedPuzzle.isSolveEnabled ? nil : "\(selectedPuzzle.displayName) has a registered placeholder architecture; solving is not implemented yet."
    }

    private func applyScramble() {
        notationError = nil
        solveResult = nil
        switch TwistyMoveNotation.parse(scrambleNotation, spec: selectedPuzzle.notation) {
        case .success(let moves):
            switch selectedPuzzle {
            case .twoByTwo:
                currentState = TwoByTwoMoveEngine.apply(moves.map(\.notation), to: .solved2x2)
            case .threeByThree:
                currentState = Cube3x3MoveEngine.apply(moves.map(\.notation), to: .solved3x3)
            case .pyraminx:
                currentState = PyraminxMoveEngine.apply(moves, to: .solvedPyraminx)
            case .skewb:
                currentState = SkewbMoveEngine.apply(moves, to: .solvedSkewb)
            default:
                currentState = CubeState.solved(selectedPuzzle)
                notationError = "Scramble replay is reserved in the \(selectedPuzzle.displayName) placeholder architecture."
            }
        case .failure(let error): notationError = error.localizedDescription
        }
    }


    private func setSticker(at index: Int) {
        guard !fixedStickerIndices.contains(index) else { return }
        var stickers = currentState.stickers
        guard stickers.indices.contains(index) else { return }
        stickers[index] = selectedSticker
        currentState = CubeState(puzzle: selectedPuzzle, stickers: stickers)
        solveResult = nil
        notationError = nil
    }

    private var fixedStickerIndices: Set<Int> {
        guard selectedPuzzle == .threeByThree else { return [] }
        return [4, 13, 22, 31, 40, 49]
    }

    private var solveOptions: CubeSolveOptions {
        switch selectedPuzzle {
        case .threeByThree:
            return CubeSolveOptions(timeout: 10, maxDepth: 24, maxNodes: 1_000_000, includeStepStates: false)
        case .pyraminx, .skewb:
            return CubeSolveOptions(timeout: 5, maxDepth: 12, maxNodes: 150_000, includeStepStates: true)
        default:
            return CubeSolveOptions(timeout: 5, maxDepth: 14, maxNodes: 75_000, includeStepStates: false)
        }
    }

    private func solveCurrentPuzzle() {
        notationError = nil
        isSolving = true
        SolverDiagnosticsStore.shared.record(modeName: selectedPuzzle.displayName, state: .solving, detail: "Twisty solve started.")
        CubeSolvingService.shared.solve(currentState, options: solveOptions) { result in
            isSolving = false
            solveResult = result
            SolverDiagnosticsStore.shared.record(modeName: selectedPuzzle.displayName, state: result.status.solveState, detail: result.failureReason ?? result.status.userFacingMessage)
        }
    }
}

struct TwistyStickerInputGrid: View {
    let state: CubeState
    @Binding var selectedSticker: String
    let onStickerTap: (Int) -> Void

    private var faces: [String] { state.puzzle.faces }
    private var centerIndices: Set<Int> { state.puzzle == .threeByThree ? [4, 13, 22, 31, 40, 49] : [] }
    private var perFace: Int { max(1, (state.puzzle.stickerCount ?? state.stickers.count) / max(1, faces.count)) }
    private var faceEntries: [(offset: Int, element: String)] { Array(faces.enumerated()) }
    private var faceGridColumns: [GridItem] { [GridItem(.adaptive(minimum: 96), spacing: 10)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            stickerPicker
            stickerInputGrid
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Twisty sticker input")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            Text("Choose a face label, then tap stickers in the reusable puzzle net. Fixed centers are locked when the puzzle requires them.")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
    }

    private var stickerPicker: some View {
        HStack(spacing: 8) {
            ForEach(faces, id: \.self) { face in
                stickerPickerButton(for: face)
            }
        }
    }

    private func stickerPickerButton(for face: String) -> some View {
        Button(face) { selectedSticker = face }
            .font(.caption.bold())
            .frame(width: 34, height: 34)
            .background(stickerColor(face))
            .foregroundColor(.black)
            .overlay(selectionOverlay(for: face))
            .cornerRadius(8)
    }

    private func selectionOverlay(for face: String) -> some View {
        let strokeColor = selectedSticker == face ? Color(hex: 0xccffff) : Color.clear
        return RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 3)
    }

    private var stickerInputGrid: some View {
        LazyVGrid(columns: faceGridColumns, spacing: 10) {
            ForEach(faceEntries, id: \.offset) { entry in
                faceInputView(faceIndex: entry.offset, face: entry.element)
            }
        }
    }

    private func faceInputView(faceIndex: Int, face: String) -> some View {
        VStack(spacing: 6) {
            Text(face)
                .foregroundColor(AppTheme.secondaryText)
                .font(.caption)

            LazyVGrid(columns: faceColumns, spacing: 4) {
                ForEach(0..<perFace, id: \.self) { offset in
                    stickerButton(stickerIndex: faceIndex * perFace + offset)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }

    private func stickerButton(stickerIndex: Int) -> some View {
        let sticker = state.stickers.indices.contains(stickerIndex) ? state.stickers[stickerIndex] : "?"
        let isCenterSticker = centerIndices.contains(stickerIndex)

        return Button(action: { onStickerTap(stickerIndex) }) {
            Text(sticker)
                .font(.caption2.bold())
                .frame(width: 22, height: 22)
                .background(stickerColor(sticker))
                .foregroundColor(.black)
                .cornerRadius(5)
                .opacity(isCenterSticker ? 0.7 : 1)
        }
        .disabled(isCenterSticker)
    }

    private var faceColumns: [GridItem] {
        let side = Int(ceil(sqrt(Double(perFace))))
        return Array(repeating: GridItem(.fixed(22), spacing: 4), count: side)
    }

    private func stickerColor(_ label: String) -> Color {
        switch label {
        case "U": return .white
        case "R": return Color(hex: 0xff9999)
        case "F": return Color(hex: 0x99ff99)
        case "D": return Color(hex: 0xffff99)
        case "L": return Color(hex: 0xffcc99)
        case "B": return Color(hex: 0x99ccff)
        case "uR", "uL", "dR", "dL", "bR", "bL", "M": return Color(hex: 0xccccff)
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
                .foregroundColor(AppTheme.primaryText)
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
                .foregroundColor(AppTheme.secondaryText)
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
                .foregroundColor(AppTheme.primaryText)
            if moves.isEmpty {
                Text("Already solved.")
                    .foregroundColor(AppTheme.secondaryText)
            } else {
                ForEach(Array(moves.enumerated()), id: \.offset) { index, move in
                    Text("\(index + 1). \(move)")
                        .foregroundColor(AppTheme.primaryText)
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
                .foregroundColor(AppTheme.secondaryText)
            if let failureReason = result.failureReason {
                Text(failureReason)
                    .foregroundColor(AppTheme.primaryText)
            }
            TwistyMoveListView(moves: result.moves)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

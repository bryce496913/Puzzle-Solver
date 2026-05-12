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
    private var tileSize: CGFloat {
        switch selectedKind {
        case .threeByThree: return 60
        case .fourByFour: return 48
        case .fiveByFive: return 40
        }
    }
    private var keypadColumns: [GridItem] { Array(repeating: GridItem(.fixed(58), spacing: 10), count: puzzleSize) }

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
                .accessibilityHint(selectedKind.solverAvailable ? "Loads a valid sample puzzle so you can preview solving." : "Loads a safe placeholder board for the planned solver.")

                if !selectedKind.solverAvailable {
                    Text("This solver is planned for a future update.")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                }

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
        let preset: SlidingPuzzleBoard
        switch selectedKind {
        case .threeByThree:
            preset = PuzzlePresets.sliding3x3Medium
        case .fourByFour:
            preset = PuzzlePresets.sliding4x4Medium
        case .fiveByFive:
            preset = PuzzlePresets.sliding5x5Placeholder
        }
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
        .frame(maxWidth: CGFloat(size) * 72)
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
    @State private var selectedStickerIndex: Int?
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

                    TwistyStickerInputGrid(state: currentState, selectedSticker: $selectedSticker, selectedStickerIndex: $selectedStickerIndex) { index in
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
                            .disabled(isSolving)
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
        selectedStickerIndex = nil
        scrambleNotation = selectedPuzzle.notation.sampleScramble
        notationError = selectedPuzzle.isSolveEnabled ? nil : "This solver is planned for a future update."
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
    @Binding var selectedStickerIndex: Int?
    let onStickerTap: (Int) -> Void

    private var faces: [String] { state.puzzle.faces }
    private var centerIndices: Set<Int> { state.puzzle == .threeByThree ? [4, 13, 22, 31, 40, 49] : [] }
    private var perFace: Int { max(1, (state.puzzle.stickerCount ?? state.stickers.count) / max(1, faces.count)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            CubeOrientationGuideView(puzzle: state.puzzle)
            CubeColorLegendView(selectedSticker: $selectedSticker, availableStickers: faces)
            SelectedStickerInfoView(state: state, selectedStickerIndex: selectedStickerIndex)
            puzzleInputLayout
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Twisty sticker input")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            Text("Choose a color, then tap stickers in the labeled net. Fixed centers are dimmed when the puzzle requires them.")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
    }

    @ViewBuilder
    private var puzzleInputLayout: some View {
        switch state.puzzle {
        case .twoByTwo, .threeByThree, .skewb, .fourByFour, .fiveByFive:
            cubeNetLayout
        case .pyraminx:
            pyraminxLayout
        default:
            placeholderLayout
        }
    }

    private var cubeNetLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    netSpacer
                    faceGroup(for: "U", helperText: "Top face")
                    netSpacer
                    netSpacer
                }

                HStack(alignment: .top, spacing: 12) {
                    faceGroup(for: "L", helperText: "Left side")
                    faceGroup(for: "F", helperText: "Facing you")
                    faceGroup(for: "R", helperText: "Right side")
                    faceGroup(for: "B", helperText: "Back face")
                }

                HStack(spacing: 12) {
                    netSpacer
                    faceGroup(for: "D", helperText: "Bottom face")
                    netSpacer
                    netSpacer
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("Cube net ordered Up, Left, Front, Right, Back, Down")
    }

    private var pyraminxLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pyraminx faces are shown as separated triangular sections. Hold one face toward you as Front, then rotate the puzzle to enter the remaining labeled faces exactly as seen.")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.55), lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 12)], spacing: 12) {
                ForEach(Array(faces.enumerated()), id: \.offset) { entry in
                    faceGroup(faceIndex: entry.offset, face: entry.element, helperText: pyraminxHelper(for: entry.element), triangular: true)
                }
            }
        }
    }

    private var placeholderLayout: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 12)], spacing: 12) {
            ForEach(Array(faces.enumerated()), id: \.offset) { entry in
                faceGroup(faceIndex: entry.offset, face: entry.element, helperText: placeholderHelper(for: entry.element), triangular: false)
            }
        }
    }

    private var netSpacer: some View {
        Color.clear
            .frame(width: CubeFaceGroupView.groupWidth(for: perFace), height: 1)
            .accessibilityHidden(true)
    }

    private func faceGroup(for face: String, helperText: String) -> some View {
        guard let faceIndex = faces.firstIndex(of: face) else {
            return AnyView(netSpacer)
        }
        return AnyView(faceGroup(faceIndex: faceIndex, face: face, helperText: helperText, triangular: false))
    }

    private func faceGroup(faceIndex: Int, face: String, helperText: String, triangular: Bool) -> some View {
        let start = faceIndex * perFace
        let stickers = (0..<perFace).map { offset -> String in
            let index = start + offset
            return state.stickers.indices.contains(index) ? state.stickers[index] : "?"
        }

        return CubeFaceGroupView(
            face: face,
            stickers: stickers,
            perFace: perFace,
            faceIndex: faceIndex,
            helperText: helperText,
            selectedStickerIndex: selectedStickerIndex,
            fixedStickerIndices: centerIndices,
            isTriangular: triangular,
            onStickerTap: selectSticker
        )
    }

    private func selectSticker(_ stickerIndex: Int) {
        selectedStickerIndex = stickerIndex
        guard !centerIndices.contains(stickerIndex) else { return }
        onStickerTap(stickerIndex)
    }

    private func pyraminxHelper(for face: String) -> String {
        switch face {
        case "U": return "Upper triangle"
        case "L": return "Left triangle"
        case "R": return "Right triangle"
        case "B": return "Back triangle"
        default: return "Triangular face"
        }
    }

    private func placeholderHelper(for face: String) -> String {
        switch face {
        case "U": return "Upper layer"
        case "D": return "Lower layer"
        case "M": return "Middle slice"
        default: return "Face reference"
        }
    }
}

struct CubeFaceLabelView: View {
    let abbreviation: String
    let fullName: String
    let helperText: String?

    init(abbreviation: String, fullName: String? = nil, helperText: String? = nil) {
        self.abbreviation = abbreviation
        self.fullName = fullName ?? TwistyVisualMetadata.fullName(for: abbreviation)
        self.helperText = helperText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(abbreviation)
                    .font(.headline.weight(.black))
                    .foregroundColor(AppTheme.highlight)
                Text(fullName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
            }
            if let helperText = helperText {
                Text(helperText)
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CubeOrientationGuideView: View {
    let puzzle: TwistyPuzzleKind

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Orientation guide", systemImage: "cube.transparent")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            ForEach(guideLines, id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(AppTheme.highlight)
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)
                    Text(line)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.65), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var guideLines: [String] {
        switch puzzle {
        case .pyraminx:
            return [
                "Hold the Pyraminx with one triangular face pointing toward you.",
                "Enter each triangular face exactly as you see it before rotating to the next face.",
                "Use matching tip and center colors as the face reference when available."
            ]
        default:
            return [
                "Hold the cube with the front face facing you.",
                "Enter each face exactly as you see it.",
                "Use the center color as the face reference when available."
            ]
        }
    }
}

struct CubeColorLegendView: View {
    @Binding var selectedSticker: String
    let availableStickers: [String]

    private var legendFaces: [String] {
        ["U", "D", "F", "B", "R", "L"].filter { availableStickers.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Color legend")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                selectedColorSummary
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 8)], spacing: 8) {
                ForEach(legendFaces, id: \.self) { face in
                    Button(action: { selectedSticker = face }) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(TwistyVisualMetadata.color(for: face))
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.black.opacity(0.35), lineWidth: 1))
                            Text(TwistyVisualMetadata.colorName(for: face))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.primaryText)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .background(selectedSticker == face ? AppTheme.highlight.opacity(0.28) : AppTheme.surface.opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selectedSticker == face ? AppTheme.highlight : AppTheme.accent.opacity(0.38), lineWidth: selectedSticker == face ? 2.5 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(AppTheme.surface.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var selectedColorSummary: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(TwistyVisualMetadata.color(for: selectedSticker))
                .frame(width: 24, height: 18)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(AppTheme.text, lineWidth: 1))
            Text("Selected: \(TwistyVisualMetadata.colorName(for: selectedSticker))")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.primaryText)
        }
    }
}

struct CubeFaceGroupView: View {
    let face: String
    let stickers: [String]
    let perFace: Int
    let faceIndex: Int
    let helperText: String
    let selectedStickerIndex: Int?
    let fixedStickerIndices: Set<Int>
    let isTriangular: Bool
    let onStickerTap: (Int) -> Void

    private var side: Int { max(1, Int(ceil(sqrt(Double(perFace))))) }
    private var columns: [GridItem] { Array(repeating: GridItem(.fixed(30), spacing: 5), count: side) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CubeFaceLabelView(abbreviation: face, helperText: helperText)

            if isTriangular {
                triangularStickerGrid
            } else {
                squareStickerGrid
            }
        }
        .padding(10)
        .frame(width: Self.groupWidth(for: perFace), alignment: .topLeading)
        .background(AppTheme.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.8), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var squareStickerGrid: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(Array(stickers.enumerated()), id: \.offset) { entry in
                stickerButton(offset: entry.offset, sticker: entry.element)
            }
        }
    }

    private var triangularStickerGrid: some View {
        VStack(spacing: 5) {
            ForEach(triangularRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 5) {
                    ForEach(triangularRows[rowIndex], id: \.self) { offset in
                        if stickers.indices.contains(offset) {
                            stickerButton(offset: offset, sticker: stickers[offset])
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var triangularRows: [[Int]] {
        let preferred = [[0], [1, 2], [3, 4, 5], [6, 7, 8]]
        let visible = preferred.map { $0.filter { $0 < stickers.count } }.filter { !$0.isEmpty }
        if visible.flatMap({ $0 }).count == stickers.count { return visible }
        return stride(from: 0, to: stickers.count, by: 3).map { start in
            Array(start..<min(start + 3, stickers.count))
        }
    }

    private func stickerButton(offset: Int, sticker: String) -> some View {
        let stickerIndex = faceIndex * perFace + offset
        let isSelected = selectedStickerIndex == stickerIndex
        let isFixed = fixedStickerIndices.contains(stickerIndex)
        return Button(action: { onStickerTap(stickerIndex) }) {
            Text(sticker)
                .font(.caption2.weight(.black))
                .minimumScaleFactor(0.6)
                .foregroundColor(.black)
                .frame(width: 30, height: 30)
                .background(TwistyVisualMetadata.color(for: sticker))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? AppTheme.highlight : Color.black.opacity(0.65), lineWidth: isSelected ? 3 : 1.5)
                )
                .overlay(alignment: .topTrailing) {
                    if isFixed {
                        Circle()
                            .fill(AppTheme.text.opacity(0.82))
                            .frame(width: 6, height: 6)
                            .padding(3)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: isSelected ? AppTheme.highlight.opacity(0.75) : .clear, radius: 5)
                .opacity(isFixed ? 0.72 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(TwistyVisualMetadata.fullName(for: face)) face row \(offset / side + 1) column \(offset % side + 1)")
    }

    static func groupWidth(for perFace: Int) -> CGFloat {
        let side = max(1, Int(ceil(sqrt(Double(perFace)))))
        return CGFloat(side * 30 + max(0, side - 1) * 5 + 20)
    }
}

struct SelectedStickerInfoView: View {
    let state: CubeState
    let selectedStickerIndex: Int?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .foregroundColor(AppTheme.highlight)
            Text(selectionText)
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.primaryText)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(AppTheme.surface.opacity(0.86))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.highlight.opacity(0.62), lineWidth: 1.25)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var selectionText: String {
        guard let selectedStickerIndex,
              let stickerCount = state.puzzle.stickerCount,
              stickerCount > 0,
              selectedStickerIndex < state.stickers.count else {
            return "Selected: tap a sticker to see its face, row, and column."
        }
        let perFace = max(1, stickerCount / max(1, state.puzzle.faces.count))
        let faceIndex = selectedStickerIndex / perFace
        let offset = selectedStickerIndex % perFace
        let side = max(1, Int(ceil(sqrt(Double(perFace)))))
        let face = state.puzzle.faces.indices.contains(faceIndex) ? state.puzzle.faces[faceIndex] : "?"
        return "Selected: \(TwistyVisualMetadata.fullName(for: face)) face, row \(offset / side + 1), column \(offset % side + 1)"
    }
}

private enum TwistyVisualMetadata {
    static func fullName(for face: String) -> String {
        switch face {
        case "U": return "Up"
        case "F": return "Front"
        case "R": return "Right"
        case "L": return "Left"
        case "B": return "Back"
        case "D": return "Down"
        case "M": return "Middle"
        case "uR": return "Upper Right"
        case "uL": return "Upper Left"
        case "dR": return "Lower Right"
        case "dL": return "Lower Left"
        case "bR": return "Back Right"
        case "bL": return "Back Left"
        default: return face
        }
    }

    static func colorName(for face: String) -> String {
        switch face {
        case "U": return "White"
        case "D": return "Yellow"
        case "F": return "Green"
        case "B": return "Blue"
        case "R": return "Red"
        case "L": return "Orange"
        default: return "Unassigned"
        }
    }

    static func color(for face: String) -> Color {
        switch face {
        case "U": return .white
        case "D": return Color(hex: 0xffe45c)
        case "F": return Color(hex: 0x42d66b)
        case "B": return Color(hex: 0x4aa3ff)
        case "R": return Color(hex: 0xff5b5b)
        case "L": return Color(hex: 0xffa23a)
        case "?", "": return Color.black.opacity(0.78)
        default: return Color(hex: 0xcfc7ff)
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

//
//  NewPuzzleView.swift
//  Puzzle Solver
//
//  Sliding puzzle V1 picker and 3×3 input flow.
//

import SwiftUI

struct NewPuzzleView: View {
    private let descriptors = PuzzleAvailabilityCatalog.descriptors(in: .sliding)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.sliding.rawValue, subtitle: PuzzleCategory.sliding.subtitle) {
            LazyVStack(spacing: 12) {
                ForEach(descriptors) { descriptor in
                    NavigationLink(destination: destination(for: descriptor)) {
                        AppPuzzleCard(descriptor: descriptor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!descriptor.status.isInteractive)
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for descriptor: PuzzleAvailabilityDescriptor) -> some View {
        if descriptor.id == "sliding-3x3", descriptor.status == .active {
            SlidingPuzzleInputView(descriptor: descriptor)
        } else {
            AppPlaceholderScreen(descriptor: descriptor)
        }
    }
}

struct SlidingPuzzleInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let descriptor: PuzzleAvailabilityDescriptor

    @State private var selectedTile: Int? = 0
    @State private var gridNumbers: [[Int?]] = SlidingPuzzleInputView.emptyGrid
    @State private var blankTile: Int?
    @State private var initialState: [[Int?]] = SlidingPuzzleInputView.emptyGrid
    @State private var validationMessage = "Select a tile, then choose a number or blank."

    private let puzzleSize = 3
    private let keypadColumns = Array(repeating: GridItem(.flexible(minimum: 54), spacing: 10), count: 3)
    private var usedNumbers: Set<Int> { Set(gridNumbers.flatMap { $0.compactMap { $0 } }) }
    private var missingNumbers: [Int] { (1..<9).filter { !usedNumbers.contains($0) } }
    private var unassignedTileCount: Int {
        gridNumbers.enumerated().reduce(0) { total, rowPair in
            let (row, values) = rowPair
            return total + values.enumerated().filter { column, value in
                value == nil && blankTile != row * puzzleSize + column
            }.count
        }
    }
    private var isComplete: Bool { usedNumbers.count == 8 && blankTile != nil && unassignedTileCount == 0 }
    private var board: SlidingPuzzleBoard? { SlidingPuzzleBoard.fromGrid(gridNumbers, size: puzzleSize) }
    private var validationResult: SlidingPuzzleValidationResult? { board.map(SlidingPuzzlePlaceholderValidator.validate) }
    private var canSolve: Bool { isComplete && validationResult?.state == .solved }

    var body: some View {
        AppScreenContainer(title: descriptor.title, subtitle: descriptor.shortDescription) {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader("Board input", subtitle: "Select a tile, then choose a number or blank.")

                SlidingBoardInputPreview(
                    gridNumbers: gridNumbers,
                    blankTile: blankTile,
                    selectedTile: selectedTile,
                    onSelect: selectTile(row:column:)
                )
                .frame(maxWidth: .infinity)

                Text(validationText)
                    .font(AppTextStyle.h3)
                    .foregroundColor(canSolve ? AppTheme.text : AppTheme.highlight)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                AppSectionHeader("Available tiles", subtitle: "Used numbers are dimmed. Choose Blank for the empty space.")

                LazyVGrid(columns: keypadColumns, spacing: 10) {
                    ForEach(1...8, id: \.self) { number in
                        SlidingKeypadButton(
                            title: "\(number)",
                            isUsed: usedNumbers.contains(number),
                            isHighlighted: selectedTile != nil
                        ) { assign(number) }
                        .disabled(selectedTile == nil || usedNumbers.contains(number))
                    }

                    SlidingKeypadButton(
                        title: "Blank",
                        isUsed: !canPlaceBlank,
                        isHighlighted: selectedTile != nil,
                        isBlank: true
                    ) { assignBlank() }
                    .disabled(selectedTile == nil || !canPlaceBlank)
                }

                HStack(spacing: 10) {
                    Button("Load Example") { loadExample() }
                        .buttonStyle(AppSecondaryButtonStyle())

                    Button("Reset") { resetPuzzle() }
                        .buttonStyle(AppResetButtonStyle())
                }

                if canSolve {
                    NavigationLink(destination: SolvingView(initialState: initialState, puzzleSize: puzzleSize)) {
                        Text("Solve 3×3 Puzzle")
                            .appButtonLabel()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.96)))
                } else {
                    Text("Solve unlocks when all numbers 1–8 and one blank are placed with no duplicates.")
                        .appParagraph()
                        .padding(.vertical, 4)
                }

                Button("Back") { dismiss() }
                    .buttonStyle(AppSecondaryButtonStyle())
            }
            .appCardStyle()
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: canSolve)
        .onChange(of: gridNumbers) { _ in updateInitialState() }
    }

    private var canPlaceBlank: Bool {
        guard let selectedTile else { return false }
        return blankTile == nil || blankTile == selectedTile
    }

    private var validationText: String {
        if let result = validationResult, isComplete {
            switch result.state {
            case .solved: return "Ready to solve."
            case .invalid: return result.message
            case .unsolvable: return "This layout is not solvable. Try swapping two numbered tiles."
            default: return result.message
            }
        }
        if !missingNumbers.isEmpty {
            return "Missing: \(missingNumbers.map(String.init).joined(separator: ", "))"
        }
        if blankTile == nil {
            return "Choose one tile and mark it as Blank."
        }
        if unassignedTileCount > 0 {
            return "Fill \(unassignedTileCount) empty tile\(unassignedTileCount == 1 ? "" : "s") before solving."
        }
        return validationMessage
    }

    private func selectTile(row: Int, column: Int) {
        selectedTile = row * puzzleSize + column
        validationMessage = "Tile row \(row + 1), column \(column + 1) selected. Choose a number or blank."
    }

    private func assign(_ number: Int) {
        guard let selectedTile, !usedNumbers.contains(number) else { return }
        let row = selectedTile / puzzleSize
        let column = selectedTile % puzzleSize
        gridNumbers[row][column] = number
        if blankTile == selectedTile { blankTile = nil }
        updateInitialState()
        self.selectedTile = nextEmptyTile(after: selectedTile)
        validationMessage = "Placed \(number)."
    }

    private func assignBlank() {
        guard let selectedTile else { return }
        let row = selectedTile / puzzleSize
        let column = selectedTile % puzzleSize
        gridNumbers[row][column] = nil
        blankTile = selectedTile
        updateInitialState()
        self.selectedTile = nextEmptyTile(after: selectedTile)
        validationMessage = "Marked row \(row + 1), column \(column + 1) as the blank tile."
    }


    private func nextEmptyTile(after index: Int) -> Int? {
        let total = puzzleSize * puzzleSize
        for offset in 1...total {
            let candidate = (index + offset) % total
            let row = candidate / puzzleSize
            let column = candidate % puzzleSize
            if gridNumbers[row][column] == nil && candidate != index && candidate != blankTile { return candidate }
        }
        return nil
    }

    private func updateInitialState() {
        if canSolve { initialState = gridNumbers }
    }

    private func loadExample() {
        gridNumbers = PuzzlePresets.sliding3x3Medium.toGrid()
        blankTile = Self.blankTileIndex(in: gridNumbers, size: puzzleSize)
        initialState = gridNumbers
        selectedTile = nil
        validationMessage = "Example loaded and ready to solve."
    }

    private func resetPuzzle() {
        gridNumbers = Self.emptyGrid
        blankTile = nil
        initialState = Self.emptyGrid
        selectedTile = 0
        validationMessage = "Select a tile, then choose a number or blank."
    }

    private static let emptyGrid = Array(repeating: Array(repeating: Optional<Int>.none, count: 3), count: 3)

    private static func blankTileIndex(in grid: [[Int?]], size: Int) -> Int? {
        for row in 0..<size {
            for column in 0..<size where grid[row][column] == nil {
                return row * size + column
            }
        }
        return nil
    }
}

private struct SlidingBoardInputPreview: View {
    let gridNumbers: [[Int?]]
    let blankTile: Int?
    let selectedTile: Int?
    let onSelect: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { column in
                        let value = gridNumbers[row][column]
                        let index = row * 3 + column
                        let isBlankTile = blankTile == index
                        Button(action: { onSelect(row, column) }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(value == nil ? AppTheme.background : AppTheme.accent.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedTile == index ? AppTheme.highlight : AppTheme.text.opacity(value == nil ? 0.42 : 0.08), lineWidth: selectedTile == index ? 3 : 1)
                                    )

                                Text(value.map(String.init) ?? (isBlankTile ? "Blank" : "Empty"))
                                    .font(AppTextStyle.h2)
                                    .foregroundColor(AppTheme.text)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(height: 68)
                        }
                        .buttonStyle(AppSecondaryButtonStyle())
                        .accessibilityLabel(value.map { "Tile \($0)" } ?? (isBlankTile ? "Blank tile" : "Empty tile"))
                        .accessibilityValue(selectedTile == index ? "Selected" : "Not selected")
                    }
                }
            }
        }
    }
}

private struct SlidingKeypadButton: View {
    let title: String
    let isUsed: Bool
    let isHighlighted: Bool
    var isBlank = false
    let action: () -> Void

    var body: some View {
        if isBlank {
            keypadButton.buttonStyle(AppDangerButtonStyle(isDisabledAppearance: isUsed))
        } else {
            keypadButton.buttonStyle(AppSecondaryButtonStyle(isDisabledAppearance: isUsed))
        }
    }

    private var keypadButton: some View {
        Button(action: action) {
            Text(title)
                .appButtonLabel()
                .foregroundColor(AppTheme.text.opacity(isUsed ? 0.48 : 1))
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isHighlighted && !isUsed ? AppTheme.highlight : AppTheme.text.opacity(0.18), lineWidth: 1.5)
                )
        }
    }
}

struct NewPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { NewPuzzleView() }
    }
}

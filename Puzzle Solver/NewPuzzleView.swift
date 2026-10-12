//
//  NewPuzzleView.swift
//  Puzzle Solver
//
//  Sliding puzzle picker and input flow.
//

import SwiftUI

struct NewPuzzleView: View {
    private let descriptors = PuzzleAvailabilityCatalog.activeDescriptors(in: .sliding)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.sliding.rawValue, subtitle: PuzzleCategory.sliding.subtitle) {
            LazyVStack(spacing: 12) {
                ForEach(descriptors) { descriptor in
                    NavigationLink(destination: ProductionPuzzleDestinationView(descriptor: descriptor)) {
                        AppPuzzleCard(descriptor: descriptor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!descriptor.status.isInteractive)
                }
            }
        }
    }

}

struct SlidingPuzzleInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let descriptor: PuzzleAvailabilityDescriptor

    @State private var selectedTile: Int? = 0
    @State private var gridNumbers: [[Int?]]
    @State private var blankTile: Int?
    @State private var initialState: [[Int?]]
    @State private var validationMessage = "Select a tile, then choose a number or blank."

    private let puzzleSize: Int
    private var usedNumbers: Set<Int> { Set(gridNumbers.flatMap { $0.compactMap { $0 } }) }
    private var missingNumbers: [Int] { (1..<(puzzleSize * puzzleSize)).filter { !usedNumbers.contains($0) } }
    private var unassignedTileCount: Int {
        gridNumbers.enumerated().reduce(0) { total, rowPair in
            let (row, values) = rowPair
            return total + values.enumerated().filter { column, value in
                value == nil && blankTile != row * puzzleSize + column
            }.count
        }
    }
    private var isComplete: Bool { usedNumbers.count == puzzleSize * puzzleSize - 1 && blankTile != nil && unassignedTileCount == 0 }
    private var board: SlidingPuzzleBoard? { SlidingPuzzleBoard.fromGrid(gridNumbers, size: puzzleSize) }
    private var validationResult: SlidingPuzzleValidationResult? { board.map(SlidingPuzzlePlaceholderValidator.validate) }
    private var canSolve: Bool { isComplete && validationResult?.state == .solved }

    init(descriptor: PuzzleAvailabilityDescriptor) {
        self.descriptor = descriptor
        let size = Int(descriptor.id.suffix(3).prefix(1)) ?? 3
        puzzleSize = size
        let grid = Self.emptyGrid(size: size)
        _gridNumbers = State(initialValue: grid)
        _initialState = State(initialValue: grid)
    }

    var body: some View {
        AppScreenContainer(title: descriptor.title, subtitle: descriptor.shortDescription) {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader("Board input", subtitle: "Select a tile, then choose a number or blank.")

                SlidingBoardInputPreview(
                    gridNumbers: gridNumbers,
                    blankTile: blankTile,
                    selectedTile: selectedTile,
                    size: puzzleSize,
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

                SlidingTilePicker(
                    size: puzzleSize,
                    usedNumbers: usedNumbers,
                    hasSelectedCell: selectedTile != nil,
                    canPlaceBlank: canPlaceBlank,
                    onNumber: assign,
                    onBlank: assignBlank
                )

                HStack(spacing: 10) {
                    Button("Load Example") { loadExample() }
                        .buttonStyle(AppSecondaryButtonStyle())

                    Button("Reset") { resetPuzzle() }
                        .buttonStyle(AppResetButtonStyle())
                }

                if canSolve {
                    NavigationLink(destination: SolvingView(initialState: initialState, puzzleSize: puzzleSize)) {
                        Text("Solve \(puzzleSize)×\(puzzleSize) Puzzle")
                            .appButtonLabel()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.96)))
                } else {
                    Text("Solve unlocks when every number and one blank are placed with no duplicates.")
                        .appParagraph()
                        .padding(.vertical, 4)
                }

                Button("Back") { dismiss() }
                    .buttonStyle(AppBackButtonStyle())
            }
            .appCardStyle()
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: canSolve)
        .appOnChange(of: gridNumbers) { _ in updateInitialState() }
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
        switch puzzleSize {
        case 3: gridNumbers = PuzzlePresets.sliding3x3Medium.toGrid()
        case 4: gridNumbers = PuzzlePresets.sliding4x4Medium.toGrid()
        default: gridNumbers = PuzzlePresets.sliding5x5OneMove.toGrid()
        }
        blankTile = Self.blankTileIndex(in: gridNumbers, size: puzzleSize)
        initialState = gridNumbers
        selectedTile = nil
        validationMessage = "Example loaded and ready to solve."
    }

    private func resetPuzzle() {
        gridNumbers = Self.emptyGrid(size: puzzleSize)
        blankTile = nil
        initialState = Self.emptyGrid(size: puzzleSize)
        selectedTile = 0
        validationMessage = "Select a tile, then choose a number or blank."
    }

    private static func emptyGrid(size: Int) -> [[Int?]] {
        Array(repeating: Array(repeating: Optional<Int>.none, count: size), count: size)
    }

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
    let size: Int
    let onSelect: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<size, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<size, id: \.self) { column in
                        let value = gridNumbers[row][column]
                        let index = row * size + column
                        let isBlankTile = blankTile == index
                        Button(action: { onSelect(row, column) }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(value == nil ? AppTheme.background : AppTheme.accent.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedTile == index ? AppTheme.highlight : AppTheme.text.opacity(value == nil ? 0.42 : 0.08), lineWidth: selectedTile == index ? 3 : 1)
                                    )

                                Text(value.map(String.init) ?? (isBlankTile ? "—" : ""))
                                    .font(size == 3 ? AppTextStyle.h1 : AppTextStyle.h2)
                                    .foregroundColor(AppTheme.text)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                    .padding(2)
                            }
                            .frame(height: size == 3 ? 68 : (size == 4 ? 54 : 44))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(value.map { "Tile \($0)" } ?? (isBlankTile ? "Blank tile" : "Empty tile"))
                        .accessibilityValue(selectedTile == index ? "Selected" : "Not selected")
                        .accessibilityIdentifier("sliding-cell-\(row + 1)-\(column + 1)")
                    }
                }
            }
        }
    }
}

/// Compact selector shared by all shipping sliding-puzzle sizes.
private struct SlidingTilePicker: View {
    let size: Int
    let usedNumbers: Set<Int>
    let hasSelectedCell: Bool
    let canPlaceBlank: Bool
    let onNumber: (Int) -> Void
    let onBlank: () -> Void

    @ScaledMetric(relativeTo: .body) private var minimumTileWidth = 54.0

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumTileWidth), spacing: 6)], spacing: 6) {
            ForEach(1..<(size * size), id: \.self) { number in
                SlidingKeypadButton(title: "\(number)", isUsed: usedNumbers.contains(number)) {
                    onNumber(number)
                }
                .disabled(!hasSelectedCell || usedNumbers.contains(number))
                .accessibilityIdentifier("sliding-key-\(number)")
                .accessibilityLabel("Tile \(number)" + (usedNumbers.contains(number) ? ", already used" : ""))
            }

            SlidingKeypadButton(title: "Blank", isUsed: !canPlaceBlank, isBlank: true, action: onBlank)
                .disabled(!hasSelectedCell || !canPlaceBlank)
                .accessibilityIdentifier("sliding-key-blank")
                .accessibilityLabel("Blank tile")
        }
    }
}

private struct SlidingKeypadButton: View {
    let title: String
    let isUsed: Bool
    var isBlank = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(SlidingKeypadButtonStyle(isBlank: isBlank, isUsed: isUsed))
    }
}

private struct SlidingKeypadButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let isBlank: Bool
    let isUsed: Bool

    func makeBody(configuration: Configuration) -> some View {
        let accent = isBlank ? AppTheme.highlight : AppTheme.accent
        configuration.label
            .foregroundColor(AppTheme.text)
            .background(accent.opacity(configuration.isPressed ? 0.3 : (isBlank ? 0.18 : 0.06)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(accent, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isEnabled && !isUsed ? 1 : 0.4)
    }
}

struct NewPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { NewPuzzleView() }
    }
}

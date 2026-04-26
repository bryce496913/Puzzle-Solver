import SwiftUI

struct LogicPuzzlePickerView: View {
    private let puzzleTypes = LogicPuzzleType.allCases.map {
        LogicPuzzleCatalogItem(puzzleType: $0, subtitle: $0.availabilitySubtitle)
    }

    private var activePuzzles: [LogicPuzzleCatalogItem] {
        puzzleTypes.filter(\.isEnabled)
    }

    private var comingSoonPuzzles: [LogicPuzzleCatalogItem] {
        puzzleTypes.filter { !$0.isEnabled }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    TwistyScreenHeader(
                        title: "Logic Puzzles",
                        subtitle: "Choose a logic puzzle type"
                    )

                    if !activePuzzles.isEmpty {
                        sectionTitle("Available now")
                        ForEach(activePuzzles) { catalogItem in
                            NavigationLink {
                                destinationView(for: catalogItem.puzzleType)
                            } label: {
                                PuzzleTypeCard(
                                    title: catalogItem.title,
                                    subtitle: catalogItem.subtitle,
                                    icon: catalogItem.icon,
                                    isEnabled: true,
                                    accentVariant: .accent
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !comingSoonPuzzles.isEmpty {
                        sectionTitle("Coming soon")
                        ForEach(comingSoonPuzzles) { catalogItem in
                            NavigationLink {
                                destinationView(for: catalogItem.puzzleType)
                            } label: {
                                PuzzleTypeCard(
                                    title: catalogItem.title,
                                    subtitle: catalogItem.subtitle,
                                    icon: catalogItem.icon,
                                    isEnabled: false,
                                    accentVariant: .highlight
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .navigationTitle("Logic Puzzles")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appTextStyle(.paragraph)
            .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func destinationView(for puzzleType: LogicPuzzleType) -> some View {
        switch puzzleType {
        case .sudoku:
            SudokuEntryView()
        case .killerSudoku, .nonogram, .kakuro:
            LogicPuzzleComingSoonView(puzzleName: puzzleType.title)
        }
    }
}

private struct LogicPuzzleCatalogItem: Identifiable {
    let puzzleType: LogicPuzzleType
    let subtitle: String

    var id: LogicPuzzleType { puzzleType }
    var title: String { puzzleType.title }
    var icon: String { puzzleType.icon }
    var isEnabled: Bool { puzzleType.isEnabled }
}

struct SudokuEntryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var grid = SudokuGrid()
    @State private var selectedCellIndex: Int?
    @State private var isSolving = false
    @State private var feedbackMessage = "Select a cell, then use the keypad to enter values 1–9."
    @State private var validationMessage = ""

    private let solver = SudokuSolver()

    private var hasAtLeastOneValue: Bool {
        grid.cells.contains { $0 != SudokuGrid.emptyValue }
    }

    private var conflictingCellIndices: Set<Int> {
        SudokuValidation.conflictingIndices(in: grid)
    }

    private var isObviousInvalid: Bool {
        !conflictingCellIndices.isEmpty
    }

    private var canSolve: Bool {
        hasAtLeastOneValue && !isObviousInvalid && !isSolving
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.medium) {
                TwistyScreenHeader(
                    title: "Sudoku",
                    subtitle: "Enter your puzzle and solve when ready"
                )

                sudokuGridView
                    .appSurfaceCard()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(isObviousInvalid ? "There are duplicate values in a row, column, or 3×3 box." : "No obvious conflicts detected.")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(isObviousInvalid ? AppTheme.Colors.highlight : AppTheme.Colors.text.opacity(0.85))

                    if !validationMessage.isEmpty {
                        Text(validationMessage)
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.highlight)
                    }

                    Text(feedbackMessage)
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appSurfaceCard()

                sudokuKeypad
                    .appSurfaceCard()

                HStack(spacing: AppTheme.Spacing.medium) {
                    Button("Back") {
                        dismiss()
                    }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))

                    Button("Reset") {
                        resetBoard()
                    }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))

                    Button {
                        Task {
                            await solveCurrentPuzzle()
                        }
                    } label: {
                        if isSolving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Solve")
                        }
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!canSolve)
                    .opacity(canSolve ? 1 : 0.5)
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .navigationBarBackButtonHidden(true)
    }

    private var sudokuGridView: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let cellSize = boardSize / CGFloat(SudokuGrid.columnCount)

            ZStack(alignment: .topLeading) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: SudokuGrid.columnCount), spacing: 0) {
                    ForEach(Array(grid.cells.enumerated()), id: \.offset) { index, value in
                        SudokuCellView(
                            value: value,
                            isSelected: selectedCellIndex == index,
                            isRelatedToSelected: isRelatedToSelected(index),
                            isConflicting: conflictingCellIndices.contains(index)
                        )
                        .frame(width: cellSize, height: cellSize)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCellIndex = index
                            validationMessage = ""
                        }
                    }
                }

                SudokuGridLinesOverlay(cellSize: cellSize)
                    .allowsHitTesting(false)
            }
            .frame(width: boardSize, height: boardSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 330)
    }

    private var sudokuKeypad: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small), count: 3), spacing: AppTheme.Spacing.small) {
                ForEach(1...9, id: \.self) { value in
                    KeypadButton(
                        title: "\(value)",
                        isDisabled: selectedCellIndex == nil,
                        isSelected: selectedValue == value,
                        onTap: { assign(value: value) }
                    )
                }
            }

            KeypadButton(
                title: "Delete",
                isDisabled: selectedCellIndex == nil,
                isSelected: false,
                onTap: clearSelectedCell,
                subtitle: "Clear selected cell"
            )
        }
    }

    private var selectedValue: Int? {
        guard let selectedCellIndex else { return nil }
        let value = grid.cells[selectedCellIndex]
        return value == SudokuGrid.emptyValue ? nil : value
    }

    private func isRelatedToSelected(_ index: Int) -> Bool {
        guard let selectedCellIndex, selectedCellIndex != index else { return false }

        let selectedRow = selectedCellIndex / SudokuGrid.columnCount
        let selectedColumn = selectedCellIndex % SudokuGrid.columnCount
        let selectedBoxRow = selectedRow / SudokuGrid.boxSize
        let selectedBoxColumn = selectedColumn / SudokuGrid.boxSize

        let row = index / SudokuGrid.columnCount
        let column = index % SudokuGrid.columnCount
        let boxRow = row / SudokuGrid.boxSize
        let boxColumn = column / SudokuGrid.boxSize

        return row == selectedRow || column == selectedColumn || (boxRow == selectedBoxRow && boxColumn == selectedBoxColumn)
    }

    private func assign(value: Int) {
        guard let selectedCellIndex else {
            validationMessage = "Select a cell first."
            return
        }

        let row = selectedCellIndex / SudokuGrid.columnCount
        let column = selectedCellIndex % SudokuGrid.columnCount

        if !grid.canPlace(value, row: row, column: column) {
            validationMessage = "\(value) conflicts with this cell’s row, column, or box."
            return
        }

        let _ = grid.setValue(value, row: row, column: column)
        validationMessage = ""
    }

    private func clearSelectedCell() {
        guard let selectedCellIndex else {
            validationMessage = "Select a cell first."
            return
        }

        let row = selectedCellIndex / SudokuGrid.columnCount
        let column = selectedCellIndex % SudokuGrid.columnCount
        let _ = grid.setValue(SudokuGrid.emptyValue, row: row, column: column)
        validationMessage = ""
    }

    private func resetBoard() {
        grid = SudokuGrid()
        selectedCellIndex = nil
        validationMessage = ""
        feedbackMessage = "Board reset. Enter a new puzzle."
    }

    @MainActor
    private func solveCurrentPuzzle() async {
        isSolving = true
        defer { isSolving = false }

        let result = await solver.solveOffMainThread(grid)

        switch (result.validity, result.completion, result.output) {
        case (.invalid(let errors), _, _):
            feedbackMessage = errors.first?.localizedDescription ?? "This Sudoku input is invalid."
        case (.valid, .solved, let solved?):
            grid = solved
            feedbackMessage = "Solved successfully."
        case (.valid, .unsolved, _):
            feedbackMessage = "No solution exists for this puzzle."
        default:
            feedbackMessage = "Sudoku could not be solved."
        }
    }
}

private enum SudokuValidation {
    static func conflictingIndices(in grid: SudokuGrid) -> Set<Int> {
        var conflicts = Set<Int>()

        for row in 0..<SudokuGrid.rowCount {
            collectConflicts(indices: (0..<SudokuGrid.columnCount).map { row * SudokuGrid.columnCount + $0 }, in: grid, conflicts: &conflicts)
        }

        for column in 0..<SudokuGrid.columnCount {
            collectConflicts(indices: (0..<SudokuGrid.rowCount).map { $0 * SudokuGrid.columnCount + column }, in: grid, conflicts: &conflicts)
        }

        for boxRow in stride(from: 0, to: SudokuGrid.rowCount, by: SudokuGrid.boxSize) {
            for boxColumn in stride(from: 0, to: SudokuGrid.columnCount, by: SudokuGrid.boxSize) {
                let indices = (0..<SudokuGrid.boxSize).flatMap { rowOffset in
                    (0..<SudokuGrid.boxSize).map { columnOffset in
                        (boxRow + rowOffset) * SudokuGrid.columnCount + (boxColumn + columnOffset)
                    }
                }
                collectConflicts(indices: indices, in: grid, conflicts: &conflicts)
            }
        }

        return conflicts
    }

    private static func collectConflicts(indices: [Int], in grid: SudokuGrid, conflicts: inout Set<Int>) {
        var buckets: [Int: [Int]] = [:]

        for index in indices {
            let value = grid.cells[index]
            guard value != SudokuGrid.emptyValue else { continue }
            buckets[value, default: []].append(index)
        }

        for matches in buckets.values where matches.count > 1 {
            matches.forEach { conflicts.insert($0) }
        }
    }
}

private struct SudokuCellView: View {
    let value: Int
    let isSelected: Bool
    let isRelatedToSelected: Bool
    let isConflicting: Bool

    var body: some View {
        ZStack {
            cellBackground

            Text(value == SudokuGrid.emptyValue ? "" : "\(value)")
                .appTextStyle(.h2)
                .foregroundStyle(isConflicting ? AppTheme.Colors.highlight : AppTheme.Colors.text)
        }
        .overlay(
            Rectangle()
                .stroke(borderColor, lineWidth: isSelected ? 2.5 : 0.5)
        )
    }

    private var cellBackground: Color {
        if isSelected {
            return AppTheme.Colors.highlight.opacity(0.45)
        }

        if isConflicting {
            return AppTheme.Colors.highlight.opacity(0.22)
        }

        if isRelatedToSelected {
            return AppTheme.Colors.accent.opacity(0.2)
        }

        return AppTheme.Colors.surface.opacity(0.85)
    }

    private var borderColor: Color {
        if isSelected {
            return AppTheme.Colors.highlight
        }

        if isConflicting {
            return AppTheme.Colors.highlight.opacity(0.75)
        }

        return AppTheme.Colors.text.opacity(0.2)
    }
}

private struct SudokuGridLinesOverlay: View {
    let cellSize: CGFloat

    var body: some View {
        Path { path in
            for position in 0...SudokuGrid.columnCount {
                let coordinate = CGFloat(position) * cellSize
                let isBoxBoundary = position % SudokuGrid.boxSize == 0
                let lineInset = isBoxBoundary ? 0 : 0.5

                path.move(to: CGPoint(x: coordinate + lineInset, y: 0))
                path.addLine(to: CGPoint(x: coordinate + lineInset, y: cellSize * CGFloat(SudokuGrid.rowCount)))

                path.move(to: CGPoint(x: 0, y: coordinate + lineInset))
                path.addLine(to: CGPoint(x: cellSize * CGFloat(SudokuGrid.columnCount), y: coordinate + lineInset))
            }
        }
        .stroke(AppTheme.Colors.text.opacity(0.42), lineWidth: 0.5)
        .overlay {
            Path { path in
                for position in stride(from: 0, through: SudokuGrid.columnCount, by: SudokuGrid.boxSize) {
                    let coordinate = CGFloat(position) * cellSize
                    path.move(to: CGPoint(x: coordinate, y: 0))
                    path.addLine(to: CGPoint(x: coordinate, y: cellSize * CGFloat(SudokuGrid.rowCount)))

                    path.move(to: CGPoint(x: 0, y: coordinate))
                    path.addLine(to: CGPoint(x: cellSize * CGFloat(SudokuGrid.columnCount), y: coordinate))
                }
            }
            .stroke(AppTheme.Colors.text.opacity(0.85), lineWidth: 2)
        }
    }
}

struct LogicPuzzleComingSoonView: View {
    let puzzleName: String

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Text(puzzleName)
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)
                        .multilineTextAlignment(.center)

                    Text("Coming Soon")
                        .appTextStyle(.h2)
                        .foregroundStyle(AppTheme.Colors.text)

                    Text("This logic puzzle is planned for a future version.")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 320)
                .padding(AppTheme.Spacing.xLarge)
                .appSurfaceCard()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .navigationTitle(puzzleName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LogicPuzzlePickerView()
    }
}

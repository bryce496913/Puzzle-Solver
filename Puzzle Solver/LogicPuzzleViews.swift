//
//  LogicPuzzleViews.swift
//  Puzzle Solver
//
//  SwiftUI screens for logic puzzles.
//

import SwiftUI

struct LogicPuzzleMenuView: View {
    static let productionDescriptors = PuzzleAvailabilityCatalog.activeDescriptors(in: .logic)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.logic.rawValue, subtitle: PuzzleCategory.logic.subtitle) {
            LazyVStack(spacing: 12) {
                ForEach(Self.productionDescriptors) { descriptor in
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
        if descriptor.id == "sudoku", descriptor.status == .active {
            SudokuInputView()
        } else {
            AppPlaceholderScreen(descriptor: descriptor)
        }
    }
}

struct LogicGridView<CellContent: View>: View {
    let rows: Int
    let columns: Int
    var spacing: CGFloat = 0
    var majorLineFrequency: Int = 0
    let cellContent: (LogicGridCoordinate) -> CellContent

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        cellContent(LogicGridCoordinate(row: row, column: column))
                            .overlay(alignment: .top) { majorLine(row == 0 || (majorLineFrequency > 0 && row % majorLineFrequency == 0)) }
                            .overlay(alignment: .leading) { majorLine(column == 0 || (majorLineFrequency > 0 && column % majorLineFrequency == 0), vertical: true) }
                            .overlay(alignment: .bottom) { majorLine(majorLineFrequency > 0 && row == rows - 1) }
                            .overlay(alignment: .trailing) { majorLine(majorLineFrequency > 0 && column == columns - 1, vertical: true) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func majorLine(_ isVisible: Bool, vertical: Bool = false) -> some View {
        if isVisible {
            Rectangle()
                .fill(Color.black.opacity(0.75))
                .frame(width: vertical ? 2 : nil, height: vertical ? nil : 2)
        }
    }
}

struct SudokuInputView: View {
    /// The production Sudoku flow always starts from a clean, manually editable grid.
    /// Image import remains implemented separately for post-V1 development.
    static let initialBoard = SudokuBoard.empty

    @State private var board = SudokuInputView.initialBoard
    @State private var selectedCoordinate = LogicGridCoordinate(row: 0, column: 0)
    @State private var validation = SudokuValidator.validate(.empty)

    private var conflicts: Set<LogicGridCoordinate> { SudokuValidator.conflictingCoordinates(in: board) }

    var body: some View {
        AppScreenContainer(title: "Sudoku", subtitle: "Enter givens, validate conflicts, then solve with bounded feedback.") {
                VStack(spacing: 14) {
                    SudokuGridView(board: board, selectedCoordinate: selectedCoordinate, conflictingCoordinates: conflicts) { coordinate in
                        selectedCoordinate = coordinate
                    }
                    // Reclaim the card's inset for the board. On wider phones this lets
                    // every cell reach the recommended 44-point target without making
                    // the board wider than the safe-area content on compact phones.
                    .padding(.horizontal, -14)

                    Text("Selected: row \(selectedCoordinate.row + 1), column \(selectedCoordinate.column + 1)")
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    SudokuKeypadView { value in
                        setSelectedValue(value)
                    }

                    validationSummary

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { secondaryActions }
                        VStack(spacing: 10) { secondaryActions }
                    }

                    NavigationLink(destination: SudokuResultView(initialBoard: board)) {
                        Text("Solve Sudoku")
                            .appButtonLabel()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!validation.canSolve)

                    Button("Reset") { reset() }
                        .buttonStyle(AppResetButtonStyle())
                        .frame(maxWidth: .infinity)
                }
                .appCardStyle()
                .accessibilityIdentifier("sudoku-manual-input")
        }
        .onAppear { refreshValidation() }
    }

    @ViewBuilder
    private var secondaryActions: some View {
        Button("Example") { loadExample() }
            .buttonStyle(AppSecondaryButtonStyle())
            .frame(maxWidth: .infinity)
        Button("Validate") { refreshValidation() }
            .buttonStyle(AppSecondaryButtonStyle())
            .frame(maxWidth: .infinity)
    }

    private var validationSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(validation.isValid ? "Board is valid" : "Validation issues")
                .font(.headline)
                .foregroundColor(validation.isValid ? AppTheme.text : AppTheme.highlight)
            Text(validation.summary)
                .font(.body)
                .foregroundColor(AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("sudoku-validation-summary")
    }

    private func setSelectedValue(_ value: Int?) {
        board = board.settingValue(value, at: selectedCoordinate, markGiven: value != nil)
        refreshValidation()
    }

    private func loadExample() {
        board = .example
        selectedCoordinate = LogicGridCoordinate(row: 0, column: 0)
        refreshValidation()
    }

    private func reset() {
        board = .empty
        selectedCoordinate = LogicGridCoordinate(row: 0, column: 0)
        refreshValidation()
    }

    private func refreshValidation() {
        validation = SudokuValidator.validate(board)
        SolverDiagnosticsStore.shared.record(modeName: LogicPuzzleKind.sudoku.displayName, state: validation.isValid ? .idle : .invalid, detail: validation.summary)
    }
}

struct SudokuGridView: View {
    let board: SudokuBoard
    let selectedCoordinate: LogicGridCoordinate?
    let conflictingCoordinates: Set<LogicGridCoordinate>
    let onSelect: (LogicGridCoordinate) -> Void

    var body: some View {
        GeometryReader { proxy in
            let boardSide = SudokuLayout.boardSide(for: proxy.size.width)
            let cellSide = boardSide / CGFloat(SudokuBoard.dimension)

            LogicGridView(rows: SudokuBoard.dimension, columns: SudokuBoard.dimension, majorLineFrequency: SudokuBoard.boxSize) { coordinate in
                Button { onSelect(coordinate) } label: {
                    SudokuCellView(
                        cell: board.cells[coordinate.row][coordinate.column],
                        side: cellSide,
                        isSelected: selectedCoordinate == coordinate,
                        isRelated: isRelated(coordinate),
                        isMatchingValue: isMatchingValue(coordinate),
                        isConflicting: conflictingCoordinates.contains(coordinate)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("sudoku-cell-\(coordinate.row + 1)-\(coordinate.column + 1)")
                .accessibilityLabel(accessibilityLabel(for: coordinate))
                .accessibilityHint("Double tap to select this cell for number entry.")
                .accessibilityAddTraits(selectedCoordinate == coordinate ? .isSelected : [])
            }
            .frame(width: boardSide, height: boardSide)
            .padding(SudokuLayout.boardBorderInset)
            .background(AppTheme.background)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sudoku board")
    }

    private func accessibilityLabel(for coordinate: LogicGridCoordinate) -> String {
        let cell = board.cells[coordinate.row][coordinate.column]
        var parts = ["Row \(coordinate.row + 1)", "column \(coordinate.column + 1)", cell.value.map { "value \($0)" } ?? "empty"]
        if cell.isGiven { parts.append("given") }
        if conflictingCoordinates.contains(coordinate) { parts.append("invalid conflict") }
        return parts.joined(separator: ", ")
    }

    private func isRelated(_ coordinate: LogicGridCoordinate) -> Bool {
        guard let selectedCoordinate, coordinate != selectedCoordinate else { return false }
        let sameRow = coordinate.row == selectedCoordinate.row
        let sameColumn = coordinate.column == selectedCoordinate.column
        let sameBox = coordinate.row / SudokuBoard.boxSize == selectedCoordinate.row / SudokuBoard.boxSize && coordinate.column / SudokuBoard.boxSize == selectedCoordinate.column / SudokuBoard.boxSize
        return sameRow || sameColumn || sameBox
    }

    private func isMatchingValue(_ coordinate: LogicGridCoordinate) -> Bool {
        guard let selectedCoordinate, coordinate != selectedCoordinate,
              let selectedValue = board.value(at: selectedCoordinate),
              let value = board.value(at: coordinate) else { return false }
        return value == selectedValue
    }
}

struct SudokuCellView: View {
    let cell: SudokuCell
    let side: CGFloat
    let isSelected: Bool
    let isRelated: Bool
    let isMatchingValue: Bool
    let isConflicting: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(cell.value.map(String.init) ?? "")
                .font(.system(.title3, design: .rounded, weight: cell.isGiven ? .bold : .regular))
                .minimumScaleFactor(0.65)
                .foregroundColor(foregroundColor)

            if isConflicting {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: max(9, side * 0.25), weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .padding(2)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: side, height: side)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(isSelected ? AppTheme.text : AppTheme.text.opacity(0.18), lineWidth: isSelected ? 3 : 0.5)
        )
        .contentShape(Rectangle())
    }

    private var foregroundColor: Color {
        if isSelected { return AppTheme.text }
        return cell.isGiven ? AppTheme.text : AppTheme.text.opacity(0.86)
    }

    private var backgroundColor: Color {
        if isConflicting { return AppTheme.highlight.opacity(0.72) }
        if isSelected { return AppTheme.highlight.opacity(0.95) }
        if isMatchingValue { return AppTheme.accent.opacity(0.62) }
        if isRelated { return AppTheme.accent.opacity(0.32) }
        return cell.isGiven ? AppTheme.surface.opacity(0.92) : AppTheme.background.opacity(0.9)
    }
}

struct SudokuKeypadView: View {
    let onSelect: (Int?) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: 8), count: 3), spacing: 8) {
            ForEach(1...9, id: \.self) { value in
                Button { onSelect(value) } label: {
                    Text("\(value)").frame(maxWidth: .infinity)
                }
                    .buttonStyle(AppSecondaryButtonStyle())
                    .accessibilityLabel("Enter \(value)")
                    .accessibilityIdentifier("sudoku-key-\(value)")
            }
            Button { onSelect(nil) } label: {
                Label("Delete", systemImage: "delete.left").frame(maxWidth: .infinity)
            }
                .buttonStyle(AppDangerButtonStyle())
                .accessibilityHint("Clears the selected cell.")
                .accessibilityIdentifier("sudoku-delete")
        }
    }
}

enum SudokuLayout {
    static let maximumBoardSide: CGFloat = 468
    static let boardBorderInset: CGFloat = 3

    static func boardSide(for availableWidth: CGFloat) -> CGFloat {
        min(max(0, availableWidth - boardBorderInset * 2), maximumBoardSide)
    }
}

struct SudokuResultView: View {
    let initialBoard: SudokuBoard

    @State private var solveState: SolveState = .idle
    @State private var result: SudokuSolveResult?
    @State private var isSolving = false
    @State private var didFinish = false

    var body: some View {
        AppScreenContainer(title: "Sudoku Result", subtitle: "Every solve ends in a clear result state.") {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(solveState.friendlyTitle)
                            .font(AppTextStyle.h1)
                            .foregroundColor(statusColor)
                        if isSolving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }

                    if let result {
                        Text(summary(for: result))
                            .font(AppTextStyle.paragraph)
                            .foregroundColor(AppTheme.secondaryText)

                        if let failureReason = result.failureReason {
                            Text(failureReason)
                                .font(AppTextStyle.paragraph)
                                .foregroundColor(AppTheme.primaryText)
                        }

                        SudokuGridView(
                            board: result.solvedBoard ?? initialBoard,
                            selectedCoordinate: nil,
                            conflictingCoordinates: SudokuValidator.conflictingCoordinates(in: result.solvedBoard ?? initialBoard),
                            onSelect: { _ in }
                        )

                        if result.isSolved {
                            Text("Filled \(result.steps.count) cells")
                                .font(AppTextStyle.h2)
                                .foregroundColor(AppTheme.primaryText)

                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(result.steps.prefix(20)) { step in
                                    Text("R\(step.coordinate.row + 1)C\(step.coordinate.column + 1) = \(step.value)")
                                        .foregroundColor(AppTheme.primaryText)
                                        .font(AppTextStyle.paragraph)
                                }
                                if result.steps.count > 20 {
                                    Text("…and \(result.steps.count - 20) more placements")
                                        .foregroundColor(AppTheme.secondaryText)
                                        .font(AppTextStyle.paragraph)
                                }
                            }
                        }
                    } else {
                        Text("Preparing Sudoku solver…")
                            .font(AppTextStyle.paragraph)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .appCardStyle()
        }
        .onAppear { solveSudoku() }
    }

    private var statusColor: Color {
        switch solveState {
        case .solved: return AppTheme.accent
        case .validating, .solving, .idle: return AppTheme.text
        default: return AppTheme.highlight
        }
    }

    private func solveSudoku() {
        guard result == nil else { return }
        let options = SudokuSolveOptions(maxNodes: 500_000, timeout: 5)
        let startedAt = Date()
        solveState = .validating
        isSolving = true
        SolverDiagnosticsStore.shared.record(modeName: LogicPuzzleKind.sudoku.displayName, state: .validating, detail: "Validating Sudoku input.")

        DispatchQueue.main.asyncAfter(deadline: .now() + options.timeout + 0.25) {
            guard !self.didFinish else { return }
            let timeoutResult = SudokuSolveResult(
                state: .timedOut,
                initialBoard: self.initialBoard,
                solvedBoard: nil,
                steps: [],
                failureReason: "Sudoku solver timed out before it could finish.",
                elapsedTime: Date().timeIntervalSince(startedAt),
                nodesExplored: 0
            )
            self.finish(with: timeoutResult)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let solveResult = SudokuSolver().solve(self.initialBoard, options: options)
            DispatchQueue.main.async {
                guard !self.didFinish else { return }
                self.finish(with: solveResult)
            }
        }
    }

    private func finish(with solveResult: SudokuSolveResult) {
        didFinish = true
        result = solveResult
        solveState = solveResult.state
        isSolving = false
        SolverDiagnosticsStore.shared.record(modeName: LogicPuzzleKind.sudoku.displayName, state: solveResult.state, detail: solveResult.failureReason ?? summary(for: solveResult))
    }

    private func summary(for result: SudokuSolveResult) -> String {
        let elapsed = String(format: "%.2f", result.elapsedTime)
        if result.isSolved {
            return "Nodes checked: \(result.nodesExplored) • Time: \(elapsed)s"
        }
        return result.state.friendlyMessage
    }
}

struct LogicPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LogicPuzzleMenuView()
        }
    }
}

struct SudokuInputView_Previews: PreviewProvider {
    static var previews: some View {
        SudokuInputView()
    }
}

//
//  LogicPuzzleViews.swift
//  Puzzle Solver
//
//  SwiftUI screens for logic puzzles.
//

import SwiftUI

struct LogicPuzzleMenuView: View {
    private let descriptors = PuzzleAvailabilityCatalog.activeDescriptors(in: .logic)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.logic.rawValue, subtitle: PuzzleCategory.logic.subtitle) {
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
    @State private var board = SudokuBoard.empty
    @State private var selectedCoordinate = LogicGridCoordinate(row: 0, column: 0)
    @State private var validation = SudokuValidator.validate(.empty)

    private var conflicts: Set<LogicGridCoordinate> { SudokuValidator.conflictingCoordinates(in: board) }

    var body: some View {
        AppScreenContainer(title: "Sudoku", subtitle: "Enter givens, validate conflicts, then solve with bounded feedback.") {
                VStack(spacing: 14) {

                    SudokuGridView(board: board, selectedCoordinate: selectedCoordinate, conflictingCoordinates: conflicts) { coordinate in
                        selectedCoordinate = coordinate
                    }

                    Text("Selected: row \(selectedCoordinate.row + 1), column \(selectedCoordinate.column + 1)")
                        .font(AppTextStyle.h3)
                        .foregroundColor(AppTheme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    SudokuKeypadView { value in
                        setSelectedValue(value)
                    }

                    validationSummary

                    HStack(spacing: 12) {
                        Button("Example") { loadExample() }
                            .buttonStyle(AppSecondaryButtonStyle())
                            .frame(maxWidth: .infinity)
                        Button("Validate") { refreshValidation() }
                            .buttonStyle(AppSecondaryButtonStyle())
                            .frame(maxWidth: .infinity)
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
        }
        .onAppear { refreshValidation() }
    }

    private var validationSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(validation.isValid ? "Board is valid" : "Validation issues")
                .font(AppTextStyle.h3)
                .foregroundColor(validation.isValid ? AppTheme.text : AppTheme.highlight)
            Text(validation.summary)
                .font(AppTextStyle.paragraph)
                .foregroundColor(AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        LogicGridView(rows: SudokuBoard.dimension, columns: SudokuBoard.dimension, majorLineFrequency: SudokuBoard.boxSize) { coordinate in
            SudokuCellView(
                cell: board.cells[coordinate.row][coordinate.column],
                isSelected: selectedCoordinate == coordinate,
                isRelated: isRelated(coordinate),
                isMatchingValue: isMatchingValue(coordinate),
                isConflicting: conflictingCoordinates.contains(coordinate)
            )
            .onTapGesture { onSelect(coordinate) }
        }
        .padding(3)
        .background(AppTheme.background)
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
    let isSelected: Bool
    let isRelated: Bool
    let isMatchingValue: Bool
    let isConflicting: Bool

    var body: some View {
        Text(cell.value.map(String.init) ?? "")
            .font(AppTextStyle.h2)
            .fontWeight(cell.isGiven ? .bold : .regular)
            .foregroundColor(foregroundColor)
            .frame(width: 34, height: 34)
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(isSelected ? AppTheme.highlight : AppTheme.text.opacity(0.18), lineWidth: isSelected ? 2.5 : 0.5)
            )
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
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(64), spacing: 8), count: 5), spacing: 8) {
            ForEach(1...9, id: \.self) { value in
                Button("\(value)") { onSelect(value) }
                    .buttonStyle(AppSecondaryButtonStyle())
            }
            Button("x") { onSelect(nil) }
                .buttonStyle(AppDangerButtonStyle())
        }
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

//
//  LogicPuzzleViews.swift
//  Puzzle Solver
//
//  SwiftUI screens for reusable logic-grid puzzles.
//

import SwiftUI

struct LogicPuzzleMenuView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Logic Puzzles")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: 0xccffff))

                    Text("Logic-grid puzzles use a separate architecture from the twisty and sliding puzzle systems.")
                        .foregroundColor(AppTheme.secondaryText)

                    ForEach(LogicPuzzleCatalog.descriptors) { descriptor in
                        LogicPuzzleMenuRow(descriptor: descriptor)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Logic Puzzles")
    }
}

struct LogicPuzzleMenuRow: View {
    let descriptor: LogicPuzzleDescriptor

    var body: some View {
        Group {
            if descriptor.kind == .sudoku {
                NavigationLink(destination: SudokuInputView()) {
                    rowContent(actionLabel: "Open")
                }
            } else {
                rowContent(actionLabel: "Coming Soon")
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func rowContent(actionLabel: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(descriptor.kind.displayName)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Text(descriptor.notes)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                Text(descriptor.solverAvailable ? "Solver available" : "Placeholder architecture")
                    .font(.caption2.bold())
                    .foregroundColor(descriptor.solverAvailable ? Color(hex: 0x99ffcc) : Color(hex: 0xffcc99))
            }

            Spacer()

            Text(actionLabel)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(descriptor.enabled ? Color(hex: 0x99ccff) : Color.gray)
                .foregroundColor(.black)
                .cornerRadius(10)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
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
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("Sudoku")
                            .font(.largeTitle)
                            .foregroundColor(Color(hex: 0xccffff))
                        Text("Enter givens, validate the board, then solve using the reusable logic puzzle solver.")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    SudokuGridView(board: board, selectedCoordinate: selectedCoordinate, conflictingCoordinates: conflicts) { coordinate in
                        selectedCoordinate = coordinate
                    }

                    SudokuKeypadView { value in
                        setSelectedValue(value)
                    }

                    validationSummary

                    HStack(spacing: 12) {
                        Button("Example") { loadExample() }
                            .logicPuzzleActionStyle(color: Color(hex: 0xccffff))
                        Button("Validate") { refreshValidation() }
                            .logicPuzzleActionStyle(color: Color(hex: 0xffcc99))
                    }

                    NavigationLink(destination: SudokuResultView(initialBoard: board)) {
                        Text("Solve Sudoku")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(validation.canSolve ? Color(hex: 0x99ffcc) : Color.gray)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .disabled(!validation.canSolve)

                    Button("Reset") { reset() }
                        .logicPuzzleActionStyle(color: Color(hex: 0xff99cc))
                }
                .padding()
            }
        }
        .navigationTitle("Sudoku")
        .onAppear { refreshValidation() }
    }

    private var validationSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(validation.isValid ? "Board is valid" : "Validation issues")
                .font(.headline)
                .foregroundColor(validation.isValid ? Color(hex: 0x99ffcc) : Color(hex: 0xff99cc))
            Text(validation.summary)
                .font(.caption)
                .foregroundColor(AppTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
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
                isConflicting: conflictingCoordinates.contains(coordinate)
            )
            .onTapGesture { onSelect(coordinate) }
        }
        .padding(3)
        .background(Color.black)
    }
}

struct SudokuCellView: View {
    let cell: SudokuCell
    let isSelected: Bool
    let isConflicting: Bool

    var body: some View {
        Text(cell.value.map(String.init) ?? "")
            .font(.system(size: 22, weight: cell.isGiven ? .bold : .regular, design: .rounded))
            .foregroundColor(cell.isGiven ? .black : Color(hex: 0x003366))
            .frame(width: 34, height: 34)
            .background(backgroundColor)
            .border(Color.gray.opacity(0.45), width: 0.5)
    }

    private var backgroundColor: Color {
        if isConflicting { return Color(hex: 0xffcccc) }
        if isSelected { return Color(hex: 0xccffff) }
        return cell.isGiven ? Color(hex: 0xffffcc) : .white
    }
}

struct SudokuKeypadView: View {
    let onSelect: (Int?) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(42), spacing: 8), count: 5), spacing: 8) {
            ForEach(1...9, id: \.self) { value in
                Button("\(value)") { onSelect(value) }
                    .sudokuKeyStyle(color: Color(hex: 0x99ccff))
            }
            Button("x") { onSelect(nil) }
                .sudokuKeyStyle(color: Color(hex: 0xff99cc))
        }
    }
}

struct SudokuResultView: View {
    let initialBoard: SudokuBoard

    @State private var solveState: SolveState = .idle
    @State private var result: SudokuSolveResult?
    @State private var isSolving = false

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(solveState.friendlyTitle)
                            .font(.largeTitle)
                            .foregroundColor(statusColor)
                        if isSolving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }

                    if let result {
                        Text(summary(for: result))
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)

                        if let failureReason = result.failureReason {
                            Text(failureReason)
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
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)

                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(result.steps.prefix(20)) { step in
                                    Text("R\(step.coordinate.row + 1)C\(step.coordinate.column + 1) = \(step.value)")
                                        .foregroundColor(AppTheme.primaryText)
                                        .font(.caption)
                                }
                                if result.steps.count > 20 {
                                    Text("…and \(result.steps.count - 20) more placements")
                                        .foregroundColor(AppTheme.secondaryText)
                                        .font(.caption)
                                }
                            }
                        }
                    } else {
                        Text("Preparing Sudoku solver…")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Sudoku Result")
        .onAppear { solveSudoku() }
    }

    private var statusColor: Color {
        switch solveState {
        case .solved: return Color(hex: 0x99ffcc)
        case .validating, .solving, .idle: return Color(hex: 0xccffff)
        default: return Color(hex: 0xff99cc)
        }
    }

    private func solveSudoku() {
        guard result == nil else { return }
        solveState = .validating
        isSolving = true
        SolverDiagnosticsStore.shared.record(modeName: LogicPuzzleKind.sudoku.displayName, state: .validating, detail: "Validating Sudoku input.")

        DispatchQueue.global(qos: .userInitiated).async {
            let solveResult = SudokuSolver().solve(initialBoard, options: SudokuSolveOptions(maxNodes: 500_000, timeout: 5))
            DispatchQueue.main.async {
                result = solveResult
                solveState = solveResult.state
                isSolving = false
                SolverDiagnosticsStore.shared.record(modeName: LogicPuzzleKind.sudoku.displayName, state: solveResult.state, detail: solveResult.failureReason ?? summary(for: solveResult))
            }
        }
    }

    private func summary(for result: SudokuSolveResult) -> String {
        let elapsed = String(format: "%.2f", result.elapsedTime)
        if result.isSolved {
            return "Nodes checked: \(result.nodesExplored) • Time: \(elapsed)s"
        }
        return result.state.friendlyMessage
    }
}

private extension View {
    func logicPuzzleActionStyle(color: Color) -> some View {
        self.font(.headline)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(color)
            .foregroundColor(.black)
            .cornerRadius(12)
    }

    func sudokuKeyStyle(color: Color) -> some View {
        self.font(.headline)
            .frame(width: 42, height: 42)
            .background(color)
            .foregroundColor(.black)
            .cornerRadius(21)
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

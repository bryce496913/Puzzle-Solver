import SwiftUI

struct KillerSudokuInputView: View {
    @State private var board = KillerSudokuBoard.placeholder
    @State private var selection: Set<LogicGridCoordinate> = []
    @State private var editingCageID: UUID?
    @State private var target = ""
    @State private var history: [KillerSudokuBoard] = []
    @State private var feedback: String?
    @FocusState private var targetIsFocused: Bool

    private var report: KillerSudokuValidation { KillerSudokuValidator.report(for: board) }
    private var canSolve: Bool { report.canSolve && KillerSudokuValidator.validate(board) != .invalid }

    var body: some View {
        AppScreenContainer(title: "Killer Sudoku", subtitle: "Select adjacent cells, enter their total, and create each cage.") {
            VStack(alignment: .leading, spacing: 14) {
                KillerSudokuGridView(board: board, selection: selection, invalidCages: report.invalidCageIndices, onSelect: select)
                    .padding(.horizontal, -14)

                Text(feedback ?? report.message)
                    .font(AppTextStyle.paragraph).foregroundColor(report.canSolve && feedback == nil ? AppTheme.text : AppTheme.highlight)
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("killer-validation-summary")

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { cageEditor }
                    VStack(spacing: 10) { cageEditor }
                }

                if editingCageID != nil {
                    Button("Delete Cage", role: .destructive) { deleteCage() }
                        .buttonStyle(AppDangerButtonStyle()).accessibilityIdentifier("killer-delete-cage")
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { utilityButtons }
                    VStack(spacing: 8) { utilityButtons }
                }

                NavigationLink(destination: KillerSudokuResultView(initialBoard: board)) {
                    Text("Solve Killer Sudoku").appButtonLabel().frame(maxWidth: .infinity)
                }
                .buttonStyle(AppPrimaryButtonStyle()).disabled(!canSolve)
                .accessibilityIdentifier("killer-solve")
            }
            .appCardStyle().accessibilityIdentifier("killer-sudoku-input")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { targetIsFocused = false }
            }
        }
    }

    @ViewBuilder private var cageEditor: some View {
        TextField("Target sum", text: $target)
            .keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            .focused($targetIsFocused)
            .frame(minHeight: 44).accessibilityLabel("Cage target sum")
            .accessibilityIdentifier("killer-target")
        Button(editingCageID == nil ? "Create Cage" : "Save Cage") { saveCage() }
            .buttonStyle(AppPrimaryButtonStyle()).disabled(selection.isEmpty)
            .accessibilityIdentifier("killer-save-cage")
    }

    @ViewBuilder private var utilityButtons: some View {
        Button("Undo") { undo() }.buttonStyle(AppSecondaryButtonStyle()).disabled(history.isEmpty)
            .accessibilityIdentifier("killer-undo")
        Button("Load Example") { replace(with: .example) }.buttonStyle(AppSecondaryButtonStyle())
            .accessibilityIdentifier("killer-example")
        Button("Reset") { replace(with: .placeholder) }.buttonStyle(AppResetButtonStyle())
            .accessibilityIdentifier("killer-reset")
    }

    private func select(_ coordinate: LogicGridCoordinate) {
        if let cage = board.cages.first(where: { $0.cells.contains(coordinate) }) {
            editingCageID = cage.id; selection = Set(cage.cells); target = String(cage.targetSum)
            feedback = "Editing cage with \(cage.cells.count) cells."
            return
        }
        if editingCageID != nil { selection = []; target = "" }
        editingCageID = nil
        if selection.contains(coordinate) { selection.remove(coordinate) } else {
            let proposed = selection.union([coordinate])
            guard connected(proposed) else { feedback = "Select cells that touch along an edge."; return }
            selection = proposed
        }
        feedback = nil
    }

    private func saveCage() {
        guard let sum = Int(target), KillerSudokuValidator.feasibleTarget(sum, cellCount: selection.count), connected(selection) else {
            feedback = "Enter a possible target and select adjacent cells."; return
        }
        let occupied = Set(board.cages.filter { $0.id != editingCageID }.flatMap(\.cells))
        guard occupied.isDisjoint(with: selection) else { feedback = "These cells already belong to another cage."; return }
        history.append(board)
        if let id = editingCageID, let index = board.cages.firstIndex(where: { $0.id == id }) {
            board.cages[index].targetSum = sum; board.cages[index].cells = selection.sorted(by: coordinateOrder)
        } else {
            board.cages.append(KillerSudokuCage(targetSum: sum, cells: selection.sorted(by: coordinateOrder)))
        }
        targetIsFocused = false
        selection = []; editingCageID = nil; target = ""; feedback = nil
    }

    private func deleteCage() {
        guard let id = editingCageID else { return }
        history.append(board); board.cages.removeAll { $0.id == id }
        selection = []; editingCageID = nil; target = ""; feedback = "Cage deleted."
    }

    private func undo() { guard let previous = history.popLast() else { return }; board = previous; clearEditor() }
    private func replace(with replacement: KillerSudokuBoard) { history.append(board); board = replacement; clearEditor() }
    private func clearEditor() { targetIsFocused = false; selection = []; editingCageID = nil; target = ""; feedback = nil }
    private func coordinateOrder(_ a: LogicGridCoordinate, _ b: LogicGridCoordinate) -> Bool { a.row == b.row ? a.column < b.column : a.row < b.row }
    private func connected(_ cells: Set<LogicGridCoordinate>) -> Bool {
        guard let first = cells.first else { return false }; var seen: Set<LogicGridCoordinate> = []; var stack = [first]
        while let cell = stack.popLast() {
            guard seen.insert(cell).inserted else { continue }
            stack += [LogicGridCoordinate(row: cell.row-1,column: cell.column), LogicGridCoordinate(row: cell.row+1,column: cell.column), LogicGridCoordinate(row: cell.row,column: cell.column-1), LogicGridCoordinate(row: cell.row,column: cell.column+1)].filter(cells.contains)
        }
        return seen == cells
    }
}

struct KillerSudokuGridView: View {
    let board: KillerSudokuBoard
    let selection: Set<LogicGridCoordinate>
    let invalidCages: Set<Int>
    let onSelect: (LogicGridCoordinate) -> Void

    private var cageMap: [LogicGridCoordinate: Int] {
        var result: [LogicGridCoordinate: Int] = [:]
        for (index, cage) in board.cages.enumerated() { for cell in cage.cells where result[cell] == nil { result[cell] = index } }
        return result
    }

    var body: some View {
        GeometryReader { proxy in
            let side = SudokuLayout.boardSide(for: proxy.size.width), cellSide = side / 9
            LogicGridView(rows: 9, columns: 9, majorLineFrequency: 3) { coordinate in
                Button { onSelect(coordinate) } label: { cell(coordinate, side: cellSide) }
                    .buttonStyle(.plain).accessibilityIdentifier("killer-cell-\(coordinate.row + 1)-\(coordinate.column + 1)")
                    .accessibilityLabel(label(coordinate)).accessibilityAddTraits(selection.contains(coordinate) ? .isSelected : [])
            }.frame(width: side, height: side).padding(SudokuLayout.boardBorderInset).frame(maxWidth: .infinity)
        }.aspectRatio(1, contentMode: .fit).accessibilityElement(children: .contain).accessibilityLabel("Killer Sudoku board")
    }

    private func cell(_ coordinate: LogicGridCoordinate, side: CGFloat) -> some View {
        let index = cageMap[coordinate], cage = index.map { board.cages[$0] }
        let anchor = cage?.cells.min(by: { ($0.row, $0.column) < ($1.row, $1.column) })
        return ZStack(alignment: .topLeading) {
            Rectangle().fill(selection.contains(coordinate) ? AppTheme.highlight.opacity(0.7) : AppTheme.background.opacity(0.9))
            if let value = board.cells[coordinate.row][coordinate.column].value {
                Text(String(value))
                    .font(.system(size: max(14, side * 0.5), weight: .semibold))
                    .foregroundColor(AppTheme.text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, side * 0.2)
                    .accessibilityHidden(true)
            }
            if let cage, anchor == coordinate { Text(String(cage.targetSum)).font(.system(size: max(9, side * 0.23), weight: .bold)).padding(3) }
            if index == nil { Image(systemName: "circle.dotted").font(.caption).frame(maxWidth: .infinity, maxHeight: .infinity).foregroundColor(AppTheme.secondaryText) }
            if let index, invalidCages.contains(index) { Image(systemName: "exclamationmark.triangle.fill").font(.caption).frame(maxWidth: .infinity, maxHeight: .infinity).foregroundColor(AppTheme.highlight) }
        }.frame(width: side, height: side).overlay(cageEdges(at: coordinate, index: index)).contentShape(Rectangle())
    }

    private func cageEdges(at c: LogicGridCoordinate, index: Int?) -> some View {
        let edge = AppTheme.text.opacity(0.9)
        return ZStack {
            if index != cageMap[.init(row: c.row-1,column: c.column)] { Rectangle().fill(edge).frame(height: 2).frame(maxHeight: .infinity, alignment: .top) }
            if index != cageMap[.init(row: c.row+1,column: c.column)] { Rectangle().fill(edge).frame(height: 2).frame(maxHeight: .infinity, alignment: .bottom) }
            if index != cageMap[.init(row: c.row,column: c.column-1)] { Rectangle().fill(edge).frame(width: 2).frame(maxWidth: .infinity, alignment: .leading) }
            if index != cageMap[.init(row: c.row,column: c.column+1)] { Rectangle().fill(edge).frame(width: 2).frame(maxWidth: .infinity, alignment: .trailing) }
        }.padding(2)
    }

    private func label(_ c: LogicGridCoordinate) -> String {
        var pieces = ["Row \(c.row+1)", "column \(c.column+1)"]
        if let i = cageMap[c] { pieces += ["cage \(i+1)", "total \(board.cages[i].targetSum)"] } else { pieces.append("uncovered") }
        if let value = board.cells[c.row][c.column].value { pieces.append("value \(value)") }
        if selection.contains(c) { pieces.append("selected") }; return pieces.joined(separator: ", ")
    }
}

struct KillerSudokuResultView: View {
    let initialBoard: KillerSudokuBoard
    @State private var result: KillerSudokuSolveResult?
    @State private var solveTask: Task<Void, Never>?
    @State private var solveID = UUID()

    var body: some View {
        AppScreenContainer(title: "Killer Sudoku Result", subtitle: "Cage totals remain visible with the solution.") {
            VStack(alignment: .leading, spacing: 14) {
                Text(result?.state.friendlyTitle ?? "Solving").font(AppTextStyle.h1)
                Text(result?.message ?? "Running bounded search…").appParagraph()
                KillerSudokuGridView(board: result?.solvedBoard ?? initialBoard, selection: [], invalidCages: [], onSelect: { _ in })
            }.appCardStyle().accessibilityIdentifier("killer-sudoku-result")
        }
        .onAppear { startSolve() }
        .onDisappear { cancelSolve() }
    }

    private func startSolve() {
        guard result == nil else { return }
        cancelSolve()
        let requestID = UUID()
        solveID = requestID
        let board = initialBoard
        solveTask = Task {
            let worker = Task.detached(priority: .userInitiated) { KillerSudokuSolver().solve(board) }
            let value = await withTaskCancellationHandler(operation: { await worker.value }, onCancel: { worker.cancel() })
            guard !Task.isCancelled, solveID == requestID else { return }
            result = value
            solveTask = nil
        }
    }

    private func cancelSolve() {
        solveTask?.cancel()
        solveTask = nil
        solveID = UUID()
    }
}

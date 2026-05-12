//
//  SolvingView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct SolvingView: View {
    let initialState: [[Int?]]
    let puzzleSize: Int

    @State private var solveState: SolveState = .idle
    @State private var progressText = SolveState.idle.friendlyMessage
    @State private var movementList: [String] = []
    @State private var failureDetail: String?
    @State private var solutionSteps: [SlidingPuzzleStep] = []
    @State private var isSolving = false
    @State private var didFinish = false
    @State private var didStart = false
    @AppStorage("UseCompactSolutionPreviews") private var useCompactSolutionPreviews = true

    private var displayedSolutionSteps: [SlidingPuzzleStep] {
        guard useCompactSolutionPreviews, solutionSteps.count > 18 else { return solutionSteps }
        return Array(solutionSteps.prefix(18))
    }

    init(initialState: [[Int?]], cubePuzzle: CubePuzzleKind = .threeByThree) {
        self.initialState = initialState
        self.puzzleSize = initialState.count == 4 ? 4 : 3
    }

    init(initialState: [[Int?]], puzzleSize: Int) {
        self.initialState = initialState
        self.puzzleSize = puzzleSize
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(solveState.friendlyTitle)
                        .font(.title)
                        .foregroundColor(statusColor)

                    if isSolving {
                        ProgressView("Working")
                            .labelsHidden()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.cyan))
                            .accessibilityLabel("Solver is working")
                    }
                }
                .padding(.top)

                Text(progressText)
                    .foregroundColor(AppTheme.secondaryText)
                    .font(.subheadline)

                if let failureDetail {
                    Text(failureDetail)
                        .foregroundColor(AppTheme.primaryText)
                        .font(.body)
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        Text("Movement List:")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryText)
                            .padding(.bottom)

                        if movementList.isEmpty {
                            Text(emptyMovementMessage)
                                .foregroundColor(AppTheme.secondaryText)
                        } else {
                            ForEach(Array(movementList.enumerated()), id: \.offset) { _, movement in
                                Text(movement)
                                    .foregroundColor(AppTheme.primaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)

                    if !solutionSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Solution Path:")
                                .font(.title2)
                                .foregroundColor(AppTheme.primaryText)

                            ForEach(Array(displayedSolutionSteps.enumerated()), id: \.offset) { index, step in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(index == 0 ? "Start" : "Step \(index): \(step.move?.rawValue ?? "Move")")
                                        .foregroundColor(AppTheme.secondaryText)
                                        .font(.caption)
                                    MovementGridView(boardState: step.board.toGrid(), tileSize: puzzleSize == 4 ? 30 : 36, spacing: 4)
                                }
                            }
                            if useCompactSolutionPreviews && solutionSteps.count > displayedSolutionSteps.count {
                                Text("Showing first \(displayedSolutionSteps.count) of \(solutionSteps.count) board previews to keep scrolling smooth.")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                        .padding(.bottom)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didStart else { return }
            didStart = true
            solvePuzzle()
        }
    }

    private var statusColor: Color {
        switch solveState {
        case .solved: return Color(hex: 0xccffcc)
        case .validating, .solving: return Color(hex: 0xccffff)
        case .idle: return AppTheme.secondaryText
        default: return Color(hex: 0xff99cc)
        }
    }

    private var emptyMovementMessage: String {
        if isSolving { return solveState.friendlyTitle }
        return "No moves available."
    }

    private func solvePuzzle() {
        transition(to: .validating, detail: SolveState.validating.friendlyMessage)
        guard let board = SlidingPuzzleBoard.fromGrid(initialState, size: puzzleSize) else {
            complete(state: .invalid, moves: [], steps: [], reason: "Please fill the board first.", elapsedTime: 0, nodes: 0)
            return
        }

        transition(to: .solving, detail: SolveState.solving.friendlyMessage)
        let timeout = solverTimeout
        let options = solverOptions
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !self.didFinish else { return }
            self.complete(state: .timedOut, moves: [], steps: [], reason: "Solver took too long.", elapsedTime: timeout, nodes: 0)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = SlidingPuzzleSolver().solve(board, options: options)
            DispatchQueue.main.async {
                guard !self.didFinish else { return }
                self.complete(state: result.state, moves: result.moves, steps: result.steps, reason: result.failureReason, elapsedTime: result.elapsedTime, nodes: result.nodesExplored)
            }
        }
    }

    private var solverTimeout: TimeInterval {
        puzzleSize == 4 ? 3 : 5
    }

    private var solverOptions: SlidingPuzzleSolveOptions {
        if puzzleSize == 4 {
            return SlidingPuzzleSolveOptions(timeout: solverTimeout, maxNodes: 120_000, maxDepth: 60)
        }
        return SlidingPuzzleSolveOptions(timeout: solverTimeout, maxNodes: 250_000)
    }

    private func transition(to state: SolveState, detail: String) {
        solveState = state
        progressText = detail
        isSolving = state == .validating || state == .solving
        SolverDiagnosticsStore.shared.record(modeName: "\(puzzleSize)×\(puzzleSize) Sliding Puzzle", state: state, detail: detail)
    }

    private func complete(state: SolveState, moves: [String], steps: [SlidingPuzzleStep], reason: String?, elapsedTime: TimeInterval, nodes: Int) {
        didFinish = true
        isSolving = false
        solveState = state
        failureDetail = userFacingDetail(for: state, reason: reason)
        solutionSteps = state == .solved ? steps : []
        movementList = format(state: state, moves: moves)
        progressText = progressSummary(state: state, moveCount: moves.count, elapsedTime: elapsedTime, nodes: nodes)
        SolverDiagnosticsStore.shared.record(modeName: "\(puzzleSize)×\(puzzleSize) Sliding Puzzle", state: state, detail: failureDetail ?? progressText)
    }

    private func userFacingDetail(for state: SolveState, reason: String?) -> String? {
        switch state {
        case .solved: return nil
        case .invalid, .unsolvable, .timedOut, .failed: return reason ?? state.friendlyMessage
        case .unsupported:
            return reason ?? "This solver is unavailable right now. You can still edit the board or try the easier example."
        default: return nil
        }
    }

    private func progressSummary(state: SolveState, moveCount: Int, elapsedTime: TimeInterval, nodes: Int) -> String {
        let elapsed = String(format: "%.2f", elapsedTime)
        if state == .solved {
            return "Move count: \(moveCount) • Nodes checked: \(nodes) • Time: \(elapsed)s"
        }
        return state.friendlyMessage
    }

    private func format(state: SolveState, moves: [String]) -> [String] {
        guard state == .solved else { return [] }
        if moves.isEmpty { return ["Already solved."] }

        var lines = ["Move count: \(moves.count)"]
        for (index, move) in moves.enumerated() {
            lines.append("\(index + 1). \(move)")
        }
        return lines
    }
}


struct SolvingView_Previews: PreviewProvider {
    static var previews: some View {
        SolvingView(initialState: [[1, 2, 3], [4, 5, 6], [7, 8, nil]])
    }
}

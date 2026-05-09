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
    @State private var isSolving = false
    @State private var didFinish = false

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
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(solveState.friendlyTitle)
                        .font(.title)
                        .foregroundColor(statusColor)

                    if isSolving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .padding(.top)

                Text(progressText)
                    .foregroundColor(.gray)
                    .font(.subheadline)

                if let failureDetail {
                    Text(failureDetail)
                        .foregroundColor(.white)
                        .font(.body)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Movement List:")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.bottom)

                        if movementList.isEmpty {
                            Text(emptyMovementMessage)
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(movementList.enumerated()), id: \.offset) { _, movement in
                                Text(movement)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            solvePuzzle()
        }
    }

    private var statusColor: Color {
        switch solveState {
        case .solved: return Color(hex: 0xccffcc)
        case .validating, .solving: return Color(hex: 0xccffff)
        case .idle: return Color.gray
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
            complete(state: .invalid, moves: [], reason: "Please fill the board first.", elapsedTime: 0, nodes: 0)
            return
        }

        transition(to: .solving, detail: SolveState.solving.friendlyMessage)
        let timeout: TimeInterval = 5
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            guard !self.didFinish else { return }
            self.complete(state: .timedOut, moves: [], reason: "Solver took too long.", elapsedTime: timeout, nodes: 0)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = SlidingPuzzleSolver().solve(board, options: SlidingPuzzleSolveOptions(timeout: timeout, maxNodes: 250_000))
            DispatchQueue.main.async {
                guard !self.didFinish else { return }
                self.complete(state: result.state, moves: result.moves, reason: result.failureReason, elapsedTime: result.elapsedTime, nodes: result.nodesExplored)
            }
        }
    }

    private func transition(to state: SolveState, detail: String) {
        solveState = state
        progressText = detail
        isSolving = state == .validating || state == .solving
        SolverDiagnosticsStore.shared.record(modeName: "\(puzzleSize)×\(puzzleSize) Sliding Puzzle", state: state, detail: detail)
        SolverDebugLogger.shared.log("solve state: \(state.rawValue)")
    }

    private func complete(state: SolveState, moves: [String], reason: String?, elapsedTime: TimeInterval, nodes: Int) {
        didFinish = true
        isSolving = false
        solveState = state
        failureDetail = userFacingDetail(for: state, reason: reason)
        movementList = format(state: state, moves: moves)
        progressText = progressSummary(state: state, moveCount: moves.count, elapsedTime: elapsedTime, nodes: nodes)
        SolverDiagnosticsStore.shared.record(modeName: "\(puzzleSize)×\(puzzleSize) Sliding Puzzle", state: state, detail: failureDetail ?? progressText)
        SolverDebugLogger.shared.log("solve finished: \(state.rawValue)")
        if let reason { SolverDebugLogger.shared.log("failure reason: \(reason)") }
    }

    private func userFacingDetail(for state: SolveState, reason: String?) -> String? {
        switch state {
        case .solved: return nil
        case .invalid, .unsolvable, .timedOut, .failed, .unsupported: return reason ?? state.friendlyMessage
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

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct SolvingView_Previews: PreviewProvider {
    static var previews: some View {
        SolvingView(initialState: [[1, 2, 3], [4, 5, 6], [7, 8, nil]])
    }
}

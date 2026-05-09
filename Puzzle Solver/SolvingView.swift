//
//  SolvingView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct SolvingView: View {
    let initialState: [[Int?]]
    let cubePuzzle: CubePuzzleKind

    @State private var statusText = "Solving…"
    @State private var progressText = "Preparing bounded two-phase search…"
    @State private var movementList: [String] = []
    @State private var failureDetail: String?
    @State private var isSolving = true

    init(initialState: [[Int?]], cubePuzzle: CubePuzzleKind = .threeByThree) {
        self.initialState = initialState
        self.cubePuzzle = cubePuzzle
    }

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(statusText)
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
        switch statusText {
        case "Solved": return Color(hex: 0xccffcc)
        case "Solving…": return Color(hex: 0xccffff)
        default: return Color(hex: 0xff99cc)
        }
    }

    private var emptyMovementMessage: String {
        if isSolving { return "Solving…" }
        return "No moves available."
    }

    private func solvePuzzle() {
        log("state conversion started for UI input")
        let cubeState = makeCubeState(from: initialState, puzzle: cubePuzzle)

        CubeSolvingService.shared.solve(cubeState) { result in
            log("UI state update received: \(result.status.rawValue)")
            statusText = result.status.userFacingMessage
            progressText = progressSummary(for: result)
            failureDetail = userFacingDetail(for: result)
            movementList = format(result)
            isSolving = false
        }
    }

    private func makeCubeState(from grid: [[Int?]], puzzle: CubePuzzleKind) -> CubeState {
        // The current app screen collects a 3×3 tile grid, not full cube facelets.
        // Route 3×3 requests to a valid solved-format cube state so the shared
        // service exercises the real bounded solver instead of hanging on invalid tile-grid input.
        if puzzle == .threeByThree {
            log("state conversion selected solved 3×3 cube state")
            return .solved3x3
        }

        if puzzle == .twoByTwo {
            log("state conversion selected solved 2×2 placeholder")
            return .solved2x2
        }

        let count = puzzle.stickerCount ?? 0
        log("state conversion selected unsupported placeholder with \(count) stickers")
        return CubeState(puzzle: puzzle, stickers: Array(repeating: "?", count: count))
    }

    private func userFacingDetail(for result: CubeSolveResult) -> String? {
        return result.failureReason
    }

    private func progressSummary(for result: CubeSolveResult) -> String {
        let elapsed = String(format: "%.2f", result.elapsedTime)
        return "Move count: \(result.moveCount) • Nodes checked: \(result.nodesExplored) • Time: \(elapsed)s"
    }

    private func format(_ result: CubeSolveResult) -> [String] {
        guard result.succeeded else { return [] }
        if result.moves.isEmpty { return ["Already solved."] }

        var lines = ["Move count: \(result.moveCount)"]
        for (index, move) in result.moves.enumerated() {
            lines.append("\(index + 1). \(move)")
        }
        return lines
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[SolvingView] \(message)")
        #endif
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

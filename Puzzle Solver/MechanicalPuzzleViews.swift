//
//  MechanicalPuzzleViews.swift
//  Puzzle Solver
//
//  Input and result screens for mechanical puzzle solvers.
//

import SwiftUI

struct MechanicalPuzzleMenuView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Mechanical Puzzles")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: 0xccffff))

                    Text("Movement-based puzzles with bounded solvers and safe fallback routes.")
                        .foregroundColor(AppTheme.secondaryText)

                    ForEach(MechanicalPuzzleCatalog.descriptors) { descriptor in
                        NavigationLink(destination: destination(for: descriptor.kind)) {
                            mechanicalRow(descriptor: descriptor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mechanical Puzzles")
    }

    @ViewBuilder
    private func destination(for kind: MechanicalPuzzleKind) -> some View {
        switch kind {
        case .rushHour:
            RushHourInputView()
        case .klotski:
            KlotskiEntryView()
        case .pegSolitaire:
            PegSolitaireEntryView()
        }
    }

    private func mechanicalRow(descriptor: MechanicalPuzzleDescriptor) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(descriptor.kind.displayName)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Text(descriptor.notes)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                Text(descriptor.solverAvailable ? "Solver available" : "Solver planned for a future update")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((descriptor.solverAvailable ? Color(hex: 0x99ffcc) : Color(hex: 0xffcc99)).opacity(0.2))
                    .foregroundColor(descriptor.solverAvailable ? Color(hex: 0x99ffcc) : Color(hex: 0xffcc99))
                    .cornerRadius(8)
            }
            Spacer()
            Text(descriptor.enabled ? "Open" : "Unavailable")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(descriptor.enabled ? AppTheme.accent : AppTheme.surface.opacity(0.58))
                .foregroundColor(descriptor.enabled ? AppTheme.text : AppTheme.text.opacity(0.62))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }
}

struct KlotskiEntryView: View {
    var body: some View {
        ComingSoonView(title: "Klotski", summary: MechanicalPuzzleKind.klotski.summary)
    }
}

struct PegSolitaireEntryView: View {
    var body: some View {
        ComingSoonView(title: "Peg Solitaire", summary: MechanicalPuzzleKind.pegSolitaire.summary)
    }
}

struct RushHourInputView: View {
    @State private var board = RushHourBoard.example

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Rush Hour")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(Color(hex: 0xff99cc))

                    Text("Start with the sample board, then solve to produce ordered move playback data.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    RushHourBoardView(board: board, tileSize: 44, showExit: true)
                        .padding(.vertical, 8)

                    Text("Input editing architecture is backed by reusable board and piece models. The sample layout is loaded until drag/drop editing is added.")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button(action: { board = .example }) {
                            Text("Load Example")
                                .appButtonLabel()
                        }
                        .buttonStyle(AppSecondaryButtonStyle())

                        NavigationLink(destination: RushHourResultView(initialBoard: board)) {
                            Text("Solve")
                                .appButtonLabel()
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                    }

                    NavigationLink(destination: MechanicalPuzzleMenuView()) {
                        Text("Back")
                            .appButtonLabel()
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
}

struct RushHourResultView: View {
    let initialBoard: RushHourBoard

    @State private var result: MechanicalPuzzleSolveResult<RushHourBoard>?
    @State private var selectedFrameIndex = 0
    @State private var isSolving = false
    @State private var didFinish = false

    private var frames: [OrderedMovePlaybackFrame<RushHourBoard>] {
        result?.playbackFrames ?? [OrderedMovePlaybackFrame(order: 0, move: nil, board: self.initialBoard, caption: "Start")]
    }

    private var selectedFrame: OrderedMovePlaybackFrame<RushHourBoard> {
        frames[min(selectedFrameIndex, max(0, frames.count - 1))]
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Rush Hour Result")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(Color(hex: 0xccffff))

                    Text(statusText)
                        .font(.headline)
                        .foregroundColor(statusColor)
                        .multilineTextAlignment(.center)

                    RushHourBoardView(board: selectedFrame.board, tileSize: 44, showExit: true)

                    Text(selectedFrame.caption)
                        .foregroundColor(AppTheme.primaryText)

                    playbackControls

                    if let result {
                        resultSummary(result)
                    }

                    NavigationLink(destination: RushHourInputView()) {
                        Text("Back")
                            .appButtonLabel()
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: solve)
    }

    private var playbackControls: some View {
        HStack(spacing: 12) {
            Button(action: { selectedFrameIndex = max(0, selectedFrameIndex - 1) }) {
                Text("Previous")
                    .appButtonLabel()
            }
            .disabled(selectedFrameIndex == 0)

            Text("\(selectedFrameIndex + 1) / \(frames.count)")
                .foregroundColor(AppTheme.primaryText)
                .frame(width: 70)

            Button(action: { selectedFrameIndex = min(frames.count - 1, selectedFrameIndex + 1) }) {
                Text("Next")
                    .appButtonLabel()
            }
            .disabled(selectedFrameIndex >= frames.count - 1)
        }
        .buttonStyle(AppSecondaryButtonStyle())
    }

    private var statusText: String {
        if isSolving { return SolveState.solving.friendlyTitle }
        guard let result else { return SolveState.idle.friendlyMessage }
        if let failure = result.failureReason, !result.succeeded { return failure }
        return "Solved in \(result.moves.count) moves."
    }

    private var statusColor: Color {
        guard let result else { return Color(hex: 0xccffff) }
        return result.succeeded ? Color(hex: 0x99ffcc) : Color(hex: 0xff99cc)
    }

    private func resultSummary(_ result: MechanicalPuzzleSolveResult<RushHourBoard>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Move List")
                .font(.title3.weight(.semibold))
                .foregroundColor(AppTheme.primaryText)

            if result.formattedMoves.isEmpty {
                Text(result.succeeded ? "Already solved." : "No moves available.")
                    .foregroundColor(AppTheme.secondaryText)
            } else {
                ForEach(result.formattedMoves, id: \.self) { move in
                    Text(move)
                        .foregroundColor(AppTheme.primaryText)
                }
            }

            Text("Nodes checked: \(result.nodesExplored) • Time: \(String(format: "%.2f", result.elapsedTime))s")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }

    private func solve() {
        guard result == nil, !isSolving else { return }
        let options = MechanicalPuzzleSolveOptions.default
        let startedAt = Date()
        isSolving = true
        SolverDiagnosticsStore.shared.record(modeName: "Rush Hour", state: .solving, detail: SolveState.solving.friendlyMessage)

        DispatchQueue.main.asyncAfter(deadline: .now() + options.timeout + 0.25) {
            guard !self.didFinish else { return }
            let timeoutResult = MechanicalPuzzleSolveResult(
                kind: .rushHour,
                state: .timedOut,
                moves: [],
                playbackFrames: [OrderedMovePlaybackFrame(order: 0, move: nil, board: self.initialBoard, caption: "Start")],
                failureReason: "Rush Hour solver timed out before it could finish.",
                elapsedTime: Date().timeIntervalSince(startedAt),
                nodesExplored: 0
            )
            self.finish(with: timeoutResult)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let solved = RushHourSolver().solve(self.initialBoard, options: options)
            DispatchQueue.main.async {
                guard !self.didFinish else { return }
                self.finish(with: solved)
            }
        }
    }

    private func finish(with solved: MechanicalPuzzleSolveResult<RushHourBoard>) {
        didFinish = true
        result = solved
        selectedFrameIndex = 0
        isSolving = false
        SolverDiagnosticsStore.shared.record(modeName: "Rush Hour", state: solved.state, detail: solved.failureReason ?? statusText)
    }
}

private struct RushHourBoardView: View {
    let board: RushHourBoard
    let tileSize: CGFloat
    let showExit: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 2) {
                ForEach(0..<board.size.rows, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<board.size.columns, id: \.self) { column in
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: tileSize, height: tileSize)
                        }
                    }
                }
            }

            if showExit {
                Text("EXIT")
                    .font(.caption2.bold())
                    .foregroundColor(Color(hex: 0x99ffcc))
                    .offset(x: CGFloat(board.size.columns) * (tileSize + 2) + 6, y: CGFloat(RushHourBoard.exitRow) * (tileSize + 2) + tileSize * 0.35)
            }

            ForEach(board.pieces) { piece in
                Text(piece.label)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.black)
                    .frame(width: CGFloat(piece.size.columns) * tileSize + CGFloat(piece.size.columns - 1) * 2,
                           height: CGFloat(piece.size.rows) * tileSize + CGFloat(piece.size.rows - 1) * 2)
                    .background(piece.isPrimary ? Color(hex: 0xff99cc) : Color(hex: 0xccffff))
                    .cornerRadius(8)
                    .offset(x: CGFloat(piece.origin.column) * (tileSize + 2), y: CGFloat(piece.origin.row) * (tileSize + 2))
            }
        }
        .frame(width: CGFloat(board.size.columns) * tileSize + CGFloat(board.size.columns - 1) * 2,
               height: CGFloat(board.size.rows) * tileSize + CGFloat(board.size.rows - 1) * 2)
    }
}

struct MechanicalPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MechanicalPuzzleMenuView()
    }
}

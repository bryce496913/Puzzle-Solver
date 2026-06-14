//
//  MechanicalPuzzleViews.swift
//  Puzzle Solver
//
//  V1 mechanical puzzle menu. Unstable/sample-only solvers route to placeholders.
//

import SwiftUI

struct MechanicalPuzzleMenuView: View {
    private let descriptors = PuzzleAvailabilityCatalog.activeDescriptors(in: .mechanical)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.mechanical.rawValue, subtitle: PuzzleCategory.mechanical.subtitle) {
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
        if descriptor.id == "rush-hour" {
            RushHourView()
        } else {
            AppPlaceholderScreen(descriptor: descriptor)
        }
    }
}

struct RushHourView: View {
    @State private var result: MechanicalPuzzleSolveResult<RushHourBoard>?
    @State private var solveState: SolveState = .idle
    @State private var didFinish = false
    @State private var frameIndex = 0

    private var displayedBoard: RushHourBoard {
        guard let frames = result?.playbackFrames, frames.indices.contains(frameIndex) else { return .example }
        return frames[frameIndex].board
    }

    var body: some View {
        AppScreenContainer(title: "Rush Hour", subtitle: "Slide the red X car to the exit on the right.") {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader("V1 puzzle", subtitle: "This release includes a stable built-in board with bounded solving and step playback.")
                RushHourBoardView(board: displayedBoard)

                AppStatusBadge(text: solveState.friendlyTitle, state: solveState)
                if let result {
                    Text(result.failureReason ?? "Solution contains \(result.moves.count) moves.")
                        .appParagraph()
                    if !result.playbackFrames.isEmpty {
                        Text(result.playbackFrames[frameIndex].caption)
                            .appH3()
                        Text("Step \(frameIndex) of \(max(result.playbackFrames.count - 1, 0))").appH3()
                        HStack(spacing: 10) {
                            Button("Previous") { frameIndex = max(0, frameIndex - 1) }
                                .buttonStyle(AppSecondaryButtonStyle())
                                .disabled(frameIndex == 0)
                            Button("Next") { frameIndex = min(result.playbackFrames.count - 1, frameIndex + 1) }
                                .buttonStyle(AppPrimaryButtonStyle())
                                .disabled(frameIndex >= result.playbackFrames.count - 1)
                        }
                    }
                }

                Button(solveState == .solving ? "Solving…" : "Solve Rush Hour") { solve() }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(solveState == .solving)
                Button("Reset") { reset() }
                    .buttonStyle(AppResetButtonStyle())
            }
            .appCardStyle()
        }
    }

    private func solve() {
        solveState = .solving
        didFinish = false
        result = nil
        frameIndex = 0
        let timeout: TimeInterval = 5
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout + 0.25) {
            guard !didFinish else { return }
            didFinish = true
            solveState = .timedOut
            result = MechanicalPuzzleSolveResult(
                kind: .rushHour,
                state: .timedOut,
                moves: [],
                playbackFrames: [OrderedMovePlaybackFrame(order: 0, move: nil, board: .example, caption: "Start")],
                failureReason: "Rush Hour took too long to solve. The board was reset safely.",
                elapsedTime: timeout,
                nodesExplored: 0
            )
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let solved = RushHourSolver().solve(.example, options: MechanicalPuzzleSolveOptions(timeout: timeout, maxNodes: 100_000))
            DispatchQueue.main.async {
                guard !didFinish else { return }
                didFinish = true
                result = solved
                solveState = solved.state
            }
        }
    }

    private func reset() {
        result = nil
        solveState = .idle
        frameIndex = 0
        didFinish = true
    }
}

private struct RushHourBoardView: View {
    let board: RushHourBoard
    private let boardDimension = 6
    private let gridSpacing: CGFloat = 3
    private let boardPadding: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let available = geometry.size.width - (boardPadding * 2)
            let cellSize = (available - CGFloat(boardDimension - 1) * gridSpacing) / CGFloat(boardDimension)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.surface)

                VStack(spacing: gridSpacing) {
                    ForEach(0..<boardDimension, id: \.self) { _ in
                        HStack(spacing: gridSpacing) {
                            ForEach(0..<boardDimension, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(AppTheme.background.opacity(0.82))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .padding(boardPadding)

                ForEach(board.pieces) { piece in
                    vehicle(piece, cellSize: cellSize)
                }

                exitMarker(cellSize: cellSize)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.65), lineWidth: 1.5)
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.trailing, 18)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Six by six Rush Hour board with exit on row three")
    }

    private func vehicle(_ piece: MechanicalPuzzlePiece, cellSize: CGFloat) -> some View {
        let width = CGFloat(piece.size.columns) * cellSize + CGFloat(piece.size.columns - 1) * gridSpacing
        let height = CGFloat(piece.size.rows) * cellSize + CGFloat(piece.size.rows - 1) * gridSpacing
        let x = boardPadding + CGFloat(piece.origin.column) * (cellSize + gridSpacing)
        let y = boardPadding + CGFloat(piece.origin.row) * (cellSize + gridSpacing)

        return RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(piece.isPrimary ? AppTheme.highlight : AppTheme.accent)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(AppTheme.text.opacity(0.75), lineWidth: piece.isPrimary ? 2 : 1)
            )
            .overlay(
                Text(piece.label)
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)
            )
            .offset(x: x, y: y)
            .accessibilityLabel(piece.isPrimary ? "Red target car \(piece.label)" : "Vehicle \(piece.label)")
    }

    private func exitMarker(cellSize: CGFloat) -> some View {
        HStack(spacing: 3) {
            Rectangle()
                .fill(AppTheme.highlight)
                .frame(width: 4, height: cellSize * 0.68)
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.highlight)
        }
        .offset(
            x: boardPadding + CGFloat(boardDimension) * (cellSize + gridSpacing) - gridSpacing + 3,
            y: boardPadding + CGFloat(RushHourBoard.exitRow) * (cellSize + gridSpacing) + cellSize * 0.16
        )
        .accessibilityLabel("Exit")
    }
}

struct MechanicalPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { MechanicalPuzzleMenuView() }
    }
}

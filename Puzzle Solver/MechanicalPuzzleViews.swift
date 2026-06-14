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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(0..<36, id: \.self) { index in
                let coordinate = MechanicalBoardCoordinate(row: index / 6, column: index % 6)
                let piece = board.piece(at: coordinate)
                Text(piece?.label ?? "")
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .background(piece?.isPrimary == true ? AppTheme.highlight : (piece == nil ? AppTheme.background : AppTheme.accent))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel(piece.map { "Vehicle \($0.label)" } ?? "Empty")
            }
        }
        .padding(6)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MechanicalPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { MechanicalPuzzleMenuView() }
    }
}

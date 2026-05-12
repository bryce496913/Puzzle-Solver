//
//  ExperimentalPuzzleViews.swift
//  Puzzle Solver
//
//  Visual and experimental puzzle picker screens.
//

import SwiftUI

struct ExperimentalPuzzleMenuView: View {
    @State private var selectedKind: ExperimentalPuzzleKind = .jigsawSolver

    private var selectedDescriptor: ExperimentalPuzzleDescriptor {
        ExperimentalPuzzleCatalog.descriptors.first { $0.kind == selectedKind } ?? ExperimentalPuzzleCatalog.descriptors[0]
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    puzzlePicker
                    selectedPuzzleCard
                }
                .padding()
            }
        }
        .navigationTitle("Visual / Experimental")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Visual / Experimental")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(AppTheme.cyan)
                .accessibilityAddTraits(.isHeader)

            Text("Explore puzzle solvers that use image-like boards, graph search, or early-stage tactical engines.")
                .font(.body)
                .foregroundColor(AppTheme.secondaryText)
                .lineSpacing(3)
        }
    }

    private var puzzlePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Puzzle Picker")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            Picker("Visual or experimental puzzle", selection: $selectedKind) {
                ForEach(ExperimentalPuzzleCatalog.descriptors) { descriptor in
                    Text(descriptor.kind.displayName).tag(descriptor.kind)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
        }
    }

    private var selectedPuzzleCard: some View {
        ExperimentalPuzzleSelectionCard(descriptor: selectedDescriptor)
    }
}

private struct ExperimentalPuzzleSelectionCard: View {
    let descriptor: ExperimentalPuzzleDescriptor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(accentColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(descriptor.kind.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.primaryText)

                    Text(descriptor.notes)
                        .font(.callout)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(3)
                }
            }

            statusPill

            NavigationLink(destination: destination(for: descriptor.kind)) {
                Text(actionTitle)
                    .appButtonLabel()
            }
            .buttonStyle(AppButtonStyle(color: accentColor))
            .accessibilityHint(accessibilityHint)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(22)
    }

    private var symbol: String {
        switch descriptor.kind {
        case .maze: return "point.topleft.down.curvedto.point.bottomright.up"
        case .chessMateInN, .chessBestMove: return "checkerboard.rectangle"
        case .jigsawSolver: return "puzzlepiece.extension.fill"
        }
    }

    private var accentColor: Color {
        switch descriptor.kind {
        case .maze: return AppTheme.green
        case .chessMateInN, .chessBestMove: return AppTheme.lavender
        case .jigsawSolver: return AppTheme.pink
        }
    }

    private var statusPill: some View {
        Text(descriptor.solverAvailable ? "Solver available" : "Coming soon")
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(descriptor.solverAvailable ? AppTheme.green.opacity(0.9) : AppTheme.amber.opacity(0.9))
            .foregroundColor(.black)
            .cornerRadius(10)
    }

    private var actionTitle: String {
        descriptor.kind == .jigsawSolver ? "Preview Jigsaw Solver" : "View Mode Status"
    }

    private var accessibilityHint: String {
        descriptor.kind == .jigsawSolver ? "Opens the Jigsaw Solver coming soon screen." : "Opens the experimental mode status screen."
    }

    @ViewBuilder
    private func destination(for kind: ExperimentalPuzzleKind) -> some View {
        switch kind {
        case .jigsawSolver:
            JigsawComingSoonView()
        default:
            ExperimentalModeStatusView(descriptor: descriptor)
        }
    }
}

private struct ExperimentalModeStatusView: View {
    let descriptor: ExperimentalPuzzleDescriptor

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundColor(AppTheme.cyan)

                Text(descriptor.kind.displayName)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(descriptor.notes)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(descriptor.solverAvailable ? "Core solver architecture is available for diagnostics; a dedicated input flow is planned." : "Placeholder architecture is ready for future implementation.")
                    .font(.callout)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle(descriptor.kind.displayName)
    }
}

struct JigsawComingSoonView: View {
    private let roadmap = [
        "Import or capture a puzzle image.",
        "Detect individual pieces and estimate edge shapes.",
        "Match tabs, blanks, colors, and image continuity before presenting a guided assembly plan."
    ]

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    hero
                    roadmapCard
                    architectureCard
                }
                .padding()
            }
        }
        .navigationTitle("Jigsaw Solver")
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(AppTheme.pink)
                .accessibilityHidden(true)

            Text("Jigsaw Solver")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)

            Text("Coming Soon")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.amber.opacity(0.9))
                .foregroundColor(.black)
                .cornerRadius(12)

            Text("The model layer is in place now so image-based solving can be added without disrupting the existing sliding, logic, mechanical, and experimental solvers.")
                .font(.body)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(26)
    }

    private var roadmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned Image Pipeline")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            ForEach(Array(roadmap.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                        .background(AppTheme.cyan)
                        .foregroundColor(.black)
                        .clipShape(Circle())

                    Text(item)
                        .font(.callout)
                        .foregroundColor(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }

    private var architectureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Placeholder Architecture")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            Label("JigsawPuzzle stores board dimensions and piece placement.", systemImage: "square.grid.3x3.fill")
            Label("JigsawPiece stores labels and per-edge shape metadata.", systemImage: "puzzlepiece.fill")
            Label("JigsawSolver returns an unsupported result until image detection and matching heuristics are implemented.", systemImage: "wand.and.stars")
        }
        .font(.callout)
        .foregroundColor(AppTheme.secondaryText)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }
}

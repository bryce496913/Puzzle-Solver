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
            .buttonStyle(AppPrimaryButtonStyle(isDisabledAppearance: !descriptor.solverAvailable))
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
        descriptor.solverAvailable ? "View Mode Status" : "Coming Soon"
    }

    private var accessibilityHint: String {
        descriptor.solverAvailable ? "Opens the experimental mode status screen." : "Opens the shared coming soon screen."
    }

    @ViewBuilder
    private func destination(for kind: ExperimentalPuzzleKind) -> some View {
        if descriptor.solverAvailable {
            ExperimentalModeStatusView(descriptor: descriptor)
        } else {
            ComingSoonView(
                title: descriptor.kind.displayName,
                summary: descriptor.notes,
                plannedItems: [
                    "Import or capture a puzzle image.",
                    "Detect individual pieces and estimate edge shapes.",
                    "Match tabs, blanks, colors, and image continuity before presenting a guided assembly plan."
                ],
                architectureNotes: [
                    "JigsawPuzzle stores board dimensions and piece placement.",
                    "JigsawPiece stores labels and per-edge shape metadata.",
                    "JigsawSolver returns an unsupported result until image detection and matching heuristics are implemented."
                ],
                symbol: "puzzlepiece.extension.fill",
                accentColor: AppTheme.pink
            )
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


struct ComingSoonView: View {
    let title: String
    let summary: String
    var plannedItems: [String] = []
    var architectureNotes: [String] = []
    var symbol: String = "clock.badge.exclamationmark.fill"
    var accentColor: Color = AppTheme.amber

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    heroCard
                    if !plannedItems.isEmpty { plannedCard }
                    if !architectureNotes.isEmpty { architectureCard }
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 58, weight: .semibold))
                .foregroundColor(accentColor)
                .accessibilityHidden(true)

            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("Coming Soon")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(AppTheme.text.opacity(0.62))
                .background(AppTheme.surface.opacity(0.58))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(summary)
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

    private var plannedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned Work")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            ForEach(Array(plannedItems.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                        .background(accentColor)
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

            ForEach(architectureNotes, id: \.self) { note in
                Label(note, systemImage: "checkmark.seal.fill")
            }
        }
        .font(.callout)
        .foregroundColor(AppTheme.secondaryText)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
    }
}

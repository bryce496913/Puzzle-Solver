//
//  ExperimentalPuzzleViews.swift
//  Puzzle Solver
//
//  V1 visual/experimental puzzle menu. All modes are placeholders.
//

import SwiftUI

struct ExperimentalPuzzleMenuView: View {
    private let descriptors = PuzzleAvailabilityCatalog.descriptors(in: .visual)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.visual.rawValue, subtitle: PuzzleCategory.visual.subtitle) {
            LazyVStack(spacing: 12) {
                ForEach(descriptors) { descriptor in
                    NavigationLink(destination: AppPlaceholderScreen(descriptor: descriptor)) {
                        AppPuzzleCard(descriptor: descriptor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!descriptor.status.isInteractive)
                }
            }
        }
    }
}

struct ComingSoonView: View {
    let title: String
    let summary: String
    var plannedItems: [String] = []
    var architectureNotes: [String] = []
    var symbol: String = "clock.badge.exclamationmark.fill"
    var accentColor: Color = AppTheme.highlight

    var body: some View {
        AppPlaceholderScreen(
            descriptor: PuzzleAvailabilityDescriptor(
                id: title.lowercased().replacingOccurrences(of: " ", with: "-"),
                category: .visual,
                title: title,
                shortDescription: summary,
                icon: symbol,
                status: .comingSoon
            )
        )
    }
}

struct ExperimentalPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { ExperimentalPuzzleMenuView() }
    }
}

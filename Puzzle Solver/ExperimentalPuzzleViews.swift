//
//  ExperimentalPuzzleViews.swift
//  Puzzle Solver
//
//  V1 visual/experimental puzzle menu. All modes are placeholders.
//

import SwiftUI

struct ComingSoonView: View {
    var body: some View {
        AppScreenContainer(title: "Coming Soon", subtitle: "Future puzzle solvers planned for later updates.") {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(PuzzleCategory.allCases.filter { !PuzzleAvailabilityCatalog.comingSoonDescriptors(in: $0).isEmpty }) { category in
                    AppSectionHeader(category.rawValue)
                    ForEach(PuzzleAvailabilityCatalog.comingSoonDescriptors(in: category)) { descriptor in
                        AppPuzzleCard(descriptor: descriptor)
                            .accessibilityHint("Informational only. No solver opens.")
                    }
                }
            }
        }
    }
}

struct ExperimentalPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { ComingSoonView() }
    }
}

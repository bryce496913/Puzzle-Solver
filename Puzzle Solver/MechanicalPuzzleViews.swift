//
//  MechanicalPuzzleViews.swift
//  Puzzle Solver
//
//  V1 mechanical puzzle menu. Unstable/sample-only solvers route to placeholders.
//

import SwiftUI

struct MechanicalPuzzleMenuView: View {
    private let descriptors = PuzzleAvailabilityCatalog.descriptors(in: .mechanical)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.mechanical.rawValue, subtitle: PuzzleCategory.mechanical.subtitle) {
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

struct MechanicalPuzzleMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { MechanicalPuzzleMenuView() }
    }
}

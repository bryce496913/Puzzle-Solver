//
//  HowView.swift
//  Puzzle Solver
//
//  Release guidance.
//

import SwiftUI

struct HowView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppScreenContainer(title: "How It Works", subtitle: "The app stays small, bounded, and predictable.") {
            VStack(alignment: .leading, spacing: 12) {
                HowCard(title: "Active puzzle solvers", detail: "Sliding puzzles, cubes, Sudoku, and Rush Hour are active because they meet the release reliability criteria.", symbol: "checkmark.circle.fill", color: AppTheme.accent)
                HowCard(title: "Clear solver states", detail: "Active solve flows validate input, solve with time limits, and end with a visible solved, invalid, no-solution, timed-out, failed, or unavailable state.", symbol: "clock.badge.checkmark", color: AppTheme.highlight)
                HowCard(title: "Placeholders are intentional", detail: "Partially working or experimental modes open a shared placeholder screen instead of fake solving or risking stuck loading.", symbol: "pause.circle.fill", color: AppTheme.highlight)

                Button("Back") { dismiss() }
                    .buttonStyle(AppBackButtonStyle())
            }
        }
    }
}

private struct HowCard: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title).appH2()
                Text(detail).appParagraph().fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCardStyle()
        .accessibilityElement(children: .combine)
    }
}

struct HowView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { HowView() }
    }
}

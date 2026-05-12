//
//  HowView.swift
//  Puzzle Solver
//
//  Created by Bryceon 30/1/24.
//

import SwiftUI

struct HowView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("How It Works")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(AppTheme.pink)
                        .accessibilityAddTraits(.isHeader)

                    Text("Puzzle Solver validates every puzzle before solving and uses bounded searches so Version 1 never appears to load forever.")
                        .font(.body)
                        .foregroundColor(AppTheme.secondaryText)

                    HowCard(title: "Supported in Version 1", detail: "Sliding puzzles, Sudoku, Rush Hour, Maze, Chess helper flows, plus bounded twisty puzzle demos for 2×2, 3×3, Pyraminx, and Skewb.", symbol: "checkmark.circle.fill", color: AppTheme.green)
                    HowCard(title: "Clear solver states", detail: "Results report Solving, Solved, Invalid, Failed, Timed Out, or Solver Unavailable with user-facing guidance.", symbol: "clock.badge.checkmark", color: AppTheme.cyan)
                    HowCard(title: "Placeholders are safe", detail: "4×4, 5×5, Megaminx, Square-1, and future catalogs describe planned support without starting indefinite work.", symbol: "pause.circle.fill", color: AppTheme.amber)

                    Button("Back") { dismiss() }
                        .buttonStyle(AppSecondaryButtonStyle())
                        .font(.headline.weight(.semibold))
                        .padding(.top)
                }
                .padding()
            }
        }
        .navigationTitle("How It Works")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HowCard: View {
    let title: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundColor(color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct HowView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HowView()
        }
    }
}

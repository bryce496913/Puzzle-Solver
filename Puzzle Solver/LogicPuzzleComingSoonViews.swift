import SwiftUI

private struct LogicPuzzleComingSoonCardView: View {
    let puzzleName: String
    let icon: String
    let featureBullets: [String]

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.large) {
                VStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.highlight)

                    Text(puzzleName)
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    Text("Coming Soon")
                        .appTextStyle(.h2)
                        .foregroundStyle(AppTheme.Colors.text)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Planned support includes:")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.9))

                    ForEach(featureBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                            Text("•")
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.highlight)
                            Text(bullet)
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.text.opacity(0.84))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppTheme.Spacing.xLarge)
            .appSurfaceCard()
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .navigationTitle(puzzleName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KakuroComingSoonView: View {
    var body: some View {
        LogicPuzzleComingSoonCardView(
            puzzleName: "Kakuro",
            icon: "plus.forwardslash.minus",
            featureBullets: [
                "Across clues with target sums",
                "Down clues with target sums",
                "Digit constraints limited to 1–9",
                "No repeated digits in each clue run"
            ]
        )
    }
}

struct KillerSudokuComingSoonView: View {
    var body: some View {
        LogicPuzzleComingSoonCardView(
            puzzleName: "Killer Sudoku",
            icon: "flame.fill",
            featureBullets: [
                "Cages with target sums",
                "No duplicate digits in a cage",
                "Full normal Sudoku row/column/box rules"
            ]
        )
    }
}

struct NonogramComingSoonView: View {
    var body: some View {
        LogicPuzzleComingSoonCardView(
            puzzleName: "Nonogram",
            icon: "square.grid.4x3.fill",
            featureBullets: [
                "Row and column clues",
                "Filled, empty, and unknown cell states",
                "Constraint-based solving with step explanations"
            ]
        )
    }
}

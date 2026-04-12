import SwiftUI

struct SlidingPuzzleSizeSelectionView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Sliding Puzzle")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    Text("Choose a board size")
                        .appTextStyle(.h2)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
                }

                VStack(spacing: AppTheme.Spacing.medium) {
                    NavigationLink {
                        SlidingPuzzleEntryView(boardSize: 3)
                    } label: {
                        PuzzleTypeCard(
                            title: "3×3 Puzzle",
                            subtitle: "Classic mode",
                            icon: "square.grid.3x3.fill",
                            accentVariant: .accent
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SlidingPuzzleEntryView(boardSize: 4)
                    } label: {
                        PuzzleTypeCard(
                            title: "4×4 Puzzle",
                            subtitle: "Advanced mode",
                            icon: "square.grid.3x3",
                            accentVariant: .highlight
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.top, AppTheme.Spacing.xLarge)
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .navigationTitle("Sliding Puzzle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SlidingPuzzleSizeSelectionView()
    }
}

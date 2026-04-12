import SwiftUI

struct TwistyPuzzlePickerView: View {
    private let twistyPuzzleTypes = TwistyPuzzleType.catalog

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Twisty Puzzles")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    Text("Choose a twisty puzzle type")
                        .appTextStyle(.h2)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.top, AppTheme.Spacing.xLarge)

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(twistyPuzzleTypes) { catalogItem in
                            NavigationLink {
                                destinationView(for: catalogItem.puzzleType)
                            } label: {
                                PuzzleTypeCard(
                                    title: catalogItem.title,
                                    subtitle: catalogItem.subtitle,
                                    icon: catalogItem.icon,
                                    isEnabled: catalogItem.isEnabled,
                                    accentVariant: catalogItem.isEnabled ? .accent : .highlight
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.bottom, AppTheme.Spacing.xLarge)
                }
            }
        }
        .navigationTitle("Twisty Puzzles")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func destinationView(for puzzleType: TwistyPuzzleType) -> some View {
        switch puzzleType {
        case .cube2x2:
            Cube2x2EntryView()
        case .cube3x3, .pyraminx, .skewb:
            FutureTwistyPuzzlePlaceholderView(puzzleType: puzzleType)
        }
    }
}

#Preview {
    NavigationStack {
        TwistyPuzzlePickerView()
    }
}

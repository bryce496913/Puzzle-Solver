import SwiftUI

struct TwistyPuzzlePickerView: View {
    private let twistyPuzzleTypes = TwistyPuzzleType.catalog

    private var activePuzzles: [TwistyPuzzleCatalogItem] {
        twistyPuzzleTypes.filter(\.isEnabled)
    }

    private var comingSoonPuzzles: [TwistyPuzzleCatalogItem] {
        twistyPuzzleTypes.filter { !$0.isEnabled }
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Twisty Puzzles",
                subtitle: "Choose a twisty puzzle type"
            )

            if !activePuzzles.isEmpty {
                sectionTitle("Available now")
                ForEach(activePuzzles) { catalogItem in
                    NavigationLink {
                        destinationView(for: catalogItem.puzzleType)
                    } label: {
                        PuzzleTypeCard(
                            title: catalogItem.title,
                            subtitle: catalogItem.subtitle,
                            icon: catalogItem.icon,
                            isEnabled: true,
                            accentVariant: .accent
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if !comingSoonPuzzles.isEmpty {
                sectionTitle("Coming soon")
                ForEach(comingSoonPuzzles) { catalogItem in
                    NavigationLink {
                        destinationView(for: catalogItem.puzzleType)
                    } label: {
                        PuzzleTypeCard(
                            title: catalogItem.title,
                            subtitle: catalogItem.subtitle,
                            icon: catalogItem.icon,
                            isEnabled: false,
                            accentVariant: .highlight
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Twisty Puzzles")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appTextStyle(.paragraph)
            .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func destinationView(for puzzleType: TwistyPuzzleType) -> some View {
        switch puzzleType {
        case .cube2x2:
            Cube2x2EntryView()
        case .cube3x3:
            Cube3x3EntryView()
        case .pyraminx, .skewb:
            FutureTwistyPuzzlePlaceholderView(puzzleType: puzzleType)
        }
    }
}

#Preview {
    NavigationStack {
        TwistyPuzzlePickerView()
    }
}

import SwiftUI

struct TwistyPuzzlePickerView: View {
    private let twistyPuzzleTypes = TwistyPuzzleType.catalog

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "Twisty Puzzles",
                subtitle: "Choose a twisty puzzle type"
            )

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
        .navigationTitle("Twisty Puzzles")
        .navigationBarTitleDisplayMode(.inline)
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

import SwiftUI

struct LogicPuzzlePickerView: View {
    private let puzzleTypes = LogicPuzzleType.allCases.map {
        LogicPuzzleCatalogItem(puzzleType: $0, subtitle: $0.availabilitySubtitle)
    }

    private var activePuzzles: [LogicPuzzleCatalogItem] {
        puzzleTypes.filter(\.isEnabled)
    }

    private var comingSoonPuzzles: [LogicPuzzleCatalogItem] {
        puzzleTypes.filter { !$0.isEnabled }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    TwistyScreenHeader(
                        title: "Logic Puzzles",
                        subtitle: "Choose a logic puzzle type"
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
                .padding(AppTheme.Spacing.large)
            }
        }
        .navigationTitle("Logic Puzzles")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appTextStyle(.paragraph)
            .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func destinationView(for puzzleType: LogicPuzzleType) -> some View {
        switch puzzleType {
        case .sudoku:
            SudokuEntryView()
        case .killerSudoku:
            KillerSudokuComingSoonView()
        case .nonogram:
            NonogramComingSoonView()
        case .kakuro:
            KakuroComingSoonView()
        }
    }
}

private struct LogicPuzzleCatalogItem: Identifiable {
    let puzzleType: LogicPuzzleType
    let subtitle: String

    var id: LogicPuzzleType { puzzleType }
    var title: String { puzzleType.title }
    var icon: String { puzzleType.icon }
    var isEnabled: Bool { puzzleType.isEnabled }
}

#Preview {
    NavigationStack {
        LogicPuzzlePickerView()
    }
}

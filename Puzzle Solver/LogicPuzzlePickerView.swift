import SwiftUI

struct LogicPuzzlePickerView: View {
    private let puzzleTypes = LogicPuzzleType.allCases

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

                    PuzzleCategorySectionsView(
                        items: puzzleTypes,
                        title: { $0.title },
                        subtitle: { $0.availabilitySubtitle },
                        icon: { $0.icon },
                        isEnabled: { $0.isEnabled },
                        destination: destinationView(for:)
                    )
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .navigationTitle("Logic Puzzles")
        .navigationBarTitleDisplayMode(.inline)
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


#Preview {
    NavigationStack {
        LogicPuzzlePickerView()
    }
}

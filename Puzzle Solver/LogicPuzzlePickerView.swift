import SwiftUI

struct LogicPuzzlePickerView: View {
    private let puzzleTypes = LogicPuzzleType.catalog

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
        case .killerSudoku, .nonogram, .kakuro:
            LogicPuzzleComingSoonView(puzzleName: puzzleType.title)
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

private enum LogicPuzzleType: String, CaseIterable, Identifiable {
    case sudoku
    case killerSudoku
    case nonogram
    case kakuro

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sudoku:
            return "Sudoku"
        case .killerSudoku:
            return "Killer Sudoku"
        case .nonogram:
            return "Nonogram"
        case .kakuro:
            return "Kakuro"
        }
    }

    var icon: String {
        switch self {
        case .sudoku:
            return "number.square.fill"
        case .killerSudoku:
            return "flame.fill"
        case .nonogram:
            return "square.grid.4x3.fill"
        case .kakuro:
            return "plus.forwardslash.minus"
        }
    }

    var isEnabled: Bool {
        self == .sudoku
    }

    static var catalog: [LogicPuzzleCatalogItem] {
        [
            LogicPuzzleCatalogItem(puzzleType: .sudoku, subtitle: "Ready now"),
            LogicPuzzleCatalogItem(puzzleType: .killerSudoku, subtitle: "Coming soon"),
            LogicPuzzleCatalogItem(puzzleType: .nonogram, subtitle: "Coming soon"),
            LogicPuzzleCatalogItem(puzzleType: .kakuro, subtitle: "Coming soon")
        ]
    }
}

struct SudokuEntryView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    TwistyScreenHeader(
                        title: "Sudoku",
                        subtitle: "Phase 5 logic puzzle support is active."
                    )

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Sudoku route is live")
                            .appTextStyle(.h2)

                        Text("This is the initial Sudoku entry point. Solver and advanced gameplay flows can now be layered on this route in upcoming phases.")
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appSurfaceCard()
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .navigationTitle("Sudoku")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LogicPuzzleComingSoonView: View {
    let puzzleName: String

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Text(puzzleName)
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)
                        .multilineTextAlignment(.center)

                    Text("Coming Soon")
                        .appTextStyle(.h2)
                        .foregroundStyle(AppTheme.Colors.text)

                    Text("This logic puzzle is planned for a future version.")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 320)
                .padding(AppTheme.Spacing.xLarge)
                .appSurfaceCard()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .navigationTitle(puzzleName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LogicPuzzlePickerView()
    }
}

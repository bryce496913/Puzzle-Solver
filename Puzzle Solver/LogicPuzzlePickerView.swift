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

struct SudokuEntryView: View {
    @State private var isSolving = false
    @State private var resultMessage = "Tap solve to run a demo Sudoku puzzle."
    @State private var solvedGrid: SudokuGrid?

    private let solver = SudokuSolver()
    private let demoGrid = SudokuGrid(rows: [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9]
    ]) ?? SudokuGrid()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    TwistyScreenHeader(
                        title: "Sudoku",
                        subtitle: "Backtracking solver with candidate-based optimization."
                    )

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Sudoku solver ready")
                            .appTextStyle(.h2)

                        Text(resultMessage)
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text.opacity(0.82))

                        if let solvedGrid {
                            Text(solvedGrid.rows().map { $0.map(String.init).joined(separator: " ") }.joined(separator: "\n"))
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(AppTheme.Colors.text.opacity(0.86))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task {
                                await solveDemoPuzzle()
                            }
                        } label: {
                            if isSolving {
                                ProgressView()
                            } else {
                                Text("Solve Demo Puzzle")
                                    .appTextStyle(.button)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.Colors.accent)
                        .disabled(isSolving)
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

    @MainActor
    private func solveDemoPuzzle() async {
        isSolving = true
        solvedGrid = nil

        let result = await solver.solveOffMainThread(demoGrid)

        switch (result.validity, result.completion, result.output) {
        case (.invalid(let errors), _, _):
            resultMessage = errors.first?.localizedDescription ?? "The Sudoku input is invalid."
        case (.valid, .solved, let solved?):
            solvedGrid = solved
            resultMessage = "Solved successfully."
        case (.valid, .unsolved, _):
            resultMessage = "No solution exists for this puzzle."
        default:
            resultMessage = "Sudoku could not be solved."
        }

        isSolving = false
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

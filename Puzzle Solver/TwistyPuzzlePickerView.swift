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
        case .pyraminx:
            PyraminxEntryView()
        case .skewb:
            SkewbEntryView()
        }
    }
}

private struct PyraminxEntryView: View {
    var body: some View {
        TwistySimpleTokenEntryView(
            puzzleType: .pyraminx,
            subtitle: "Enter your Pyraminx scramble or state tokens in WCA notation.",
            helperText: "Example: R U L' B U' R'. We'll parse each token and pass it to the puzzle mode.",
            makeState: { tokens in PyraminxState(stickerTokens: tokens) }
        )
    }
}

private struct SkewbEntryView: View {
    var body: some View {
        TwistySimpleTokenEntryView(
            puzzleType: .skewb,
            subtitle: "Enter your Skewb scramble or state tokens in WCA notation.",
            helperText: "Example: R L' U B' R'. We'll parse each token and pass it to the puzzle mode.",
            makeState: { tokens in SkewbState(stickerTokens: tokens) }
        )
    }
}

private struct TwistySimpleTokenEntryView<State: TwistyPuzzleState>: View {
    @Environment(\.dismiss) private var dismiss

    let puzzleType: TwistyPuzzleType
    let subtitle: String
    let helperText: String
    let makeState: ([String]) -> State

    @State private var tokenInput = ""
    @State private var solveState: State?
    @State private var shouldNavigateToSolve = false

    private var tokens: [String] {
        tokenInput
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private var validation: TwistyEntryValidationStatus {
        if tokens.isEmpty {
            return .incomplete("Enter at least one move token to continue.")
        }
        return .ready("Looks good. \(tokens.count) token\(tokens.count == 1 ? "" : "s") detected.")
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "\(puzzleType.metadata.shortTitle) Entry",
                subtitle: subtitle
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("How to enter")
                    .appTextStyle(.h2)
                Text(helperText)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.86))
                Text(validation.message)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(validation.messageColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurfaceCard()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Move tokens")
                    .appTextStyle(.h2)

                TextEditor(text: $tokenInput)
                    .frame(minHeight: 120)
                    .padding(AppTheme.Spacing.xSmall)
                    .background(AppTheme.Colors.background.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))

                Text("Detected: \(tokens.joined(separator: " "))")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurfaceCard()

            Button("Solve") {
                solveState = makeState(tokens)
                shouldNavigateToSolve = true
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(!validation.isReady)
            .opacity(validation.isReady ? 1 : 0.5)

            HStack(spacing: AppTheme.Spacing.medium) {
                Button("Back") { dismiss() }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))

                Button("Reset") { tokenInput = "" }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(puzzleType.metadata.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToSolve) {
            if let solveState {
                TwistySimpleSolveView(initialState: solveState)
            }
        }
    }
}

private struct TwistySimpleSolveView<State: TwistyPuzzleState>: View {
    let initialState: State

    @State private var isSolving = true
    @State private var solveResult: TwistySolveResult?

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: "\(initialState.puzzleType.metadata.shortTitle) Solution",
                subtitle: "Review solving output for your entered tokens."
            )

            if isSolving {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    ProgressView()
                        .tint(AppTheme.Colors.highlight)
                    Text("Solving \(initialState.puzzleType.metadata.shortTitle)…")
                        .appTextStyle(.h2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appSurfaceCard()
            } else if let solveResult {
                TwistySolveSummaryCard(result: solveResult)
                TwistyNumberedMoveListView(title: "Ordered move list", moves: solveResult.moves)

                ForEach(solveResult.makeStepViewData()) { step in
                    TwistyStepCardView(step: step)
                }
            }
        }
        .task {
            await solve()
        }
        .navigationTitle("\(initialState.puzzleType.metadata.shortTitle) Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func solve() async {
        let result: TwistySolveResult

        switch initialState.puzzleType {
        case .pyraminx:
            guard let state = initialState as? PyraminxState else { return }
            result = await Task.detached(priority: .userInitiated) {
                await PyraminxSolver().solve(from: state)
            }.value
        case .skewb:
            guard let state = initialState as? SkewbState else { return }
            result = await Task.detached(priority: .userInitiated) {
                await SkewbSolver().solve(from: state)
            }.value
        case .cube2x2, .cube3x3:
            return
        }

        solveResult = result
        isSolving = false
    }
}

#Preview {
    NavigationStack {
        TwistyPuzzlePickerView()
    }
}

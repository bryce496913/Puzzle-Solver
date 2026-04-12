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
            ComingSoonPuzzleView(puzzleName: puzzleType.metadata.title)
        }
    }
}

private struct Cube2x2EntryView: View {
    @State private var scrambleText = ""
    @State private var isSolving = false
    @State private var solveResult: TwistySolveResult?
    @State private var inputError: String?

    private let notationRenderer = StandardTwistyNotationRenderer()

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    Text("2×2 Cube")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Enter scramble notation")
                            .appTextStyle(.h2)
                            .foregroundStyle(AppTheme.Colors.text)

                        TextField("Example: R U R' F U'", text: $scrambleText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled(true)
                            .padding(AppTheme.Spacing.small)
                            .background(AppTheme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))

                        Text("Supported moves: U, U', R, R', F, F'. Moves are space-separated.")
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text.opacity(0.78))

                        if let inputError {
                            Text(inputError)
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.highlight)
                        }
                    }
                    .appSurfaceCard()

                    Button {
                        Task { await solveCube() }
                    } label: {
                        Text(isSolving ? "Solving…" : "Solve 2×2")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(isSolving)

                    if let solveResult {
                        solveSummaryCard(for: solveResult)

                        ForEach(solveResult.makeStepViewData(renderer: notationRenderer)) { stepData in
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                                Text("Step \(stepData.stepNumber): \(stepData.primaryText)")
                                    .appTextStyle(.h3)
                                    .foregroundStyle(AppTheme.Colors.text)
                                if let secondaryText = stepData.secondaryText {
                                    Text(secondaryText)
                                        .appTextStyle(.paragraph)
                                        .foregroundStyle(AppTheme.Colors.text.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appSurfaceCard()
                        }
                    }
                }
                .padding(AppTheme.Spacing.large)
            }
        }
        .navigationTitle("2×2 Cube")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func solveSummaryCard(for result: TwistySolveResult) -> some View {
        let summary = result.makeSummaryViewData()
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(summary.statusText)
                .appTextStyle(.h2)
                .foregroundStyle(result.isSolvable ? AppTheme.Colors.text : AppTheme.Colors.highlight)
            Text(summary.moveCountText)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text)
            Text(summary.stepCountText)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.86))
            if let finalStateDescription = result.finalStateDescription {
                Text("Final state: \(finalStateDescription)")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    @MainActor
    private func solveCube() async {
        inputError = nil
        solveResult = nil
        isSolving = true

        let parsing = parseScramble(scrambleText)
        guard let scrambleMoves = parsing.moves else {
            inputError = parsing.errorMessage
            isSolving = false
            return
        }

        let initialState = scrambleMoves.reduce(Cube2x2State.solved) { partialState, move in
            partialState.applying(move)
        }

        let result = await Task.detached(priority: .userInitiated) {
            await Cube2x2Solver().solve(from: initialState)
        }.value

        solveResult = result
        isSolving = false
    }

    private func parseScramble(_ raw: String) -> (moves: [Cube2x2Move]?, errorMessage: String?) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ([], nil)
        }

        var parsedMoves: [Cube2x2Move] = []
        for token in trimmed.split(whereSeparator: \.isWhitespace) {
            guard let move = Cube2x2Move(rawValue: String(token)) else {
                return (nil, "Unsupported move: \(token). Use only U, U', R, R', F, F'.")
            }
            parsedMoves.append(move)
        }

        return (parsedMoves, nil)
    }
}

#Preview {
    NavigationStack {
        TwistyPuzzlePickerView()
    }
}

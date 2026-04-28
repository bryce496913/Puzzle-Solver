import SwiftUI

struct MechanicalPuzzlePickerView: View {
    private let puzzleTypes = MechanicalPuzzleType.allCases

    private var activePuzzles: [MechanicalPuzzleType] {
        puzzleTypes.filter(\.isEnabled)
    }

    private var comingSoonPuzzles: [MechanicalPuzzleType] {
        puzzleTypes.filter { !$0.isEnabled }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    TwistyScreenHeader(
                        title: "Mechanical Puzzles",
                        subtitle: "Choose a mechanical puzzle type"
                    )

                    if !activePuzzles.isEmpty {
                        sectionTitle("Available now")
                        ForEach(activePuzzles) { puzzleType in
                            NavigationLink {
                                destinationView(for: puzzleType)
                            } label: {
                                PuzzleTypeCard(
                                    title: puzzleType.title,
                                    subtitle: puzzleType.subtitle,
                                    icon: puzzleType.icon,
                                    isEnabled: true,
                                    accentVariant: .accent
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !comingSoonPuzzles.isEmpty {
                        sectionTitle("Coming soon")
                        ForEach(comingSoonPuzzles) { puzzleType in
                            NavigationLink {
                                destinationView(for: puzzleType)
                            } label: {
                                PuzzleTypeCard(
                                    title: puzzleType.title,
                                    subtitle: puzzleType.subtitle,
                                    icon: puzzleType.icon,
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
        .navigationTitle("Mechanical Puzzles")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appTextStyle(.paragraph)
            .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func destinationView(for puzzleType: MechanicalPuzzleType) -> some View {
        switch puzzleType {
        case .rushHour:
            RushHourEntryView()
        case .lightsOut:
            MechanicalComingSoonView(
                puzzleType: puzzleType,
                details: [
                    "Tap-to-toggle behavior for each pressed cell plus orthogonal neighbors.",
                    "Board sizes optimized for classic 5×5 layouts and custom practice grids.",
                    "Step-by-step elimination output generated from a binary linear solve."
                ]
            )
        case .klotski, .pegSolitaire, .towersOfHanoi:
            MechanicalComingSoonView(puzzleType: puzzleType)
        }
    }
}

private struct MechanicalComingSoonView: View {
    let puzzleType: MechanicalPuzzleType
    let details: [String]

    init(puzzleType: MechanicalPuzzleType, details: [String] = []) {
        self.puzzleType = puzzleType
        self.details = details
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: puzzleType.icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.highlight)

                Text(puzzleType.title)
                    .appTextStyle(.h1)
                    .foregroundStyle(AppTheme.Colors.highlight)

                Text("Coming Soon")
                    .appTextStyle(.h2)
                    .foregroundStyle(AppTheme.Colors.text)

                if details.isEmpty {
                    Text("This mechanical puzzle is planned for a future Phase 6 polish pass.")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.84))
                        .multilineTextAlignment(.center)
                } else {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Planned support includes:")
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text.opacity(0.9))

                        ForEach(details, id: \.self) { detail in
                            bulletRow(detail)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppTheme.Spacing.xLarge)
            .appSurfaceCard()
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .navigationTitle(puzzleType.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
            Text("•")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.highlight)
            Text(text)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.84))
        }
    }
}

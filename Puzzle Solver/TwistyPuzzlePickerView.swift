import SwiftUI

struct TwistyPuzzlePickerView: View {
    private let twistyPuzzleTypes = TwistyPuzzleType.all

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
                        ForEach(twistyPuzzleTypes) { puzzleType in
                            NavigationLink {
                                destinationView(for: puzzleType)
                            } label: {
                                PuzzleTypeCard(
                                    title: puzzleType.title,
                                    subtitle: puzzleType.subtitle,
                                    icon: puzzleType.icon,
                                    isEnabled: puzzleType.availability == .available,
                                    accentVariant: puzzleType.accentVariant
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
        switch puzzleType.destination {
        case .cube2x2:
            Cube2x2EntryView()
        case .comingSoon:
            ComingSoonPuzzleView(puzzleName: puzzleType.title)
        }
    }
}

private struct TwistyPuzzleType: Identifiable {
    enum Availability {
        case available
        case comingSoon

        var subtitle: String {
            switch self {
            case .available:
                return "Phase 2 target"
            case .comingSoon:
                return "Coming soon"
            }
        }
    }

    enum Destination {
        case cube2x2
        case comingSoon
    }

    let id: String
    let title: String
    let icon: String
    let availability: Availability
    let destination: Destination

    var subtitle: String {
        availability.subtitle
    }

    var accentVariant: PuzzleTypeCard.AccentVariant {
        availability == .available ? .accent : .highlight
    }

    static let all: [TwistyPuzzleType] = [
        TwistyPuzzleType(
            id: "cube-2x2",
            title: "2×2 Cube",
            icon: "square.grid.2x2.fill",
            availability: .available,
            destination: .cube2x2
        ),
        TwistyPuzzleType(
            id: "rubiks-cube",
            title: "3×3 Rubik’s Cube",
            icon: "cube.fill",
            availability: .comingSoon,
            destination: .comingSoon
        ),
        TwistyPuzzleType(
            id: "pyraminx",
            title: "Pyraminx",
            icon: "triangle.fill",
            availability: .comingSoon,
            destination: .comingSoon
        ),
        TwistyPuzzleType(
            id: "skewb",
            title: "Skewb",
            icon: "diamond.fill",
            availability: .comingSoon,
            destination: .comingSoon
        )
    ]
}

private struct Cube2x2EntryView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Text("2×2 Cube")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)
                        .multilineTextAlignment(.center)

                    Text("Phase 2 in progress")
                        .appTextStyle(.h2)
                        .foregroundStyle(AppTheme.Colors.text)

                    Text("This is the first active twisty puzzle target. Solver-specific tools and workflows will be added here next.")
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
        .navigationTitle("2×2 Cube")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TwistyPuzzlePickerView()
    }
}

//
//  MainMenuView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct MainMenuView: View {
    private let puzzleCategories = PuzzleCategory.all

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text("Puzzle Solver")
                        .appTextStyle(.h1)
                        .foregroundStyle(AppTheme.Colors.highlight)

                    Text("Choose a puzzle type")
                        .appTextStyle(.h2)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.top, AppTheme.Spacing.xLarge)

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(puzzleCategories) { puzzleCategory in
                            NavigationLink {
                                destinationView(for: puzzleCategory)
                            } label: {
                                PuzzleTypeCard(
                                    title: puzzleCategory.title,
                                    subtitle: puzzleCategory.subtitle,
                                    icon: puzzleCategory.icon,
                                    isEnabled: puzzleCategory.availability == .available,
                                    accentVariant: puzzleCategory.accentVariant
                                )
                            }
                            .disabled(puzzleCategory.availability == .comingSoon)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.bottom, AppTheme.Spacing.xLarge)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func destinationView(for puzzleCategory: PuzzleCategory) -> some View {
        switch puzzleCategory.destination {
        case .slidingPuzzleSizeSelection:
            SlidingPuzzleSizeSelectionView()
        case .twistyPuzzlePicker:
            TwistyPuzzlePickerView()
        case .logicPuzzlePicker:
            LogicPuzzlePickerView()
        case .mechanicalPuzzlePicker:
            MechanicalPuzzlePickerView()
        case .comingSoon:
            ComingSoonPuzzleView(puzzleName: puzzleCategory.title)
        }
    }
}

private struct PuzzleCategory: Identifiable {
    enum Availability {
        case available
        case comingSoon

        var subtitle: String {
            switch self {
            case .available:
                return "Ready now"
            case .comingSoon:
                return "Coming soon"
            }
        }
    }

    enum Destination {
        case slidingPuzzleSizeSelection
        case twistyPuzzlePicker
        case logicPuzzlePicker
        case mechanicalPuzzlePicker
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

    static let all: [PuzzleCategory] = [
        PuzzleCategory(
            id: "sliding",
            title: "Sliding Puzzle",
            icon: "square.grid.3x3.fill",
            availability: .available,
            destination: .slidingPuzzleSizeSelection
        ),
        PuzzleCategory(
            id: "twisty",
            title: "Twisty Puzzles",
            icon: "cube.transparent.fill",
            availability: .available,
            destination: .twistyPuzzlePicker
        ),
        PuzzleCategory(
            id: "logic",
            title: "Logic Puzzles",
            icon: "number.square.fill",
            availability: .available,
            destination: .logicPuzzlePicker
        ),
        PuzzleCategory(
            id: "mechanical",
            title: "Mechanical Puzzles",
            icon: "shippingbox.fill",
            availability: .available,
            destination: .mechanicalPuzzlePicker
        )
    ]
}

private struct MechanicalPuzzlePickerView: View {
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
        case .klotski:
            KlotskiComingSoonView()
        case .pegSolitaire:
            PegSolitaireComingSoonView()
        case .towersOfHanoi:
            MechanicalComingSoonView(puzzleType: puzzleType)
        case .lightsOut:
            LightsOutComingSoonView()
        }
    }
}

private struct KlotskiComingSoonView: View {
    var body: some View {
        MechanicalComingSoonView(puzzleType: .klotski)
    }
}

private struct PegSolitaireComingSoonView: View {
    var body: some View {
        MechanicalComingSoonView(puzzleType: .pegSolitaire)
    }
}

private struct LightsOutComingSoonView: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.large) {
                Image(systemName: MechanicalPuzzleType.lightsOut.icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.highlight)

                Text(MechanicalPuzzleType.lightsOut.title)
                    .appTextStyle(.h1)
                    .foregroundStyle(AppTheme.Colors.highlight)

                Text("Coming Soon")
                    .appTextStyle(.h2)
                    .foregroundStyle(AppTheme.Colors.text)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Planned support includes:")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.9))

                    lightsOutBullet("Tap-to-toggle behavior for each pressed cell plus orthogonal neighbors.")
                    lightsOutBullet("Board sizes optimized for classic 5×5 layouts and custom practice grids.")
                    lightsOutBullet("Step-by-step elimination output generated from a binary linear solve.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppTheme.Spacing.xLarge)
            .appSurfaceCard()
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .navigationTitle(MechanicalPuzzleType.lightsOut.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lightsOutBullet(_ text: String) -> some View {
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

private struct MechanicalComingSoonView: View {
    let puzzleType: MechanicalPuzzleType

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

                Text("This mechanical puzzle is planned for a future Phase 6 polish pass.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.84))
                    .multilineTextAlignment(.center)
            }
            .padding(AppTheme.Spacing.xLarge)
            .appSurfaceCard()
            .padding(.horizontal, AppTheme.Spacing.large)
        }
        .navigationTitle(puzzleType.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ComingSoonPuzzleView: View {
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

                    Text("This puzzle mode is planned for a future version.")
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

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MainMenuView()
        }
    }
}

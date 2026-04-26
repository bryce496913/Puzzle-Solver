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
        )
    ]
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

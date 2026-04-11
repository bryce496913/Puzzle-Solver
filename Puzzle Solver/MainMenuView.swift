//
//  MainMenuView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct MainMenuView: View {
    private let puzzleTypes = PuzzleType.all

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
                        ForEach(puzzleTypes) { puzzleType in
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
                            .disabled(puzzleType.availability == .comingSoon)
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
    private func destinationView(for puzzleType: PuzzleType) -> some View {
        switch puzzleType.destination {
        case .newPuzzle:
            NewPuzzleView()
        case .comingSoon:
            ComingSoonPuzzleView(puzzleName: puzzleType.title)
        }
    }
}

private struct PuzzleType: Identifiable {
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
        case newPuzzle
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

    static let all: [PuzzleType] = [
        PuzzleType(
            id: "sliding-3x3",
            title: "3×3 Sliding Puzzle",
            icon: "square.grid.3x3.fill",
            availability: .available,
            destination: .newPuzzle
        ),
        PuzzleType(
            id: "sliding-4x4",
            title: "4×4 Sliding Puzzle",
            icon: "square.grid.4x3.fill",
            availability: .comingSoon,
            destination: .comingSoon
        ),
        PuzzleType(
            id: "rubiks-cube",
            title: "Rubik’s Cube",
            icon: "cube.fill",
            availability: .comingSoon,
            destination: .comingSoon
        ),
        PuzzleType(
            id: "cube-2x2",
            title: "2×2 Cube",
            icon: "square.grid.2x2.fill",
            availability: .comingSoon,
            destination: .comingSoon
        ),
        PuzzleType(
            id: "pyraminx",
            title: "Pyraminx",
            icon: "triangle.fill",
            availability: .comingSoon,
            destination: .comingSoon
        ),
        PuzzleType(
            id: "skewb",
            title: "Skewb",
            icon: "diamond.fill",
            availability: .comingSoon,
            destination: .comingSoon
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

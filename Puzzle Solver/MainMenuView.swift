//
//  MainMenuView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct MainMenuView: View {
    private let puzzleTypes: [PuzzleType] = [.sliding3x3, .sliding4x4, .rubiksCube, .cube2x2, .pyraminx, .skewb]

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
                                    isEnabled: true,
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
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func destinationView(for puzzleType: PuzzleType) -> some View {
        if puzzleType == .sliding3x3 {
            NewPuzzleView()
        } else {
            ComingSoonPuzzleView(puzzleName: puzzleType.title)
        }
    }
}

private enum PuzzleType: String, CaseIterable, Identifiable {
    case sliding3x3
    case sliding4x4
    case rubiksCube
    case cube2x2
    case pyraminx
    case skewb

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sliding3x3:
            return "3×3 Sliding Puzzle"
        case .sliding4x4:
            return "4×4 Sliding Puzzle"
        case .rubiksCube:
            return "Rubik’s Cube"
        case .cube2x2:
            return "2×2 Cube"
        case .pyraminx:
            return "Pyraminx"
        case .skewb:
            return "Skewb"
        }
    }

    var subtitle: String {
        switch self {
        case .sliding3x3:
            return "Ready now"
        default:
            return "Coming soon"
        }
    }

    var icon: String {
        switch self {
        case .sliding3x3:
            return "square.grid.3x3.fill"
        case .sliding4x4:
            return "square.grid.4x3.fill"
        case .rubiksCube:
            return "cube.fill"
        case .cube2x2:
            return "square.grid.2x2.fill"
        case .pyraminx:
            return "triangle.fill"
        case .skewb:
            return "diamond.fill"
        }
    }

    var isImplemented: Bool {
        self == .sliding3x3
    }

    var accentVariant: PuzzleTypeCard.AccentVariant {
        isImplemented ? .accent : .highlight
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

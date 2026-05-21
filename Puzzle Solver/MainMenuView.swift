//
//  MainMenuView.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

struct MainMenuView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let menuItems: [MainMenuItem] = [
        MainMenuItem(title: "Sliding Puzzles", subtitle: "Create and solve a sliding puzzle.", symbol: "square.grid.3x3.fill", color: AppTheme.blue, destination: AnyView(NewPuzzleView())),
        MainMenuItem(title: "Twisty Puzzles", subtitle: "Enter cube-style scrambles and sticker states.", symbol: "cube.fill", color: AppTheme.green, destination: AnyView(TwistyPuzzleInputView())),
        MainMenuItem(title: "Logic Puzzles", subtitle: "Try Sudoku and other logic-grid solvers.", symbol: "brain.head.profile", color: AppTheme.cyan, destination: AnyView(LogicPuzzleMenuView())),
        MainMenuItem(title: "Mechanical Puzzles", subtitle: "Explore movement-based mechanical puzzles.", symbol: "car.fill", color: AppTheme.amber, destination: AnyView(MechanicalPuzzleMenuView())),
        MainMenuItem(title: "Visual / Experimental", subtitle: "Preview visual, graph, maze, chess, and jigsaw modes.", symbol: "puzzlepiece.extension.fill", color: AppTheme.pink, destination: AnyView(ExperimentalPuzzleMenuView())),
        MainMenuItem(title: "How It Works", subtitle: "Learn what Version 1 can solve safely.", symbol: "questionmark.circle.fill", color: AppTheme.lavender, destination: AnyView(HowView()))
    ]

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    LazyVStack(spacing: 14) {
                        ForEach(menuItems) { item in
                            NavigationLink(destination: item.destination) {
                                MainMenuCard(item: item)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                    .accessibilityHint("Opens app appearance, onboarding, and TestFlight readiness settings.")
                }
                .padding()
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: reduceMotion)
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Puzzle")
                    .appTitleStyle(color: AppTheme.pink)
                Text("Solver")
                    .appTitleStyle(color: AppTheme.cyan)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Puzzle Solver")

            Text("Choose a puzzle type, enter its current state, and get a bounded Version 1 result.")
                .font(.body)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
}

private struct MainMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    let destination: AnyView
}

private struct MainMenuCard: View {
    let item: MainMenuItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title2.weight(.semibold))
                .foregroundColor(.black)
                .frame(width: 48, height: 48)
                .background(item.color)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundColor(AppTheme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(item.title).")
    }
}

struct SettingsView: View {
    @AppStorage("PreferredAppearance") private var preferredAppearance = AppAppearanceOption.system.rawValue
    @AppStorage("HasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("UseCompactSolutionPreviews") private var useCompactSolutionPreviews = true

    private var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var buildNumber: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }

    var body: some View {
        Form {
            Section(header: Text("Appearance"), footer: Text("System keeps the app matched to iOS, while Light and Dark are useful for TestFlight review passes.")) {
                Picker("Theme", selection: $preferredAppearance) {
                    ForEach(AppAppearanceOption.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section(header: Text("Solving"), footer: Text("Compact previews reduce memory and rendering work on large solution paths.")) {
                Toggle("Compact solution previews", isOn: $useCompactSolutionPreviews)
            }

            Section(header: Text("Onboarding")) {
                Button("Show onboarding again") {
                    hasCompletedOnboarding = false
                }
                .buttonStyle(AppSecondaryButtonStyle())
                .accessibilityHint("Returns to the Version 1 onboarding flow.")
            }

            Section(header: Text("TestFlight")) {
                SettingsValueRow(title: "Version", value: appVersion)
                SettingsValueRow(title: "Build", value: buildNumber)
                Label("App icon, launch screen, signing, and Version 1 build settings are configured.", systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainMenuView()
        }
    }
}

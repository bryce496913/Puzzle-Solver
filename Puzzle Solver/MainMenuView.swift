//
//  MainMenuView.swift
//  Puzzle Solver
//
//  V1 App Store-ready home menu.
//

import SwiftUI

struct MainMenuView: View {
    private let categories = PuzzleCategory.allCases

    var body: some View {
        AppScreenContainer(
            title: "Puzzle Solver",
            subtitle: "A focused V1 release with only reliable solvers active and every other mode safely parked."
        ) {
            LazyVStack(spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(destination: destination(for: category)) {
                        categoryCard(category)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                NavigationLink(destination: SettingsView()) {
                    settingsCard
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func destination(for category: PuzzleCategory) -> some View {
        switch category {
        case .sliding: NewPuzzleView()
        case .twisty: TwistyPlaceholderMenuView()
        case .logic: LogicPuzzleMenuView()
        case .mechanical: MechanicalPuzzleMenuView()
        case .visual: ExperimentalPuzzleMenuView()
        }
    }

    private func categoryCard(_ category: PuzzleCategory) -> some View {
        let activeCount = PuzzleAvailabilityCatalog.descriptors(in: category).filter { $0.status.isActive }.count
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .frame(width: 42, height: 42)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(category.rawValue).appH2()
                Text(category.subtitle).appParagraph().fixedSize(horizontal: false, vertical: true)
                Text(activeCount == 0 ? "V1 placeholders" : "\(activeCount) active V1 solver\(activeCount == 1 ? "" : "s")")
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((activeCount == 0 ? AppTheme.highlight : AppTheme.accent).opacity(0.45))
                    .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.text.opacity(0.72))
                .padding(.top, 14)
                .accessibilityHidden(true)
        }
        .appCardStyle()
        .accessibilityElement(children: .combine)
    }

    private var settingsCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .frame(width: 38, height: 38)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Settings").appH2()
                Text("Appearance and lightweight V1 review preferences.").appParagraph()
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.text.opacity(0.72))
        }
        .appCardStyle()
    }
}

struct SettingsView: View {
    @AppStorage("PreferredAppearance") private var preferredAppearance = AppAppearanceOption.system.rawValue
    @AppStorage("HasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("UseCompactSolutionPreviews") private var useCompactSolutionPreviews = true

    private var appVersion: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0" }
    private var buildNumber: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1" }

    var body: some View {
        AppScreenContainer(title: "Settings", subtitle: "Keep the V1 experience predictable during review and QA.") {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader("Appearance", subtitle: "Choose a preferred presentation while preserving the V1 black/surface/accent palette.")
                Picker("Theme", selection: $preferredAppearance) {
                    ForEach(AppAppearanceOption.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Toggle("Use compact solution previews", isOn: $useCompactSolutionPreviews)
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)

                Button("Show onboarding again") {
                    hasCompletedOnboarding = false
                }
                .buttonStyle(AppSecondaryButtonStyle())

                Text("Version \(appVersion) (\(buildNumber))")
                    .appParagraph()
            }
            .appCardStyle()
        }
    }
}

struct TwistyPlaceholderMenuView: View {
    private let descriptors = PuzzleAvailabilityCatalog.descriptors(in: .twisty)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.twisty.rawValue, subtitle: PuzzleCategory.twisty.subtitle) {
            LazyVStack(spacing: 12) {
                ForEach(descriptors) { descriptor in
                    NavigationLink(destination: AppPlaceholderScreen(descriptor: descriptor)) {
                        AppPuzzleCard(descriptor: descriptor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

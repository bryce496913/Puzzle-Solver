//
//  MainMenuView.swift
//  Puzzle Solver
//
//  V1 App Store-ready home menu.
//

import SwiftUI

struct MainMenuView: View {
    private let categories: [PuzzleCategory] = [.sliding, .twisty, .logic, .mechanical]

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

                NavigationLink(destination: ComingSoonView()) {
                    menuCard(
                        title: "Coming Soon",
                        subtitle: "Future puzzle solvers planned for later updates.",
                        icon: "clock.fill"
                    )
                }
                .buttonStyle(PlainButtonStyle())

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
        case .twisty: TwistyPuzzleMenuView()
        case .logic: LogicPuzzleMenuView()
        case .mechanical: MechanicalPuzzleMenuView()
        case .visual: ComingSoonView()
        }
    }

    private func categoryCard(_ category: PuzzleCategory) -> some View {
        let activeCount = PuzzleAvailabilityCatalog.activeDescriptors(in: category).count
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
                Text("\(activeCount) active V1 solver\(activeCount == 1 ? "" : "s")")
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent.opacity(0.45))
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

    private func menuCard(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .frame(width: 38, height: 38)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).appH2()
                Text(subtitle).appParagraph()
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.text.opacity(0.72))
        }
        .appCardStyle()
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

struct TwistyPuzzleMenuView: View {
    private let descriptors = PuzzleAvailabilityCatalog.activeDescriptors(in: .twisty)

    var body: some View {
        AppScreenContainer(title: PuzzleCategory.twisty.rawValue, subtitle: PuzzleCategory.twisty.subtitle) {
            LazyVStack(spacing: 12) {
                ForEach(descriptors) { descriptor in
                    NavigationLink(destination: destination(for: descriptor)) {
                        AppPuzzleCard(descriptor: descriptor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for descriptor: PuzzleAvailabilityDescriptor) -> some View {
        switch descriptor.id {
        case "cube-2x2", "cube-3x3":
            CubeInputView(descriptor: descriptor)
        default:
            AppPlaceholderScreen(descriptor: descriptor)
        }
    }
}

struct CubeInputView: View {
    let descriptor: PuzzleAvailabilityDescriptor

    @State private var stickers: [String]
    @State private var selectedColor = "U"
    @State private var selectedSticker = 0
    @State private var solveResult: CubeSolveResult?
    @State private var solveState: SolveState = .idle
    @State private var didFinish = false

    private let colors = ["U", "R", "F", "D", "L", "B"]
    private var kind: CubePuzzleKind { descriptor.id == "cube-2x2" ? .twoByTwo : .threeByThree }
    private var faceSize: Int { kind == .twoByTwo ? 2 : 3 }
    private var stickersPerFace: Int { faceSize * faceSize }
    private var countsAreValid: Bool {
        colors.allSatisfy { color in stickers.filter { $0 == color }.count == stickersPerFace }
    }

    init(descriptor: PuzzleAvailabilityDescriptor) {
        self.descriptor = descriptor
        let kind: CubePuzzleKind = descriptor.id == "cube-2x2" ? .twoByTwo : .threeByThree
        _stickers = State(initialValue: CubeState.solved(kind).stickers)
    }

    var body: some View {
        AppScreenContainer(title: descriptor.title, subtitle: "Front faces you; Up is above it and Right is to its right.") {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader("Cube orientation", subtitle: "U above F, R to the right, D below, with L and B completing the net.")
                cubeNet

                AppSectionHeader("Sticker color", subtitle: "Select a color, then tap a sticker. The outlined sticker is selected.")
                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { color in
                        Button(color) { selectedColor = color }
                            .buttonStyle(AppSecondaryButtonStyle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(color == selectedColor ? AppTheme.highlight : Color.clear, lineWidth: 3)
                            )
                            .accessibilityLabel("\(colorName(color)) color")
                            .accessibilityValue(color == selectedColor ? "Selected" : "")
                    }
                }

                AppStatusBadge(
                    text: countsAreValid ? "Color counts valid" : colorCountSummary,
                    state: countsAreValid ? .solved : .invalid
                )

                HStack(spacing: 10) {
                    Button("Solved Example") { resetSolved() }
                        .buttonStyle(AppSecondaryButtonStyle())
                    Button("Reset") { resetSolved() }
                        .buttonStyle(AppResetButtonStyle())
                }

                Button(solveState == .solving ? "Solving…" : "Solve Cube") { solve() }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!countsAreValid || solveState == .solving)

                if let solveResult {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(solveState.friendlyTitle).appH2()
                        Text(solveResult.failureReason ?? (solveResult.moves.isEmpty ? "Cube is already solved." : solveResult.formattedMoves))
                            .appParagraph()
                    }
                    .appCardStyle()
                }
            }
            .appCardStyle()
        }
    }

    private var cubeNet: some View {
        VStack(spacing: 8) {
            face("U", faceIndex: 0).padding(.leading, CGFloat(faceSize * 30))
            HStack(spacing: 8) {
                face("L", faceIndex: 4)
                face("F", faceIndex: 2)
                face("R", faceIndex: 1)
                face("B", faceIndex: 5)
            }
            face("D", faceIndex: 3).padding(.leading, CGFloat(faceSize * 30))
        }
        .frame(maxWidth: .infinity)
    }

    private func face(_ label: String, faceIndex: Int) -> some View {
        VStack(spacing: 3) {
            Text(label).appH3()
            VStack(spacing: 2) {
                ForEach(0..<faceSize, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<faceSize, id: \.self) { column in
                            let index = faceIndex * stickersPerFace + row * faceSize + column
                            Button {
                                selectedSticker = index
                                stickers[index] = selectedColor
                                solveResult = nil
                                solveState = .idle
                            } label: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(stickerColor(stickers[index]))
                                    .frame(width: faceSize == 2 ? 28 : 20, height: faceSize == 2 ? 28 : 20)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(selectedSticker == index ? AppTheme.highlight : Color.white.opacity(0.5), lineWidth: selectedSticker == index ? 3 : 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var colorCountSummary: String {
        colors.map { color in "\(color): \(stickers.filter { $0 == color }.count)" }.joined(separator: " • ")
    }

    private func solve() {
        guard countsAreValid else {
            solveState = .invalid
            return
        }
        solveState = .solving
        didFinish = false
        let state = CubeState(puzzle: kind, stickers: stickers)
        let options = CubeSolveOptions(timeout: 5, maxDepth: kind == .twoByTwo ? 10 : 8, maxNodes: kind == .twoByTwo ? 100_000 : 250_000, includeStepStates: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + options.timeout + 0.25) {
            guard !didFinish else { return }
            didFinish = true
            solveState = .timedOut
            solveResult = CubeSolveResult(status: .timeout, puzzle: kind, moves: [], steps: [], failureReason: "The bounded V1 solver timed out. Try a simpler cube state.", elapsedTime: options.timeout, nodesExplored: 0)
        }
        CubeSolvingService.shared.solve(state, options: options) { result in
            DispatchQueue.main.async {
                guard !didFinish else { return }
                didFinish = true
                solveResult = result
                solveState = result.solveState
            }
        }
    }

    private func resetSolved() {
        stickers = CubeState.solved(kind).stickers
        selectedSticker = 0
        solveResult = nil
        solveState = .idle
    }

    private func stickerColor(_ code: String) -> Color {
        switch code {
        case "U": return .white
        case "R": return .red
        case "F": return .green
        case "D": return .yellow
        case "L": return .orange
        default: return .blue
        }
    }

    private func colorName(_ code: String) -> String {
        ["U": "white", "R": "red", "F": "green", "D": "yellow", "L": "orange", "B": "blue"][code] ?? code
    }
}

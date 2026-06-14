//
//  MainMenuView.swift
//  Puzzle Solver
//
//  App Store-ready home menu.
//

import SwiftUI

struct MainMenuView: View {
    private let categories: [PuzzleCategory] = [.sliding, .twisty, .logic, .mechanical]

    var body: some View {
        AppScreenContainer(
            title: "Puzzle Solver",
            subtitle: "A focused puzzle collection with reliable solvers and future modes safely parked."
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
                Text("\(activeCount) active solver\(activeCount == 1 ? "" : "s")")
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
                Text("Appearance and lightweight review preferences.").appParagraph()
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
        AppScreenContainer(title: "Settings", subtitle: "Keep the app experience predictable during review and QA.") {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader("Appearance", subtitle: "Choose a preferred presentation while preserving the black, purple, and pink palette.")
                HStack(spacing: 6) {
                    ForEach(AppAppearanceOption.allCases) { option in
                        Button {
                            preferredAppearance = option.rawValue
                        } label: {
                            Text(option.title)
                                .font(AppTextStyle.h3)
                                .foregroundColor(AppTheme.text)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 42)
                                .background(preferredAppearance == option.rawValue ? AppTheme.accent : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityValue(preferredAppearance == option.rawValue ? "Selected" : "Not selected")
                    }
                }
                .padding(4)
                .background(AppTheme.background.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.7), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

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
                Text("Selected color: \(colorName(selectedColor))")
                    .appH3()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(colors, id: \.self) { code in
                        Button {
                            selectedColor = code
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(stickerColor(code))
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                                Text(colorName(code))
                                    .font(AppTextStyle.h3)
                                    .foregroundColor(AppTheme.text)
                                Spacer(minLength: 0)
                                if code == selectedColor {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.highlight)
                                }
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 48)
                            .background(AppTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(code == selectedColor ? AppTheme.highlight : AppTheme.accent.opacity(0.65), lineWidth: code == selectedColor ? 3 : 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("\(colorName(code)) color")
                        .accessibilityValue(code == selectedColor ? "Selected" : "")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(countsAreValid ? "Color counts valid" : "Color counts")
                        .appH3()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 6) {
                        ForEach(colors, id: \.self) { code in
                            HStack(spacing: 5) {
                                Circle().fill(stickerColor(code)).frame(width: 12, height: 12)
                                Text("\(colorName(code)): \(stickers.filter { $0 == code }.count)/\(stickersPerFace)")
                                    .font(AppTextStyle.paragraph)
                                    .foregroundColor(AppTheme.text)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                        }
                    }
                }
                .padding(10)
                .background(AppTheme.background.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
            solveResult = CubeSolveResult(status: .timeout, puzzle: kind, moves: [], steps: [], failureReason: "The bounded solver timed out. Try a simpler cube state.", elapsedTime: options.timeout, nodesExplored: 0)
        }
        CubeSolvingService.shared.solve(state, options: options) { result in
            DispatchQueue.main.async {
                guard !didFinish else { return }
                didFinish = true
                solveResult = result
                solveState = result.status.solveState
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
        ["U": "White", "R": "Red", "F": "Green", "D": "Yellow", "L": "Orange", "B": "Blue"][code] ?? code
    }
}

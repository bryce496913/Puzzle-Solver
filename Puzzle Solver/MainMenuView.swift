//
//  MainMenuView.swift
//  Puzzle Solver
//
//  App Store-ready home menu.
//

import SwiftUI
import UIKit

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

    private enum EntryMode: String, CaseIterable { case guided = "Guided entry", advanced = "Advanced net input" }
    private enum GuidedStage: Equatable { case orientation, face(Int), review, solution }
    private struct FaceGuide: Identifiable {
        let face: CubeFace
        let color: CubeColor
        var id: String { face.rawValue }
        var title: String { face.displayName }
        var subtitle: String { "\(physicalName) face (\(color.name) center)" }
        var physicalName: String {
            switch face { case .up: return "Top"; case .front: return "Front"; case .right: return "Right"; case .back: return "Back"; case .left: return "Left"; case .down: return "Bottom" }
        }
        var helper: String { "Look at the \(physicalName.lowercased()) face and tap the colors you see." }
    }

    @State private var stickers: [String]
    @State private var selectedColor = "U"
    @State private var selectedSticker = 0
    @State private var solveResult: CubeSolveResult?
    @State private var solveState: SolveState = .idle
    @State private var progressText = "Ready to solve."
    @State private var solveStartedAt: Date?
    @State private var entryMode: EntryMode = .guided
    @State private var guidedStage: GuidedStage = .orientation
    @State private var compactNotationVisible = true
    @State private var stepModeVisible = false
    @State private var currentSolutionStep = 0

    private let faceOrder: [CubeFace] = [.up, .front, .right, .back, .left, .down]
    private let storageFaceOrder: [CubeFace] = [.up, .right, .front, .down, .left, .back]
    private let colors = CubeColor.defaultFaceOrder.map(\.rawValue)
    private var guides: [FaceGuide] { faceOrder.map { FaceGuide(face: $0, color: CubeColor.defaultFaceMapping[$0] ?? .white) } }
    private var kind: CubePuzzleKind { descriptor.id == "cube-2x2" ? .twoByTwo : .threeByThree }
    private var faceSize: Int { kind == .twoByTwo ? 2 : 3 }
    private var stickersPerFace: Int { faceSize * faceSize }
    private var countsAreValid: Bool { colors.allSatisfy { color in stickers.filter { $0 == color }.count == stickersPerFace } }

    init(descriptor: PuzzleAvailabilityDescriptor) {
        self.descriptor = descriptor
        let kind: CubePuzzleKind = descriptor.id == "cube-2x2" ? .twoByTwo : .threeByThree
        _stickers = State(initialValue: CubeState.solved(kind).stickers)
    }

    var body: some View {
        AppScreenContainer(title: descriptor.title, subtitle: "Guided cube entry for real physical cubes.") {
            VStack(alignment: .leading, spacing: 14) {
                modePicker
                if entryMode == .guided { guidedContent } else { advancedContent }
                solveProgressCard
                if let solveResult { solutionCard(solveResult) }
            }
            .appCardStyle()
        }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(EntryMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) { entryMode = mode }
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(mode == entryMode ? AppTheme.accent : AppTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(mode == entryMode ? AppTheme.highlight : AppTheme.accent.opacity(0.6), lineWidth: mode == entryMode ? 2 : 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder private var guidedContent: some View {
        switch guidedStage {
        case .orientation: orientationScreen
        case .face(let i): faceEntryScreen(index: i)
        case .review: reviewScreen
        case .solution: reviewScreen
        }
    }

    private var orientationScreen: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader("Step 1: Orient your cube", subtitle: "Hold the cube with the White face on top and the Green face facing you.")
            orientationHelper(highlight: .front)
            Text("Now enter each face exactly as you see it. Keep the cube in the same orientation until you are told to turn it.").appParagraph()
            Button("Start Entering Up Face") { guidedStage = .face(0) }.buttonStyle(AppPrimaryButtonStyle())
        }
    }

    private func faceEntryScreen(index: Int) -> some View {
        let guide = guides[index]
        return VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader("Step \(index + 1) of 6", subtitle: "Enter the \(guide.title) face")
            orientationHelper(highlight: guide.face)
            Text(guide.subtitle).appH2()
            Text(guide.helper).appParagraph()
            singleFaceGrid(guide.face)
            colorControls
            navigationRow(index: index)
        }
    }

    private func navigationRow(index: Int) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button("Back") { guidedStage = index == 0 ? .orientation : .face(index - 1) }.buttonStyle(AppSecondaryButtonStyle())
                Button("Next") { guidedStage = index == guides.count - 1 ? .review : .face(index + 1) }.buttonStyle(AppPrimaryButtonStyle())
            }
            HStack(spacing: 8) {
                Button("Reset Face") { resetFace(guides[index].face) }.buttonStyle(AppResetButtonStyle())
                Button("Review All Faces") { guidedStage = .review }.buttonStyle(AppSecondaryButtonStyle())
                Button("Start Over") { resetSolved(); guidedStage = .orientation }.buttonStyle(AppResetButtonStyle())
            }
        }
    }

    private var reviewScreen: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader("Review and solve", subtitle: "This layout matches the guided entry order. Hold the cube with Up on top and Front facing you.")
            cubeNet
            validationCard
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(guides.enumerated()), id: \.element.id) { i, guide in
                    Button("Edit \(guide.title)") { guidedStage = .face(i) }.buttonStyle(AppSecondaryButtonStyle())
                }
            }
            Button("Solve Cube") { solve() }.buttonStyle(AppPrimaryButtonStyle()).disabled(!countsAreValid || solveState == .solving || solveState == .validating)
        }
    }

    private var advancedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader("Advanced net input", subtitle: "This layout matches the guided entry order. Hold the cube with Up on top and Front facing you.")
            orientationHelper(highlight: .front)
            cubeNet
            colorControls
            validationCard
            Button("Solve Cube") { solve() }.buttonStyle(AppPrimaryButtonStyle()).disabled(!countsAreValid)
        }
    }

    private var colorControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected color: \(colorName(selectedColor))").appH2()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(colors, id: \.self) { code in
                    Button { selectedColor = code } label: {
                        HStack { Circle().fill(stickerColor(code)).frame(width: 30, height: 30).overlay(Circle().stroke(.white, lineWidth: 1)); Text("\(colorName(code)) (\(faceMeaning(code)))").font(AppTextStyle.h3).foregroundColor(AppTheme.text); Spacer(); if code == selectedColor { Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.highlight) } }
                            .padding(12).frame(minHeight: 56).background(AppTheme.surface).overlay(RoundedRectangle(cornerRadius: 14).stroke(code == selectedColor ? AppTheme.highlight : AppTheme.accent.opacity(0.65), lineWidth: code == selectedColor ? 4 : 1)).clipShape(RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var validationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(countsAreValid ? "Validation passed" : "Check these colors before solving").appH3()
            ForEach(colors, id: \.self) { code in Text(countText(code)).font(AppTextStyle.paragraph).foregroundColor(countIsValid(code) ? AppTheme.text : AppTheme.highlight) }
            if stickers.contains(where: { !colors.contains($0) }) { Text("Some stickers are still missing.").appParagraph() }
        }.padding(10).background(AppTheme.background.opacity(0.55)).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var solveProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) { HStack(spacing: 10) { if solveState == .validating || solveState == .solving { ProgressView() }; Text(progressText).appParagraph() }; if solveState == .validating || solveState == .solving { Text("Checking colors… Preparing cube… Solving…").font(AppTextStyle.paragraph).foregroundColor(AppTheme.text.opacity(0.62)) } }.appCardStyle()
    }

    private func solutionCard(_ result: CubeSolveResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(result.status.userFacingMessage, subtitle: result.status == .alreadySolved ? "Already solved." : "Follow these moves in order. Keep the cube oriented the same way as shown in the input guide.")
            Text("\(result.moveCount) move\(result.moveCount == 1 ? "" : "s")").appH2()
            if !result.moves.isEmpty {
                HStack { Button("Copy Moves") { UIPasteboard.general.string = result.formattedMoves }.buttonStyle(AppSecondaryButtonStyle()); Button(compactNotationVisible ? "Hide Compact Notation" : "Show Compact Notation") { compactNotationVisible.toggle() }.buttonStyle(AppSecondaryButtonStyle()) }
                if compactNotationVisible { Text(result.formattedMoves).font(AppTextStyle.h3).foregroundColor(AppTheme.text).padding(10).background(AppTheme.background.opacity(0.55)).clipShape(RoundedRectangle(cornerRadius: 10)) }
                Button(stepModeVisible ? "Show Step-by-Step List" : "Show One Move at a Time") { stepModeVisible.toggle() }.buttonStyle(AppPrimaryButtonStyle())
                if stepModeVisible { oneMoveView(result.moves) } else { moveList(result.moves) }
                notationLegend
                HStack { Button("Try Another Cube") { resetSolved(); guidedStage = .orientation }.buttonStyle(AppResetButtonStyle()); Button("Back to Cube Entry") { guidedStage = .review }.buttonStyle(AppSecondaryButtonStyle()) }
            }
        }.appCardStyle()
    }

    private func moveList(_ moves: [String]) -> some View { VStack(alignment: .leading, spacing: 8) { ForEach(Array(moves.enumerated()), id: \.offset) { i, m in moveRow(i: i, move: m) } } }
    private func oneMoveView(_ moves: [String]) -> some View { let m = moves[min(currentSolutionStep, max(0, moves.count-1))]; return VStack(alignment: .leading, spacing: 10) { Text("Step \(currentSolutionStep + 1) of \(moves.count)").appH3(); orientationHelper(highlight: faceForMove(m)); moveRow(i: currentSolutionStep, move: m); HStack { Button("Previous") { currentSolutionStep = max(0, currentSolutionStep - 1) }.buttonStyle(AppSecondaryButtonStyle()); Button("Next") { currentSolutionStep = min(moves.count - 1, currentSolutionStep + 1) }.buttonStyle(AppPrimaryButtonStyle()); Button("Restart") { currentSolutionStep = 0 }.buttonStyle(AppResetButtonStyle()) } } }
    private func moveRow(i: Int, move: String) -> some View { HStack(alignment: .top) { Text("\(i+1).").appH3().frame(width: 34, alignment: .leading); Text(move).appH2().frame(width: 44, alignment: .leading); Text(moveExplanation(move)).appParagraph(); Spacer() }.padding(10).background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12)) }
    private var notationLegend: some View { Text("Legend: U = Up, D = Down, F = Front, B = Back, L = Left, R = Right. ' = counter-clockwise. 2 = 180° turn.").appParagraph() }

    private func orientationHelper(highlight: CubeFace) -> some View { HStack(alignment: .top, spacing: 12) { Image(systemName: "cube.transparent.fill").font(.system(size: 40)).foregroundColor(AppTheme.highlight); VStack(alignment: .leading) { Text("Physical cube orientation").appH3(); Text("Top: White (Up) • Front: Green (Front)").appParagraph(); Text("Entering now: \(highlight.displayName)").font(AppTextStyle.h3).foregroundColor(AppTheme.highlight) } }.padding(10).background(AppTheme.background.opacity(0.55)).clipShape(RoundedRectangle(cornerRadius: 12)) }

    private var cubeNet: some View { VStack(spacing: 8) { Text("Top ↑").appH3(); face("Up", faceIndex: index(of: .up)).padding(.leading, CGFloat(faceSize * 34)); HStack(spacing: 8) { face("Left", faceIndex: index(of: .left)); face("Front", faceIndex: index(of: .front)); face("Right", faceIndex: index(of: .right)); face("Back", faceIndex: index(of: .back)) }; face("Down", faceIndex: index(of: .down)).padding(.leading, CGFloat(faceSize * 34)); Text("Front faces you").appParagraph() }.frame(maxWidth: .infinity) }
    private func face(_ label: String, faceIndex: Int) -> some View { VStack(spacing: 3) { Text(label).appH3(); stickerGrid(faceIndex: faceIndex, small: true) } }
    private func singleFaceGrid(_ cubeFace: CubeFace) -> some View { stickerGrid(faceIndex: index(of: cubeFace), small: false).frame(maxWidth: .infinity) }
    private func stickerGrid(faceIndex: Int, small: Bool) -> some View { VStack(spacing: 4) { ForEach(0..<faceSize, id: \.self) { row in HStack(spacing: 4) { ForEach(0..<faceSize, id: \.self) { column in let idx = faceIndex * stickersPerFace + row * faceSize + column; Button { selectedSticker = idx; stickers[idx] = selectedColor; solveResult = nil; solveState = .idle; progressText = "Sticker updated." } label: { RoundedRectangle(cornerRadius: 6).fill(stickerColor(stickers[idx])).frame(width: small ? (faceSize == 2 ? 34 : 24) : 58, height: small ? (faceSize == 2 ? 34 : 24) : 58).overlay(RoundedRectangle(cornerRadius: 6).stroke(selectedSticker == idx ? AppTheme.highlight : Color.white.opacity(0.7), lineWidth: selectedSticker == idx ? 4 : 1)) }.buttonStyle(PlainButtonStyle()) } } } } }

    private func solve() { guard countsAreValid else { solveState = .invalid; progressText = validationSummary(); return }; solveResult = nil; solveState = .validating; progressText = "Checking colors…"; solveStartedAt = Date(); let state = CubeState(puzzle: kind, stickers: stickers); if state.isSolved { solveResult = CubeSolveResult(status: .alreadySolved, puzzle: kind, moves: [], steps: [], failureReason: nil, elapsedTime: 0, nodesExplored: 0); solveState = .solved; progressText = "Already solved."; return }; let options = CubeSolveOptions(timeout: kind == .twoByTwo ? 2 : 5, maxDepth: kind == .twoByTwo ? 10 : 6, maxNodes: kind == .twoByTwo ? 100_000 : 80_000, includeStepStates: false); DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { solveState = .solving; progressText = "Preparing cube… Solving…"; CubeSolvingService.shared.solve(state, options: options) { result in solveResult = result; solveState = result.status.solveState; progressText = resultMessage(result); solveStartedAt = nil; guidedStage = .solution } } }
    private func resultMessage(_ result: CubeSolveResult) -> String { if result.status == .alreadySolved { return "Already solved." }; if let reason = result.failureReason { return reason }; return result.moves.isEmpty ? result.status.userFacingMessage : "Solution ready." }
    private func resetSolved() { stickers = CubeState.solved(kind).stickers; selectedSticker = 0; solveResult = nil; solveState = .idle; progressText = "Ready to solve."; solveStartedAt = nil; currentSolutionStep = 0 }
    private func resetFace(_ face: CubeFace) { let start = index(of: face) * stickersPerFace; let color = CubeColor.defaultFaceMapping[face]?.rawValue ?? "U"; for i in start..<(start + stickersPerFace) { stickers[i] = color } }
    private func index(of face: CubeFace) -> Int { storageFaceOrder.firstIndex(of: face) ?? 0 }
    private func stickerColor(_ code: String) -> Color { switch code { case "U": return .white; case "R": return .red; case "F": return .green; case "D": return .yellow; case "L": return .orange; default: return .blue } }
    private func colorName(_ code: String) -> String { CubeColor(rawValue: code)?.name ?? code }
    private func faceMeaning(_ code: String) -> String { CubeColor.defaultFaceMapping.first(where: { $0.value.rawValue == code })?.key.displayName ?? "Face" }
    private func countIsValid(_ code: String) -> Bool { stickers.filter { $0 == code }.count == stickersPerFace }
    private func countText(_ code: String) -> String { let c = stickers.filter { $0 == code }.count; if c == stickersPerFace { return "\(colorName(code)): \(c)/\(stickersPerFace)" }; return c > stickersPerFace ? "\(colorName(code)) has too many stickers (\(c)/\(stickersPerFace))." : "\(colorName(code)) has \(c) of \(stickersPerFace) stickers." }
    private func validationSummary() -> String { colors.filter { !countIsValid($0) }.map(countText).joined(separator: " ") }
    private func faceForMove(_ move: String) -> CubeFace { CubeFace(rawValue: String(move.prefix(1))) ?? .front }
    private func moveExplanation(_ move: String) -> String { let f = faceForMove(move).displayName.lowercased(); if move.contains("2") { return "Turn the \(f) face 180°." }; if move.contains("'") { return "Turn the \(f) face counter-clockwise." }; return "Turn the \(f) face clockwise." }
}

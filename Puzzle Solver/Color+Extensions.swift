//
//  Color+Extensions.swift
//  Puzzle Solver
//
//  Created by Bryce on 30/1/24.
//

import SwiftUI

extension Color {
    init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
}

enum AppTheme {
    static let background = Color.black
    static let surface = Color(red: 0.12, green: 0.04, blue: 0.2)
    static let accent = Color(red: 0.72, green: 0.29, blue: 0.95)
    static let highlight = Color(red: 0.98, green: 0.32, blue: 0.67)
    static let text = Color.white

    static let pink = highlight
    static let cyan = accent
    static let blue = accent
    static let green = accent
    static let amber = highlight
    static let lavender = surface

    static let primaryText = text
    static let secondaryText = text.opacity(0.72)
    static let cardBackground = surface.opacity(0.92)
    static let elevatedBackground = surface

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum AppAppearanceOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Text {
    func appTitleStyle(color: Color) -> some View {
        self
            .foregroundColor(color)
            .font(AppTextStyle.screenTitle)
            .minimumScaleFactor(0.7)
    }

    func appButtonLabel() -> some View {
        self
            .font(AppTextStyle.h2)
            .frame(minHeight: 44)
    }
}

enum AppButtonRole {
    case primary
    case secondary
    case danger
    case disabled
}

extension View {
    func appButtonChrome(role: AppButtonRole, isPressed: Bool) -> some View {
        self
            .font(AppTextStyle.h2)
            .foregroundColor(appButtonForegroundColor(for: role))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background(appButtonBackground(for: role, isPressed: isPressed))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(appButtonBorderColor(for: role), lineWidth: role == .secondary ? 1.5 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isPressed ? 0.88 : 1)
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }

    fileprivate func appButtonForegroundColor(for role: AppButtonRole) -> Color {
        switch role {
        case .primary, .danger, .secondary:
            return AppTheme.text
        case .disabled:
            return AppTheme.text.opacity(0.62)
        }
    }

    fileprivate func appButtonBackground(for role: AppButtonRole, isPressed: Bool) -> Color {
        let opacity = isPressed ? 0.78 : 1
        switch role {
        case .primary:
            return AppTheme.accent.opacity(opacity)
        case .secondary:
            return AppTheme.surface.opacity(isPressed ? 0.82 : 1)
        case .danger:
            return AppTheme.highlight.opacity(opacity)
        case .disabled:
            return AppTheme.surface.opacity(isPressed ? 0.44 : 0.58)
        }
    }

    fileprivate func appButtonBorderColor(for role: AppButtonRole) -> Color {
        switch role {
        case .secondary:
            return AppTheme.accent
        case .disabled:
            return AppTheme.text.opacity(0.18)
        case .primary, .danger:
            return .clear
        }
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    var isDisabledAppearance = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(
            role: isEnabled && !isDisabledAppearance ? .primary : .disabled,
            isPressed: configuration.isPressed
        )
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    var isDisabledAppearance = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(
            role: isEnabled && !isDisabledAppearance ? .secondary : .disabled,
            isPressed: configuration.isPressed
        )
    }
}

struct AppBackButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left")
                .font(.system(size: 13, weight: .bold))
            configuration.label
        }
        .appButtonChrome(role: isEnabled ? .secondary : .disabled, isPressed: configuration.isPressed)
    }
}

struct AppDangerButtonStyle: ButtonStyle {
    var isDisabledAppearance = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(
            role: isEnabled && !isDisabledAppearance ? .danger : .disabled,
            isPressed: configuration.isPressed
        )
    }
}

struct AppDisabledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(role: .disabled, isPressed: configuration.isPressed)
    }
}

// MARK: - Design system and puzzle availability

enum AppTextStyle {
    static let screenTitle: Font = .system(size: 30, weight: .bold, design: .rounded)
    static let h1: Font = .system(size: 20, weight: .bold, design: .rounded)
    static let h2: Font = .system(size: 16, weight: .semibold, design: .rounded)
    static let h3: Font = .system(size: 14, weight: .semibold, design: .rounded)
    static let paragraph: Font = .system(size: 14, weight: .regular, design: .rounded)
}

extension Text {
    func appScreenTitle() -> some View { self.font(AppTextStyle.screenTitle).foregroundColor(AppTheme.text) }
    func appH1() -> some View { self.font(AppTextStyle.h1).foregroundColor(AppTheme.text) }
    func appH2() -> some View { self.font(AppTextStyle.h2).foregroundColor(AppTheme.text) }
    func appH3() -> some View { self.font(AppTextStyle.h3).foregroundColor(AppTheme.text) }
    func appParagraph() -> some View { self.font(AppTextStyle.paragraph).foregroundColor(AppTheme.text.opacity(0.72)) }
}

struct AppResetButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.appButtonChrome(role: isEnabled ? .danger : .disabled, isPressed: configuration.isPressed)
    }
}

struct AppCardStyle: ViewModifier {
    var isDisabled = false

    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface.opacity(isDisabled ? 0.54 : 0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.accent.opacity(isDisabled ? 0.22 : 0.55), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func appCardStyle(isDisabled: Bool = false) -> some View {
        modifier(AppCardStyle(isDisabled: isDisabled))
    }
}

struct AppScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String
    var scrolls: Bool
    let content: Content

    init(title: String, subtitle: String, scrolls: Bool = true, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.scrolls = scrolls
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            if scrolls {
                ScrollView { screenContent.padding() }
            } else {
                screenContent.padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var screenContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).appScreenTitle().accessibilityAddTraits(.isHeader)
                Text(subtitle).appParagraph().fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).appH2()
            if let subtitle {
                Text(subtitle).appParagraph().fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }
}

struct AppStatusBadge: View {
    let text: String
    let state: SolveState

    var body: some View {
        Text(text)
            .font(AppTextStyle.h3)
            .foregroundColor(AppTheme.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((state == .solved ? AppTheme.accent : AppTheme.highlight).opacity(0.62))
            .clipShape(Capsule())
            .fixedSize(horizontal: false, vertical: true)
    }
}

enum PuzzleAvailability: String, CaseIterable, Hashable {
    case active
    case comingSoon

    var label: String {
        switch self {
        case .active: return "Active"
        case .comingSoon: return "Coming soon"
        }
    }

    var detail: String {
        switch self {
        case .active: return "Ready to open and solve."
        case .comingSoon: return "Planned for a future update."
        }
    }

    var isInteractive: Bool { self == .active }
    var isActive: Bool { self == .active }
    var color: Color { isActive ? AppTheme.accent : AppTheme.highlight }
}

enum PuzzleCategory: String, CaseIterable, Identifiable {
    case sliding = "Sliding Puzzles"
    case twisty = "Twisty Puzzles"
    case logic = "Logic Puzzles"
    case mechanical = "Mechanical Puzzles"
    case visual = "Visual / Experimental"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .sliding: return "Solve 3×3, 4×4, and 5×5 sliding tile layouts."
        case .twisty: return "Enter and solve 2×2 and 3×3 cube states."
        case .logic: return "Solve classic Sudoku with guided input."
        case .mechanical: return "Clear the path in Rush Hour."
        case .visual: return "Visual and experimental ideas planned for later updates."
        }
    }

    var icon: String {
        switch self {
        case .sliding: return "square.grid.3x3.fill"
        case .twisty: return "cube.fill"
        case .logic: return "brain.head.profile"
        case .mechanical: return "car.fill"
        case .visual: return "puzzlepiece.extension.fill"
        }
    }
}

struct PuzzleAvailabilityDescriptor: Identifiable, Hashable {
    let id: String
    let category: PuzzleCategory
    let title: String
    let shortDescription: String
    let icon: String
    let status: PuzzleAvailability

    var placeholderDescription: String {
        status.isActive ? shortDescription : shortDescription
    }
}

enum PuzzleAvailabilityCatalog {
    static let all: [PuzzleAvailabilityDescriptor] = [
        PuzzleAvailabilityDescriptor(id: "sliding-3x3", category: .sliding, title: "3×3 Sliding Puzzle", shortDescription: "Enter all eight tiles and the blank, then solve with animated playback.", icon: "square.grid.3x3.fill", status: .active),
        PuzzleAvailabilityDescriptor(id: "sliding-4x4", category: .sliding, title: "4×4 Sliding Puzzle", shortDescription: "Solve with a bounded, memory-safe search and clear timeout feedback.", icon: "square.grid.4x3.fill", status: .active),
        PuzzleAvailabilityDescriptor(id: "sliding-5x5", category: .sliding, title: "5×5 Sliding Puzzle", shortDescription: "Enter a 5×5 board and receive a safe result without unbounded searching.", icon: "square.grid.3x3.square", status: .active),
        PuzzleAvailabilityDescriptor(id: "cube-2x2", category: .twisty, title: "2×2 Cube", shortDescription: "Enter sticker colors on a labeled cube net and solve bounded scrambles.", icon: "cube.fill", status: .active),
        PuzzleAvailabilityDescriptor(id: "cube-3x3", category: .twisty, title: "3×3 Rubik’s Cube", shortDescription: "Enter a validated cube state and use the bounded solver.", icon: "cube.transparent.fill", status: .active),
        PuzzleAvailabilityDescriptor(id: "pyraminx", category: .twisty, title: "Pyraminx", shortDescription: "Solve the four-sided twisty pyramid puzzle.", icon: "triangle.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "skewb", category: .twisty, title: "Skewb", shortDescription: "Solve the corner-turning cube puzzle.", icon: "diamond.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "megaminx", category: .twisty, title: "Megaminx", shortDescription: "Solve the dodecahedron twisty puzzle.", icon: "pentagon.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "square-1", category: .twisty, title: "Square-1", shortDescription: "Solve the shape-shifting cube puzzle.", icon: "square.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "sudoku", category: .logic, title: "Sudoku", shortDescription: "Enter givens, validate conflicts, and solve with clear feedback.", icon: "squareshape.split.3x3", status: .active),
        PuzzleAvailabilityDescriptor(id: "killer-sudoku", category: .logic, title: "Killer Sudoku", shortDescription: "Solve Sudoku puzzles with cage-sum rules.", icon: "sum", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "nonogram", category: .logic, title: "Nonogram", shortDescription: "Solve picture logic puzzles from row and column clues.", icon: "rectangle.grid.3x2.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "kakuro", category: .logic, title: "Kakuro", shortDescription: "Solve crossword-style number-sum puzzles.", icon: "number.square.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "slitherlink", category: .logic, title: "Slitherlink", shortDescription: "Solve loop puzzles using numbered grid clues.", icon: "point.topleft.down.curvedto.point.bottomright.up", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "rush-hour", category: .mechanical, title: "Rush Hour", shortDescription: "Slide blocking vehicles until the target car reaches the exit.", icon: "car.fill", status: .active),
        PuzzleAvailabilityDescriptor(id: "klotski", category: .mechanical, title: "Klotski", shortDescription: "Solve sliding block escape puzzles.", icon: "rectangle.3.group.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "peg-solitaire", category: .mechanical, title: "Peg Solitaire", shortDescription: "Solve peg-jumping board puzzles.", icon: "circle.grid.cross.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "maze-solver", category: .visual, title: "Maze Solver", shortDescription: "Find paths through drawn or generated mazes.", icon: "arrow.triangle.turn.up.right.diamond.fill", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "chess-puzzles", category: .visual, title: "Chess Puzzles", shortDescription: "Solve mate-in-N and best-move chess positions.", icon: "checkerboard.rectangle", status: .comingSoon),
        PuzzleAvailabilityDescriptor(id: "jigsaw-solver", category: .visual, title: "Jigsaw Solver", shortDescription: "Explore future image-based jigsaw solving.", icon: "puzzlepiece.extension.fill", status: .comingSoon)
    ]

    static func descriptors(in category: PuzzleCategory) -> [PuzzleAvailabilityDescriptor] {
        all.filter { $0.category == category }
    }

    static func activeDescriptors(in category: PuzzleCategory) -> [PuzzleAvailabilityDescriptor] {
        descriptors(in: category).filter { $0.status == .active }
    }

    static func comingSoonDescriptors(in category: PuzzleCategory) -> [PuzzleAvailabilityDescriptor] {
        descriptors(in: category).filter { $0.status == .comingSoon }
    }

    static func descriptor(id: String) -> PuzzleAvailabilityDescriptor {
        all.first { $0.id == id } ?? all[0]
    }
}

struct AppPuzzleCard: View {
    let descriptor: PuzzleAvailabilityDescriptor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: descriptor.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .frame(width: 38, height: 38)
                .background(descriptor.status.color.opacity(descriptor.status.isActive ? 0.95 : 0.55))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(descriptor.title).appH2()
                Text(descriptor.shortDescription).appParagraph().fixedSize(horizontal: false, vertical: true)
                Text(descriptor.status.label)
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(descriptor.status.color.opacity(descriptor.status.isActive ? 0.7 : 0.42))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 8)

            Image(systemName: descriptor.status.isInteractive ? "chevron.right" : "clock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.text.opacity(0.72))
                .padding(.top, 12)
                .accessibilityHidden(true)
        }
        .appCardStyle(isDisabled: !descriptor.status.isInteractive)
        .accessibilityElement(children: .combine)
        .accessibilityHint(descriptor.status.detail)
    }
}

struct AppPlaceholderScreen: View {
    @Environment(\.dismiss) private var dismiss
    let descriptor: PuzzleAvailabilityDescriptor

    var body: some View {
        AppScreenContainer(title: descriptor.title, subtitle: descriptor.category.rawValue) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: descriptor.icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(descriptor.status.color)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityHidden(true)

                AppSectionHeader(descriptor.status.label, subtitle: descriptor.placeholderDescription)

                Text("Planned for a future update")
                    .font(AppTextStyle.h3)
                    .foregroundColor(AppTheme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AppTheme.highlight.opacity(0.42))
                    .clipShape(Capsule())

                Text("No solve button is shown because this mode has not met all reliability criteria yet. This prevents crashes, infinite loading, and confusing partial results.")
                    .appParagraph()
                    .fixedSize(horizontal: false, vertical: true)

                Button("Back") { dismiss() }
                    .buttonStyle(AppBackButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .appCardStyle()
        }
    }
}

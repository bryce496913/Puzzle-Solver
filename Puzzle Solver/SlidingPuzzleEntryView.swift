import SwiftUI

struct SlidingPuzzleEntryView: View {
    let boardSize: Int

    @State private var selectedTileIndex: Int?
    @State private var tileAssignments: [Int?]

    init(boardSize: Int) {
        self.boardSize = boardSize
        _tileAssignments = State(initialValue: Array(repeating: nil, count: boardSize * boardSize))
    }

    private var allowedValues: [Int] {
        Array(1..<(boardSize * boardSize))
    }

    private var usedValues: Set<Int> {
        Set(tileAssignments.compactMap { $0 })
    }

    private var emptyTileCount: Int {
        tileAssignments.filter { $0 == nil }.count
    }

    private var uniqueAssignedCount: Int {
        usedValues.count
    }

    private var validationState: PuzzleEntryValidationState {
        let assignedCount = tileAssignments.compactMap { $0 }.count
        if assignedCount < allowedValues.count {
            return .incomplete
        }

        guard emptyTileCount == 1, uniqueAssignedCount == allowedValues.count else {
            return .invalid
        }

        return .ready
    }

    private var canSolve: Bool {
        validationState == .ready && entryState != nil
    }

    private var helperText: String {
        switch validationState {
        case .incomplete:
            let missingCount = allowedValues.count - tileAssignments.compactMap { $0 }.count
            if missingCount == 1 {
                return "Add 1 more tile value, then leave exactly one tile empty."
            }
            return "Add \(missingCount) more tile values. Leave exactly one tile empty."
        case .invalid:
            return "That board setup is invalid. Use each number once and keep one empty tile."
        case .ready:
            return "Looks good. Tap Solve when you're ready."
        }
    }

    private var entryState: SlidingPuzzleState? {
        guard validationState == .ready else { return nil }
        let tiles = tileAssignments.map { $0 ?? 0 }
        return SlidingPuzzleState(size: boardSize, tiles: tiles)
    }


    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.large) {
                Text("Set Up \(boardSize)×\(boardSize) Puzzle")
                    .appTextStyle(.h1)
                    .foregroundStyle(AppTheme.Colors.highlight)

                SlidingPuzzleBoardView(
                    boardValues: tileAssignments,
                    boardSize: boardSize,
                    selectedTileIndex: selectedTileIndex,
                    onTileTap: { index in
                        selectedTileIndex = index
                    },
                    mode: .input
                )
                .appSurfaceCard()

                VStack(spacing: AppTheme.Spacing.medium) {
                    helperBanner

                    SlidingPuzzleKeypadView(
                        boardSize: boardSize,
                        selectedValue: nil,
                        usedValues: usedValues,
                        onTap: { value in
                            assign(value: value)
                        },
                        onClear: {
                            clearSelectedTile()
                        }
                    )

                    NavigationLink {
                        if let entryState {
                            SolvingView(initialState: entryState)
                        }
                    } label: {
                        Text("Solve")
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!canSolve)
                    .opacity(canSolve ? 1 : 0.5)
                }
                .appSurfaceCard()

                HStack(spacing: AppTheme.Spacing.medium) {
                    NavigationLink {
                        MainMenuView()
                    } label: {
                        Text("Back")
                    }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.surface))

                    NavigationLink {
                        SlidingPuzzleEntryView(boardSize: boardSize)
                    } label: {
                        Text("Reset")
                    }
                    .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent))
                }
            }
            .padding(AppTheme.Spacing.large)
        }
        .navigationBarHidden(true)
    }

    private var helperBanner: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(helperText)
                .appTextStyle(.paragraph)
                .foregroundStyle(validationState == .invalid ? AppTheme.Colors.highlight : AppTheme.Colors.text.opacity(0.9))

            Text("Tip: select a board tile first, then tap a number or Blank.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }

    private func assign(value: Int) {
        guard let selectedTileIndex else { return }

        if let existing = tileAssignments[selectedTileIndex], existing != value {
            tileAssignments[selectedTileIndex] = nil
        }

        guard !usedValues.contains(value) || tileAssignments[selectedTileIndex] == value else { return }
        tileAssignments[selectedTileIndex] = value
    }

    private func clearSelectedTile() {
        guard let selectedTileIndex else { return }
        tileAssignments[selectedTileIndex] = nil
    }
}

private enum PuzzleEntryValidationState {
    case incomplete
    case invalid
    case ready
}

struct SlidingPuzzleKeypadView: View {
    let boardSize: Int
    let selectedValue: Int?
    let usedValues: Set<Int>
    let onTap: (Int) -> Void
    let onClear: () -> Void

    private var values: [Int] {
        Array(1..<(boardSize * boardSize))
    }

    private var keypadColumns: [GridItem] {
        let maxColumns = boardSize == 3 ? 3 : 4
        return Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small), count: maxColumns)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ScrollView {
                LazyVGrid(columns: keypadColumns, spacing: AppTheme.Spacing.small) {
                    ForEach(values, id: \.self) { value in
                        KeypadButton(
                            title: "\(value)",
                            isDisabled: usedValues.contains(value) && selectedValue != value,
                            isSelected: selectedValue == value,
                            onTap: { onTap(value) }
                        )
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xSmall)
            }
            .frame(maxHeight: boardSize == 3 ? 130 : 190)

            KeypadButton(
                title: "Blank",
                isDisabled: false,
                isSelected: false,
                onTap: onClear,
                subtitle: "Clear selected tile"
            )
        }
    }
}

struct KeypadButton: View {
    let title: String
    let isDisabled: Bool
    let isSelected: Bool
    let onTap: () -> Void
    var subtitle: String?

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text(title)
                    .appTextStyle(.h3)
                    .foregroundStyle(AppTheme.Colors.text)

                if let subtitle {
                    Text(subtitle)
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: subtitle == nil ? 44 : 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }

    private var backgroundColor: Color {
        isSelected ? AppTheme.Colors.highlight.opacity(0.8) : AppTheme.Colors.accent
    }

    private var borderColor: Color {
        isSelected ? AppTheme.Colors.highlight : AppTheme.Colors.text.opacity(0.7)
    }
}

#Preview {
    NavigationStack {
        SlidingPuzzleEntryView(boardSize: 4)
    }
}

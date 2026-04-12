import SwiftUI

/// Backward-compatible name used by navigation.
struct NewPuzzleView: View {
    let puzzleSize: Int

    var body: some View {
        SlidingPuzzleEntryView(boardSize: puzzleSize)
    }
}

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

    private var isConfigurationValid: Bool {
        tileAssignments.filter { $0 == nil }.count == 1 && usedValues.count == allowedValues.count
    }

    private var entryState: SlidingPuzzleState? {
        guard isConfigurationValid else { return nil }
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
                    .disabled(entryState == nil)
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
                onTap: onClear
            )
        }
    }
}

struct KeypadButton: View {
    let title: String
    let isDisabled: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .appTextStyle(.h3)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(backgroundColor)
                .foregroundStyle(AppTheme.Colors.text)
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
